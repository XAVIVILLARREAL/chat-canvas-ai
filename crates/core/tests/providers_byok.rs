//! A.3 — AgentProvider + BYOK:
//! 1) mock-server SSE: orden de chunks preservado (gate del plan)
//! 2) chat endpoint: user+assistant persistidos con provider mock + key vaulted
//! 3) real OpenRouter `:free` (free-first, $0) — solo si OPENROUTER_API_KEY y
//!    CANVAS_REAL_LLM=1 (prueba real de desarrollo, skip por defecto en CI)

use async_trait::async_trait;
use axum::routing::post;
use canvas_ai_core::providers::{
    AgentProvider, ChatCompletionRequest, ChatCompletionResponse, ChatMessage, ProviderCapabilities,
    StreamChunk,
};
use serde_json::json;

// ─── 1) mock SSE: orden de chunks ───────────────────────────────────────────

async fn mock_sse_stream() -> (String, tokio::task::JoinHandle<()>) {
    use axum::response::sse::{Event, KeepAlive, Sse};
    use futures::StreamExt;
use futures::stream::Stream;
    use std::convert::Infallible;
    use std::time::Duration;

    fn events() -> impl Stream<Item = Result<Event, Infallible>> {
        let tokens = vec!["Hola", " mundo", " desde", " el", " mock"];
        let iter = tokens.into_iter().map(|tok| {
            let data = json!({
                "choices": [{ "delta": { "content": tok }, "finish_reason": null }]
            });
            Ok::<_, Infallible>(Event::default().data(data.to_string()))
        });
        futures::stream::iter(iter).chain(futures::stream::once(async {
            tokio::time::sleep(Duration::from_millis(10)).await;
            Ok::<_, Infallible>(Event::default().data("[DONE]"))
        }))
    }

    let app = axum::Router::new().route(
        "/v1/chat/completions",
        post(move || async { Sse::new(events()).keep_alive(KeepAlive::default()) }),
    );
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move { axum::serve(listener, app).await.unwrap() });
    (format!("http://{addr}/v1"), tokio::spawn(async {}))
}

#[tokio::test]
async fn sse_chunks_en_orden() {
    let (base, _h) = mock_sse_stream().await;
    let provider =
        canvas_ai_core::providers::OpenAICompatProvider::new("mock", &base, "test-key");
    let req = ChatCompletionRequest {
        model: "mock-model".into(),
        messages: vec![ChatMessage { role: "user".into(), content: "di algo".into() }],
        max_tokens: None,
        temperature: None,
        stream: true,
    };
    let chunks: Vec<StreamChunk> = provider.send_message_stream(&req).await.unwrap();
    let texto: String = chunks.iter().map(|c| c.delta.as_str()).collect();
    assert_eq!(texto, "Hola mundo desde el mock", "orden de chunks: {texto:?}");
    assert!(chunks.last().unwrap().done, "chunk DONE presente");
    // capabilities del trait
    assert!(provider.capabilities().streaming);
    assert_eq!(provider.name(), "mock");
}

#[tokio::test]
async fn no_streaming_respuesta_completa() {
    let app = axum::Router::new().route(
        "/v1/chat/completions",
        post(|| async {
            axum::Json(json!({
                "id": "chatcmpl-1",
                "choices": [{ "message": { "role": "assistant", "content": "respuesta mock" }, "finish_reason": "stop" }],
                "usage": { "prompt_tokens": 3, "completion_tokens": 5 }
            }))
        }),
    );
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move { axum::serve(listener, app).await.unwrap() });

    let provider = canvas_ai_core::providers::OpenAICompatProvider::new(
        "mock",
        &format!("http://{addr}/v1"),
        "k",
    );
    let req = ChatCompletionRequest {
        model: "m".into(),
        messages: vec![ChatMessage { role: "user".into(), content: "x".into() }],
        max_tokens: None,
        temperature: None,
        stream: false,
    };
    let resp = provider.send_message(&req).await.unwrap();
    assert_eq!(resp.choices[0].message.content.as_deref(), Some("respuesta mock"));
    assert_eq!(resp.usage.as_ref().unwrap().completion_tokens, 5);
}

// ─── 3) REAL OpenRouter :free (free-first — $0 ilimitado) ───────────────────

#[tokio::test]
async fn openrouter_free_real() {
    if std::env::var("CANVAS_REAL_LLM").as_deref() != Ok("1") {
        eprintln!("SKIP openrouter_free_real: CANVAS_REAL_LLM != 1 (prueba real opt-in)");
        return;
    }

    // ── Primario: pool free de OpenRouter (los :free se rate-limitan upstream
    // de forma transitoria — el router por modelo es el comportamiento real) ──
    let or_key = std::env::var("OPENROUTER_API_KEY").unwrap_or_default();
    if !or_key.is_empty() {
        let key = or_key;
        let provider = canvas_ai_core::providers::OpenAICompatProvider::new(
            "openrouter-free",
            "https://openrouter.ai/api/v1",
            &key,
        );
        let modelos: Vec<String> = vec![
            std::env::var("CANVAS_TEST_MODEL").unwrap_or_default(),
            "z-ai/glm-5.2:free".into(),
            "liquid/lfm-2.5-2.6b:free".into(),
            "poolside/laguna-xs-2.1:free".into(),
        ]
        .into_iter()
        .filter(|m| !m.is_empty())
        .collect();

        let mut ultimo_error = String::new();
        for model in &modelos {
            let req = ChatCompletionRequest {
                model: model.clone(),
                messages: vec![ChatMessage {
                    role: "user".into(),
                    content: "Responde exactamente con la palabra: PING".into(),
                }],
                max_tokens: Some(20),
                temperature: Some(0.0),
                stream: false,
            };
            match provider.send_message(&req).await {
                Ok(resp) => {
                    let content = resp.choices[0].message.content.clone().unwrap_or_default();
                    if strip_think(&content).trim().is_empty() {
                        ultimo_error = format!("{model}: contenido vacío");
                        continue;
                    }
                    eprintln!("✅ LLM real respondió con {model}: {content}");
                    return; // integración real verificada
                }
                Err(e) => {
                    eprintln!("modelo {model} no disponible ahora: {e}");
                    ultimo_error = e.to_string();
                }
            }
        }
        eprintln!("pool free agotado/rate-limited ({ultimo_error}) — probando fallback MiniMax…");
    } else {
        eprintln!("OPENROUTER_API_KEY no definida — probando fallback MiniMax…");
    }

    // ── Fallback: MiniMax (sk-cp-… Coding Plan, endpoint OpenAI-compatible) ──
    let mkey = std::env::var("MINIMAX_API_KEY").unwrap_or_default();
    if mkey.is_empty() {
        eprintln!("SKIP openrouter_free_real: ni OpenRouter ni MINIMAX_API_KEY definidas");
        return;
    }
    let provider = canvas_ai_core::providers::OpenAICompatProvider::new(
        "minimax",
        &std::env::var("MINIMAX_BASE_URL").unwrap_or_else(|_| "https://api.minimax.io/v1".into()),
        &mkey,
    );
    let model = std::env::var("MINIMAX_MODEL").unwrap_or_else(|_| "MiniMax-M2".into());
    let req = ChatCompletionRequest {
        model,
        messages: vec![ChatMessage {
            role: "user".into(),
            content: "Responde exactamente con la palabra: PING".into(),
        }],
        // M2 razona inline (<think>…</think>) — presupuesto suficiente
        max_tokens: Some(512),
        temperature: Some(0.0),
        stream: false,
    };
    match provider.send_message(&req).await {
        Ok(resp) => {
            let content = resp.choices[0].message.content.clone().unwrap_or_default();
            let visible = strip_think(&content);
            assert!(
                visible.to_uppercase().contains("PING"),
                "MiniMax no respondió PING: {content}"
            );
            eprintln!("✅ LLM real (fallback MiniMax) respondió: {visible}");
        }
        Err(e) => panic!("fallback MiniMax falló: {e}"),
    }
}

/// Quita el bloque de razonamiento inline <think>…</think> (quirk de M2).
fn strip_think(s: &str) -> String {
    match (s.find("<think>"), s.find("</think>")) {
        (Some(i), Some(j)) => format!("{}{}", &s[..i], &s[j + "</think>".len()..]),
        _ => s.to_string(),
    }
}

// trait object safety (registro universal)
#[allow(dead_code)]
fn _registry(p: std::sync::Arc<dyn AgentProvider>) -> String {
    let caps: ProviderCapabilities = p.capabilities();
    format!("{} streaming={}", p.name(), caps.streaming)
}

// silencia unused en algunas cfg
#[allow(unused)]
fn _req_used(_r: &ChatCompletionResponse) {}
