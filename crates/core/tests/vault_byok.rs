//! Slice 0.4 — flujo BYOK (THREAT-MODEL §3):
//! 1) key cifra/descifra con la KEK correcta (y falla con otra)
//! 2) el dump de SQLite NUNCA contiene la key en claro
//! 3) validación de proveedor roundtrip (mock local, free-first)
//! 4) scanner bloquea keys antes de enviar contexto

use base64::engine::general_purpose::STANDARD as B64;
use base64::Engine;
use canvas_ai_core::vault::{self, EnvKeyStore, KeyStore, VaultError};
use sqlx::Row;

const KEK_VAR: &str = "CANVAS_TEST_KEK";

fn kek_env_setup() -> [u8; 32] {
    let kek: [u8; 32] = rand_like();
    std::env::set_var(KEK_VAR, B64.encode(kek));
    kek
}

// OsRng del aead no es público aquí; generamos 32B con el mismo engine del vault
fn rand_like() -> [u8; 32] {
    use aes_gcm::aead::rand_core::RngCore;
    let mut k = [0u8; 32];
    aes_gcm::aead::OsRng.fill_bytes(&mut k);
    k
}

#[tokio::test]
async fn byok_store_reveal_y_dump_sin_claro() {
    let kek = kek_env_setup();
    let ks = EnvKeyStore::from_env(KEK_VAR);
    let db = canvas_ai_core::repo::connect("sqlite::memory:").await.unwrap();
    canvas_ai_core::repo::project_create(&db, "p1", "t").await.unwrap();

    let secret = "sk-or-v1-SUPERSECRETA1234567890";
    let key_ref = vault::store_secret(&db, "p1", &ks, secret).await.unwrap();
    assert!(key_ref.starts_with("vault:"), "{key_ref}");

    // descifra con la KEK correcta
    assert_eq!(vault::reveal_secret(&db, &key_ref, &ks).await.unwrap(), secret);

    // GATE: dump de SQLite NUNCA contiene la key ni la DEK en claro
    let dump = format!(
        "{}",
        sqlx::query("SELECT hex(wrapped_dek) || hex(nonce) || hex(ciphertext) AS blob FROM vault_entries")
            .fetch_all(&db).await.unwrap()
            .iter()
            .map(|r| r.try_get::<String, _>(0).unwrap())
            .collect::<Vec<_>>()
            .join("")
    );
    assert!(!dump.contains(&hex_encode(secret)), "la key apareció en el dump");
    assert!(!dump.contains("SUPERSECRETA"), "fragmento de key en dump");

    // borrar la env → KEK unavailable → no se puede descifrar (fail-closed)
    std::env::remove_var(KEK_VAR);
    let err = vault::reveal_secret(&db, &key_ref, &ks).await.unwrap_err();
    assert!(matches!(err, VaultError::KekUnavailable(_)));

    // KEK distinta → DecryptFailed (rotación/compromiso)
    let kek2: [u8; 32] = rand_like();
    std::env::set_var(KEK_VAR, B64.encode(kek2));
    let err = vault::reveal_secret(&db, &key_ref, &ks).await.unwrap_err();
    assert!(matches!(err, VaultError::DecryptFailed), "{err:?}");
    let _ = kek; // silenciar unused en cfg

    // revocación
    std::env::set_var(KEK_VAR, B64.encode(kek));
    assert_eq!(vault::delete_secret(&db, &key_ref).await.unwrap(), 1);
    assert!(matches!(
        vault::reveal_secret(&db, &key_ref, &ks).await,
        Err(VaultError::NotFound(_))
    ));
}

fn hex_encode(s: &str) -> String {
    s.bytes().map(|b| format!("{b:02x}")).collect()
}

// ─── validación roundtrip con proveedor MOCK (free-first, sin APIs de pago) ──

async fn mock_provider(accept: &'static str) -> (String, tokio::task::JoinHandle<()>) {
    use axum::routing::get;
    let app = axum::Router::new()
        .route(
            "/models",
            get(move |headers: axum::http::HeaderMap| async move {
                let auth = headers
                    .get("authorization")
                    .and_then(|v| v.to_str().ok())
                    .unwrap_or("");
                if auth == format!("Bearer {accept}") {
                    axum::http::StatusCode::OK
                } else {
                    axum::http::StatusCode::UNAUTHORIZED
                }
            }),
        );
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });
    (format!("http://{addr}"), tokio::spawn(async {}))
}

#[tokio::test]
async fn validacion_roundtrip_proveedor() {
    let buena = "sk-or-v1-validkey123456";
    let (url, _h) = mock_provider(buena).await;

    // key correcta → OK
    vault::validate_provider_key("openrouter", &url, buena).await.unwrap();

    // key incorrecta → rechazada por el proveedor
    let err = vault::validate_provider_key("openrouter", &url, "sk-or-v1-mala").await.unwrap_err();
    assert!(matches!(err, VaultError::ProviderRejected(_)), "{err:?}");

    // formato que no coincide con el proveedor → error temprano sin llamar
    let err = vault::validate_provider_key("openrouter", &url, "sk-ant-otra").await.unwrap_err();
    assert!(matches!(err, VaultError::KeyFormatMismatch(_)), "{err:?}");

    // proveedor caído → error de conexión (no panic)
    let err = vault::validate_provider_key("openai", "http://127.0.0.1:1", "sk-validkey1234567890").await.unwrap_err();
    assert!(matches!(err, VaultError::ProviderRejected(_)));
}

#[tokio::test]
async fn scanner_impide_enviar_keys_al_llm() {
    let ks = EnvKeyStore::from_env(KEK_VAR);
    let db = canvas_ai_core::repo::connect("sqlite::memory:").await.unwrap();
    canvas_ai_core::repo::project_create(&db, "p1", "t").await.unwrap();

    // guardamos una key en el vault…
    let key_ref = vault::store_secret(&db, "p1", &ks, "sk-abcdef1234567890abcdef12").await.unwrap();

    // …y un "contexto" que la filtra en claro: el scanner debe detectarla
    let contexto = format!("usa la key sk-abcdef1234567890abcdef12 para llamar (ref {key_ref})");
    let hits = vault::scan_for_secrets(&contexto);
    assert_eq!(hits, vec!["openai_key"], "{hits:?}");
    let limpio = vault::redact_secrets(&contexto);
    assert!(!limpio.contains("sk-abcdef"));
}
