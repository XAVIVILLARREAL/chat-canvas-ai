//! Slice 0.1 — wiring del server: CRUD HTTP + persistencia real en SQLite.
//! El mini-gate "la data sobrevive a reinicio del server" se prueba aquí
//! a nivel HTTP: router 1 crea → drop → router 2 (mismo archivo) lee.

use axum::body::Body;
use axum::http::{Request, StatusCode};
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
    // los errores son texto plano ("X not found"); solo parseamos JSON
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

#[tokio::test]
async fn crud_http_y_persistencia_tras_reinicio() {
    let tmp = tempfile::tempdir().unwrap();
    let url = format!("sqlite://{}/server.db", tmp.path().display());

    // ── "arranque" 1 del server ──
    let state = AppState::connect(&url).await.unwrap();
    let app = create_router(state);

    // health (responde texto plano "ok")
    let resp = app
        .clone()
        .oneshot(Request::builder().uri("/healthz").body(Body::empty()).unwrap())
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);

    // create canvas
    let (st, canvas) = req_json(app.clone(), "POST", "/api/canvases",
        Some(json!({"name": "Mi Canvas", "description": "test", "created_by": "tester"})))
        .await;
    assert_eq!(st, StatusCode::OK, "body: {canvas}");
    let canvas_id = canvas["id"].as_str().unwrap().to_string();

    // get canvas
    let (st, got) = req_json(app.clone(), "GET", &format!("/api/canvases/{canvas_id}"), None).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(got["name"], "Mi Canvas");

    // create skill + update (nueva versión)
    let (st, skill) = req_json(app.clone(), "POST", "/api/skills",
        Some(json!({"name": "revisor", "description": "d", "category": "custom", "created_by": "t"})))
        .await;
    assert_eq!(st, StatusCode::OK, "body: {skill}");
    let skill_id = skill["id"].as_str().unwrap().to_string();
    let mut skill_upd = skill.clone();
    skill_upd["description"] = json!("actualizada");
    let (st, skill2) = req_json(app.clone(), "PUT", &format!("/api/skills/{skill_id}"), Some(skill_upd)).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(skill2["version"], "1.0.1");
    // historial: 2 versiones (snapshot 0001 + update)
    let (st, versions) = req_json(app.clone(), "GET", &format!("/api/skills/{skill_id}/versions"), None).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(versions.as_array().unwrap().len(), 2, "2 snapshots: inicial + update");

    // create agent + asignar skill
    let (st, agent) = req_json(app.clone(), "POST", "/api/agents",
        Some(json!({"name": "jefe", "description": "", "role": "coordinator", "created_by": "t"})))
        .await;
    assert_eq!(st, StatusCode::OK, "body: {agent}");
    let agent_id = agent["id"].as_str().unwrap().to_string();
    let (st, agent2) = req_json(app.clone(), "POST", &format!("/api/agents/{agent_id}/skills"),
        Some(json!({"skill_id": skill_id})))
        .await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(agent2["skills"][0], skill_id);

    // ejecutar canvas (spawn interno → esperar a completed)
    let (st, exec) = req_json(app.clone(), "POST", &format!("/api/canvases/{canvas_id}/execute"),
        Some(json!({"canvas_id": canvas_id, "trigger": {"trigger_type": "manual", "payload": {}, "triggered_by": "t"}})))
        .await;
    assert_eq!(st, StatusCode::OK, "body: {exec}");
    let exec_id = exec["execution_id"].as_str().unwrap().to_string();
    tokio::time::sleep(std::time::Duration::from_millis(400)).await; // el task simula 100ms
    let (st, exec_got) = req_json(app.clone(), "GET", &format!("/api/executions/{exec_id}"), None).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(exec_got["status"], "completed");
    assert_eq!(exec_got["canvas_id"], canvas_id);
    assert_eq!(exec_got["result"]["success"], true);

    drop(app); // ── el server "se cae" ──

    // ── "arranque" 2: mismo archivo → TODO sigue ──
    let state = AppState::connect(&url).await.unwrap();
    let app = create_router(state);

    let (st, got) = req_json(app.clone(), "GET", &format!("/api/canvases/{canvas_id}"), None).await;
    assert_eq!(st, StatusCode::OK, "canvas debe sobrevivir reinicio");
    assert_eq!(got["name"], "Mi Canvas");

    let (st, got) = req_json(app, "GET", &format!("/api/executions/{exec_id}"), None).await;
    assert_eq!(st, StatusCode::OK, "execution debe sobrevivir reinicio");
    assert_eq!(got["status"], "completed");
}

#[tokio::test]
async fn deletes_y_404() {
    let state = AppState::connect("sqlite::memory:").await.unwrap();
    let app = create_router(state);

    let (st, canvas) = req_json(app.clone(), "POST", "/api/canvases",
        Some(json!({"name": "x", "description": "", "created_by": "t"})))
        .await;
    assert_eq!(st, StatusCode::OK);
    let id = canvas["id"].as_str().unwrap().to_string();

    let (st, _) = req_json(app.clone(), "DELETE", &format!("/api/canvases/{id}"), None).await;
    assert_eq!(st, StatusCode::NO_CONTENT);

    // segunda vez → 404 (soft delete ya aplicado)
    let (st, _) = req_json(app.clone(), "DELETE", &format!("/api/canvases/{id}"), None).await;
    assert_eq!(st, StatusCode::NOT_FOUND);

    let (st, _) = req_json(app, "GET", &format!("/api/canvases/{id}"), None).await;
    assert_eq!(st, StatusCode::NOT_FOUND);
}
