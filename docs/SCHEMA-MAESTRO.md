# SCHEMA MAESTRO — Modelo canónico de datos (Etapa 0)

> **Estado:** v1.0 · 2026-08-25 · Base: [ADR-006](./ADRs/ADR-006-vision-hibrida-local-nube.md) y [PRD](./PRD.md)
> **Objetivo:** modelo único que corre en **SQLite (local-first)** y **PostgreSQL (nube multi-tenant)**. Migraciones versionadas desde el día 1. `tenant_id`/`project_id` en TODO dato.
> **Ejecución:** fase **A.0.5** del plan maestro. Convierte el server de `HashMap` en memoria a persistencia real.

---

## 1 · Principios

1. **Un solo modelo, dos dialectos** (SQLite/Postgres) — solo cambia el driver; DDL compartido con adapters por tipo (TEXT vs JSONB, etc.).
2. **Append-only para el histórico** — el `event_stream` nunca se UPDATE/DELETE (triggers que lo prohíben).
3. **Columnas de auditoría en toda tabla:** `created_at`, `updated_at`, `created_by` (actor_type+actor_id).
4. **Soft-delete** (`deleted_at`) para recuperación; hard-delete solo tras backup.
5. **IDs:** UUID v4 en nube; en local puede ser UUID igualmente (misma semántica, sync fácil).
6. **Tipos compartidos** desde `crates/core` (specta) → **OpenAPI del gateway** como artefacto consumible (frontend, SDK, docs).

## 2 · Entidades y relaciones

```
projects 1─n sessions 1─n messages
                │
                ├─n event_stream (toda tabla emite)
                ├─n executions 1─n node_states
sessions 1─n skills_used (join skill×session)
projects 1─n documents 1─n document_links (segundo cerebro)
projects 1─n providers (BYOK — secreto cifrado)
projects 1─n settings (claves/valores JSON)
skills 1─n skill_versions (historial .md)
agents (skills instanciados en sesión) → en session.agent_config
```

## 3 · DDL canónico (esquema de trabajo)

```sql
-- Toda tabla lleva project_id (nube) / workspace (local); aquí se omite por brevedad.

CREATE TABLE projects (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  settings JSON NOT NULL DEFAULT '{}',       -- config global del workspace
  created_at INTEGER NOT NULL,               -- epoch ms (portable SQLite/Postgres)
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);

CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id),
  title TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',      -- active|archived|deleted
  agent_config JSON NOT NULL DEFAULT '{}',   -- skills/agentes activos + perfil
  total_tokens INTEGER NOT NULL DEFAULT 0,
  total_cost_usd REAL NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER
);

CREATE TABLE messages (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL REFERENCES sessions(id),
  role TEXT NOT NULL,                          -- user|assistant|system|tool
  content TEXT NOT NULL,
  model TEXT,
  tokens_prompt INTEGER, tokens_completion INTEGER,
  cost_usd REAL, cache_hits INTEGER,
  metadata JSON NOT NULL DEFAULT '{}',         -- tool_calls, artifacts, reasoning
  created_at INTEGER NOT NULL
);
CREATE INDEX idx_messages_session ON messages(session_id, created_at);

-- LEDGER: histórico inmutable de rungs (taxonomía de eventos)
CREATE TABLE event_stream (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT NOT NULL,
  event_type TEXT NOT NULL,                    -- PROMPT|PHASE|DIFF|TEST_RESULT|DECISION|ESCALATION|DELIVERY
  summary TEXT NOT NULL,
  payload JSON,                                -- diff, tests, decisiones
  lines_added INTEGER DEFAULT 0, lines_deleted INTEGER DEFAULT 0,
  test_passed BOOLEAN, model_used TEXT, tokens_used INTEGER DEFAULT 0,
  cost_usd REAL DEFAULT 0, actor_type TEXT, actor_id TEXT,
  created_at INTEGER NOT NULL
);
-- Trigger append-only: prohíbe UPDATE/DELETE sobre event_stream.

-- Skills (.md canónicos) con versionado
CREATE TABLE skills (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id),
  slug TEXT NOT NULL,                          -- nombre único para /skill <slug>
  current_version INTEGER NOT NULL DEFAULT 1,
  manifest JSON NOT NULL,                      -- ver CONTRATO-SKILL.md (frontmatter)
  body_md TEXT NOT NULL,                       -- instrucciones (receta)
  avatar TEXT, emoji TEXT, bio TEXT,
  is_global BOOLEAN NOT NULL DEFAULT 0,        -- global vs por-proyecto
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER
);
CREATE TABLE skill_versions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  skill_id TEXT NOT NULL REFERENCES skills(id),
  version INTEGER NOT NULL,
  manifest JSON NOT NULL, body_md TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  UNIQUE(skill_id, version)
);

-- BYOK: proveedores (el secreto NO vive aquí en claro; se cifra aparte)
CREATE TABLE providers (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id),
  provider_type TEXT NOT NULL,                 -- openai|anthropic|openrouter|deepseek|ollama|generic
  name TEXT NOT NULL,
  base_url TEXT, model_tier TEXT DEFAULT 'balanced',
  key_ref TEXT,                                -- referencia al vault cifrado (keychain/vault por tenant)
  enabled BOOLEAN NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
);

CREATE TABLE documents (                       -- Segundo Cerebro
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id),
  path TEXT NOT NULL, title TEXT, summary TEXT, tags JSON,
  content_md TEXT, embedding JSON,             -- sqlite-vec (local) / pgvector (nube)
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
);
CREATE TABLE document_links (                  -- enlaces [[wiki]]
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source_doc TEXT NOT NULL REFERENCES documents(id),
  target_doc TEXT NOT NULL REFERENCES documents(id),
  created_at INTEGER NOT NULL
);

CREATE TABLE executions (                      -- Canvas de automatización
  id TEXT PRIMARY KEY,
  canvas_id TEXT NOT NULL, trigger JSON NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',      -- pending|running|paused|completed|failed|cancelled|waitingForHuman
  node_states JSON NOT NULL DEFAULT '{}',
  variables JSON NOT NULL DEFAULT '{}',
  started_at INTEGER, completed_at INTEGER,
  result JSON
);

CREATE TABLE settings (
  project_id TEXT NOT NULL REFERENCES projects(id),
  key TEXT NOT NULL, value JSON NOT NULL,
  PRIMARY KEY (project_id, key)
);
```

## 4 · Taxonomía del `event_stream` (rungs — contrato)

| Rung | Cuándo | Campos clave del payload |
|---|---|---|
| `PROMPT` | Requerimiento al agente | prompt, criterios_aceptacion |
| `PHASE` | Fase del SOP (Plan/Impl/Test/Review) | phase |
| `DIFF` | Modificación concreta | patch, lines_added/deleted, archivo |
| `TEST_RESULT` | Evidencia de ejecución | suite, pass/fail, cobertura |
| `DECISION` | Decisión técnica aprobada/descartada | decision, scope, evidencia |
| `ESCALATION` | Doble fallo → modelo mejor | tier_antes/tier_despues, motivo |
| `DELIVERY` | Entrega aceptada (north-star) | artifact, diff_stats |

## 5 · Migraciones y tipos

- **Herramienta:** sqlx migrations (ambos dialectos) versionadas `NNNN_desc.sql` (up+down).
- **En CI:** `sqlx offline` (compile-time checks sin DB viva) — ya elegido en [plan-s](./SDDs/SDD-001-plan-base/plan-s-despliegue-costos.md#s2).
- **Tipos compartidos:** `crates/core` (specta) → JSON schema → **OpenAPI del gateway** (`docs/openapi.yml` generado). El frontend y el contrato de skills se generan de aquí.
- **Numeración de migraciones:** arrancar en `0001_*` para este repositorio (el ERP tiene su propio esquema).

## 6 · Decisiones de diseño (por qué así)

- **`created_at INTEGER (epoch ms)`** en vez de TIMESTAMPTZ → idéntico en SQLite y Postgres, sin parsing.
- **Skills versionados** → el marketplace (O.1) y el rollback de un skill son triviales.
- **`providers.key_ref`** apunta al vault cifrado (keychain OS local / envelope por tenant en nube); el secreto **nunca** viaja en la tabla ni al webview ([THREAT-MODEL](./THREAT-MODEL.md)).
- **Event stream en `event_stream`** = la fuente de telemetría, auditoría, replay y Time-Scrubber — no duplicamos historial.

## 7 · Gate de la Etapa 0

`cargo test` de repos (CRUD) en SQLite y Postgres · migración idempotente (up/down/up) · trigger append-only rechaza UPDATE/DELETE · seed produce `project→session→message→rung` · key BYOK se cifra y descifra con la correcta · OpenAPI generado sin errores.
