-- 0007_message_branches (Postgres) — Ramas visuales (A.9)
ALTER TABLE messages ADD COLUMN variant_group TEXT;
ALTER TABLE messages ADD COLUMN active INTEGER NOT NULL DEFAULT 1;
CREATE INDEX idx_messages_group ON messages(session_id, variant_group);
