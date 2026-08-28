-- 0002_workspace (Postgres) — Objetos de workspace del server (ADR-007)
-- Patrón payload-JSON: el dominio completo como JSON en `data`.

CREATE TABLE canvases (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  data JSON NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT
);
CREATE INDEX idx_canvases_project ON canvases(project_id, updated_at);

CREATE TABLE agents (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  data JSON NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT
);
CREATE INDEX idx_agents_project ON agents(project_id, updated_at);

CREATE TABLE mcp_servers (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  data JSON NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT
);
CREATE INDEX idx_mcp_servers_project ON mcp_servers(project_id, updated_at);
