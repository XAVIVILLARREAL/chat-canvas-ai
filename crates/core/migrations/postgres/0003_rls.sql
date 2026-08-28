-- 0003_rls (Postgres) — Row Level Security FAIL-CLOSED (slice 0.2)
--
-- Contrato (AUTH.md + SCHEMA-MAESTRO regla general "toda tabla lleva project_id"):
--   * La frontera multi-tenant es project_id.
--   * Contexto por request: SET app.project_id = '<id>' (set_config por transacción).
--   * FAIL-CLOSED: si el setting NO está → current_setting(..., true) = NULL →
--     la política no matchea → 0 filas. Nada escapa por defecto.
--   * FORCE RLS: aplica también al owner de las tablas (no solo a otros roles).
--     Los superusers BYPASS RLS siempre — en producción nadie conecta como superuser.

-- ── helpers de contexto (idempotentes) ──────────────────────────────────────
CREATE OR REPLACE FUNCTION app_tenant() RETURNS TEXT AS $$
  SELECT current_setting('app.project_id', true);
$$ LANGUAGE SQL STABLE;

-- ── projects: la propia fila ES el tenant ───────────────────────────────────
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_projects ON projects
  USING (id = app_tenant())
  WITH CHECK (id = app_tenant());

-- ── tablas con project_id directo ───────────────────────────────────────────
DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'sessions', 'skills', 'providers', 'documents', 'settings',
    'canvases', 'agents', 'mcp_servers'
  ] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
    EXECUTE format($f$
      CREATE POLICY %I ON %I
        USING (project_id = app_tenant())
        WITH CHECK (project_id = app_tenant())
    $f$, 'tenant_' || t, t);
  END LOOP;
END $$;

-- ── messages / event_stream: vía session → project ─────────────────────────
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_messages ON messages
  USING (EXISTS (SELECT 1 FROM sessions s
                 WHERE s.id = messages.session_id AND s.project_id = app_tenant()))
  WITH CHECK (EXISTS (SELECT 1 FROM sessions s
                 WHERE s.id = messages.session_id AND s.project_id = app_tenant()));

ALTER TABLE event_stream ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_stream FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_event_stream ON event_stream
  USING (EXISTS (SELECT 1 FROM sessions s
                 WHERE s.id = event_stream.session_id AND s.project_id = app_tenant()))
  WITH CHECK (EXISTS (SELECT 1 FROM sessions s
                 WHERE s.id = event_stream.session_id AND s.project_id = app_tenant()));

-- ── skill_versions: vía skill → project ─────────────────────────────────────
ALTER TABLE skill_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE skill_versions FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_skill_versions ON skill_versions
  USING (EXISTS (SELECT 1 FROM skills k
                 WHERE k.id = skill_versions.skill_id AND k.project_id = app_tenant()))
  WITH CHECK (EXISTS (SELECT 1 FROM skills k
                 WHERE k.id = skill_versions.skill_id AND k.project_id = app_tenant()));

-- ── document_links: vía documento fuente → project ──────────────────────────
ALTER TABLE document_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_links FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_document_links ON document_links
  USING (EXISTS (SELECT 1 FROM documents d
                 WHERE d.id = document_links.source_doc AND d.project_id = app_tenant()))
  WITH CHECK (EXISTS (SELECT 1 FROM documents d
                 WHERE d.id = document_links.source_doc AND d.project_id = app_tenant()));

-- ── executions: canvas_id no tiene FK a una tabla (canvas es payload JSON);
--    el gateway SIEMPRE setea app.project_id, y executions lleva su propia
--    columna project_id para que RLS sea directo. ─────────────────────────────
ALTER TABLE executions ADD COLUMN project_id TEXT NOT NULL DEFAULT '';
CREATE INDEX idx_executions_project ON executions(project_id);
ALTER TABLE executions ENABLE ROW LEVEL SECURITY;
ALTER TABLE executions FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_executions ON executions
  USING (project_id = app_tenant())
  WITH CHECK (project_id = app_tenant());
