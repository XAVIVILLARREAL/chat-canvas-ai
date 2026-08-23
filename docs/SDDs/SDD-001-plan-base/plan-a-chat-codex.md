# PLAN A — Chat núcleo Codex

> [← Maestro](./README.md) · Siguiente: [PLAN B →](./plan-b-sidepanels-lovable.md)
> Base de todos los demás planes. Copia los patrones de interacción de OpenAI Codex.

**Entregable:** abres la app, chateas con streaming, controlas permisos con 2 perillas, el historial persiste, slash commands funcionan.

## Fases

### A.1 — AppShell + stores
- Layout 3 paneles responsive según ADR-001: Sidebar proyectos / ChatPanel / WorkArea placeholder
- Stores Zustand: `session-store` (sesión activa, mensajes), `ui-store` (paneles, perillas)
- `useResponsive` wired a AppShell
- **Pruebas:** Vitest stores+hook. E2E: layout mobile 375px (BottomNav) y desktop 1440px (sidebar)

<a id="a2"></a>
### A.2 — Persistencia SQLite
- Tablas `sessions`, `messages` via sqlx (migraciones embebidas)
- Commands Tauri CRUD + bindings tauri-specta
- **Pruebas:** Cargo test repositorios; integration roundtrip mensaje

<a id="a3"></a>
### A.3 — Trait AgentProvider + DeepSeekDirect
```rust
#[async_trait]
trait AgentProvider {
    async fn send(&self, session: &SessionId, msg: &str, policy: &PermissionPolicy) -> EventStream;
    fn capabilities(&self) -> Capabilities;
}
```
- `DeepSeekDirect`: HTTP SSE en Rust (key cifrada en tabla settings — JAMÁS al webview)
- Streaming → evento Tauri `chat://chunk`
- **Pruebas:** unit con mock-server SSE; integration orden de chunks

<a id="a4"></a>
### A.4 — UX Codex (el corazón copiado)
- **2 perillas ortogonales** junto al composer (patrón Codex):
  - Perilla 1 alcance: `Solo lectura | Workspace | Total` 
  - Perilla 2 aprobación: `Nunca | Al salir del sandbox | Siempre`
  - Presets con nombre: **Auto** (workspace+al-salir), **Lectura**, **Plan**
  - Traducción a modos Reasonix (`ask/auto/plan/acceptEdits/dontAsk`) documentada para [PLAN C](./plan-c-reasonix-deepseek.md#c1)
- Cards de tool-call: nombre + args colapsados + resultado + estado
- Visor de diff unificado inline en el chat
- Panel terminal colapsable (salida de comandos del agente)
- **Slash commands**: `/resume`, `/fork`, `/status`, `/permissions` (parser propio; `/compact` llega con [D](./plan-d-memoria-v3code.md#d1))
- Aprobar/rechazar acción pendiente con scopes "una vez" vs "toda la sesión" (Codex)
- **Pruebas:** E2E browser-mode con provider MOCK scriptado (sin key real): prompt→streaming→tool-call→aprobar→diff visible→slash fork duplica sesión

## 🚪 GATE A (demo verificable)

1. Conversación REAL con DeepSeek (key de prueba) con streaming carácter a carácter
2. Cambiar la perilla de aprobación cambia el comportamiento observado (mock pregunta o no)
3. `/fork` crea sesión hermana; historial sobrevive reinicio completo de la app
4. Evidencia: video + suites verdes (vitest/cargo/playwright)

---
[← Maestro](./README.md) · [PLAN B →](./plan-b-sidepanels-lovable.md)
