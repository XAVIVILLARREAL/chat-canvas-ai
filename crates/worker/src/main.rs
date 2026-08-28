//! Worker stateless de agentes — patrón Everruns (SDD-008).
//!
//! REGLA DURA (Everruns): este binario NO tiene credenciales de base de datos.
//! Reclama tareas vía cola Postgres `FOR UPDATE SKIP LOCKED` a través de un pool
//! acotado (o gRPC del control-plane) y reporta heartbeat; nunca escribe fuera
//! de su propio job.
//!
//! v1: heartbeat únicamente — el claim de tareas llega con C.3; el sandbox
//! Docker por agente vive en `canvas_ai_worker::sandbox` (slice 0.5, H.9a).

use std::time::Duration;

#[tokio::main]
async fn main() {
    let worker_id = worker_id();
    let heartbeat_secs: u64 = std::env::var("WORKER_HEARTBEAT_SECS")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(30);

    println!("[canvas-ai-worker] {worker_id} arrancando (stateless, sin credenciales DB)");
    println!("[canvas-ai-worker] sandbox disponible: canvas_ai_worker::sandbox (contrato CPU/RAM/pids/red-ro)");

    // Bucle de vida: heartbeat + (futuro) claim de tareas SKIP LOCKED.
    let mut tick = tokio::time::interval(Duration::from_secs(heartbeat_secs));
    tick.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Delay);
    loop {
        tick.tick().await;
        println!("[canvas-ai-worker] {worker_id} heartbeat ok");
    }
}

fn worker_id() -> String {
    std::env::var("WORKER_ID").unwrap_or_else(|_| format!("worker-{}", uuid::Uuid::new_v4().simple()))
}
