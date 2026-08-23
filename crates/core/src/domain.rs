//! Tipos de dominio compartidos por todos los binarios.
//! Derivan `specta::Type` para que tauri-specta genere bindings TS
//! y el servidor pueda exponer los mismos contratos por HTTP.

use serde::{Deserialize, Serialize};
use specta::Type;

#[derive(Debug, Serialize, Deserialize, Clone, Type)]
pub struct Agent {
    pub id: String,
    pub name: String,
    pub role: String,
    pub status: String,
}

impl Agent {
    /// Fábrica única: cualquier shell (Tauri o servidor) crea agentes igual.
    pub fn new(id: String, name: String) -> Self {
        Self {
            id,
            name,
            role: "dev".into(),
            status: "idle".into(),
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, Type)]
pub struct Task {
    pub id: String,
    pub title: String,
    pub description: String,
    pub status: String,
    pub assigned_agent_id: Option<String>,
}
