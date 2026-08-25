# PLAN A — Chat con Sesiones

> [← Maestro](./README.md) · [PLAN B →](./plan-b-sidepanels-lovable.md)
> Referencia primaria: Hermes Agent (session persistence, subagent delegation, executive functions)
> Referencia secundaria: GrokBot (session sidebar, chief of staff, proactive behavior)

**Entregable:** Chat funcional con sesiones persistentes, sidebar de navegación, streaming de respuestas, y conexión con múltiples proveedores de IA.

---

## Qué construimos

Un chat que no es solo un input + output. Es un **entorno de trabajo** donde:
- Cada conversación es una **sesión** persistente (se reanuda, se busca, se organiza)
- El usuario puede invocar **agentes** específicos dentro de una sesión
- Las respuestas se renderizan con **markdown vivo**, código con syntax highlight, y previews de apps
- El **costo** de cada interacción es visible en tiempo real
- La **memoria** de sesiones anteriores alimenta las nuevas

---

## Fases

### A.1 — Modelo de datos de sesiones

Tabla `sessions` en SQLite:
```
id, title, created_at, updated_at, project_id, 
agent_config (JSON), status (active/archived/deleted),
total_tokens, total_cost_usd, metadata (JSON)
```

Tabla `messages`:
```
id, session_id, role (user/assistant/system/tool), 
content, model, tokens_prompt, tokens_completion,
cost_usd, timestamp, metadata (JSON)
```

Store Zustand `useSessionStore`:
- `sessions: Session[]` — lista de sesiones
- `activeSessionId: string | null`
- `messages: Map<string, Message[]>` — mensajes por sesión
- CRUD completo con optimistic updates via React Query

**Pruebas:** Cargo test schema + CRUD. E2E: crear sesión, enviar mensaje, verificar persistencia.

---

### A.2 — Sidebar de sesiones

Componente `SessionSidebar` (panel izquierdo):
- Lista cronológica de sesiones (más recientes arriba)
- Búsqueda por título/contenido (FTS5)
- Filtros: activas / archivadas / todas
- Carpetas/etiquetas para organizar
- Acciones: renombrar, archivar, eliminar, duplicar
- Indicador de sesión activa (highlight + badge de costo)
- Botón "Nueva sesión" prominente

**Diseño:** Obsidian Glass theme (bg-slate-900/80, backdrop-blur-xl, border-white/10)

**Pruebas:** E2E: crear 3 sesiones, buscar, filtrar, archivar, eliminar.

---

### A.3 — Panel de chat

Componente `ChatPanel` (panel derecho):
- **Mensajes**: markdown renderizado (react-markdown + rehype-highlight)
- **Código**: syntax highlight con Prism/Shiki, botón copiar, bloques expandibles
- **Streaming**: SSE o WebSocket, tokens aparecen en tiempo real
- **Input**: textarea con auto-resize, slash commands, adjuntos de archivos
- **Tool calls**: renderizado especial (mostrar tool name, args, resultado colapsable)
- **Costo visible**: badge en cada mensaje con tokens + USD

Slash commands:
- `/compact` — comprimir historial viejo a resumen
- `/agent <nombre>` — cambiar de agente
- `/skill <nombre>` — invocar un skill
- `/run <comando>` — ejecutar comando en sandbox
- `/help` — listar comandos disponibles

**Pruebas:** E2E: enviar mensaje, verificar streaming, probar slash commands.

---

### A.4 — Trait AgentProvider (Rust)

```rust
#[async_trait]
pub trait AgentProvider: Send + Sync {
    async fn send_message(&self, msg: &str, ctx: &SessionContext) -> AgentStream;
    async fn cancel(&self, request_id: &str) -> Result<()>;
    fn name(&self) -> &str;
    fn capabilities(&self) -> ProviderCapabilities;
}
```

Implementaciones:
- **ReasonixProvider**: spawn `reasonix serve`, SSE streaming, health check, graceful stop
- **DeepSeekDirectProvider**: HTTP directo a DeepSeek API, streaming SSE
- **OllamaProvider**: local, para modelos embebidos

Router inteligente:
- Chat simple sin tools → DeepSeekDirect (sin overhead de 31k tokens de Reasonix)
- Tarea con tool-calls → Reasonix (perfiles economy/balanced)
- Planificación dura → deepseek-reasoner

**Pruebas:** Cargo test trait + implementaciones mock. Integration: chat real con DeepSeek.

---

### A.5 — Memory Rail

Franja vertical junto al chat:
- Muestra rungs de la sesión (eventos tipados: PROMPT, DIFF, DECISION, TEST_RESULT)
- Icono por tipo de rung
- Click en rung → filtra el chat a ese momento
- Scrubber: arrastrar para navegar la sesión
- Coloreado por sesión (paleta consistente)

**Pruebas:** E2E: sesión con múltiples rungs, navegación por memory rail.

---

### A.6 — Persistencia y reanudación

- Todas las sesiones se guardan en SQLite al momento
- Al reanudar sesión: cargar historial completo, reconstruir contexto
- `/compact` genera un resumen LLM del historial viejo y lo guarda como system message
- Export: sesión → JSONL compatible con formato Codex
- Import: JSONL → sesión reconstruida

**Pruebas:** Cargo test serialización/deserialización. E2E: crear sesión, cerrar app, reanudar.

---

### A.7 — Widget de costo

Badge flotante en el chat:
- Tokens totales de la sesión (prompt + completion)
- Costo acumulado en USD
- Cache hits (si aplica)
- Costo por mensaje (hover)
- historial de costos por sesión (gráfico simple)

**Pruebas:** Unit: cálculo de costos. E2E: verificar que el badge actualiza con cada mensaje.

---

## 🚪 GATE A (demo verificable)

Abro Canvas AI → creo nueva sesión → escribo "hola" → recibo respuesta con streaming → el mensaje aparece en la memory rail → cierro y reabro → la sesión persiste → veo el costo acumulado → cambio a otra sesión → vuelvo → todo intacto. Slash commands funcionan. Suite humana verde.

---

[← Maestro](./README.md) · [PLAN B →](./plan-b-sidepanels-lovable.md)
