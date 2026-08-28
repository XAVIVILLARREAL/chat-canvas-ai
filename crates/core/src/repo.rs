//! Repos SQLite (Etapa 0, slice 0.1).
//!
//! Contrato: `docs/SCHEMA-MAESTRO.md` §3. sqlx + SQLite; Postgres llega en 0.2
//! con el mismo contrato de queries (SQL portable: epoch ms, JSON como TEXT).
//!
//! Convenciones:
//! - Toda fila de negocio lleva `project_id` → frontera multi-tenant (RLS en nube).
//! - Timestamps epoch ms (i64). JSON serializado con serde_json.
//! - Soft-delete (`deleted_at`) en sessions/skills/projects.

use sqlx::sqlite::{SqliteConnectOptions, SqlitePool, SqlitePoolOptions};
use sqlx::Row;
use std::str::FromStr;

pub type Db = SqlitePool;

/// Pool Postgres (nube). Mismo contrato de queries que SQLite (SQL portable).
pub type PgDb = sqlx::PgPool;

/// Abre un pool SQLite con FKs activadas y migraciones aplicadas.
/// `sqlite://ruta.db` o `sqlite::memory:` para tests.
pub async fn connect(url: &str) -> Result<Db, sqlx::Error> {
    let opts = SqliteConnectOptions::from_str(url)?
        .foreign_keys(true)
        .create_if_missing(true);
    let pool = SqlitePoolOptions::new().max_connections(5).connect_with(opts).await?;
    migrate(&pool).await?;
    Ok(pool)
}

/// Aplica migraciones embebidas (idempotente: sqlx guarda `_sqlx_migrations`).
pub async fn migrate(pool: &Db) -> Result<(), sqlx::Error> {
    let migrator = sqlx::migrate!("./migrations/sqlite");
    migrator.run(pool).await.map_err(sqlx::Error::from)
}

/// Abre un pool Postgres (nube, slice 0.2) y aplica migraciones + RLS.
/// Requiere usuario NO-superuser (FORCE RLS no blindan a superusers).
pub async fn connect_postgres(url: &str) -> Result<PgDb, sqlx::Error> {
    let pool = sqlx::postgres::PgPoolOptions::new()
        .max_connections(5)
        .connect(url)
        .await?;
    migrate_postgres(&pool).await?;
    Ok(pool)
}

/// Migrador Postgres cargado en runtime (mismos shapes, dialecto PG + RLS).
pub async fn migrate_postgres(pool: &PgDb) -> Result<(), sqlx::Error> {
    let migrator = sqlx::migrate::Migrator::new(std::path::Path::new(concat!(
        env!("CARGO_MANIFEST_DIR"),
        "/migrations/postgres"
    )))
    .await?;
    migrator.run(pool).await.map_err(sqlx::Error::from)
}

/// Abre el pool SIN aplicar migraciones (para tests de down/reversa).
pub async fn open_raw(url: &str) -> Result<Db, sqlx::Error> {
    let opts = SqliteConnectOptions::from_str(url)?.foreign_keys(true);
    SqlitePoolOptions::new().max_connections(5).connect_with(opts).await
}

pub fn now_ms() -> i64 {
    chrono::Utc::now().timestamp_millis()
}

// ─── Models (filas del schema) ──────────────────────────────────────────────

#[derive(Debug, Clone, serde::Serialize, sqlx::FromRow)]
pub struct Project {
    pub id: String,
    pub name: String,
    pub settings: String,
    pub created_at: i64,
    pub updated_at: i64,
    pub deleted_at: Option<i64>,
}

#[derive(Debug, Clone, serde::Serialize, sqlx::FromRow, schemars::JsonSchema, specta::Type)]
pub struct Session {
    pub id: String,
    pub project_id: String,
    pub title: String,
    pub status: String,
    pub agent_config: String,
    pub total_tokens: i64,
    pub total_cost_usd: f64,
    pub created_at: i64,
    pub updated_at: i64,
    pub deleted_at: Option<i64>,
}

#[derive(Debug, Clone, serde::Serialize, sqlx::FromRow, schemars::JsonSchema, specta::Type)]
pub struct Message {
    pub id: String,
    pub session_id: String,
    pub role: String,
    pub content: String,
    pub model: Option<String>,
    pub tokens_prompt: Option<i64>,
    pub tokens_completion: Option<i64>,
    pub cost_usd: Option<f64>,
    pub cache_hits: Option<i64>,
    pub metadata: String,
    pub created_at: i64,
}

#[derive(Debug, Clone, serde::Serialize, sqlx::FromRow)]
pub struct Skill {
    pub id: String,
    pub project_id: String,
    pub slug: String,
    pub current_version: i64,
    pub manifest: String,
    pub body_md: String,
    pub avatar: Option<String>,
    pub emoji: Option<String>,
    pub bio: Option<String>,
    pub is_global: bool,
    pub created_at: i64,
    pub updated_at: i64,
    pub deleted_at: Option<i64>,
}

#[derive(Debug, Clone, serde::Serialize, sqlx::FromRow, schemars::JsonSchema, specta::Type)]
pub struct Provider {
    pub id: String,
    pub project_id: String,
    pub provider_type: String,
    pub name: String,
    pub base_url: Option<String>,
    pub model_tier: Option<String>,
    pub key_ref: Option<String>,
    pub enabled: bool,
    pub created_at: i64,
    pub updated_at: i64,
}

#[derive(Debug, Clone, serde::Serialize, sqlx::FromRow)]
pub struct Execution {
    pub id: String,
    pub canvas_id: String,
    pub trigger: String,
    pub status: String,
    pub node_states: String,
    pub variables: String,
    pub started_at: Option<i64>,
    pub completed_at: Option<i64>,
    pub result: Option<String>,
}

#[derive(Debug, Clone, serde::Serialize, sqlx::FromRow, schemars::JsonSchema, specta::Type)]
pub struct StreamEvent {
    pub id: i64,
    pub session_id: String,
    pub event_type: String,
    pub summary: String,
    pub payload: Option<String>,
    pub lines_added: Option<i64>,
    pub lines_deleted: Option<i64>,
    pub model_used: Option<String>,
    pub tokens_used: Option<i64>,
    pub cost_usd: Option<f64>,
    pub actor_type: Option<String>,
    pub actor_id: Option<String>,
    pub created_at: i64,
}

// ─── Projects ───────────────────────────────────────────────────────────────

pub async fn project_create(db: &Db, id: &str, name: &str) -> Result<Project, sqlx::Error> {
    let now = now_ms();
    sqlx::query("INSERT INTO projects (id, name, created_at, updated_at) VALUES (?1, ?2, ?3, ?3)")
        .bind(id).bind(name).bind(now)
        .execute(db).await?;
    Ok(project_get(db, id).await?.expect("just inserted"))
}

pub async fn project_get(db: &Db, id: &str) -> Result<Option<Project>, sqlx::Error> {
    sqlx::query_as("SELECT * FROM projects WHERE id = ?1 AND deleted_at IS NULL")
        .bind(id).fetch_optional(db).await
}

pub async fn project_list(db: &Db) -> Result<Vec<Project>, sqlx::Error> {
    sqlx::query_as("SELECT * FROM projects WHERE deleted_at IS NULL ORDER BY created_at")
        .fetch_all(db).await
}

pub async fn project_rename(db: &Db, id: &str, name: &str) -> Result<u64, sqlx::Error> {
    let r = sqlx::query("UPDATE projects SET name = ?2, updated_at = ?3 WHERE id = ?1")
        .bind(id).bind(name).bind(now_ms())
        .execute(db).await?;
    Ok(r.rows_affected())
}

pub async fn project_soft_delete(db: &Db, id: &str) -> Result<u64, sqlx::Error> {
    let r = sqlx::query("UPDATE projects SET deleted_at = ?2 WHERE id = ?1 AND deleted_at IS NULL")
        .bind(id).bind(now_ms())
        .execute(db).await?;
    Ok(r.rows_affected())
}

// ─── Sessions ───────────────────────────────────────────────────────────────

pub async fn session_create(db: &Db, id: &str, project_id: &str, title: &str) -> Result<Session, sqlx::Error> {
    let now = now_ms();
    sqlx::query("INSERT INTO sessions (id, project_id, title, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?4)")
        .bind(id).bind(project_id).bind(title).bind(now)
        .execute(db).await?;
    // evento de producto (PRODUCT-METRICS §2): crear dato → emitir evento
    event_append(db, id, product_events::SESSION_CREATED, &format!("sesión '{title}' creada"), Some(&serde_json::json!({"mode": "local"})), None, 0, 0.0, Some("user"), None).await?;
    Ok(session_get(db, id).await?.expect("just inserted"))
}

pub async fn session_get(db: &Db, id: &str) -> Result<Option<Session>, sqlx::Error> {
    sqlx::query_as("SELECT * FROM sessions WHERE id = ?1 AND deleted_at IS NULL")
        .bind(id).fetch_optional(db).await
}

pub async fn session_list_by_project(db: &Db, project_id: &str) -> Result<Vec<Session>, sqlx::Error> {
    sqlx::query_as("SELECT * FROM sessions WHERE project_id = ?1 AND deleted_at IS NULL ORDER BY created_at")
        .bind(project_id).fetch_all(db).await
}

pub async fn session_archive(db: &Db, id: &str) -> Result<u64, sqlx::Error> {
    let r = sqlx::query("UPDATE sessions SET status = 'archived', updated_at = ?2 WHERE id = ?1")
        .bind(id).bind(now_ms())
        .execute(db).await?;
    Ok(r.rows_affected())
}

/// Acumula tokens/costo en la sesión (rollup tras cada mensaje).
pub async fn session_add_usage(db: &Db, id: &str, tokens: i64, cost_usd: f64) -> Result<u64, sqlx::Error> {
    let r = sqlx::query(
        "UPDATE sessions SET total_tokens = total_tokens + ?2, total_cost_usd = total_cost_usd + ?3, updated_at = ?4 WHERE id = ?1",
    )
    .bind(id).bind(tokens).bind(cost_usd).bind(now_ms())
    .execute(db).await?;
    Ok(r.rows_affected())
}

// ─── Messages ───────────────────────────────────────────────────────────────

#[allow(clippy::too_many_arguments)]
pub async fn message_create(
    db: &Db, id: &str, session_id: &str, role: &str, content: &str,
    model: Option<&str>, tokens_prompt: Option<i64>, tokens_completion: Option<i64>,
    cost_usd: Option<f64>, metadata: &serde_json::Value,
) -> Result<Message, sqlx::Error> {
    let meta = serde_json::to_string(metadata).expect("metadata serializable");
    sqlx::query(
        "INSERT INTO messages (id, session_id, role, content, model, tokens_prompt, tokens_completion, cost_usd, metadata, created_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)",
    )
    .bind(id).bind(session_id).bind(role).bind(content)
    .bind(model).bind(tokens_prompt).bind(tokens_completion).bind(cost_usd)
    .bind(meta).bind(now_ms())
    .execute(db).await?;
    // evento de producto: tokens/costo del stream (PRODUCT-METRICS §2)
    let tokens = tokens_completion.unwrap_or(0) + tokens_prompt.unwrap_or(0);
    event_append(db, session_id, product_events::MESSAGE_STREAMED, &format!("mensaje {role}"), None, model, tokens, cost_usd.unwrap_or(0.0), Some("user"), None).await?;
    Ok(message_get(db, id).await?.expect("just inserted"))
}

pub async fn message_get(db: &Db, id: &str) -> Result<Option<Message>, sqlx::Error> {
    sqlx::query_as("SELECT * FROM messages WHERE id = ?1").bind(id).fetch_optional(db).await
}

pub async fn message_list_by_session(db: &Db, session_id: &str) -> Result<Vec<Message>, sqlx::Error> {
    sqlx::query_as("SELECT * FROM messages WHERE session_id = ?1 ORDER BY created_at, id")
        .bind(session_id).fetch_all(db).await
}

// ─── Skills (+ versiones) ───────────────────────────────────────────────────

pub async fn skill_create(
    db: &Db, id: &str, project_id: &str, slug: &str,
    manifest: &serde_json::Value, body_md: &str,
) -> Result<Skill, sqlx::Error> {
    let now = now_ms();
    let manifest = serde_json::to_string(manifest).expect("manifest serializable");
    sqlx::query(
        "INSERT INTO skills (id, project_id, slug, manifest, body_md, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?6)",
    )
    .bind(id).bind(project_id).bind(slug).bind(&manifest).bind(body_md).bind(now)
    .execute(db).await?;
    // versión 1 en el historial
    sqlx::query("INSERT INTO skill_versions (skill_id, version, manifest, body_md, created_at) VALUES (?1, 1, ?2, ?3, ?4)")
        .bind(id).bind(&manifest).bind(body_md).bind(now)
        .execute(db).await?;
    Ok(skill_get(db, id).await?.expect("just inserted"))
}

pub async fn skill_get(db: &Db, id: &str) -> Result<Option<Skill>, sqlx::Error> {
    sqlx::query_as("SELECT * FROM skills WHERE id = ?1 AND deleted_at IS NULL")
        .bind(id).fetch_optional(db).await
}

pub async fn skill_soft_delete(db: &Db, id: &str) -> Result<u64, sqlx::Error> {
    let r = sqlx::query("UPDATE skills SET deleted_at = ?2 WHERE id = ?1 AND deleted_at IS NULL")
        .bind(id).bind(now_ms())
        .execute(db).await?;
    Ok(r.rows_affected())
}

pub async fn skill_list_by_project(db: &Db, project_id: &str) -> Result<Vec<Skill>, sqlx::Error> {
    sqlx::query_as("SELECT * FROM skills WHERE project_id = ?1 AND deleted_at IS NULL ORDER BY created_at")
        .bind(project_id).fetch_all(db).await
}

/// Nueva versión del skill: inserta en historial y avanza `current_version`.
pub async fn skill_new_version(db: &Db, id: &str, manifest: &serde_json::Value, body_md: &str) -> Result<i64, sqlx::Error> {
    let manifest = serde_json::to_string(manifest).expect("manifest serializable");
    let now = now_ms();
    let next: i64 = sqlx::query_scalar("SELECT current_version + 1 FROM skills WHERE id = ?1")
        .bind(id).fetch_one(db).await?;
    let mut tx = db.begin().await?;
    sqlx::query("INSERT INTO skill_versions (skill_id, version, manifest, body_md, created_at) VALUES (?1, ?2, ?3, ?4, ?5)")
        .bind(id).bind(next).bind(&manifest).bind(body_md).bind(now)
        .execute(&mut *tx).await?;
    sqlx::query("UPDATE skills SET current_version = ?2, manifest = ?3, body_md = ?4, updated_at = ?5 WHERE id = ?1")
        .bind(id).bind(next).bind(&manifest).bind(body_md).bind(now)
        .execute(&mut *tx).await?;
    tx.commit().await?;
    Ok(next)
}

pub async fn skill_list_versions(db: &Db, skill_id: &str) -> Result<Vec<(i64, String)>, sqlx::Error> {
    let rows = sqlx::query("SELECT version, body_md FROM skill_versions WHERE skill_id = ?1 ORDER BY version")
        .bind(skill_id).fetch_all(db).await?;
    Ok(rows.into_iter().map(|r| (r.get::<i64, _>(0), r.get::<String, _>(1))).collect())
}

// ─── Providers (BYOK — solo key_ref, nunca la key) ──────────────────────────

#[allow(clippy::too_many_arguments)]
pub async fn provider_create(
    db: &Db, id: &str, project_id: &str, provider_type: &str, name: &str,
    base_url: Option<&str>, key_ref: Option<&str>,
) -> Result<Provider, sqlx::Error> {
    let now = now_ms();
    sqlx::query(
        "INSERT INTO providers (id, project_id, provider_type, name, base_url, key_ref, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?7)",
    )
    .bind(id).bind(project_id).bind(provider_type).bind(name).bind(base_url).bind(key_ref).bind(now)
    .execute(db).await?;
    Ok(provider_get(db, id).await?.expect("just inserted"))
}

pub async fn provider_get(db: &Db, id: &str) -> Result<Option<Provider>, sqlx::Error> {
    sqlx::query_as("SELECT * FROM providers WHERE id = ?1").bind(id).fetch_optional(db).await
}

pub async fn provider_list_by_project(db: &Db, project_id: &str) -> Result<Vec<Provider>, sqlx::Error> {
    sqlx::query_as("SELECT * FROM providers WHERE project_id = ?1 ORDER BY created_at")
        .bind(project_id).fetch_all(db).await
}

pub async fn provider_delete(db: &Db, id: &str) -> Result<u64, sqlx::Error> {
    let r = sqlx::query("DELETE FROM providers WHERE id = ?1").bind(id).execute(db).await?;
    Ok(r.rows_affected())
}

// ─── Executions (canvas de automatización) ──────────────────────────────────

pub async fn execution_create(db: &Db, id: &str, canvas_id: &str, trigger: &serde_json::Value) -> Result<Execution, sqlx::Error> {
    let trigger = serde_json::to_string(trigger).expect("trigger serializable");
    sqlx::query("INSERT INTO executions (id, canvas_id, \"trigger\", started_at) VALUES (?1, ?2, ?3, ?4)")
        .bind(id).bind(canvas_id).bind(trigger).bind(now_ms())
        .execute(db).await?;
    Ok(execution_get(db, id).await?.expect("just inserted"))
}

pub async fn execution_get(db: &Db, id: &str) -> Result<Option<Execution>, sqlx::Error> {
    sqlx::query_as("SELECT * FROM executions WHERE id = ?1").bind(id).fetch_optional(db).await
}

pub async fn execution_set_status(db: &Db, id: &str, status: &str, result: Option<&serde_json::Value>) -> Result<u64, sqlx::Error> {
    let result = result.map(|r| serde_json::to_string(r).expect("result serializable"));
    let r = sqlx::query(
        "UPDATE executions SET status = ?2, result = ?3, completed_at = CASE WHEN ?2 IN ('completed','failed','cancelled') THEN ?4 ELSE completed_at END WHERE id = ?1",
    )
    .bind(id).bind(status).bind(result).bind(now_ms())
    .execute(db).await?;
    Ok(r.rows_affected())
}

pub async fn execution_list_by_canvas(db: &Db, canvas_id: &str) -> Result<Vec<Execution>, sqlx::Error> {
    sqlx::query_as("SELECT * FROM executions WHERE canvas_id = ?1 ORDER BY started_at")
        .bind(canvas_id).fetch_all(db).await
}

// ─── Settings (clave/valor JSON por proyecto) ───────────────────────────────

pub async fn setting_set(db: &Db, project_id: &str, key: &str, value: &serde_json::Value) -> Result<(), sqlx::Error> {
    let v = serde_json::to_string(value).expect("value serializable");
    sqlx::query(
        "INSERT INTO settings (project_id, key, value) VALUES (?1, ?2, ?3)
         ON CONFLICT(project_id, key) DO UPDATE SET value = excluded.value",
    )
    .bind(project_id).bind(key).bind(v)
    .execute(db).await?;
    Ok(())
}

pub async fn setting_get(db: &Db, project_id: &str, key: &str) -> Result<Option<serde_json::Value>, sqlx::Error> {
    let row: Option<(String,)> = sqlx::query_as("SELECT value FROM settings WHERE project_id = ?1 AND key = ?2")
        .bind(project_id).bind(key)
        .fetch_optional(db).await?;
    Ok(row.map(|(v,)| serde_json::from_str(&v).expect("settings value es JSON válido")))
}

// ─── Event stream (ledger append-only, slice 0.3) ───────────────────────────

/// Taxonomía de rungs (SCHEMA-MAESTRO §4). La taxonomía vive aquí, NO en un
/// CHECK de SQL: al mismo ledger van también los eventos de producto
/// dot-namespace (`session.created`, ...) según PRODUCT-METRICS §2.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Rung {
    Prompt,
    Phase,
    Diff,
    TestResult,
    Decision,
    Escalation,
    Delivery,
}

impl Rung {
    pub fn as_str(&self) -> &'static str {
        match self {
            Rung::Prompt => "PROMPT",
            Rung::Phase => "PHASE",
            Rung::Diff => "DIFF",
            Rung::TestResult => "TEST_RESULT",
            Rung::Decision => "DECISION",
            Rung::Escalation => "ESCALATION",
            Rung::Delivery => "DELIVERY",
        }
    }
}

/// Eventos de producto (PRODUCT-METRICS §2) — mismos strings que emite el server.
pub mod product_events {
    pub const SESSION_CREATED: &str = "session.created";
    pub const AGENT_INVOKED: &str = "agent.invoked";
    pub const MESSAGE_STREAMED: &str = "message.streamed";
    pub const TASK_CREATED: &str = "task.created";
    pub const TASK_COMPLETED: &str = "task.completed";
    pub const DELIVERY_ACCEPTED: &str = "delivery.accepted";
    pub const SKILL_CREATED: &str = "skill.created";
    pub const SKILL_RAN: &str = "skill.ran";
    pub const PROVIDER_ERROR: &str = "provider.error";
    pub const NUBE_SUBSCRIBED: &str = "nube.subscribed";
    pub const SESSION_EXPORTED: &str = "session.exported";
}

#[allow(clippy::too_many_arguments)]
pub async fn event_append(
    db: &Db, session_id: &str, event_type: &str, summary: &str,
    payload: Option<&serde_json::Value>, model_used: Option<&str>,
    tokens_used: i64, cost_usd: f64, actor_type: Option<&str>, actor_id: Option<&str>,
) -> Result<i64, sqlx::Error> {
    let payload = payload.map(|p| serde_json::to_string(p).expect("payload serializable"));
    let r = sqlx::query(
        "INSERT INTO event_stream (session_id, event_type, summary, payload, model_used, tokens_used, cost_usd, actor_type, actor_id, created_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)",
    )
    .bind(session_id).bind(event_type).bind(summary).bind(payload)
    .bind(model_used).bind(tokens_used).bind(cost_usd).bind(actor_type).bind(actor_id)
    .bind(now_ms())
    .execute(db).await?;
    Ok(r.last_insert_rowid())
}

/// `emitEvent()` — helper tipado para rungs (SCHEMA-MAESTRO §4).
#[allow(clippy::too_many_arguments)]
pub async fn emit_event(
    db: &Db, session_id: &str, rung: Rung, summary: &str,
    payload: Option<&serde_json::Value>, model_used: Option<&str>,
    tokens_used: i64, cost_usd: f64, actor_type: Option<&str>, actor_id: Option<&str>,
) -> Result<i64, sqlx::Error> {
    event_append(db, session_id, rung.as_str(), summary, payload, model_used, tokens_used, cost_usd, actor_type, actor_id).await
}

pub async fn event_list_by_session(db: &Db, session_id: &str) -> Result<Vec<StreamEvent>, sqlx::Error> {
    sqlx::query_as("SELECT * FROM event_stream WHERE session_id = ?1 ORDER BY id")
        .bind(session_id).fetch_all(db).await
}

// ─── Workspace layer (ADR-007): dominio ↔ SQLite ────────────────────────────
//
// Objetos de workspace (Canvas/Agent/MCPServer) como payload JSON;
// Skill sobre la tabla canónica (manifest); Execution sobre columnas tipadas.

use crate::domain::{Agent, Canvas, ExecutionContext, MCPServer, Skill as DomainSkill};

fn to_json<T: serde::Serialize>(v: &T) -> String {
    serde_json::to_string(v).expect("dominio serializable")
}

fn from_json<T: for<'de> serde::Deserialize<'de>>(s: &str) -> T {
    serde_json::from_str(s).expect("dominio deserializable (row corrupta)")
}

// ── Canvas ──────────────────────────────────────────────────────────────────

pub async fn canvas_put(db: &Db, project_id: &str, canvas: &Canvas) -> Result<(), sqlx::Error> {
    sqlx::query(
        "INSERT INTO canvases (id, project_id, data, updated_at) VALUES (?1, ?2, ?3, ?4)
         ON CONFLICT(id) DO UPDATE SET data = excluded.data, updated_at = excluded.updated_at, deleted_at = NULL",
    )
    .bind(&canvas.id).bind(project_id).bind(to_json(canvas)).bind(now_ms())
    .execute(db).await?;
    Ok(())
}

pub async fn canvas_get(db: &Db, id: &str) -> Result<Option<Canvas>, sqlx::Error> {
    let row: Option<(String,)> =
        sqlx::query_as("SELECT data FROM canvases WHERE id = ?1 AND deleted_at IS NULL")
            .bind(id).fetch_optional(db).await?;
    Ok(row.map(|(d,)| from_json(&d)))
}

pub async fn canvas_list(db: &Db, project_id: &str) -> Result<Vec<Canvas>, sqlx::Error> {
    let rows: Vec<(String,)> =
        sqlx::query_as("SELECT data FROM canvases WHERE project_id = ?1 AND deleted_at IS NULL ORDER BY updated_at")
            .bind(project_id).fetch_all(db).await?;
    Ok(rows.into_iter().map(|(d,)| from_json(&d)).collect())
}

pub async fn canvas_delete(db: &Db, id: &str) -> Result<u64, sqlx::Error> {
    let r = sqlx::query("UPDATE canvases SET deleted_at = ?2 WHERE id = ?1 AND deleted_at IS NULL")
        .bind(id).bind(now_ms())
        .execute(db).await?;
    Ok(r.rows_affected())
}

// ── Agent ───────────────────────────────────────────────────────────────────

pub async fn agent_put(db: &Db, project_id: &str, agent: &Agent) -> Result<(), sqlx::Error> {
    sqlx::query(
        "INSERT INTO agents (id, project_id, data, updated_at) VALUES (?1, ?2, ?3, ?4)
         ON CONFLICT(id) DO UPDATE SET data = excluded.data, updated_at = excluded.updated_at, deleted_at = NULL",
    )
    .bind(&agent.id).bind(project_id).bind(to_json(agent)).bind(now_ms())
    .execute(db).await?;
    Ok(())
}

pub async fn agent_get(db: &Db, id: &str) -> Result<Option<Agent>, sqlx::Error> {
    let row: Option<(String,)> =
        sqlx::query_as("SELECT data FROM agents WHERE id = ?1 AND deleted_at IS NULL")
            .bind(id).fetch_optional(db).await?;
    Ok(row.map(|(d,)| from_json(&d)))
}

pub async fn agent_list(db: &Db, project_id: &str) -> Result<Vec<Agent>, sqlx::Error> {
    let rows: Vec<(String,)> =
        sqlx::query_as("SELECT data FROM agents WHERE project_id = ?1 AND deleted_at IS NULL ORDER BY updated_at")
            .bind(project_id).fetch_all(db).await?;
    Ok(rows.into_iter().map(|(d,)| from_json(&d)).collect())
}

pub async fn agent_delete(db: &Db, id: &str) -> Result<u64, sqlx::Error> {
    let r = sqlx::query("UPDATE agents SET deleted_at = ?2 WHERE id = ?1 AND deleted_at IS NULL")
        .bind(id).bind(now_ms())
        .execute(db).await?;
    Ok(r.rows_affected())
}

// ── MCP server ──────────────────────────────────────────────────────────────

pub async fn mcp_put(db: &Db, project_id: &str, server: &MCPServer) -> Result<(), sqlx::Error> {
    sqlx::query(
        "INSERT INTO mcp_servers (id, project_id, data, updated_at) VALUES (?1, ?2, ?3, ?4)
         ON CONFLICT(id) DO UPDATE SET data = excluded.data, updated_at = excluded.updated_at, deleted_at = NULL",
    )
    .bind(&server.id).bind(project_id).bind(to_json(server)).bind(now_ms())
    .execute(db).await?;
    Ok(())
}

pub async fn mcp_get(db: &Db, id: &str) -> Result<Option<MCPServer>, sqlx::Error> {
    let row: Option<(String,)> =
        sqlx::query_as("SELECT data FROM mcp_servers WHERE id = ?1 AND deleted_at IS NULL")
            .bind(id).fetch_optional(db).await?;
    Ok(row.map(|(d,)| from_json(&d)))
}

pub async fn mcp_list(db: &Db, project_id: &str) -> Result<Vec<MCPServer>, sqlx::Error> {
    let rows: Vec<(String,)> =
        sqlx::query_as("SELECT data FROM mcp_servers WHERE project_id = ?1 AND deleted_at IS NULL ORDER BY updated_at")
            .bind(project_id).fetch_all(db).await?;
    Ok(rows.into_iter().map(|(d,)| from_json(&d)).collect())
}

pub async fn mcp_delete(db: &Db, id: &str) -> Result<u64, sqlx::Error> {
    let r = sqlx::query("UPDATE mcp_servers SET deleted_at = ?2 WHERE id = ?1 AND deleted_at IS NULL")
        .bind(id).bind(now_ms())
        .execute(db).await?;
    Ok(r.rows_affected())
}

// ── Skill (dominio) sobre tabla canónica ────────────────────────────────────

/// `session_anchor`: sesión activa del usuario al crear el skill — ancla el
/// evento de producto `skill.created` en el ledger (event_stream exige
/// session_id; Skills Lab lo pasa, los seeds del server pueden omitirlo).
pub async fn skill_domain_create(db: &Db, project_id: &str, skill: &DomainSkill, session_anchor: Option<&str>) -> Result<(), sqlx::Error> {
    let manifest: serde_json::Value = serde_json::to_value(skill).expect("skill serializable");
    skill_create(db, &skill.id, project_id, &skill.id, &manifest, "").await?;
    if let Some(sid) = session_anchor {
        event_append(db, sid, product_events::SKILL_CREATED, &format!("skill '{}' creado", skill.name), Some(&serde_json::json!({"skill_id": skill.id})), None, 0, 0.0, Some("user"), None).await?;
    }
    Ok(())
}

/// Upsert de una nueva versión del skill (nuevo snapshot en skill_versions).
pub async fn skill_domain_update(db: &Db, skill: &DomainSkill) -> Result<(), sqlx::Error> {
    let manifest: serde_json::Value = serde_json::to_value(skill).expect("skill serializable");
    skill_new_version(db, &skill.id, &manifest, "").await?;
    Ok(())
}

pub async fn skill_domain_get(db: &Db, id: &str) -> Result<Option<DomainSkill>, sqlx::Error> {
    let row: Option<(String,)> =
        sqlx::query_as("SELECT manifest FROM skills WHERE id = ?1 AND deleted_at IS NULL")
            .bind(id).fetch_optional(db).await?;
    Ok(row.map(|(m,)| from_json(&m)))
}

pub async fn skill_domain_list(db: &Db, project_id: &str) -> Result<Vec<DomainSkill>, sqlx::Error> {
    let rows: Vec<(String,)> =
        sqlx::query_as("SELECT manifest FROM skills WHERE project_id = ?1 AND deleted_at IS NULL ORDER BY updated_at")
            .bind(project_id).fetch_all(db).await?;
    Ok(rows.into_iter().map(|(m,)| from_json(&m)).collect())
}

/// Historial de versiones como skills de dominio (desde los snapshots).
pub async fn skill_domain_versions(db: &Db, skill_id: &str) -> Result<Vec<DomainSkill>, sqlx::Error> {
    let rows: Vec<(String,)> =
        sqlx::query_as("SELECT manifest FROM skill_versions WHERE skill_id = ?1 ORDER BY version")
            .bind(skill_id).fetch_all(db).await?;
    Ok(rows.into_iter().map(|(m,)| from_json(&m)).collect())
}

// ── Execution (dominio) sobre columnas tipadas ──────────────────────────────

pub async fn execution_domain_create(db: &Db, ctx: &ExecutionContext) -> Result<(), sqlx::Error> {
    let trigger = serde_json::to_value(&ctx.trigger).expect("trigger serializable");
    let trigger = serde_json::to_string(&trigger).expect("trigger string");
    sqlx::query(
        "INSERT INTO executions (id, canvas_id, \"trigger\", status, node_states, variables, started_at, completed_at, result)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
    )
    .bind(&ctx.execution_id).bind(&ctx.canvas_id).bind(trigger)
    .bind(to_json(&ctx.status))
    .bind(to_json(&ctx.node_states)).bind(to_json(&ctx.variables))
    .bind(ctx.started_at).bind(ctx.completed_at)
    .bind(ctx.result.as_ref().map(to_json))
    .execute(db).await?;
    Ok(())
}

pub async fn execution_domain_update(db: &Db, ctx: &ExecutionContext) -> Result<u64, sqlx::Error> {
    let r = sqlx::query(
        "UPDATE executions SET status = ?2, node_states = ?3, variables = ?4, completed_at = ?5, result = ?6 WHERE id = ?1",
    )
    .bind(&ctx.execution_id)
    .bind(to_json(&ctx.status))
    .bind(to_json(&ctx.node_states)).bind(to_json(&ctx.variables))
    .bind(ctx.completed_at)
    .bind(ctx.result.as_ref().map(to_json))
    .execute(db).await?;
    Ok(r.rows_affected())
}

pub async fn execution_domain_get(db: &Db, id: &str) -> Result<Option<ExecutionContext>, sqlx::Error> {
    let row: Option<ExecRow> = sqlx::query_as(
        "SELECT id, canvas_id, \"trigger\", status, node_states, variables, started_at, completed_at, result FROM executions WHERE id = ?1",
    )
    .bind(id)
    .fetch_optional(db).await?;
    Ok(row.map(ExecRow::into_domain))
}

pub async fn execution_domain_list(db: &Db) -> Result<Vec<ExecutionContext>, sqlx::Error> {
    let rows: Vec<ExecRow> = sqlx::query_as(
        "SELECT id, canvas_id, \"trigger\", status, node_states, variables, started_at, completed_at, result FROM executions ORDER BY started_at",
    )
    .fetch_all(db).await?;
    Ok(rows.into_iter().map(ExecRow::into_domain).collect())
}

/// Fila de executions mapeada a ExecutionContext (los enums van como JSON serde).
#[derive(sqlx::FromRow)]
struct ExecRow {
    id: String,
    canvas_id: String,
    trigger: String,
    status: String,
    node_states: String,
    variables: String,
    started_at: Option<i64>,
    completed_at: Option<i64>,
    result: Option<String>,
}

impl ExecRow {
    fn into_domain(self) -> ExecutionContext {
        ExecutionContext {
            execution_id: self.id,
            canvas_id: self.canvas_id,
            trigger: from_json(&self.trigger),
            variables: from_json(&self.variables),
            node_states: from_json(&self.node_states),
            started_at: self.started_at.unwrap_or(0),
            completed_at: self.completed_at,
            status: from_json(&self.status),
            result: self.result.as_deref().map(from_json),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn memory_db_migrates() {
        let db = connect("sqlite::memory:").await.unwrap();
        // tablas creadas: insert mínimo en cada una no debe fallar por schema
        project_create(&db, "p1", "test").await.unwrap();
        assert!(project_get(&db, "p1").await.unwrap().is_some());
    }
}

// ─── Settings con scopes (A.0): Global → Proyecto → Sesión → Agente ─────────
//
// Convención A.0: el proyecto reservado `global` guarda la configuración global;
// cada proyecto puede SOBREESCRIBIR claves en su propio (project_id, key).
// `setting_resolve` lee proyecto primero y cae a global — el override local
// JAMÁS muta el global (tablas separadas por clave primaria).

/// Proyecto reservado para configuración global (no aparece en listados de UI).
pub const GLOBAL_PROJECT_ID: &str = "global";

/// Asegura que el proyecto global exista (llamar en el arranque del server).
pub async fn ensure_global_project(db: &Db) -> Result<(), sqlx::Error> {
    if project_get(db, GLOBAL_PROJECT_ID).await?.is_none() {
        project_create(db, GLOBAL_PROJECT_ID, "Configuración global").await?;
    }
    Ok(())
}

/// Escribe una clave GLOBAL (scope global; los proyectos heredan).
pub async fn global_setting_set(db: &Db, key: &str, value: &serde_json::Value) -> Result<(), sqlx::Error> {
    setting_set(db, GLOBAL_PROJECT_ID, key, value).await
}

/// Lee una clave con resolución de scopes: proyecto → global → None.
pub async fn setting_resolve(db: &Db, project_id: &str, key: &str) -> Result<Option<serde_json::Value>, sqlx::Error> {
    if let Some(v) = setting_get(db, project_id, key).await? {
        return Ok(Some(v));
    }
    if project_id != GLOBAL_PROJECT_ID {
        if let Some(v) = setting_get(db, GLOBAL_PROJECT_ID, key).await? {
            return Ok(Some(v));
        }
    }
    Ok(None)
}

/// Lista de claves del proyecto + heredadas del global (merged; gana el proyecto).
pub async fn settings_resolved(db: &Db, project_id: &str) -> Result<serde_json::Map<String, serde_json::Value>, sqlx::Error> {
    let mut out = serde_json::Map::new();
    if project_id != GLOBAL_PROJECT_ID {
        if let Ok(rows) = sqlx::query_as::<_, (String, String)>(
            "SELECT key, value FROM settings WHERE project_id = ?1",
        )
        .bind(GLOBAL_PROJECT_ID)
        .fetch_all(db)
        .await
        {
            for (k, v) in rows {
                out.insert(k, serde_json::from_str(&v).expect("settings JSON válido"));
            }
        }
    }
    if let Ok(rows) = sqlx::query_as::<_, (String, String)>(
        "SELECT key, value FROM settings WHERE project_id = ?1",
    )
    .bind(project_id)
    .fetch_all(db)
    .await
    {
        for (k, v) in rows {
            out.insert(k, serde_json::from_str(&v).expect("settings JSON válido"));
        }
    }
    Ok(out)
}

/// Quita el override local de un proyecto (vuelve a heredar del global).
pub async fn project_setting_clear(db: &Db, project_id: &str, key: &str) -> Result<u64, sqlx::Error> {
    let r = sqlx::query("DELETE FROM settings WHERE project_id = ?1 AND key = ?2")
        .bind(project_id)
        .bind(key)
        .execute(db)
        .await?;
    Ok(r.rows_affected())
}

// ─── Skills globales vs copia local (A.0) ───────────────────────────────────

/// Marca/desmarca un skill como GLOBAL (visible desde cualquier proyecto).
pub async fn skill_set_global(db: &Db, id: &str, is_global: bool) -> Result<u64, sqlx::Error> {
    let r = sqlx::query("UPDATE skills SET is_global = ?2 WHERE id = ?1 AND deleted_at IS NULL")
        .bind(id).bind(is_global)
        .execute(db).await?;
    Ok(r.rows_affected())
}

/// Lista para un proyecto: sus skills locales + los GLOBALES de otros proyectos.
pub async fn skill_list_for_project(db: &Db, project_id: &str) -> Result<Vec<Skill>, sqlx::Error> {
    sqlx::query_as(
        "SELECT * FROM skills WHERE deleted_at IS NULL AND (project_id = ?1 OR is_global = 1) ORDER BY created_at",
    )
    .bind(project_id)
    .fetch_all(db)
    .await
}

/// Copia un skill a otro proyecto como copia LOCAL (nuevo id, parent apunta al
/// original; la copia nunca es global — edición local no toca el original).
pub async fn skill_copy_to_project(
    db: &Db,
    skill_id: &str,
    target_project: &str,
) -> Result<Option<DomainSkill>, sqlx::Error> {
    let original = match skill_domain_get(db, skill_id).await? {
        Some(s) => s,
        None => return Ok(None),
    };
    let mut copy = original.clone();
    copy.id = uuid::Uuid::new_v4().to_string();
    copy.metadata.parent_skill_id = Some(skill_id.to_string());
    copy.created_at = now_ms();
    copy.updated_at = now_ms();
    let manifest = serde_json::to_value(&copy).expect("skill serializable");
    skill_create(db, &copy.id, target_project, &copy.id, &manifest, "").await?;
    Ok(Some(copy))
}
