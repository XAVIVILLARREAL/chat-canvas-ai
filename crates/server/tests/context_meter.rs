//! A.5 — Medidor y debug de contexto:
//! 1) GET /api/sessions/:id/context refleja el desglose del historial real
//! 2) el límite (setting `context_max_tokens`) trunca lo que se envía
//! 3) request capturado por el provider mock == lo que muestra el medidor
//!    (meta `context` del evento `done` del stream)

use axum::body::Body;
use axum::http::{Request, StatusCode};
use axum::response::IntoResponse;
use axum::routing::post;
use canvas_ai_server::api::{create_router, AppState};
use http_body_util::BodyExt;
use serde_json::{json, Value};
use tower::ServiceExt;

async fn json_body(resp: axum::response::Response) -> Value {
    let bytes = resp.into_body().collect().await.unwrap().to_bytes();
    serde_json::from_slice(&bytes).expect("respuesta JSON")
}

async fn req_json(
    app: axum::Router,
    method: &str,
    uri: &str,
    body: Option<Value>,
) -> (StatusCode, Value) {
    let method = axum::http::Method::from_bytes(method.as_bytes()).unwrap();
    let mut builder = Request::builder().method(method).uri(uri);
    if body.is_some() {
        builder = builder.header("content-type", "application/json");
    }
    let req = builder
        .body(Body::from(body.map(|b| b.to_string()).unwrap_or_default()))
        .unwrap();
    let resp = app.oneshot(req).await.unwrap();
    let status = resp.status();
    if status == StatusCode::NO_CONTENT {
        return (status, Value::Null);
    }
    let is_json = resp
        .headers()
        .get("content-type")
        .and_then(|v| v.to_str().ok())
        .map(|v| v.contains("application/json"))
        .unwrap_or(false);
    if !is_json {
        return (status, Value::Null);
    }
    (status, json_body(resp).await)
}

async fn setup() -> (axum::Router, String) {
    let tmp = tempfile::tempdir().unwrap();
    let url = format!("sqlite://{}/ctx.db", tmp.path().display());
    let state = AppState::connect(&url).await.unwrap();
    let app = create_router(state);
    let (_, session) = req_json(
        app.clone(),
        "POST",
        "/api/sessions",
        Some(json!({"title": "A5 ctx"})),
    )
    .await;
    let sid = session["id"].as_str().unwrap().to_string();
    // std::mem::forget para que la tmpdir viva durante el test (SQLite abierto)
    std::mem::forget(tmp);
    (app, sid)
}

async fn add_msg(app: &axum::Router, sid: &str, role: &str, content: &str) {
    let (st, _) = req_json(
        app.clone(),
        "POST",
        &format!("/api/sessions/{sid}/messages"),
        Some(json!({"role": role, "content": content})),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
}

/// Estimación chars/4 (igual que core::context::estimate_tokens) para comparar.
fn est(s: &str) -> usize {
    (s.chars().count() + 3) / 4
}

/// Handler del mock: captura el body del completion y responde un stream mínimo.
async fn mock_capture(
    axum::extract::State(captured): axum::extract::State<
        std::sync::Arc<tokio::sync::Mutex<Option<Value>>>,
    >,
    axum::Json(body): axum::Json<Value>,
) -> axum::response::Response {
    *captured.lock().await = Some(body);
    use axum::response::sse::{Event, KeepAlive, Sse};
    let data = json!({
        "choices": [{ "delta": { "content": "ok" }, "finish_reason": null }]
    });
    let ev = futures::stream::iter(vec![Ok::<_, std::convert::Infallible>(
        Event::default().data(data.to_string()),
    )]);
    Sse::new(ev).keep_alive(KeepAlive::default()).into_response()
}

#[allow(clippy::needless_return_with_question_mark)]
fn b64(data: &[u8]) -> String {
    use base64::Engine as _;
    base64::engine::general_purpose::STANDARD.encode(data)
}

/// 1) desglose en vivo con historial real; límite holgado → nada se recorta.
#[tokio::test]
async fn contexto_desglose_en_vivo() {
    let (app, sid) = setup().await;

    add_msg(&app, &sid, "user", "hola").await;
    add_msg(&app, &sid, "assistant", "¡Hola! ¿en qué te ayudo?").await;

    let (st, ctx) = req_json(app.clone(), "GET", &format!("/api/sessions/{sid}/context"), None).await;
    assert_eq!(st, StatusCode::OK, "{ctx}");

    let sources = ctx["sources"].as_array().unwrap();
    assert_eq!(sources.len(), 5, "las 5 fuentes siempre presentes");
    let get = |name: &str| {
        sources
            .iter()
            .find(|s| s["source"] == name)
            .unwrap()["tokens"]
            .as_u64()
            .unwrap()
    };
    assert_eq!(get("system"), 0, "sin mensajes system aún");
    let esperado: u64 = (est("hola") + est("¡Hola! ¿en qué te ayudo?")) as u64;
    assert_eq!(get("historial"), esperado, "historial = estimación del contenido real");
    assert_eq!(get("knowledge"), 0);
    assert_eq!(get("tools"), 0);
    assert_eq!(get("archivos"), 0);
    assert_eq!(ctx["total_tokens"], esperado);
    assert_eq!(ctx["sent_tokens"], ctx["total_tokens"], "límite default: sin truncado");
    assert_eq!(ctx["limit_tokens"], 8192, "límite default documentado");

    // sesión inexistente → 404
    let (st, _) = req_json(app.clone(), "GET", "/api/sessions/no-existe/context", None).await;
    assert_eq!(st, StatusCode::NOT_FOUND);
}

/// 2) límite chico → el medidor muestra truncado y el request capturado coincide.
#[tokio::test]
async fn limite_recorta_y_request_capturado_coincide() {
    // KEK para el vault del provider BYOK (mock)
    std::env::set_var("CANVAS_KEK", b64(&[7u8; 32]));

    let (app, sid) = setup().await;
    add_msg(&app, &sid, "user", "mensaje viejo numero uno que ocupa espacio").await;
    // contenido largo para superar el piso del límite (256) y forzar truncado
    add_msg(&app, &sid, "assistant", &"palabra ".repeat(80)).await;
    add_msg(&app, &sid, "user", &"respuesta ".repeat(40)).await;
    add_msg(&app, &sid, "assistant", "penultimo mensaje tres").await;

    // límite global chico (override de settings, herencia global → proyecto)
    let (st, _) = req_json(
        app.clone(),
        "PUT",
        "/api/settings",
        Some(json!({"key": "context_max_tokens", "value": 256})),
    )
    .await;
    assert_eq!(st, StatusCode::OK);

    let (_, ctx) = req_json(app.clone(), "GET", &format!("/api/sessions/{sid}/context"), None).await;
    assert_eq!(ctx["limit_tokens"], 256);
    let total = ctx["total_tokens"].as_u64().unwrap();
    let sent_antes = ctx["sent_tokens"].as_u64().unwrap();
    assert!(sent_antes < total, "historial truncado por el límite: {ctx}");

    // provider mock que CAPTURA el request y responde un stream mínimo
    type Captured = std::sync::Arc<tokio::sync::Mutex<Option<Value>>>;
    let captured: Captured = Default::default();
    let mock = axum::Router::new()
        .route("/v1/chat/completions", post(mock_capture))
        .with_state(captured.clone());
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move { axum::serve(listener, mock).await.unwrap() });

    // provider BYOK apuntando al mock (validate:false — el mock no es OpenAI real)
    let (st, _) = req_json(
        app.clone(),
        "POST",
        "/api/providers",
        Some(json!({
            "provider_type": "generic",
            "name": "mock-cap",
            "base_url": format!("http://{addr}/v1"),
            "api_key": "test-key",
            "validate": false
        })),
    )
    .await;
    assert_eq!(st, StatusCode::OK);

    // chat streaming (el medidor del gateway calcula el contexto incluida la user msg nueva)
    let req = Request::builder()
        .method("POST")
        .uri(format!("/api/sessions/{sid}/chat/stream"))
        .header("content-type", "application/json")
        .body(Body::from(json!({"content": "mensaje final cuatro"}).to_string()))
        .unwrap();
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let bytes = resp.into_body().collect().await.unwrap().to_bytes();
    let sse = String::from_utf8(bytes.to_vec()).unwrap();

    // meta del evento done: el desglose que "mostraría el medidor"
    let meta = sse
        .lines()
        .filter_map(|l| l.strip_prefix("data: "))
        .filter_map(|l| serde_json::from_str::<Value>(l).ok())
        .find(|v| v["done"] == json!(true))
        .expect("evento done en el stream");
    let ctx_stream = &meta["context"];
    assert!(ctx_stream.is_object(), "meta incluye desglose A.5: {meta}");

    // ── la aserción clave: request capturado == lo que muestra el medidor ──
    let capturado = captured.lock().await.take().expect("mock capturó el request");
    let msgs = capturado["messages"].as_array().unwrap();
    let tokens_capturados: usize = msgs
        .iter()
        .map(|m| est(m["content"].as_str().unwrap()))
        .sum();
    assert_eq!(
        tokens_capturados as u64,
        ctx_stream["sent_tokens"],
        "tokens del request capturado = sent_tokens del medidor"
    );
    assert_eq!(
        msgs.last().unwrap()["content"],
        "mensaje final cuatro",
        "el mensaje más reciente siempre viaja"
    );
    assert!(
        tokens_capturados as u64 <= sent_antes + est("mensaje final cuatro") as u64,
        "solo se añadieron la user msg nueva (+system): capturado {tokens_capturados} ≤ {sent_antes}+{}",
        est("mensaje final cuatro")
    );
}
