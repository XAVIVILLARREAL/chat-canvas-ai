//! AgentProvider (A.3) — registro universal BYOK.
//!
//! TODOS los proveedores BYOK (openai/anthropic-compat/openrouter/deepseek/
//! ollama) hablan el dialecto OpenAI `/chat/completions` → un solo
//! `OpenAICompatProvider` parametrizado (base_url + key) los cubre.
//! Regla dura: la key vive en el vault — jamás en claro fuera de memoria.
//!
//! Tests: mock-server SSE (orden de chunks) + real contra OpenRouter `:free`
//! (regla free-first, $0) cuando OPENROUTER_API_KEY está definida.

use async_trait::async_trait;
use futures::StreamExt;
use serde::{Deserialize, Serialize};

// ─── Contratos ──────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize)]
pub struct ChatMessage {
    pub role: String, // system|user|assistant
    pub content: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct ChatCompletionRequest {
    pub model: String,
    pub messages: Vec<ChatMessage>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub max_tokens: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub temperature: Option<f64>,
    pub stream: bool,
}

#[derive(Debug, Clone, Serialize)]
pub struct ProviderCapabilities {
    pub streaming: bool,
    pub tools: bool,     // tool-calls → ReasonixProvider en Etapa C
    pub reasoning: bool, // razonamiento → reasoner (Etapa C)
}

#[derive(Debug, Clone, Deserialize)]
pub struct ChatCompletionResponse {
    #[allow(dead_code)]
    pub id: Option<String>,
    pub choices: Vec<Choice>,
    #[serde(default)]
    pub usage: Option<Usage>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct Choice {
    pub message: ResponseMessage,
    #[serde(default)]
    pub finish_reason: Option<String>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ResponseMessage {
    pub role: String,
    pub content: Option<String>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct Usage {
    #[serde(default)]
    pub prompt_tokens: i64,
    #[serde(default)]
    pub completion_tokens: i64,
}

/// Chunk de streaming (A.4 lo renderiza en vivo).
#[derive(Debug, Clone)]
pub struct StreamChunk {
    pub delta: String,
    pub finish_reason: Option<String>,
    pub usage: Option<Usage>,
    pub done: bool,
}

#[derive(Debug, thiserror::Error)]
pub enum ProviderError {
    #[error("provider {0} rechazó la key (HTTP {1})")]
    Unauthorized(String, u16),
    #[error("provider {0} respondió HTTP {1}")]
    Http(String, u16),
    #[error("error de conexión con {0}: {1}")]
    Network(String, String),
    #[error("respuesta ilegible de {0}: {1}")]
    Parse(String, String),
}

// ─── Trait ──────────────────────────────────────────────────────────────────

#[async_trait]
pub trait AgentProvider: Send + Sync {
    fn name(&self) -> &str;
    fn capabilities(&self) -> ProviderCapabilities;
    async fn send_message(
        &self,
        req: &ChatCompletionRequest,
    ) -> Result<ChatCompletionResponse, ProviderError>;
    /// Streaming SSE (orden de chunks preservado).
    async fn send_message_stream(
        &self,
        req: &ChatCompletionRequest,
    ) -> Result<Vec<StreamChunk>, ProviderError>;
    /// Cancelación — v1: no-op (el streaming real con cancel llega en A.4).
    fn cancel(&self) {}
}

// ─── OpenAICompatProvider (cubre openai/openrouter/deepseek/ollama) ─────────

pub struct OpenAICompatProvider {
    pub provider_name: String,
    pub base_url: String, // ej. https://openrouter.ai/api/v1
    pub api_key: String,  // en memoria — desde el vault, jamás persistida aquí
    client: reqwest::Client,
}

impl OpenAICompatProvider {
    pub fn new(name: &str, base_url: &str, api_key: &str) -> Self {
        Self {
            provider_name: name.to_string(),
            base_url: base_url.trim_end_matches('/').to_string(),
            api_key: api_key.to_string(),
            client: reqwest::Client::builder()
                .timeout(std::time::Duration::from_secs(90))
                .build()
                .expect("reqwest client"),
        }
    }

    fn chat_url(&self) -> String {
        format!("{}/chat/completions", self.base_url)
    }
}

#[async_trait]
impl AgentProvider for OpenAICompatProvider {
    fn name(&self) -> &str {
        &self.provider_name
    }

    fn capabilities(&self) -> ProviderCapabilities {
        ProviderCapabilities { streaming: true, tools: false, reasoning: false }
    }

    async fn send_message(
        &self,
        req: &ChatCompletionRequest,
    ) -> Result<ChatCompletionResponse, ProviderError> {
        let mut body = serde_json::to_value(req).map_err(|e| ProviderError::Parse(self.provider_name.clone(), e.to_string()))?;
        body["stream"] = serde_json::Value::Bool(false);
        let resp = self
            .client
            .post(self.chat_url())
            .bearer_auth(&self.api_key)
            .json(&body)
            .send()
            .await
            .map_err(|e| ProviderError::Network(self.provider_name.clone(), e.to_string()))?;
        let status = resp.status();
        if status.as_u16() == 401 || status.as_u16() == 403 {
            return Err(ProviderError::Unauthorized(self.provider_name.clone(), status.as_u16()));
        }
        if !status.is_success() {
            return Err(ProviderError::Http(self.provider_name.clone(), status.as_u16()));
        }
        resp.json::<ChatCompletionResponse>()
            .await
            .map_err(|e| ProviderError::Parse(self.provider_name.clone(), e.to_string()))
    }

    async fn send_message_stream(
        &self,
        req: &ChatCompletionRequest,
    ) -> Result<Vec<StreamChunk>, ProviderError> {
        let mut body = serde_json::to_value(req).map_err(|e| ProviderError::Parse(self.provider_name.clone(), e.to_string()))?;
        body["stream"] = serde_json::Value::Bool(true);
        let resp = self
            .client
            .post(self.chat_url())
            .bearer_auth(&self.api_key)
            .json(&body)
            .send()
            .await
            .map_err(|e| ProviderError::Network(self.provider_name.clone(), e.to_string()))?;
        let status = resp.status();
        if status.as_u16() == 401 || status.as_u16() == 403 {
            return Err(ProviderError::Unauthorized(self.provider_name.clone(), status.as_u16()));
        }
        if !status.is_success() {
            return Err(ProviderError::Http(self.provider_name.clone(), status.as_u16()));
        }

        // SSE: líneas "data: {...}" separadas por \n\n; "data: [DONE]" cierra.
        let mut stream = resp.bytes_stream();
        let mut buffer = String::new();
        let mut chunks = Vec::new();
        while let Some(item) = stream.next().await {
            let bytes = item.map_err(|e| ProviderError::Network(self.provider_name.clone(), e.to_string()))?;
            buffer.push_str(&String::from_utf8_lossy(&bytes));
            while let Some(pos) = buffer.find("\n\n") {
                let event: String = buffer.drain(..pos + 2).collect();
                for line in event.lines() {
                    let Some(data) = line.strip_prefix("data: ") else { continue };
                    let data = data.trim();
                    if data == "[DONE]" {
                        chunks.push(StreamChunk { delta: String::new(), finish_reason: None, usage: None, done: true });
                        return Ok(chunks);
                    }
                    if let Ok(v) = serde_json::from_str::<serde_json::Value>(data) {
                        let delta = v["choices"][0]["delta"]["content"]
                            .as_str()
                            .unwrap_or("")
                            .to_string();
                        let finish_reason = v["choices"][0]["finish_reason"]
                            .as_str()
                            .map(String::from);
                        let usage = v.get("usage").and_then(|u| {
                            if u.is_null() { None } else { serde_json::from_value::<Usage>(u.clone()).ok() }
                        });
                        chunks.push(StreamChunk { delta, finish_reason, usage, done: false });
                    }
                }
            }
        }
        Ok(chunks)
    }
}

/// base_url por defecto según provider_type (la tabla puede sobreescribirla).
pub fn default_base_url(provider_type: &str) -> Option<&'static str> {
    match provider_type {
        "openai" => Some("https://api.openai.com/v1"),
        "openrouter" => Some("https://openrouter.ai/api/v1"),
        "deepseek" => Some("https://api.deepseek.com/v1"),
        "ollama" => Some("http://127.0.0.1:11434/v1"),
        _ => None, // generic → exige base_url explícita
    }
}
