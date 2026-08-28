-- 0003_rls down — quitar políticas, RLS y columna añadida
DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'sessions', 'skills', 'providers', 'documents', 'settings',
    'canvases', 'agents', 'mcp_servers'
  ] LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', 'tenant_' || t, t);
    EXECUTE format('ALTER TABLE %I DISABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE %I NO FORCE ROW LEVEL SECURITY', t);
  END LOOP;
END $$;

DROP POLICY IF EXISTS tenant_messages ON messages;
DROP POLICY IF EXISTS tenant_event_stream ON event_stream;
DROP POLICY IF EXISTS tenant_skill_versions ON skill_versions;
DROP POLICY IF EXISTS tenant_document_links ON document_links;
DROP POLICY IF EXISTS tenant_executions ON executions;
DROP POLICY IF EXISTS tenant_projects ON projects;

ALTER TABLE messages NO FORCE ROW LEVEL SECURITY;
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE event_stream NO FORCE ROW LEVEL SECURITY;
ALTER TABLE event_stream DISABLE ROW LEVEL SECURITY;
ALTER TABLE skill_versions NO FORCE ROW LEVEL SECURITY;
ALTER TABLE skill_versions DISABLE ROW LEVEL SECURITY;
ALTER TABLE document_links NO FORCE ROW LEVEL SECURITY;
ALTER TABLE document_links DISABLE ROW LEVEL SECURITY;
ALTER TABLE executions NO FORCE ROW LEVEL SECURITY;
ALTER TABLE executions DISABLE ROW LEVEL SECURITY;
ALTER TABLE projects NO FORCE ROW LEVEL SECURITY;
ALTER TABLE projects DISABLE ROW LEVEL SECURITY;

ALTER TABLE executions DROP COLUMN IF EXISTS project_id;
DROP FUNCTION IF EXISTS app_tenant();
