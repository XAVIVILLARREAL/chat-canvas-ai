-- 0005_vault (Postgres) — Secretos BYOK cifrados (slice 0.4, THREAT-MODEL §3)
-- Envelope: DEK por proyecto (random 32B, envuelta con KEK AES-256-GCM) +
-- secreto cifrado con la DEK. En claro NUNCA: ni la key ni la DEK.
-- key_ref = 'vault:<id>' (local usa keychain OS → 'keyring:...' sin tabla).

CREATE TABLE vault_entries (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  wrapped_dek TEXT NOT NULL,
  nonce TEXT NOT NULL,
  ciphertext TEXT NOT NULL,
  created_at BIGINT NOT NULL
);
CREATE INDEX idx_vault_project ON vault_entries(project_id);
