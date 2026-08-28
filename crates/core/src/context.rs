//! Medidor de contexto (A.5) — desglose de tokens por fuente + política de truncado.
//!
//! Heurística honesta: `estimate_tokens` aproxima chars/4 (sin tokenizer real —
//! se documenta como estimación, no promesa). Las fuentes knowledge/tools/archivos
//! llegan en etapas C/D; hoy se reportan en 0 para que el desglose sea extensible
//! sin cambiar el contrato.
//!
//! Política de truncado (aplicada por el gateway en cada request):
//! 1. Los mensajes `system` SIEMPRE se envían (son instrucciones base).
//! 2. El mensaje más reciente SIEMPRE se envía (es lo que el usuario acaba de pedir).
//! 3. El resto del historial se recorta del más viejo al más nuevo hasta caber en el límite.

use serde::{Deserialize, Serialize};

/// Fuentes del contexto (contrato estable para el medidor).
pub const SOURCE_SYSTEM: &str = "system";
pub const SOURCE_HISTORIAL: &str = "historial";
pub const SOURCE_KNOWLEDGE: &str = "knowledge";
pub const SOURCE_TOOLS: &str = "tools";
pub const SOURCE_FILES: &str = "archivos";

/// Límite default de contexto si no hay setting `context_max_tokens`.
pub const DEFAULT_CONTEXT_LIMIT: usize = 8192;

/// Estimación de tokens: chars/4 redondeado arriba (heurística documentada,
/// suficiente para un medidor visual; el uso real llega en el `usage` del provider).
pub fn estimate_tokens(text: &str) -> usize {
    (text.chars().count() + 3) / 4
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, schemars::JsonSchema, specta::Type)]
pub struct ContextSource {
    pub source: String,
    pub tokens: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, schemars::JsonSchema, specta::Type)]
pub struct ContextBreakdown {
    /// Desglose por fuente (las 5 fuentes siempre presentes; 0 si aún no existen).
    pub sources: Vec<ContextSource>,
    /// Total del historial completo (sin truncar).
    pub total_tokens: usize,
    /// Límite efectivo (setting `context_max_tokens`, default 8192).
    pub limit_tokens: usize,
    /// Lo que realmente se enviaría al provider tras la política de truncado.
    pub sent_tokens: usize,
}

/// Mensaje mínimo para el cálculo (rol OpenAI: system|user|assistant|tool).
#[derive(Debug, Clone)]
pub struct ContextMessage {
    pub role: String,
    pub content: String,
}

impl ContextMessage {
    pub fn new(role: &str, content: &str) -> Self {
        Self { role: role.into(), content: content.into() }
    }
}

/// Desglose + mensajes que se enviarían tras aplicar el límite.
///
/// Reglas: system siempre viaja; el más reciente siempre viaja; el resto se
/// recorta de viejo a nuevo. Si ni system cabe en el límite, igual viaja
/// (el límite gobierna el historial, nunca corta instrucciones base).
pub fn build_context(
    messages: &[ContextMessage],
    limit: usize,
) -> (Vec<ContextMessage>, ContextBreakdown) {
    let system: Vec<ContextMessage> = messages
        .iter()
        .filter(|m| m.role == SOURCE_SYSTEM)
        .cloned()
        .collect();
    let rest: Vec<ContextMessage> = messages
        .iter()
        .filter(|m| m.role != SOURCE_SYSTEM)
        .cloned()
        .collect();

    let system_tokens: usize = system.iter().map(|m| estimate_tokens(&m.content)).sum();
    let rest_tokens: Vec<usize> = rest.iter().map(|m| estimate_tokens(&m.content)).collect();
    let total = system_tokens + rest_tokens.iter().sum::<usize>();

    // Historial (sin system) que viaja: de lo más nuevo a lo más viejo.
    let budget = limit.saturating_sub(system_tokens);
    let mut kept_idx: Vec<usize> = Vec::new();
    let mut used = 0usize;
    for (i, &tok) in rest_tokens.iter().enumerate().rev() {
        // el mensaje más reciente siempre viaja aunque exceda el límite
        if i == rest.len() - 1 || used + tok <= budget {
            kept_idx.push(i);
            used += tok;
        }
    }
    kept_idx.reverse();

    let mut kept: Vec<ContextMessage> = Vec::with_capacity(system.len() + kept_idx.len());
    kept.extend(system);
    kept.extend(kept_idx.iter().map(|&i| rest[i].clone()));

    let sent = system_tokens + used;
    let sources = vec![
        ContextSource { source: SOURCE_SYSTEM.into(), tokens: system_tokens },
        ContextSource { source: SOURCE_HISTORIAL.into(), tokens: total - system_tokens },
        ContextSource { source: SOURCE_KNOWLEDGE.into(), tokens: 0 },
        ContextSource { source: SOURCE_TOOLS.into(), tokens: 0 },
        ContextSource { source: SOURCE_FILES.into(), tokens: 0 },
    ];

    let breakdown = ContextBreakdown {
        sources,
        total_tokens: total,
        limit_tokens: limit,
        sent_tokens: sent,
    };
    (kept, breakdown)
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Fixture: historial de 4 mensajes + 1 system, límite holgado → nada se recorta.
    #[test]
    fn desglose_sin_truncado() {
        let msgs = vec![
            ContextMessage::new("system", "Eres un asistente útil"), // 22 chars → 6 tok
            ContextMessage::new("user", "hola"),                     // 1 tok
            ContextMessage::new("assistant", "¡Hola! ¿cómo estás?"), // 19 chars → 5 tok
            ContextMessage::new("user", "dime un chiste"),           // 14 chars → 4 tok
        ];
        let (kept, b) = build_context(&msgs, DEFAULT_CONTEXT_LIMIT);

        assert_eq!(kept.len(), msgs.len(), "límite holgado: todos viajan");
        assert_eq!(b.total_tokens, b.sent_tokens);
        assert_eq!(b.limit_tokens, DEFAULT_CONTEXT_LIMIT);
        let s = |name: &str| b.sources.iter().find(|x| x.source == name).unwrap().tokens;
        assert_eq!(s(SOURCE_SYSTEM), 6);
        assert_eq!(s(SOURCE_HISTORIAL), 10);
        assert_eq!(s(SOURCE_KNOWLEDGE), 0, "futuras etapas: 0 honesto");
        assert_eq!(s(SOURCE_TOOLS), 0);
        assert_eq!(s(SOURCE_FILES), 0);
        assert_eq!(b.total_tokens, 16);
    }

    /// Fixture: límite chico → el historial viejo se recorta primero,
    /// system y el mensaje más reciente siempre viajan.
    #[test]
    fn truncado_recorta_lo_viejo_primero() {
        let msgs = vec![
            ContextMessage::new("system", "instrucciones base"),
            ContextMessage::new("user", "mensaje viejo 1"),
            ContextMessage::new("assistant", "respuesta vieja 2 algo mas larga"),
            ContextMessage::new("user", "mensaje reciente final"),
        ];
        // historial (sin system) = 4 + 8 + 6 = 18 tok; system = 18 chars → 5 tok
        let (kept, b) = build_context(&msgs, 12);

        assert_eq!(b.total_tokens, 23);
        assert!(b.sent_tokens <= 12 + 5, "sent respeta el límite (system + historial): {b:?}");
        assert!(kept.iter().any(|m| m.content == "instrucciones base"), "system siempre viaja");
        assert_eq!(kept.last().unwrap().content, "mensaje reciente final", "el más reciente siempre viaja");
        assert!(!kept.iter().any(|m| m.content == "mensaje viejo 1"), "lo más viejo se recorta primero");
    }

    /// Un solo mensaje que excede el límite: viaja de todos modos (es lo último pedido).
    #[test]
    fn mensaje_reciente_viaja_aunque_exceda() {
        let msgs = vec![ContextMessage::new("user", "un mensaje muy largo que solo solo solo excede el limite")];
        let (kept, b) = build_context(&msgs, 4);
        assert_eq!(kept.len(), 1);
        assert!(b.sent_tokens > b.limit_tokens, "excepción documentada del más reciente");
    }

    /// Sin system y sin mensajes: desglose vacío pero contrato completo.
    #[test]
    fn historial_vacio() {
        let (kept, b) = build_context(&[], DEFAULT_CONTEXT_LIMIT);
        assert!(kept.is_empty());
        assert_eq!(b.total_tokens, 0);
        assert_eq!(b.sent_tokens, 0);
        assert_eq!(b.sources.len(), 5);
    }

    /// La estimación es chars/4 redondeado arriba.
    #[test]
    fn estimacion_tokens() {
        assert_eq!(estimate_tokens(""), 0);
        assert_eq!(estimate_tokens("hola"), 1);
        assert_eq!(estimate_tokens("holaa"), 2);
        assert_eq!(estimate_tokens("áéíóú ñ"), 2, "cuenta chars, no bytes");
    }
}
