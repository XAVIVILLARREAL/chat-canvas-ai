//! A.6 — Centro de Configuración:
//! 1) valor efectivo con herencia Agente > Sesión > Proyecto > Global
//! 2) override de sesión escribe/borra en agent_config
//! 3) el chat capturado por el mock usa temperature/model del setting

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
    let url = format!("sqlite://{}/cfg.db", tmp.path().display());
    let state = AppState::connect(&url).await.unwrap();
    let app = create_router(state);
    let (_, session) = req_json(
        app.clone(),
        "POST",
        "/api/sessions",
        Some(json!({"title": "A6 cfg"})),
    )
    .await;
    let sid = session["id"].as_str().unwrap().to_string();
    std::mem::forget(tmp);
    (app, sid)
}

/// Origen y valor de una clave en la vista efectiva.
fn entry<'a>(eff: &'a Value, key: &str) -> &'a Value {
    eff["items"]
        .as_array()
        .unwrap()
        .iter()
        .find(|e| e["key"] == key)
        .unwrap_or_else(|| panic!("clave {key} no está en {eff}"))
}

/// 1) herencia: el scope más específico gana; sin override, hereda.
#[tokio::test]
async fn valor_efectivo_por_capa() {
    let (app, sid) = setup().await;

    // Global: temperature 0.9
    let (st, _) = req_json(
        app.clone(),
        "PUT",
        "/api/settings",
        Some(json!({"key": "temperature", "value": 0.9})),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
    // Proyecto: temperature 0.5 + model propio
    let (st, _) = req_json(
        app.clone(),
        "PUT",
        "/api/settings/local-default",
        Some(json!({"key": "temperature", "value": 0.5})),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
    // Sesión: temperature 0.2
    let (st, _) = req_json(
        app.clone(),
        "PUT",
        &format!("/api/sessions/{sid}/settings"),
        Some(json!({"key": "temperature", "value": 0.2})),
    )
    .await;
    assert_eq!(st, StatusCode::OK);

    // con session_id → gana la sesión
    let (_, eff) = req_json(
        app.clone(),
        "GET",
        &format!("/api/settings/local-default/effective?session_id={sid}"),
        None,
    )
    .await;
    assert_eq!(entry(&eff, "temperature")["value"], 0.2);
    assert_eq!(entry(&eff, "temperature")["origin"], "session");

    // sin session_id → gana el proyecto
    let (_, eff) = req_json(
        app.clone(),
        "GET",
        "/api/settings/local-default/effective",
        None,
    )
    .await;
    assert_eq!(entry(&eff, "temperature")["value"], 0.5);
    assert_eq!(entry(&eff, "temperature")["origin"], "project");

    // quitando el override de sesión → vuelve a heredar del proyecto
    let (st, _) = req_json(
        app.clone(),
        "DELETE",
        &format!("/api/sessions/{sid}/settings?key=temperature"),
        None,
    )
    .await;
    assert_eq!(st, StatusCode::OK);
    let (_, eff) = req_json(
        app.clone(),
        "GET",
        &format!("/api/settings/local-default/effective?session_id={sid}"),
        None,
    )
    .await;
    assert_eq!(entry(&eff, "temperature")["value"], 0.5);
    assert_eq!(entry(&eff, "temperature")["origin"], "project");

    // sesión inexistente en PUT → 404
    let (st, _) = req_json(
        app.clone(),
        "PUT",
        "/api/sessions/no-existe/settings",
        Some(json!({"key": "temperature", "value": 1})),
    )
    .await;
    assert_eq!(st, StatusCode::NOT_FOUND);
}

/// 1b) la capa AGENTE (AgentConfig del agente) gana sobre todas.
#[tokio::test]
async fn capa_agente_gana() {
    let (app, sid) = setup().await;

    let (st, agent) = req_json(
        app.clone(),
        "POST",
        "/api/agents",
        Some(json!({"name": "jefe", "description": "", "role": "coordinator", "created_by": "t"})),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{agent}");
    let aid = agent["id"].as_str().unwrap().to_string();
    // default del dominio: model gpt-4o, temperature 0.7
    assert_eq!(agent["config"]["model"], "gpt-4o");

    let (st, _) = req_json(
        app.clone(),
        "PUT",
        "/api/settings",
        Some(json!({"key": "model", "value": "global-model"})),
    )
    .await;
    assert_eq!(st, StatusCode::OK);

    let (_, eff) = req_json(
        app.clone(),
        "GET",
        &format!("/api/settings/local-default/effective?session_id={sid}&agent_id={aid}"),
        None,
    )
    .await;
    assert_eq!(entry(&eff, "model")["value"], "gpt-4o", "el agente gana sobre global");
    assert_eq!(entry(&eff, "model")["origin"], "agent");
    assert_eq!(entry(&eff, "temperature")["origin"], "agent");
    // temperature es f32 en el dominio → comparar con tolerancia
    let t = entry(&eff, "temperature")["value"].as_f64().unwrap();
    assert!((t - 0.7).abs() < 0.001, "temperature del agente (f32): {t}");
}

/// 2) el chat capturado usa temperature/model resueltos de settings.
#[tokio::test]
async fn chat_usa_settings_de_sesion() {
    std::env::set_var(
        "CANVAS_KEK",
        {
            use base64::Engine as _;
            base64::engine::general_purpose::STANDARD.encode([7u8; 32])
        },
    );

    let (app, sid) = setup().await;

    // overrides de sesión: model + temperature
    for (k, v) in [("model", json!("mock-model")), ("temperature", json!(0.42))] {
        let (st, _) = req_json(
            app.clone(),
            "PUT",
            &format!("/api/sessions/{sid}/settings"),
            Some(json!({"key": k, "value": v})),
        )
        .await;
        assert_eq!(st, StatusCode::OK);
    }

    // provider mock que captura el request
    type Captured = std::sync::Arc<tokio::sync::Mutex<Option<Value>>>;
    let captured: Captured = Default::default();
    let mock = axum::Router::new()
        .route("/v1/chat/completions", post(mock_capture))
        .with_state(captured.clone());
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move { axum::serve(listener, mock).await.unwrap() });

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

    let req = Request::builder()
        .method("POST")
        .uri(format!("/api/sessions/{sid}/chat/stream"))
        .header("content-type", "application/json")
        .body(Body::from(json!({"content": "ping"}).to_string()))
        .unwrap();
    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let _ = resp.into_body().collect().await.unwrap().to_bytes();

    let capturado = captured.lock().await.take().expect("mock capturó el request");
    assert_eq!(
        capturado["temperature"], 0.42,
        "el request usó la temperature del setting de sesión: {capturado}"
    );
    assert_eq!(
        capturado["model"], "mock-model",
        "el request usó el model del setting de sesión"
    );
}

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
