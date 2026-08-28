-- 0004_append_only down (sqlite) — quitar triggers
DROP TRIGGER IF EXISTS event_stream_no_update;
DROP TRIGGER IF EXISTS event_stream_no_delete;
