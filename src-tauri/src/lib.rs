use serde::{Deserialize, Serialize};
use specta::Type;
use specta_typescript::Typescript;
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
fn greet(name: String) -> String {
    format!("Hello, {}! Welcome to Empresa Dev.", name)
}

#[tauri::command]
#[specta::specta]
fn get_app_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let builder = tauri_specta::Builder::<tauri::Wry>::new()
        .commands(tauri_specta::collect_commands![greet, get_app_version]);

    #[cfg(debug_assertions)]
    builder
        .export(Typescript::default(), "../src/bindings.ts")
        .expect("Failed to export TypeScript bindings");

    let app_builder = tauri::Builder::default()
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
        app_builder = app_builder.plugin(tauri_plugin_playwright::init());
    }

    app_builder
        .invoke_handler(builder.invoke_handler())
        .setup(move |app| {
            builder.mount_events(app);
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
