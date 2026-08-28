-- down 0007 — ramas de mensajes (A.9)
DROP INDEX IF EXISTS idx_messages_group;
ALTER TABLE messages DROP COLUMN variant_group;
ALTER TABLE messages DROP COLUMN active;
