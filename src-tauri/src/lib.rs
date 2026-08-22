use serde::{Deserialize, Serialize};
use specta::Type;
use tauri::Manager;

#[derive(Debug, Serialize, Deserialize, Clone, Type)]
pub struct Agent {
    pub id: String,
    pub name: String,
    pub role: String,
    pub status: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type)]
pub struct Task {
    pub id: String,
    pub title: String,
    pub description: String,
    pub status: String,
    pub assigned_agent_id: Option<String>,
}

#[tauri::command]
#[specta::specta]
fn greet(name: &str) -> String {
    format!("Hello, {}! Welcome to Empresa Dev.", name)
}

#[tauri::command]
#[specta::specta]
fn get_app_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri_specta::Builder::new()
        .command(greet)
        .command(get_app_version)
        .export(
            specta::collect_types![greet, get_app_version],
            "../src/bindings.ts",
        )
        .expect("Failed to export TypeScript bindings");

    let mut builder = tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_notification::init())
        .plugin(tauri_plugin_global_shortcut::Builder::new().build())
        .plugin(tauri_plugin_clipboard_manager::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_http::init())
        .plugin(tauri_plugin_store::Builder::new().build())
        .plugin(tauri_plugin_single_instance::init(|app, _args, _cwd| {
            if let Some(window) = app.get_webview_window("main") {
                let _ = window.set_focus();
            }
        }))
        .plugin(tauri_plugin_window_state::Builder::new().build());

    #[cfg(feature = "e2e-testing")]
    {
        builder = builder.plugin(tauri_plugin_playwright::init());
    }

    builder
        .invoke_handler(tauri::generate_handler![greet, get_app_version])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
