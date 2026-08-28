//! A.7 — Modo ENCARGO:
//! 1) crear encargo (sin prompt del usuario) → runner en background → completed
//!    con evidencia (result/model/tokens/duración) y mensajes en la sesión
//! 2) sin provider → failed con error honesto
//! 3) listado por proyecto, más reciente primero

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

/// Espera a que el encargo salga de pending/running (runner en background).
async fn wait_terminal(app: &axum::Router, id: &str) -> Value {
    for _ in 0..40 {
        let (st, e) = req_json(app.clone(), "GET", &format!("/api/encargos/{id}"), None).await;
        assert_eq!(st, StatusCode::OK);
        let status = e["status"].as_str().unwrap();
        if status == "completed" || status == "failed" {
            return e;
        }
        tokio::time::sleep(std::time::Duration::from_millis(100)).await;
    }
    panic!("encargo {id} no terminó a tiempo");
}

fn b64(data: &[u8]) -> String {
    use base64::Engine as _;
    base64::engine::general_purpose::STANDARD.encode(data)
}

/// Provider mock NO-streaming (el runner usa chat no-streaming).
async fn spawn_mock(provider_name: &str) -> String {
    let name = provider_name.to_string();
    let mock = axum::Router::new().route(
        "/v1/chat/completions",
        post(move || {
            let name = name.clone();
            async move {
                axum::Json(json!({
                    "id": "chatcmpl-enc",
                    "choices": [{ "message": { "role": "assistant", "content": format!("evidencia de {name}: criterios cumplidos 1) 2) 3)") }, "finish_reason": "stop" }],
                    "usage": { "prompt_tokens": 12, "completion_tokens": 30 }
                }))
            }
        }),
    );
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move { axum::serve(listener, mock).await.unwrap() });
    format!("http://{addr}/v1")
}

async fn register_provider(app: &axum::Router, name: &str, base: &str) {
    let (st, _) = req_json(
        app.clone(),
        "POST",
        "/api/providers",
        Some(json!({
            "provider_type": "generic",
            "name": name,
            "base_url": base,
            "api_key": "test-key",
            "validate": false
        })),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
}

/// 1) flujo completo: crear sin prompt → completado con evidencia en sesión.
#[tokio::test]
async fn encargo_se_completa_con_mock() {
    std::env::set_var("CANVAS_KEK", b64(&[7u8; 32]));
    let tmp = tempfile::tempdir().unwrap();
    let url = format!("sqlite://{}/enc.db", tmp.path().display());
    let state = AppState::connect(&url).await.unwrap();
    let app = create_router(state);
    std::mem::forget(tmp);

    let base = spawn_mock("mock-enc").await;
    register_provider(&app, "mock-enc", &base).await;

    let (st, enc) = req_json(
        app.clone(),
        "POST",
        "/api/encargos",
        Some(json!({
            "title": "Preparar informe",
            "criteria": "Resumen ejecutivo\nDatos verificados\nConclusión clara"
        })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{enc}");
    assert_eq!(enc["status"], "pending");
    let encargo_id = enc["id"].as_str().unwrap().to_string();
    let session_id = enc["session_id"].as_str().unwrap().to_string();

    let e = wait_terminal(&app, &encargo_id).await;
    assert_eq!(e["status"], "completed", "evidencia: {e}");
    assert!(
        e["result"].as_str().unwrap().contains("criterios cumplidos"),
        "la evidencia es la respuesta del agente: {e}"
    );
    assert_eq!(e["model"], "mock-enc");
    assert_eq!(e["tokens"], 42);
    assert!(e["duration_ms"].as_i64().unwrap() >= 0);

    // evidencia también en la sesión: prompt compuesto (título + criterios) + respuesta
    let (_, msgs) = req_json(
        app.clone(),
        "GET",
        &format!("/api/sessions/{session_id}/messages"),
        None,
    )
    .await;
    let msgs = msgs.as_array().unwrap();
    assert_eq!(msgs.len(), 2, "user (prompt compuesto) + assistant (respuesta)");
    let user_prompt = msgs[0]["content"].as_str().unwrap();
    assert!(user_prompt.contains("Preparar informe"), "el prompt incluye el título");
    assert!(user_prompt.contains("Datos verificados"), "el prompt incluye los criterios");
    assert_eq!(msgs[1]["role"], "assistant");

    // título de la sesión auto-creada
    let (_, ses) = req_json(app.clone(), "GET", &format!("/api/sessions/{session_id}"), None).await;
    assert_eq!(ses["title"], "Encargo: Preparar informe");

    // listado: el encargo aparece
    let (_, list) = req_json(app.clone(), "GET", "/api/encargos", None).await;
    assert_eq!(list.as_array().unwrap().len(), 1);
}

/// 2) sin provider configurado → failed con error honesto (no cuelga).
#[tokio::test]
async fn encargo_sin_provider_falla() {
    let tmp = tempfile::tempdir().unwrap();
    let url = format!("sqlite://{}/enc2.db", tmp.path().display());
    let state = AppState::connect(&url).await.unwrap();
    let app = create_router(state);
    std::mem::forget(tmp);

    let (st, enc) = req_json(
        app.clone(),
        "POST",
        "/api/encargos",
        Some(json!({"title": "X", "criteria": "hacer Y"})),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
    let e = wait_terminal(&app, enc["id"].as_str().unwrap()).await;
    assert_eq!(e["status"], "failed");
    assert!(
        e["error"].as_str().unwrap().contains("provider"),
        "el error menciona al provider: {e}"
    );
    assert!(e["result"].is_null());
}

/// 3) validación: título o criterios vacíos → 400.
#[tokio::test]
async fn encargo_validacion() {
    let tmp = tempfile::tempdir().unwrap();
    let url = format!("sqlite://{}/enc3.db", tmp.path().display());
    let state = AppState::connect(&url).await.unwrap();
    let app = create_router(state);
    std::mem::forget(tmp);

    let (st, _) = req_json(
        app.clone(),
        "POST",
        "/api/encargos",
        Some(json!({"title": "  ", "criteria": "criterio"})),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST);

    let (st, _) = req_json(
        app.clone(),
        "POST",
        "/api/encargos",
        Some(json!({"title": "t", "criteria": ""})),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST);
}
