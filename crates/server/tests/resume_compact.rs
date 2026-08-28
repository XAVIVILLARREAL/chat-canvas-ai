//! A.8 — Resume inteligente:
//! 1) card de resume: turno interrumpido (último = user, sin respuesta)
//! 2) /compact con mock: historial viejo → mensaje system resumen + recientes
//! 3) /compact sin provider → error honesto; /compact sin nada viejo → no-op

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
    let url = format!("sqlite://{}/a8.db", tmp.path().display());
    let state = AppState::connect(&url).await.unwrap();
    let app = create_router(state);
    let (_, session) = req_json(
        app.clone(),
        "POST",
        "/api/sessions",
        Some(json!({"title": "A8"})),
    )
    .await;
    let sid = session["id"].as_str().unwrap().to_string();
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

fn b64(data: &[u8]) -> String {
    use base64::Engine as _;
    base64::engine::general_purpose::STANDARD.encode(data)
}

/// 1) la card de resume detecta el turno interrumpido.
#[tokio::test]
async fn resume_detecta_turno_interrumpido() {
    let (app, sid) = setup().await;

    // sesión vacía → 0 mensajes, sin card
    let (_, r) = req_json(app.clone(), "GET", &format!("/api/sessions/{sid}/resume"), None).await;
    assert_eq!(r["total_messages"], 0);
    assert_eq!(r["unanswered"], false);

    // el usuario pregunta y NADIE responde (interrumpido)
    add_msg(&app, &sid, "user", "¿cómo importo un csv?").await;
    let (_, r) = req_json(app.clone(), "GET", &format!("/api/sessions/{sid}/resume"), None).await;
    assert_eq!(r["unanswered"], true, "último = user sin respuesta");
    assert_eq!(r["total_messages"], 1);
    assert_eq!(r["last_user_message"], "¿cómo importo un csv?");
    assert!(r["last_activity_at"].as_i64().unwrap() > 0);

    // el asistente responde → ya no está interrumpida
    add_msg(&app, &sid, "assistant", "usa el asistente de importación").await;
    let (_, r) = req_json(app.clone(), "GET", &format!("/api/sessions/{sid}/resume"), None).await;
    assert_eq!(r["unanswered"], false);
    assert_eq!(r["total_messages"], 2);

    // sesión inexistente → 404
    let (st, _) = req_json(app.clone(), "GET", "/api/sessions/no-existe/resume", None).await;
    assert_eq!(st, StatusCode::NOT_FOUND);
}

async fn spawn_mock() -> String {
    let mock = axum::Router::new().route(
        "/v1/chat/completions",
        post(|| async {
            axum::Json(json!({
                "id": "chatcmpl-sum",
                "choices": [{ "message": { "role": "assistant", "content": "RESUMEN-MOCK: hablaron de csv y chistes" }, "finish_reason": "stop" }],
                "usage": { "prompt_tokens": 10, "completion_tokens": 8 }
            }))
        }),
    );
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move { axum::serve(listener, mock).await.unwrap() });
    format!("http://{addr}/v1")
}

async fn register_provider(app: &axum::Router, base: &str) {
    std::env::set_var("CANVAS_KEK", b64(&[7u8; 32]));
    let (st, _) = req_json(
        app.clone(),
        "POST",
        "/api/providers",
        Some(json!({
            "provider_type": "generic",
            "name": "mock-sum",
            "base_url": base,
            "api_key": "k",
            "validate": false
        })),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
}

/// 2) /compact: 6 mensajes, keep 2 → 4 viejos → resumen system + 2 recientes.
#[tokio::test]
async fn compact_comprime_historial_viejo() {
    let (app, sid) = setup().await;
    register_provider(&app, &spawn_mock().await).await;

    for i in 1..=6 {
        let role = if i % 2 == 1 { "user" } else { "assistant" };
        // contenido sustancial: 4 viejos deben pesar MÁS que el resumen que los reemplaza
        add_msg(&app, &sid, role, &format!("mensaje numero {i}: {}", "contenido sustancial ".repeat(6))).await;
    }
    // contexto antes: 6 mensajes de historial
    let (_, ctx) = req_json(app.clone(), "GET", &format!("/api/sessions/{sid}/context"), None).await;
    let total_antes = ctx["total_tokens"].as_u64().unwrap();

    let (st, c) = req_json(
        app.clone(),
        "POST",
        &format!("/api/sessions/{sid}/compact"),
        Some(json!({"keep": 2})),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{c}");
    assert_eq!(c["compacted"], true);
    assert_eq!(c["removed"], 4);

    // mensajes: resumen (system) + 2 recientes; el resumen va primero en el tiempo
    let (_, msgs) = req_json(app.clone(), "GET", &format!("/api/sessions/{sid}/messages"), None).await;
    let msgs = msgs.as_array().unwrap();
    assert_eq!(msgs.len(), 3, "resumen + 2 recientes");
    assert_eq!(msgs[0]["role"], "system");
    assert!(
        msgs[0]["content"].as_str().unwrap().contains("RESUMEN-MOCK"),
        "el resumen viene del provider mock: {}",
        msgs[0]["content"]
    );
    assert_eq!(
        msgs[1]["content"].as_str().unwrap().split(':').next().unwrap().trim(),
        "mensaje numero 5"
    );
    assert_eq!(
        msgs[2]["content"].as_str().unwrap().split(':').next().unwrap().trim(),
        "mensaje numero 6"
    );

    // el medidor de contexto refleja la compresión
    let (_, ctx) = req_json(app.clone(), "GET", &format!("/api/sessions/{sid}/context"), None).await;
    assert!(
        ctx["total_tokens"].as_u64().unwrap() < total_antes,
        "el historial comprimido pesa menos: {} < {total_antes}",
        ctx["total_tokens"]
    );
}

/// 3) sin provider → 400 honesto; sin historial viejo → no-op (compacted=false).
#[tokio::test]
async fn compact_casos_borde() {
    let (app, sid) = setup().await;
    for i in 1..=6 {
        add_msg(&app, &sid, "user", &format!("m{i}")).await;
    }

    // sin provider: el resumen es trabajo de LLM → error honesto (400/502)
    let (st, _) = req_json(
        app.clone(),
        "POST",
        &format!("/api/sessions/{sid}/compact"),
        Some(json!({"keep": 2})),
    )
    .await;
    assert!(
        st == StatusCode::BAD_REQUEST || st == StatusCode::BAD_GATEWAY,
        "sin provider no compacta: {st}"
    );

    // con provider pero sin nada viejo → no-op documentado
    register_provider(&app, &spawn_mock().await).await;
    let (_, s2) = req_json(
        app.clone(),
        "POST",
        "/api/sessions",
        Some(json!({"title": "casi vacía"})),
    )
    .await;
    let sid2 = s2["id"].as_str().unwrap().to_string();
    add_msg(&app, &sid2, "user", "hola").await;
    let (_, c) = req_json(
        app.clone(),
        "POST",
        &format!("/api/sessions/{sid2}/compact"),
        Some(json!({"keep": 4})),
    )
    .await;
    assert_eq!(c["compacted"], false);
    assert_eq!(c["reason"], "nada que comprimir");
}
