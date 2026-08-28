//! Slice 0.1 — mini-gate: `cargo test -p canvas-ai-core` verde.
//! 1) Migración up/down/up idempotente.
//! 2) CRUD por project_id (frontera multi-tenant).
//! 3) La data sobrevive a "reinicio" del server (cerrar pool → reabrir archivo).

use canvas_ai_core::repo;
use serde_json::json;

const DOWN_0001: &str = include_str!("../migrations/sqlite/down/0001_init.sql");
const DOWN_0002: &str = include_str!("../migrations/sqlite/down/0002_workspace.sql");
const DOWN_0004: &str = include_str!("../migrations/sqlite/down/0004_append_only.sql");
const DOWN_0005: &str = include_str!("../migrations/sqlite/down/0005_vault.sql");

/// Ejecuta TODAS las reversas (0002 → 0001) y limpia el registro de sqlx.
async fn run_all_down(db: &repo::Db) {
    for stmt in DOWN_0002.split(';').map(str::trim).filter(|s| !s.is_empty()) {
        sqlx::query(stmt).execute(db).await.unwrap();
    }
    for stmt in DOWN_0005.split(';').map(str::trim).filter(|s| !s.is_empty()) {
        sqlx::query(stmt).execute(db).await.unwrap();
    }
    for stmt in DOWN_0004.split(';').map(str::trim).filter(|s| !s.is_empty()) {
        sqlx::query(stmt).execute(db).await.unwrap();
    }
    for stmt in DOWN_0001.split(';').map(str::trim).filter(|s| !s.is_empty()) {
        sqlx::query(stmt).execute(db).await.unwrap();
    }
    sqlx::query("DELETE FROM _sqlx_migrations").execute(db).await.unwrap();
}

#[tokio::test]
async fn migracion_up_down_up_idempotente() {
    let tmp = tempfile::tempdir().unwrap();
    let url = format!("sqlite://{}/test.db", tmp.path().display());

    // up
    let db = repo::connect(&url).await.unwrap();
    repo::project_create(&db, "p1", "proyecto").await.unwrap();
    db.close().await;

    // down (reversa exacta de TODAS las migraciones sobre el mismo archivo)
    let db = repo::open_raw(&url).await.unwrap();
    run_all_down(&db).await;
    let tables: Vec<(String,)> = sqlx::query_as(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != '_sqlx_migrations'",
    )
    .fetch_all(&db)
    .await
    .unwrap();
    assert!(tables.is_empty(), "down debe dejar 0 tablas de negocio, quedó: {tables:?}");

    // up de nuevo (reaplica limpio y el dato ya no existe)
    repo::migrate(&db).await.unwrap();
    assert!(repo::project_get(&db, "p1").await.unwrap().is_none());
    db.close().await;
}

#[tokio::test]
async fn crud_por_proyecto_y_flujo_completo() {
    let db = repo::connect("sqlite::memory:").await.unwrap();

    repo::project_create(&db, "p1", "Uno").await.unwrap();
    repo::project_create(&db, "p2", "Dos").await.unwrap();

    // sesión + mensajes con rollup de uso
    let s1 = repo::session_create(&db, "s1", "p1", "Hola").await.unwrap();
    assert_eq!(s1.project_id, "p1");
    repo::message_create(&db, "m1", "s1", "user", "hola", None, Some(10), None, None, &json!({})).await.unwrap();
    repo::message_create(&db, "m2", "s1", "assistant", "¡hola!", Some("test-model"), Some(5), Some(8), Some(0.001), &json!({})).await.unwrap();
    repo::session_add_usage(&db, "s1", 23, 0.001).await.unwrap();

    let msgs = repo::message_list_by_session(&db, "s1").await.unwrap();
    assert_eq!(msgs.len(), 2);
    let s1b = repo::session_get(&db, "s1").await.unwrap().unwrap();
    assert_eq!(s1b.total_tokens, 23);
    assert!((s1b.total_cost_usd - 0.001).abs() < 1e-9);

    // aislamiento: p2 no ve sesiones de p1
    let sesiones_p2 = repo::session_list_by_project(&db, "p2").await.unwrap();
    assert!(sesiones_p2.is_empty());

    // skills con versionado
    let sk = repo::skill_create(&db, "sk1", "p1", "revisor", &json!({"role": "reviewer"}), "hago review").await.unwrap();
    assert_eq!(sk.current_version, 1);
    let v2 = repo::skill_new_version(&db, "sk1", &json!({"role": "reviewer"}), "hago review v2").await.unwrap();
    assert_eq!(v2, 2);
    assert_eq!(repo::skill_list_versions(&db, "sk1").await.unwrap().len(), 2);

    // provider BYOK: solo key_ref, nunca la key
    repo::provider_create(&db, "prov1", "p1", "openrouter", "OR", Some("https://openrouter.ai/api/v1"), Some("vault:or-key")).await.unwrap();
    let prov = repo::provider_get(&db, "prov1").await.unwrap().unwrap();
    assert_eq!(prov.key_ref.as_deref(), Some("vault:or-key"));

    // settings upsert
    repo::setting_set(&db, "p1", "tema", &json!("dark")).await.unwrap();
    repo::setting_set(&db, "p1", "tema", &json!("light")).await.unwrap();
    assert_eq!(repo::setting_get(&db, "p1", "tema").await.unwrap(), Some(json!("light")));

    // ejecución con cierre
    repo::execution_create(&db, "e1", "canvas1", &json!({"type": "manual"})).await.unwrap();
    repo::execution_set_status(&db, "e1", "completed", Some(&json!({"ok": true}))).await.unwrap();
    let e1 = repo::execution_get(&db, "e1").await.unwrap().unwrap();
    assert_eq!(e1.status, "completed");
    assert!(e1.completed_at.is_some());

    // event_stream (slice 0.3): session.created(auto) + 2×message.streamed(auto) + PROMPT
    let ev = repo::event_append(&db, "s1", "PROMPT", "usuario preguntó", None, Some("test-model"), 10, 0.0001, Some("user"), Some("u1")).await.unwrap();
    assert!(ev > 0);
    let evs = repo::event_list_by_session(&db, "s1").await.unwrap();
    assert_eq!(evs.len(), 4, "session.created + 2×message.streamed + PROMPT");
    assert!(evs.iter().any(|e| e.event_type == repo::product_events::SESSION_CREATED));
    assert_eq!(evs.iter().filter(|e| e.event_type == repo::product_events::MESSAGE_STREAMED).count(), 2);

    // soft delete de proyecto
    repo::project_soft_delete(&db, "p1").await.unwrap();
    assert!(repo::project_get(&db, "p1").await.unwrap().is_none());

    // FK cascade: borrar proyecto borra sus sesiones
    repo::session_create(&db, "s2", "p2", "temp").await.unwrap();
    sqlx::query("DELETE FROM projects WHERE id = 'p2'").execute(&db).await.unwrap();
    let count: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM sessions WHERE project_id = 'p2'").fetch_one(&db).await.unwrap();
    assert_eq!(count.0, 0, "cascade debe borrar las sesiones del proyecto");
}

#[tokio::test]
async fn data_sobrevive_reinicio_del_server() {
    let tmp = tempfile::tempdir().unwrap();
    let url = format!("sqlite://{}/persist.db", tmp.path().display());

    // "arranque" 1: crear datos
    let db = repo::connect(&url).await.unwrap();
    repo::project_create(&db, "p1", "Persistente").await.unwrap();
    repo::session_create(&db, "s1", "p1", "sesión").await.unwrap();
    repo::message_create(&db, "m1", "s1", "user", "dato", None, None, None, None, &json!({})).await.unwrap();
    db.close().await; // el server "se cae"

    // "arranque" 2: reabrir el mismo archivo → todo sigue
    let db = repo::connect(&url).await.unwrap();
    assert_eq!(repo::project_list(&db).await.unwrap().len(), 1);
    assert_eq!(repo::message_list_by_session(&db, "s1").await.unwrap().len(), 1);
    // migraciones NO se reaplican (idempotente): 0001+0002+0004+0005
    let versiones: Vec<(i64,)> = sqlx::query_as("SELECT version FROM _sqlx_migrations").fetch_all(&db).await.unwrap();
    assert_eq!(versiones.len(), 4);
}
