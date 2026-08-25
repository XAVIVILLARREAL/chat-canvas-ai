use canvas_ai_core::domain::{Agent, AgentRole};
use specta_typescript::Typescript;
use tauri::Manager;

// ADR-005 D1: los tipos de dominio viven en crates/core y son re-exportados
// aquí; el shell solo define comandos IPC que envuelven lógica del core.

/// Ejemplo de comando que fabrica dominio via core: mismo contrato para
/// Tauri (IPC) y servidor (HTTP /api/domain/agent-demo).
#[tauri::command]
#[specta::specta]
fn draft_agent(id: String, name: String) -> Agent {
    Agent::new(id, name, AgentRole::Custom("dev".into()), "tauri-user".into())
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

// Los tipos Agent/AgentRole se referencian en la firma de comandos/export specta
// para mantenerlos vivos hasta que las fases A/B los consuman.
#[allow(dead_code)]
type DomainTypes = (Agent, AgentRole);

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let builder = tauri_specta::Builder::<tauri::Wry>::new()
        .commands(tauri_specta::collect_commands![
            greet,
            get_app_version,
            draft_agent
        ]);

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
