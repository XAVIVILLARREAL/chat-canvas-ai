-- 0001_init (Postgres) — Schema maestro Canvas AI, mismo shapes que sqlite/0001_init.sql
-- Fuente canónica: docs/SCHEMA-MAESTRO.md §3. Convenciones: epoch ms BIGINT,
-- JSON nativo, soft-delete con deleted_at. Regla general: toda tabla lleva
-- project_id (frontera multi-tenant; RLS en 0003_rls.sql).

CREATE TABLE projects (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  settings JSON NOT NULL DEFAULT '{}',
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT
);

CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  agent_config JSON NOT NULL DEFAULT '{}',
  total_tokens BIGINT NOT NULL DEFAULT 0,
  total_cost_usd DOUBLE PRECISION NOT NULL DEFAULT 0,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT
);
CREATE INDEX idx_sessions_project ON sessions(project_id, created_at);

CREATE TABLE messages (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  model TEXT,
  tokens_prompt BIGINT,
  tokens_completion BIGINT,
  cost_usd DOUBLE PRECISION,
  cache_hits BIGINT,
  metadata JSON NOT NULL DEFAULT '{}',
  created_at BIGINT NOT NULL
);
CREATE INDEX idx_messages_session ON messages(session_id, created_at);

-- LEDGER: histórico inmutable de rungs (append-only trigger en slice 0.3)
CREATE TABLE event_stream (
  id BIGSERIAL PRIMARY KEY,
  session_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  summary TEXT NOT NULL,
  payload JSON,
  lines_added BIGINT DEFAULT 0,
  lines_deleted BIGINT DEFAULT 0,
  test_passed BOOLEAN,
  model_used TEXT,
  tokens_used BIGINT DEFAULT 0,
  cost_usd DOUBLE PRECISION DEFAULT 0,
  actor_type TEXT,
  actor_id TEXT,
  created_at BIGINT NOT NULL
);
CREATE INDEX idx_event_stream_session ON event_stream(session_id, created_at);

-- Skills (.md canónicos) con versionado
CREATE TABLE skills (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  slug TEXT NOT NULL,
  current_version BIGINT NOT NULL DEFAULT 1,
  manifest JSON NOT NULL,
  body_md TEXT NOT NULL,
  avatar TEXT,
  emoji TEXT,
  bio TEXT,
  is_global BOOLEAN NOT NULL DEFAULT FALSE,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT
);
CREATE UNIQUE INDEX idx_skills_slug ON skills(project_id, slug);
CREATE TABLE skill_versions (
  id BIGSERIAL PRIMARY KEY,
  skill_id TEXT NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
  version BIGINT NOT NULL,
  manifest JSON NOT NULL,
  body_md TEXT NOT NULL,
  created_at BIGINT NOT NULL,
  UNIQUE(skill_id, version)
);

-- BYOK: el secreto NO vive aquí en claro (key_ref → vault, slice 0.4)
CREATE TABLE providers (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  provider_type TEXT NOT NULL,
  name TEXT NOT NULL,
  base_url TEXT,
  model_tier TEXT DEFAULT 'balanced',
  key_ref TEXT,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL
);
CREATE INDEX idx_providers_project ON providers(project_id);

CREATE TABLE documents (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  path TEXT NOT NULL,
  title TEXT,
  summary TEXT,
  tags JSON,
  content_md TEXT,
  embedding JSON,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL
);
CREATE INDEX idx_documents_project ON documents(project_id, path);

CREATE TABLE document_links (
  id BIGSERIAL PRIMARY KEY,
  source_doc TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  target_doc TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  created_at BIGINT NOT NULL
);

CREATE TABLE executions (
  id TEXT PRIMARY KEY,
  canvas_id TEXT NOT NULL,
  "trigger" JSON NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  node_states JSON NOT NULL DEFAULT '{}',
  variables JSON NOT NULL DEFAULT '{}',
  started_at BIGINT,
  completed_at BIGINT,
  result JSON
);
CREATE INDEX idx_executions_canvas ON executions(canvas_id, started_at);

CREATE TABLE settings (
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  key TEXT NOT NULL,
  value JSON NOT NULL,
  PRIMARY KEY (project_id, key)
);
