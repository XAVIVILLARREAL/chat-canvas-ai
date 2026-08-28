-- 0007_message_branches (sqlite) — Ramas visuales (A.9):
-- editar un mensaje crea una VARIANTE hermana (mismo variant_group); el campo
-- active marca qué variante está en el camino activo (1) y cuáles duermen (0).
ALTER TABLE messages ADD COLUMN variant_group TEXT;
ALTER TABLE messages ADD COLUMN active INTEGER NOT NULL DEFAULT 1;
CREATE INDEX idx_messages_group ON messages(session_id, variant_group);
