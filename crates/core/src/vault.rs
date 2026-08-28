//! Vault BYOK (slice 0.4 — THREAT-MODEL §3).
//!
//! Envelope AES-256-GCM: KEK maestra (env local-nube / keychain OS en desktop)
//! envuelve una DEK por proyecto; el secreto se cifra con la DEK.
//! Reglas duras:
//!  * La key del usuario JAMÁS en claro en DB ni en respuestas — solo `key_ref`.
//!  * KEK distinta → descifrado falla (rotación/revocación por tenant).
//!  * Scanner de secretos antes de enviar contexto a un LLM.

use aes_gcm::aead::rand_core::RngCore;
use aes_gcm::aead::{Aead, KeyInit, OsRng};
use aes_gcm::{Aes256Gcm, Key, Nonce};
use base64::engine::general_purpose::STANDARD as B64;
use base64::Engine;

use crate::repo::Db;

const NONCE_LEN: usize = 12;

// ─── KeyStore: de dónde viene la KEK ────────────────────────────────────────

pub trait KeyStore: Send + Sync {
    /// KEK de 32 bytes (AES-256).
    fn kek(&self) -> Result<[u8; 32], VaultError>;
}

/// KEK desde variable de entorno (gateway nube / tests). Formato: base64 de 32B.
pub struct EnvKeyStore {
    pub var_name: String,
}

impl EnvKeyStore {
    pub fn from_env(var: &str) -> Self {
        Self { var_name: var.to_string() }
    }
}

impl KeyStore for EnvKeyStore {
    fn kek(&self) -> Result<[u8; 32], VaultError> {
        let raw = std::env::var(&self.var_name)
            .map_err(|_| VaultError::KekUnavailable(format!("env {} no definida", self.var_name)))?;
        let bytes = B64.decode(raw.trim())
            .map_err(|_| VaultError::KekUnavailable(format!("env {} no es base64 válido", self.var_name)))?;
        bytes.try_into().map_err(|_| {
            VaultError::KekUnavailable(format!("env {} debe ser 32 bytes (base64)", self.var_name))
        })
    }
}

// ─── Errores ────────────────────────────────────────────────────────────────

#[derive(Debug, thiserror::Error)]
pub enum VaultError {
    #[error("KEK no disponible: {0}")]
    KekUnavailable(String),
    #[error("secreto no encontrado: {0}")]
    NotFound(String),
    #[error("descifrado falló (¿KEK distinta o dato corrupto?)")]
    DecryptFailed,
    #[error("key_ref inválida: {0}")]
    BadRef(String),
    #[error("validación de proveedor falló: {0}")]
    ProviderRejected(String),
    #[error("key contiene formato de otro proveedor: {0}")]
    KeyFormatMismatch(String),
    #[error("crypto error")]
    Crypto,
    #[error("db error: {0}")]
    Db(#[from] sqlx::Error),
    #[error("base64 inválido")]
    Base64(#[from] base64::DecodeError),
}

// ─── Primitivas AES-256-GCM ─────────────────────────────────────────────────

fn seal(key32: &[u8; 32], plaintext: &[u8]) -> Result<(Vec<u8>, Vec<u8>), VaultError> {
    let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(key32));
    let mut nonce_bytes = [0u8; NONCE_LEN];
    OsRng.fill_bytes(&mut nonce_bytes);
    let ct = cipher
        .encrypt(Nonce::from_slice(&nonce_bytes), plaintext)
        .map_err(|_| VaultError::Crypto)?;
    Ok((nonce_bytes.to_vec(), ct))
}

fn open(key32: &[u8; 32], nonce: &[u8], ct: &[u8]) -> Result<Vec<u8>, VaultError> {
    let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(key32));
    cipher
        .decrypt(Nonce::from_slice(nonce), ct)
        .map_err(|_| VaultError::DecryptFailed)
}

fn random32() -> [u8; 32] {
    let mut k = [0u8; 32];
    OsRng.fill_bytes(&mut k);
    k
}

// ─── Vault sobre la tabla vault_entries ─────────────────────────────────────

/// Guarda un secreto cifrado (envelope). Devuelve `key_ref = "vault:<id>"`.
pub async fn store_secret(
    db: &Db,
    project_id: &str,
    ks: &dyn KeyStore,
    plaintext: &str,
) -> Result<String, VaultError> {
    let kek = ks.kek()?;
    let dek = random32();
    let (dek_nonce, wrapped_dek) = seal(&kek, &dek)?;
    let (sec_nonce, ciphertext) = seal(&dek, plaintext.as_bytes())?;

    let id = uuid::Uuid::new_v4().to_string();
    sqlx::query(
        "INSERT INTO vault_entries (id, project_id, wrapped_dek, nonce, ciphertext, created_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
    )
    .bind(&id)
    .bind(project_id)
    .bind(B64.encode(wrapped_dek))
    // nonce de la DEK precede al nonce del secreto en formato "<b64a>:<b64b>"
    .bind(format!("{}:{}", B64.encode(dek_nonce), B64.encode(sec_nonce)))
    .bind(B64.encode(ciphertext))
    .bind(crate::repo::now_ms())
    .execute(db)
    .await?;
    Ok(format!("vault:{id}"))
}

/// Recupera y descifra un secreto (solo lado server/worker — jamás el webview).
pub async fn reveal_secret(db: &Db, key_ref: &str, ks: &dyn KeyStore) -> Result<String, VaultError> {
    let id = key_ref
        .strip_prefix("vault:")
        .ok_or_else(|| VaultError::BadRef(key_ref.to_string()))?;
    let row: Option<(String, String, String)> = sqlx::query_as(
        "SELECT wrapped_dek, nonce, ciphertext FROM vault_entries WHERE id = ?1",
    )
    .bind(id)
    .fetch_optional(db)
    .await?;
    let (wrapped_dek_b64, nonces, ciphertext_b64) =
        row.ok_or_else(|| VaultError::NotFound(key_ref.to_string()))?;

    // "nonces" = "<b64 nonce DEK>:<b64 nonce secreto>"
    let mut parts = nonces.splitn(2, ':');
    let dek_nonce = B64.decode(parts.next().ok_or_else(|| VaultError::BadRef("nonce".into()))?)?;
    let sec_nonce = B64.decode(parts.next().ok_or_else(|| VaultError::BadRef("nonce".into()))?)?;
    let wrapped_dek = B64.decode(wrapped_dek_b64)?;
    let ciphertext = B64.decode(ciphertext_b64)?;

    // envelope: KEK abre la DEK; la DEK abre el secreto. KEK distinta → error.
    let kek = ks.kek()?;
    let dek_vec = open(&kek, &dek_nonce, &wrapped_dek)?;
    let dek: [u8; 32] = dek_vec.try_into().map_err(|_| VaultError::DecryptFailed)?;
    let plaintext = open(&dek, &sec_nonce, &ciphertext)?;
    String::from_utf8(plaintext).map_err(|_| VaultError::DecryptFailed)
}

/// Elimina un secreto (revocación inmediata).
pub async fn delete_secret(db: &Db, key_ref: &str) -> Result<u64, VaultError> {
    let id = key_ref
        .strip_prefix("vault:")
        .ok_or_else(|| VaultError::BadRef(key_ref.to_string()))?;
    let r = sqlx::query("DELETE FROM vault_entries WHERE id = ?1")
        .bind(id)
        .execute(db)
        .await?;
    Ok(r.rows_affected())
}

// ─── Validación de proveedor (roundtrip mínimo al pegar la key) ─────────────

/// Roundtrip mínimo: GET {base_url}/models con Bearer; 200 = válida.
/// Nunca loguea la key. `base_url` sin trailing slash.
pub async fn validate_provider_key(
    provider_type: &str,
    base_url: &str,
    key: &str,
) -> Result<(), VaultError> {
    check_key_format(provider_type, key)?;

    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|_| VaultError::Crypto)?;
    let url = format!("{}/models", base_url.trim_end_matches('/'));
    let resp = client
        .get(&url)
        .bearer_auth(key)
        .send()
        .await
        .map_err(|e| VaultError::ProviderRejected(format!("sin conexión al proveedor: {e}")))?;
    match resp.status() {
        s if s.is_success() => Ok(()),
        s if s.as_u16() == 401 || s.as_u16() == 403 => {
            Err(VaultError::ProviderRejected(format!("key rechazada por {provider_type} (HTTP {})", s.as_u16())))
        }
        s => Err(VaultError::ProviderRejected(format!("proveedor respondió HTTP {}", s.as_u16()))),
    }
}

/// El formato de la key debe coincidir con el proveedor (detected early).
fn check_key_format(provider_type: &str, key: &str) -> Result<(), VaultError> {
    let ok = match provider_type {
        "openai" => key.starts_with("sk-") && !key.starts_with("sk-or-") && !key.starts_with("sk-ant-"),
        "openrouter" => key.starts_with("sk-or-"),
        "anthropic" => key.starts_with("sk-ant-"),
        "deepseek" => key.starts_with("sk-"),
        "ollama" => true, // local, sin key o dummy
        "generic" => !key.is_empty(),
        other => return Err(VaultError::ProviderRejected(format!("tipo desconocido: {other}"))),
    };
    if ok { Ok(()) } else { Err(VaultError::KeyFormatMismatch(provider_type.to_string())) }
}

// ─── Scanner de secretos (antes de enviar contexto a un LLM) ────────────────

/// Hallazgos de secretos en texto libre (prompts, contexto, logs).
pub fn scan_for_secrets(text: &str) -> Vec<&'static str> {
    let mut found = Vec::new();
    let mut has = |pat: &str, name: &'static str| {
        if text.contains(pat) && !found.contains(&name) {
            found.push(name);
        }
    };
    has("sk-or-", "openrouter_key");
    has("sk-ant-", "anthropic_key");
    has("AKIA", "aws_access_key");
    has("ghp_", "github_token");
    has("gho_", "github_token");
    has("xoxb-", "slack_token");
    has("xoxp-", "slack_token");
    has("AIza", "google_api_key");
    // openai genérico: sk- seguido de ≥20 alfanuméricos (evita sk-or-/sk-ant ya marcados)
    if text
        .split(|c: char| !c.is_ascii_alphanumeric() && c != '-')
        .any(|tok| tok.starts_with("sk-") && tok.len() >= 20 && !tok.starts_with("sk-or-") && !tok.starts_with("sk-ant-"))
    {
        found.push("openai_key");
    }
    found
}

/// Redacta los hallazgos (reemplaza por el nombre del patrón).
pub fn redact_secrets(text: &str) -> String {
    let mut out = text.to_string();
    for name in scan_for_secrets(text) {
        out = redact_pattern(&out, name);
    }
    out
}

fn redact_pattern(text: &str, name: &str) -> String {
    // por tokens (same tokenizer que el scanner)
    let mut out = Vec::new();
    for tok in text.split(' ') {
        let hit = match name {
            "openrouter_key" => tok.starts_with("sk-or-"),
            "anthropic_key" => tok.starts_with("sk-ant-"),
            "aws_access_key" => tok.contains("AKIA"),
            "github_token" => tok.starts_with("ghp_") || tok.starts_with("gho_"),
            "slack_token" => tok.starts_with("xoxb-") || tok.starts_with("xoxp-"),
            "google_api_key" => tok.contains("AIza"),
            "openai_key" => {
                tok.starts_with("sk-")
                    && tok.len() >= 20
                    && !tok.starts_with("sk-or-")
                    && !tok.starts_with("sk-ant-")
            }
            _ => false,
        };
        out.push(if hit { format!("[REDACTED:{name}]") } else { tok.to_string() });
    }
    out.join(" ")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn seal_open_roundtrip_y_kek_distinta_falla() {
        let kek = random32();
        let (nonce, ct) = seal(&kek, b"sk-test-123").unwrap();
        assert_eq!(open(&kek, &nonce, &ct).unwrap(), b"sk-test-123");
        let otra_kek = random32();
        assert!(matches!(open(&otra_kek, &nonce, &ct), Err(VaultError::DecryptFailed)));
    }

    #[test]
    fn scanner_detecta_y_redacta() {
        let prompt = "usa esta key sk-abcdef1234567890abcdef12 y ghp_abcdef123456789012345678901234567890";
        let found = scan_for_secrets(prompt);
        assert!(found.contains(&"openai_key"), "{found:?}");
        assert!(found.contains(&"github_token"));
        let redacted = redact_secrets(prompt);
        assert!(!redacted.contains("sk-abcdef"), "{redacted}");
        assert!(redacted.contains("[REDACTED:openai_key]"));
        // texto limpio → sin hallazgos
        assert!(scan_for_secrets("hola mundo, nada raro").is_empty());
    }
}

// ─── Secret settings (A.2): settings sensibles cifradas — jamás plano ───────
//
// Patrón T.SEC: la fila de `settings` guarda SOLO el marcador {"__secret": key_ref};
// el secreto vive cifrado en vault_entries. `settings_resolved` es safe-by-default
// (devuelve key_refs, nunca plaintext); el plaintext SOLO via reveal explícito.

pub const SECRET_MARKER: &str = "__secret";

/// Guarda un setting sensible cifrado. La fila queda con la referencia, jamás el valor.
pub async fn set_secret_setting(
    db: &Db,
    project_id: &str,
    key: &str,
    plaintext: &str,
    ks: &dyn KeyStore,
) -> Result<(), VaultError> {
    let key_ref = store_secret(db, project_id, ks, plaintext).await?;
    crate::repo::setting_set(db, project_id, key, &serde_json::json!({ SECRET_MARKER: key_ref })).await?;
    Ok(())
}

/// Lee el marcador de un setting sensible (key_ref, sin descifrar).
pub async fn secret_setting_ref(
    db: &Db,
    project_id: &str,
    key: &str,
) -> Result<Option<String>, VaultError> {
    match crate::repo::setting_resolve(db, project_id, key).await? {
        Some(v) => Ok(Some(
            v.get(SECRET_MARKER)
                .and_then(|r| r.as_str())
                .map(String::from)
                .ok_or(VaultError::NotFound(format!("setting '{key}' no es un secreto")))?,
        )),
        None => Ok(None),
    }
}

/// Descifra un setting sensible (server/worker — jamás el webview).
pub async fn reveal_secret_setting(
    db: &Db,
    project_id: &str,
    key: &str,
    ks: &dyn KeyStore,
) -> Result<Option<String>, VaultError> {
    match secret_setting_ref(db, project_id, key).await? {
        Some(key_ref) => Ok(Some(reveal_secret(db, &key_ref, ks).await?)),
        None => Ok(None),
    }
}

/// Borra un setting sensible (fila + secreto del vault).
pub async fn delete_secret_setting(db: &Db, project_id: &str, key: &str) -> Result<(), VaultError> {
    if let Some(key_ref) = secret_setting_ref(db, project_id, key).await? {
        delete_secret(db, &key_ref).await?;
    }
    crate::repo::project_setting_clear(db, project_id, key).await?;
    Ok(())
}
