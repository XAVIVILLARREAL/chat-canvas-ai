-- 0004_append_only (sqlite) — Ledger inmutable (slice 0.3)
-- UPDATE/DELETE sobre event_stream → rechazados. TRUNCATE no existe en SQLite.
-- La taxonomía de rungs + eventos de producto NO se restringe por CHECK:
-- conviven los 7 rungs y los eventos dot-namespace (PRODUCT-METRICS §2).

CREATE TRIGGER event_stream_no_update
BEFORE UPDATE ON event_stream
BEGIN
  SELECT RAISE(ABORT, 'event_stream es append-only: UPDATE prohibido');
END;

CREATE TRIGGER event_stream_no_delete
BEFORE DELETE ON event_stream
BEGIN
  SELECT RAISE(ABORT, 'event_stream es append-only: DELETE prohibido');
END;
