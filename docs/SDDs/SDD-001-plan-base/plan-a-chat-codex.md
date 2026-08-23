# PLAN A — Chat núcleo Codex

> [← Maestro](./README.md) · Siguiente: [PLAN B →](./plan-b-sidepanels-lovable.md)
> Base de todos los demás planes. Copia los patrones de interacción de OpenAI Codex.

**Entregable:** abres la app, chateas con streaming, controlas permisos con 2 perillas, el historial persiste, slash commands funcionan.

## Fases

<a id="a0"></a>
### A.0 — Proyectos como TENANTS: cards + tabs + historial aislado (FUNDACIÓN, va sobre todo lo demás)
- **Modelo**: tabla `projects`; TODAS las demás tablas (sessions, messages, event_stream, knowledge, tasks, settings-overrides) llevan `project_id` — aislamiento total estilo multitenant, pero por proyecto de software
- **Cards de selección**: al abrir la app, grid de tarjetas simples (avatar/color generado, nombre, última actividad, agentes activos) — seleccionar y entrar. Crear/renombrar/archivar proyecto desde ahí
- **Tabs de proyectos**: barra superior con los proyectos ABIERTOS como tabs (estilo navegador) — cambiar entre ellos sin cerrar nada; cada tab conserva su chat/sesión activa; las tabs se restauran tras reiniciar
- **Historial 100% aislado**: las conversaciones de un proyecto JAMÁS se mezclan con otro; buscar/fork/export opera dentro del proyecto actual
- **Tareas en background entre tabs**: cambiar de tab NO detiene al agente del otro proyecto — sigue trabajando (badge de actividad en su tab)
- **Configuraciones por proyecto persistidas**: modelo preferido, permisos default, apariencia del workspace — cada tenant recuerda lo suyo ([A·A.6](./plan-a-chat-codex.md#a6) herencia global→proyecto)
- **Global vs Local decidido por el usuario** para MCP ([PLAN P](./plan-p-centro-mcp.md)), skills ([G](./plan-g-skills-lab.md)) y agentes: biblioteca GLOBAL compartida O "hacer copia local" editable sin afectar a otros proyectos — toggle explícito por elemento
- **Pruebas:**
  - Unit: repos filtran por project_id en TODAS las consultas; resolución de scopes global→local
  - Integration: proyecto A no ve NADA de B (queries cross-tenant vacías); override local no muta el global; restauración de tabs tras reinicio
  - E2E funcional: crear 2 proyectos → alternar tabs → historiales separados → skill global usada en ambos → copia local editada solo afecta a uno
  - Suite HUMANA @core: entro por card, cambio de tab como usuario real, veo que nada se mezcló

<a id="a1"></a>
### A.1 — AppShell + stores
- Layout 3 paneles responsive según ADR-001: Sidebar proyectos / ChatPanel / WorkArea placeholder
- Stores Zustand: `session-store` (sesión activa, mensajes), `ui-store` (paneles, perillas)
- `useResponsive` wired a AppShell
- **Pruebas:** Vitest stores+hook. E2E: layout mobile 375px (BottomNav) y desktop 1440px (sidebar)

<a id="a2"></a>
### A.2 — Persistencia SQLite
- Tablas `sessions`, `messages` via sqlx (migraciones embebidas) — **ambas con `project_id` desde el día 1** ([A·A.0](./plan-a-chat-codex.md#a0)): el aislamiento multitenant NO se retrofittea después
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
- **Streaming vía Command async + `Channel<TokenEvent>`** con batch ~30ms en Rust (patrón [PLAN S·S3](./plan-s-despliegue-costos.md)): el stream vive en reqwest/Rust y sobrevive al background del webview (iOS pausa fetch-SSE en JS)
- Visor de diff unificado inline en el chat
- Panel terminal colapsable (salida de comandos del agente)
- **Slash commands**: `/resume` (dentro del proyecto actual), `/fork`, `/status`, `/permissions` (parser propio; `/compact` llega con [D](./plan-d-memoria-v3code.md#d1))
- Aprobar/rechazar acción pendiente con scopes "una vez" vs "toda la sesión" (Codex)
- **Pruebas:** E2E browser-mode con provider MOCK scriptado (sin key real): prompt→streaming→tool-call→aprobar→diff visible→slash fork duplica sesión

<a id="a6"></a>
### A.6 — Centro de Configuración (flexible para todos los públicos)
- Hub unificado accesible desde sidebar, con **búsqueda de ajustes** y dos modos de presentación: **tarjetas en lenguaje claro** (no-programadores: toggles, descripciones humanas, presets) y **modo crudo** (programadores: JSON editable con validación)
- Categorías: Cuenta · Apariencia · Modelos y proveedores · Permisos/Sandbox por defecto · Notificaciones · Voz · Sync · Presupuestos · Privacidad/Datos · Atajos · MCP ([PLAN P](./plan-p-centro-mcp.md)) · Avanzado
- **Jerarquía completa de 5 scopes**: Global → Proyecto → Equipo/Empresa → Agente → Subagente, con herencia y override visible en cada campo: badge "heredado de: Global" / "modificado aquí" (patrón VS Code "Modified in"), tooltip con la cadena completa de overrides, reset que elimina SOLO la capa actual, merge declarado POR TIPO (escalares reemplazan · arrays se fusionan · políticas 🔒 enforced arriba que abajo no tocan — patrón Cursor Team Rules/Claude managed), validación que marca claves "no configurables en este nivel" (patrón Codex), y **vista de VALOR EFECTIVO** con origen (patrón git --show-origin) + diff renderizado antes/después del override
- Aplica a TODO lo configurable: contexto/caché ([C·C.5](./plan-c-reasonix-deepseek.md#c5)), memorias ([D·D.8](./plan-d-memoria-v3code.md#d8)), respaldos ([H·H.9](./plan-h-motor-pruebas.md#h9)), skills/MCP global-vs-local, permisos, voz, presupuestos
- Alcance GLOBAL vs POR-PROYECTO con herencia y override visible ("este proyecto sobreescribe X")
- Import/export de configuración portable · Modo seguro (arranca sin terceros) · Reset por categoría con confirmación · Todo cambio auditado en el Ledger
- **Pruebas:** Unit store settings + herencia global/proyecto. E2E humano: no-programador cambia un ajuste solo con clicks; programador edita JSON crudo validado; override por proyecto visible

<a id="a7"></a>
### A.7 — Modo ENCARGO: dar trabajo, no prompts (patrón Grok Bot)
- Alternativa al prompt libre: botón "Nuevo encargo" con campos en lenguaje humano — **qué resultado esperas** (criterios), **cuándo** (al terminar / fecha), **autonomía** (me consultas siempre / solo lo peligroso / todo tuyo)
- El encargo se convierte internamente en tarea con criterios ([H·H.1](./plan-h-motor-pruebas.md#h1)) — el agente trabaja y "vuelve cuando está listo o necesita juicio"
- Menos como promptear, más como delegar a un compañero
- **Pruebas:** E2E humano: crear encargo sin escribir un prompt; agente mock lo completa; notificación de vuelta con evidencia

<a id="a8"></a>
### A.8 — Resume inteligente al abrir (patrón Grok Bot)
- Al abrir la app: tarjeta contextual por sesión activa — "ayer quedaste en X, el agente dejó Y pendiente, ¿continúo?"
- Reconstruye contexto desde rungs del Ledger ([D·D.1](./plan-d-memoria-v3code.md#d1)) y ofrece continuar/ignorar/descartar con un click
- **Pruebas:** Integration: sesión interrumpida → resume card correcta. E2E humano: cerrar a mitad de tarea → reabrir → continuar fluido

<a id="a9"></a>
### A.9 — Ramas visuales al editar mensajes (patrón ChatGPT)
- Al editar un mensaje ([A·A.7](./plan-a-chat-codex.md#a7) fork): navegadores ‹2/3› sobre el mensaje para moverse entre ramas de la conversación
- Indicador de rama activa en el header + acceso a "otras ramas" con su resultado final comparado
- **Pruebas:** Unit tree-store. E2E humano: edito mensaje 2 veces → flechas ‹› navegan alternativas sin perder ninguna

## 🚪 GATE A (demo verificable)

1. Conversación REAL con DeepSeek (key de prueba) con streaming carácter a carácter
2. Cambiar la perilla de aprobación cambia el comportamiento observado (mock pregunta o no)
3. `/fork` crea sesión hermana; historial sobrevive reinicio completo de la app
4. Evidencia: video + suites verdes (vitest/cargo/playwright)

---
[← Maestro](./README.md) · [PLAN B →](./plan-b-sidepanels-lovable.md)
