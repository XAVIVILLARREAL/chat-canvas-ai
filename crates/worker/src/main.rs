//! Worker stateless de agentes — patrón Everruns (SDD-008).
//!
//! REGLA DURA (Everruns): este binario NO tiene credenciales de base de datos.
//! Reclama tareas vía cola Postgres `FOR UPDATE SKIP LOCKED` a través de un pool
//! acotado (o gRPC del control-plane) y reporta heartbeat; nunca escribe fuera
//! de su propio job.
//!
//! v1: heartbeat únicamente — el claim de tareas y el sandbox Docker por agente
//! llegan con C.3 (robustez) y H.9a (aislamiento contenedor mínimo, Etapa 3/8).

use std::time::Duration;

#[tokio::main]
async fn main() {
    let worker_id = worker_id();
    let heartbeat_secs: u64 = std::env::var("WORKER_HEARTBEAT_SECS")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(30);

    println!("[canvas-ai-worker] {worker_id} arrancando (stateless, sin credenciales DB)");

    // Bucle de vida: heartbeat + (futuro) claim de tareas SKIP LOCKED.
    let mut tick = tokio::time::interval(Duration::from_secs(heartbeat_secs));
    tick.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Delay);
    loop {
        tick.tick().await;
        println!("[canvas-ai-worker] {worker_id} heartbeat ok");
    }
}

/// Identidad EFÍMERA del worker (hostname + pid) — el control-plane la registra
/// en cada heartbeat; aquí nunca se persiste nada sensible.
fn worker_id() -> String {
    let host = std::env::var("HOSTNAME").unwrap_or_else(|_| "local".into());
    format!("{host}-{}", std::process::id())
}
