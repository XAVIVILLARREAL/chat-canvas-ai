//! Slice 0.2 — integración Postgres + RLS fail-closed.
//!
//! Gate: "cargo test contra Postgres; 2 tenants → datos aislados (SQL directo);
//! sin tenant → 0 filas". Se ejecuta contra un Postgres real si
//! `CANVAS_TEST_PG_URL` está definida (skip silencioso si no, para CI sin PG).
//!
//! Requisitos del usuario de PG: NO superuser, NO bypassrls (FORCE RLS aplica
//! al owner; los superusers bypasean RLS siempre).
//!
//! Ejemplo local:
//!   CANVAS_TEST_PG_URL=postgres://empresa:empresa_dev@localhost:5433/canvas_ai_test \
//!     cargo test -p canvas-ai-core --test rls_postgres

use sqlx::{Executor, Row};

/// Los 3 tests tocan la MISMA base de datos con DDL/TRUNCATE — corren serializados
/// (en paralelo los locks DDL de Postgres se pisan y se cuelgan).
static SERIAL: std::sync::OnceLock<tokio::sync::Mutex<()>> = std::sync::OnceLock::new();

async fn serial_lock() -> tokio::sync::MutexGuard<'static, ()> {
    SERIAL.get_or_init(|| tokio::sync::Mutex::new(())).lock().await
}

async fn pg_url() -> Option<String> {
    std::env::var("CANVAS_TEST_PG_URL").ok()
}

async fn set_guard(conn: &mut sqlx::PgConnection) {
    conn.execute(sqlx::raw_sql(
        "SET statement_timeout = '15s'; SET idle_in_transaction_session_timeout = '15s'; SET lock_timeout = '10s';",
    ))
    .await
    .expect("set guard timeouts");
}

/// Contexto de tenant en la conexión (así viaja en producción: por request).
async fn set_tenant(conn: &mut sqlx::PgConnection, project_id: &str) {
    conn.execute(sqlx::query("SELECT set_config('app.project_id', $1, false)").bind(project_id))
        .await
        .expect("set_config tenant");
}

async fn count_sessions(conn: &mut sqlx::PgConnection) -> i64 {
    let row: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM sessions")
        .fetch_one(conn)
        .await
        .expect("count sessions");
    row.0
}

/// Limpia todo (TRUNCATE no pasa por RLS — es del harness, no del gateway).
/// event_stream queda fuera: es append-only (trigger 0004 lo prohíbe) y los
/// tests no asumen counts globales del ledger.
async fn limpiar(pool: &sqlx::PgPool) {
    sqlx::query(
        "TRUNCATE settings, document_links, documents, skill_versions, skills, messages, sessions, providers, canvases, agents, mcp_servers, executions, projects CASCADE",
    )
    .execute(pool)
    .await
    .expect("truncate");
}

#[tokio::test]
async fn rls_postgres_aislamiento_y_fail_closed() {
    let _serial = serial_lock().await;
    let Some(url) = pg_url().await else {
        eprintln!("SKIP rls_postgres: CANVAS_TEST_PG_URL no definida");
        return;
    };

    // migraciones (schema + RLS) — idempotente
    let pool = canvas_ai_core::repo::connect_postgres(&url)
        .await
        .expect("conectar+migrar Postgres");
    limpiar(&pool).await;

    // ── seed: 2 tenants (projects) con datos, SIEMPRE con contexto seteado ──
    // (FORCE RLS aplica al owner: sin contexto, ni INSERT funciona — fail-closed)
    let mut c1 = pool.acquire().await.unwrap();
    set_guard(&mut c1).await;
    set_tenant(&mut c1, "p1").await;
    sqlx::query("INSERT INTO projects (id, name, created_at, updated_at) VALUES ('p1','Tenant Uno',1,1) ON CONFLICT (id) DO NOTHING")
        .execute(&mut *c1).await.unwrap();
    sqlx::query("INSERT INTO sessions (id, project_id, title, created_at, updated_at) VALUES ('s1','p1','sesion p1',1,1)")
        .execute(&mut *c1).await.unwrap();
    sqlx::query("INSERT INTO messages (id, session_id, role, content, created_at) VALUES ('m1','s1','user','hola p1',1)")
        .execute(&mut *c1).await.unwrap();

    let mut c2 = pool.acquire().await.unwrap();
    set_guard(&mut c2).await;
    set_tenant(&mut c2, "p2").await;
    sqlx::query("INSERT INTO projects (id, name, created_at, updated_at) VALUES ('p2','Tenant Dos',2,2) ON CONFLICT (id) DO NOTHING")
        .execute(&mut *c2).await.unwrap();
    sqlx::query("INSERT INTO sessions (id, project_id, title, created_at, updated_at) VALUES ('s2','p2','sesion p2',2,2)")
        .execute(&mut *c2).await.unwrap();
    sqlx::query("INSERT INTO messages (id, session_id, role, content, created_at) VALUES ('m2','s2','user','hola p2',2)")
        .execute(&mut *c2).await.unwrap();

    // ── aislamiento: p1 solo ve lo suyo; p2 solo lo suyo ──
    assert_eq!(count_sessions(&mut c1).await, 1, "p1 ve SOLO su sesión");
    assert_eq!(count_sessions(&mut c2).await, 1, "p2 ve SOLO su sesión");

    let titulo_p1: (String,) = sqlx::query_as("SELECT title FROM sessions WHERE id = 's1'")
        .fetch_one(&mut *c1).await.unwrap();
    assert_eq!(titulo_p1.0, "sesion p1");
    let p1_ve_s2: Option<(String,)> = sqlx::query_as("SELECT title FROM sessions WHERE id = 's2'")
        .fetch_optional(&mut *c1).await.unwrap();
    assert!(p1_ve_s2.is_none(), "p1 NO puede ver la sesión de p2");

    // mensajes vía la política EXISTS (session → project)
    let msgs_p1: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM messages")
        .fetch_one(&mut *c1).await.unwrap();
    assert_eq!(msgs_p1.0, 1, "p1 ve solo su mensaje");
    let msgs_p2: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM messages")
        .fetch_one(&mut *c2).await.unwrap();
    assert_eq!(msgs_p2.0, 1);

    // ── cross-tenant UPDATE/DELETE no afectan filas ajenas ──
    let affected = sqlx::query("UPDATE sessions SET title = 'hackeada' WHERE project_id = 'p2'")
        .execute(&mut *c1).await.unwrap().rows_affected();
    assert_eq!(affected, 0, "p1 NO puede mutar filas de p2");
    let affected = sqlx::query("DELETE FROM sessions WHERE project_id = 'p2'")
        .execute(&mut *c1).await.unwrap().rows_affected();
    assert_eq!(affected, 0, "p1 NO puede borrar filas de p2");

    // ── FAIL-CLOSED: conexión SIN contexto → 0 filas ──
    let mut c3 = pool.acquire().await.unwrap(); // nunca seteó app.project_id
    set_guard(&mut c3).await;
    assert_eq!(count_sessions(&mut c3).await, 0, "sin tenant → 0 filas (fail-closed)");
    let proyectos: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM projects")
        .fetch_one(&mut *c3).await.unwrap();
    assert_eq!(proyectos.0, 0);
    // y el UPDATE sin contexto no toca NADA
    let affected = sqlx::query("UPDATE sessions SET title = 'sin contexto'")
        .execute(&mut *c3).await.unwrap().rows_affected();
    assert_eq!(affected, 0, "UPDATE sin tenant no toca ninguna fila");

    // ── settings/tablas de workspace también aisladas ──
    sqlx::query("INSERT INTO settings (project_id, key, value) VALUES ('p1','tema','\"dark\"'::json)")
        .execute(&mut *c1).await.unwrap();
    let (st,): (i64,) = sqlx::query_as("SELECT COUNT(*) FROM settings")
        .fetch_one(&mut *c2).await.unwrap();
    assert_eq!(st, 0, "p2 no ve settings de p1");

    // sanity: el UPDATE de p1 a su propia fila SÍ funciona (no sobre-bloqueo)
    let affected = sqlx::query("UPDATE sessions SET title = 'sesion p1 editada' WHERE project_id = 'p1'")
        .execute(&mut *c1).await.unwrap().rows_affected();
    assert_eq!(affected, 1, "el tenant SÍ puede editar lo suyo");

    drop(c1); drop(c2); drop(c3); // soltar ANTES del close (ver ADR del test)
    pool.close().await;
}

/// up/down/up idempotente en Postgres (la fila de la MATRIZ lo exige junto a SQLite).
#[tokio::test]
async fn migracion_postgres_up_down_up() {
    let _serial = serial_lock().await;
    let Some(url) = pg_url().await else {
        eprintln!("SKIP migracion_postgres: CANVAS_TEST_PG_URL no definida");
        return;
    };
    let down_dir = concat!(env!("CARGO_MANIFEST_DIR"), "/migrations/postgres/down");

    let pool = canvas_ai_core::repo::connect_postgres(&url).await.unwrap();
    limpiar(&pool).await;

    // semilla mínima (el contexto DEBE coincidir con el project_id insertado:
    // el WITH CHECK de la política lo impone — un tenant no puede crear filas ajenas)
    let mut c = pool.acquire().await.unwrap();
    set_guard(&mut c).await;
    set_tenant(&mut c, "px").await;
    sqlx::query("INSERT INTO projects (id, name, created_at, updated_at) VALUES ('px','x',1,1)")
        .execute(&mut *c).await.unwrap();

    // down TOTAL (todas las reversas en orden inverso, cada archivo como raw_sql
    // — los bloques DO $$ no se pueden partir por ';')
    let mut orden = std::fs::read_dir(down_dir).unwrap()
        .filter_map(|e| e.ok())
        .map(|e| e.path())
        .collect::<Vec<_>>();
    orden.sort();
    for path in orden.into_iter().rev() {
        let sql = std::fs::read_to_string(&path).unwrap();
        sqlx::raw_sql(&sql).execute(&pool).await
            .unwrap_or_else(|e| panic!("down {:?} falló: {e}", path));
    }
    sqlx::query("DELETE FROM _sqlx_migrations").execute(&pool).await.unwrap();
    let tablas: Vec<(String,)> = sqlx::query_as(
        "SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename != '_sqlx_migrations'"
    ).fetch_all(&pool).await.unwrap();
    assert!(tablas.is_empty(), "down debe dejar 0 tablas de negocio, quedó: {tablas:?}");

    // up de nuevo (migrador runtime)
    canvas_ai_core::repo::migrate_postgres(&pool).await.unwrap();
    let mut c = pool.acquire().await.unwrap();
    set_guard(&mut c).await;
    set_tenant(&mut c, "px").await;
    let ya_no: Option<(String,)> = sqlx::query_as("SELECT name FROM projects WHERE id = 'px'")
        .fetch_optional(&mut *c).await.unwrap();
    drop(c); // soltar ANTES del close: pool.close() espera conexiones checked-out
    assert!(ya_no.is_none(), "tras down/up la data vieja no existe");
    pool.close().await;
}

/// smoke: el pool responde y las políticas existen (evidencia SQL directa).
#[tokio::test]
async fn politicas_rls_instaladas() {
    let _serial = serial_lock().await;
    let Some(url) = pg_url().await else {
        eprintln!("SKIP politicas_rls: CANVAS_TEST_PG_URL no definida");
        return;
    };
    let pool = canvas_ai_core::repo::connect_postgres(&url).await.unwrap();
    let (n,): (i64,) = sqlx::query_as(
        "SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND policyname LIKE 'tenant_%'",
    )
    .fetch_one(&pool)
    .await
    .unwrap();
    // 1 (projects) + 8 directas + 4 vía EXISTS + 1 (executions) = 14 políticas tenant_*
    assert_eq!(n, 14, "se esperaban 14 políticas tenant_*, hay {n}");
    pool.close().await;
}

// silencia el warning si Row no se usa en alguna cfg
#[allow(unused)]
fn _row_used(r: &sqlx::postgres::PgRow) -> i64 {
    r.get(0)
}

// ─── Slice 0.3: ledger append-only bajo RLS ─────────────────────────────────

/// append-only en PG: UPDATE/DELETE/TRUNCATE rechazados; seed project→session→message→rung.
#[tokio::test]
async fn ledger_append_only_postgres() {
    let _serial = serial_lock().await;
    let Some(url) = pg_url().await else {
        eprintln!("SKIP ledger_append_only_pg: CANVAS_TEST_PG_URL no definida");
        return;
    };
    let pool = canvas_ai_core::repo::connect_postgres(&url).await.unwrap();
    limpiar(&pool).await;

    let mut c = pool.acquire().await.unwrap();
    set_guard(&mut c).await;
    set_tenant(&mut c, "p1").await;
    sqlx::query("INSERT INTO projects (id, name, created_at, updated_at) VALUES ('p1','uno',1,1)")
        .execute(&mut *c).await.unwrap();
    sqlx::query("INSERT INTO sessions (id, project_id, title, created_at, updated_at) VALUES ('s1','p1','ses',1,1)")
        .execute(&mut *c).await.unwrap();
    sqlx::query("INSERT INTO messages (id, session_id, role, content, created_at) VALUES ('m1','s1','user','hola',1)")
        .execute(&mut *c).await.unwrap();
    let rid: (i64,) = sqlx::query_as(
        "INSERT INTO event_stream (session_id, event_type, summary, created_at) VALUES ('s1','PROMPT','primer rung',1) RETURNING id",
    ).fetch_one(&mut *c).await.unwrap();

    // UPDATE → rechazado
    let err = sqlx::query("UPDATE event_stream SET summary='x' WHERE id=$1")
        .bind(rid.0).execute(&mut *c).await;
    assert!(err.is_err(), "UPDATE debe ser rechazado");
    assert!(err.unwrap_err().to_string().contains("append-only"));
    // DELETE → rechazado
    let err = sqlx::query("DELETE FROM event_stream WHERE id=$1")
        .bind(rid.0).execute(&mut *c).await;
    assert!(err.is_err(), "DELETE debe ser rechazado");
    // TRUNCATE → rechazado (statement trigger)
    let err = sqlx::query("TRUNCATE event_stream").execute(&mut *c).await;
    assert!(err.is_err(), "TRUNCATE debe ser rechazado");

    // el rung sigue ahí (y visible solo para su tenant)
    let (n,): (i64,) = sqlx::query_as("SELECT COUNT(*) FROM event_stream WHERE session_id='s1'")
        .fetch_one(&mut *c).await.unwrap();
    assert_eq!(n, 1, "ledger intacto");
    drop(c);
    pool.close().await;
}
