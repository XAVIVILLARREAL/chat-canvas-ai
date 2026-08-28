-- 0004_append_only down — quitar triggers y función
DROP TRIGGER IF EXISTS event_stream_no_update ON event_stream;
DROP TRIGGER IF EXISTS event_stream_no_delete ON event_stream;
DROP TRIGGER IF EXISTS event_stream_no_truncate ON event_stream;
DROP FUNCTION IF EXISTS event_stream_forbid_mutation();
