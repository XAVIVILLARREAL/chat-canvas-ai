-- 0004_append_only.sql (Postgres) — Ledger inmutable (slice 0.3)
-- UPDATE/DELETE sobre event_stream → rechazados (row triggers).
-- (TRUNCATE bypasa row-triggers; se bloquea aparte con un statement trigger.)

CREATE OR REPLACE FUNCTION event_stream_forbid_mutation() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'event_stream es append-only: % prohibido', TG_OP;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER event_stream_no_update
BEFORE UPDATE ON event_stream
FOR EACH ROW EXECUTE FUNCTION event_stream_forbid_mutation();

CREATE TRIGGER event_stream_no_delete
BEFORE DELETE ON event_stream
FOR EACH ROW EXECUTE FUNCTION event_stream_forbid_mutation();

CREATE TRIGGER event_stream_no_truncate
BEFORE TRUNCATE ON event_stream
FOR EACH STATEMENT EXECUTE FUNCTION event_stream_forbid_mutation();
