//! Servidor central de Empresa Dev — prueba viva de ADR-005 D1:
//! el MISMO crate `empresa-dev-core` que usa la app Tauri sirve HTTP aquí.
//! Etapa 12 (Plan L) lo expandirá a SyncHub completo (sesiones CRDT, repos).

use axum::{routing::get, Json, Router};
use empresa_dev_core::domain::Agent;

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/healthz", get(healthz))
        .route("/api/version", get(version))
        .route("/api/domain/agent-demo", get(agent_demo));

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3010")
        .await
        .expect("puerto 3010 disponible");
    println!("[empresa-dev-server] escuchando en http://0.0.0.0:3010");
    axum::serve(listener, app).await.expect("servidor axum");
}

async fn healthz() -> &'static str {
    "ok"
}

async fn version() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "app": env!("CARGO_PKG_NAME"),
        "version": env!("CARGO_PKG_VERSION"),
    }))
}

/// Demuestra que el dominio del core es servido por HTTP sin cambios:
/// el mismo tipo `Agent` que verá el shell Tauri por IPC.
async fn agent_demo() -> Json<Agent> {
    Json(Agent::new(
        "demo".into(),
        "Agente de ejemplo del core compartido".into(),
    ))
}
