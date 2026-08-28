-- 0006_encargos (Postgres) — Modo ENCARGO (A.7) + RLS fail-closed (0003).
CREATE TABLE encargos (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  criteria TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',  -- pending|running|completed|failed
  session_id TEXT REFERENCES sessions(id) ON DELETE SET NULL,
  agent_id TEXT,
  result TEXT,
  error TEXT,
  model TEXT,
  tokens INTEGER NOT NULL DEFAULT 0,
  duration_ms INTEGER,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  completed_at BIGINT
);
CREATE INDEX idx_encargos_project ON encargos(project_id, created_at);
CREATE INDEX idx_encargos_status ON encargos(status);

-- RLS fail-closed (patrón 0003): sin app.project_id → 0 filas.
ALTER TABLE encargos ENABLE ROW LEVEL SECURITY;
ALTER TABLE encargos FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_encargos ON encargos
  USING (project_id = app_tenant())
  WITH CHECK (project_id = app_tenant());
