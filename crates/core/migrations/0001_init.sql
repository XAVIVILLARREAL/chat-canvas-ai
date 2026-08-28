-- 0001_init — Schema maestro Canvas AI (Etapa 0, slice 0.1)
-- Fuente canónica: docs/SCHEMA-MAESTRO.md §3 (DDL de trabajo)
-- Convenciones: epoch ms (portable SQLite/Postgres), JSON como TEXT,
-- soft-delete con deleted_at donde aplica, project_id como frontera multi-tenant.

CREATE TABLE projects (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  settings TEXT NOT NULL DEFAULT '{}',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);

CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  agent_config TEXT NOT NULL DEFAULT '{}',
  total_tokens INTEGER NOT NULL DEFAULT 0,
  total_cost_usd REAL NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);
CREATE INDEX idx_sessions_project ON sessions(project_id, created_at);

CREATE TABLE messages (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  model TEXT,
  tokens_prompt INTEGER,
  tokens_completion INTEGER,
  cost_usd REAL,
  cache_hits INTEGER,
  metadata TEXT NOT NULL DEFAULT '{}',
  created_at INTEGER NOT NULL
);
CREATE INDEX idx_messages_session ON messages(session_id, created_at);

-- LEDGER: histórico inmutable de rungs (taxonomía en slice 0.3)
CREATE TABLE event_stream (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  summary TEXT NOT NULL,
  payload TEXT,
  lines_added INTEGER DEFAULT 0,
  lines_deleted INTEGER DEFAULT 0,
  test_passed INTEGER,
  model_used TEXT,
  tokens_used INTEGER DEFAULT 0,
  cost_usd REAL DEFAULT 0,
  actor_type TEXT,
  actor_id TEXT,
  created_at INTEGER NOT NULL
);
CREATE INDEX idx_event_stream_session ON event_stream(session_id, created_at);

-- Skills (.md canónicos) con versionado
CREATE TABLE skills (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  slug TEXT NOT NULL,
  current_version INTEGER NOT NULL DEFAULT 1,
  manifest TEXT NOT NULL,
  body_md TEXT NOT NULL,
  avatar TEXT,
  emoji TEXT,
  bio TEXT,
  is_global INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);
CREATE UNIQUE INDEX idx_skills_slug ON skills(project_id, slug);
CREATE TABLE skill_versions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  skill_id TEXT NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
  version INTEGER NOT NULL,
  manifest TEXT NOT NULL,
  body_md TEXT NOT NULL,
  created_at INTEGER NOT NULL,
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
  enabled INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_providers_project ON providers(project_id);

CREATE TABLE documents (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  path TEXT NOT NULL,
  title TEXT,
  summary TEXT,
  tags TEXT,
  content_md TEXT,
  embedding TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_documents_project ON documents(project_id, path);

CREATE TABLE document_links (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source_doc TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  target_doc TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  created_at INTEGER NOT NULL
);

CREATE TABLE executions (
  id TEXT PRIMARY KEY,
  canvas_id TEXT NOT NULL,
  "trigger" TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  node_states TEXT NOT NULL DEFAULT '{}',
  variables TEXT NOT NULL DEFAULT '{}',
  started_at INTEGER,
  completed_at INTEGER,
  result TEXT
);
CREATE INDEX idx_executions_canvas ON executions(canvas_id, started_at);

CREATE TABLE settings (
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  PRIMARY KEY (project_id, key)
);
