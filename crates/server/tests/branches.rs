//! A.9 — Ramas visuales al editar:
//! 1) editar 2× un mensaje → 3 variantes en el mismo grupo, solo la última activa
//! 2) flechas: activar cualquier variante → nada se pierde y el contexto la usa
//! 3) bordes: editar assistant → 400, contenido vacío → 400, id inexistente → 404

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
    let url = format!("sqlite://{}/a9.db", tmp.path().display());
    let state = AppState::connect(&url).await.unwrap();
    let app = create_router(state);
    let (_, session) = req_json(
        app.clone(),
        "POST",
        "/api/sessions",
        Some(json!({"title": "A9 ramas"})),
    )
    .await;
    let sid = session["id"].as_str().unwrap().to_string();
    std::mem::forget(tmp);
    (app, sid)
}

/// 1+2) editar dos veces crea el grupo y las flechas navegan sin perder nada.
#[tokio::test]
async fn editar_crea_ramas_y_navega() {
    let (app, sid) = setup().await;

    let (st, m1) = req_json(
        app.clone(),
        "POST",
        &format!("/api/sessions/{sid}/messages"),
        Some(json!({"role": "user", "content": "pregunta versión 1"})),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
    let id1 = m1["id"].as_str().unwrap().to_string();

    // edición 1 y 2 (el gate del plan: edito mensaje 2×)
    let (st, m2) = req_json(
        app.clone(),
        "PUT",
        &format!("/api/messages/{id1}"),
        Some(json!({"content": "pregunta versión 2"})),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{m2}");
    let id2 = m2["id"].as_str().unwrap().to_string();
    assert_ne!(id2, id1, "editar NO muta: crea variante nueva");
    assert_eq!(m2["variant_group"], id1, "el grupo se ancla en el original");
    assert_eq!(m2["active"], 1);

    let (st, m3) = req_json(
        app.clone(),
        "PUT",
        &format!("/api/messages/{id2}"),
        Some(json!({"content": "pregunta versión 3"})),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
    let id3 = m3["id"].as_str().unwrap().to_string();

    // listado completo: 3 variantes del MISMO grupo, solo la última activa
    let (_, all) = req_json(app.clone(), "GET", &format!("/api/sessions/{sid}/messages"), None).await;
    let all = all.as_array().unwrap();
    assert_eq!(all.len(), 3, "las 3 variantes existen — nada se pierde");
    assert!(all.iter().all(|m| m["variant_group"] == json!(id1)));
    assert_eq!(all.iter().filter(|m| m["active"] == 1).count(), 1);
    assert_eq!(all.iter().find(|m| m["active"] == 1).unwrap()["id"], json!(id3));

    // activar la variante 1 (flecha ‹ ‹) → el camino activo cambia
    let (st, group) = req_json(app.clone(), "POST", &format!("/api/messages/{id1}/activate"), None).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(group.as_array().unwrap().len(), 3);
    let (_, all) = req_json(app.clone(), "GET", &format!("/api/sessions/{sid}/messages"), None).await;
    let activa = all.as_array().unwrap().iter().find(|m| m["active"] == 1).unwrap();
    assert_eq!(activa["id"], json!(id1), "la variante 1 quedó activa");
    assert_eq!(activa["content"], "pregunta versión 1");

    // el contexto del chat usa SOLO el camino activo (1 mensaje user)
    let (_, ctx) = req_json(app.clone(), "GET", &format!("/api/sessions/{sid}/context"), None).await;
    let hist = ctx["sources"]
        .as_array()
        .unwrap()
        .iter()
        .find(|s| s["source"] == "historial")
        .unwrap()["tokens"]
        .as_u64()
        .unwrap();
    assert_eq!(hist, 5, "'pregunta versión 1' = 18 chars → 5 tokens (solo la variante activa)");
}

/// 3) bordes honestos.
#[tokio::test]
async fn edicion_bordes() {
    let (app, sid) = setup().await;

    // assistant NO editable (v1)
    let (_, m) = req_json(
        app.clone(),
        "POST",
        &format!("/api/sessions/{sid}/messages"),
        Some(json!({"role": "assistant", "content": "respuesta"})),
    )
    .await;
    let (st, _) = req_json(
        app.clone(),
        "PUT",
        &format!("/api/messages/{}", m["id"].as_str().unwrap()),
        Some(json!({"content": "nueva"})),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST);

    // contenido vacío → 400
    let (_, u) = req_json(
        app.clone(),
        "POST",
        &format!("/api/sessions/{sid}/messages"),
        Some(json!({"role": "user", "content": "hola"})),
    )
    .await;
    let (st, _) = req_json(
        app.clone(),
        "PUT",
        &format!("/api/messages/{}", u["id"].as_str().unwrap()),
        Some(json!({"content": "   "})),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST);

    // id inexistente → 404
    let (st, _) = req_json(
        app.clone(),
        "PUT",
        "/api/messages/no-existe",
        Some(json!({"content": "x"})),
    )
    .await;
    assert_eq!(st, StatusCode::NOT_FOUND);
}
