# PLAN A — Chat con Sesiones (A.0–A.9, alineado a MATRIZ + ADR-006)

> [← Maestro](./README.md) · [PLAN B →](./plan-b-sidepanels-lovable.md)
> Referencia primaria: Hermes Agent (session persistence, BYOK, subagent delegation) · Referencia secundaria: GrokBot (session sidebar)
> **Alineado con ADR-006**: local-first (SQLite) + nube multi-tenant (Postgres+RLS); "proyectos" = scope de datos (`project_id` en toda tabla); BYOK (trae tu API key).
> **Numeración A.0-A.9 = fuente de verdad de la MATRIZ.**

**Entregable:** Chat funcional con sesiones persistentes, sidebar, streaming, costo visible y BYOK con múltiples proveedores.

---

### A.0 — Proyectos como scope (FUNDACIÓN)
- Proyecto = unidad de aislamiento de datos (workspace). `project_id` en TODA tabla ([SCHEMA-MAESTRO](../../SCHEMA-MAESTRO.md)).
- En local = carpeta/workspace; en nube = tenant con RLS fail-closed.
- Scopes de configuración: Global → Proyecto → Sesión → Agente.
- **Pruebas:** unit: repos filtran por project_id, override local no muta global; integration: cross-proyecto vacío, tabs restauran tras reinicio; E2E: 2 proyectos alternando tabs, skill global vs copia local; HUMANA @core: cambiar de proyecto, nada se mezcla.

### A.1 — AppShell + stores
- Shell de la app: header, sidebar (sesiones), panel chat, memory rail placeholders. Zustand + immer + React Query.
- **Pruebas:** Vitest stores+hook. E2E: layout móvil 375 (BottomNav) y desktop 1440 (sidebar).

### A.2 — Persistencia SQLite (settings cifradas)
- Repos sqlx sobre [SCHEMA-MAESTRO](../../SCHEMA-MAESTRO.md): `sessions`, `messages`, `settings`, `event_stream`.
- Settings sensibles cifradas (envelope local: keychain → SQLite cifrado AES-GCM, patrón [T.SEC](./plan-t-excelencia.md#tsec)).
- **Pruebas:** Cargo test repos; integration roundtrip mensaje con project_id.

### A.3 — Trait AgentProvider + BYOK + DeepSeekDirect
- `trait AgentProvider` (Rust): `send_message`, `cancel`, `name`, `capabilities` ([PRD](./PRD.md) F2).
- **Registro universal de proveedores (BYOK)**: OpenAI/Anthropic/OpenRouter/DeepSeek/Ollama via key+URL; key en keychain (local) / vault cifrado (nube) — jamás al webview ([THREAT-MODEL](../../THREAT-MODEL.md)).
- DeepSeekDirectProvider (HTTP+SSE), OllamaProvider (local/offline), ReasonixProvider (spawn+SSE) en C.
- Router: chat simple → directo; tool-calls → reasonix; razonamiento → reasoner.
- **Pruebas:** unit con mock-server SSE; integration orden de chunks.

### A.4 — UX del chat (perillas, tool-calls, diff, slash)
- Streaming SSE/WS, markdown vivo, tool-calls renderizados, diffs aprobables por hunks, slash (`/compact`, `/agent`, `/skill`, `/run`, `/help`), costo por mensaje.
- **Pruebas:** E2E browser con provider mock: prompt→streaming→tool-call→aprobar→diff→/fork duplica. HUMANA: cambiar perilla cambia comportamiento observado.

### A.5 — Medidor y debug de contexto
- Desglose de tokens por fuente (historial, system, knowledge, tools, archivos) en vivo; ajustar límite → siguiente request lo refleja.
- **Pruebas:** unit desglose con fixtures; integration request capturado = lo que muestra el medidor; E2E HUMANA: abrir medidor en sesión real, ajustar límite.

### A.6 — Centro de Configuración (2 públicos, 5 scopes)
- Público no-programador: ajustes con clicks. Público programador: JSON validado.
- Scopes: Global→Proyecto→Sesión→Agente→Subagente con vista de valor efectivo y origen.
- **Pruebas:** unit store + herencia; E2E HUMANA: no-programador cambia ajuste con clicks; programador edita JSON; override por proyecto visible.

### A.7 — Modo ENCARGO (v1)
- "Haz X" sin escribir prompt: tarea mínima con criterios; el agente la completa; notificación de vuelta con evidencia ([PRD](./PRD.md) F6). Formalizado en H.1.
- **Pruebas:** E2E HUMANA: crear encargo sin escribir prompt; agente mock lo completa; notificación con evidencia.

### A.8 — Resume inteligente (v1)
- Reanudar sesión interrumpida: card de resumen de dónde se quedó; `/compact` comprime historial viejo.
- **Pruebas:** integration sesión interrumpida → resume card correcta; E2E HUMANA: cerrar a mitad → reabrir → continuar fluido.

### A.9 — Ramas visuales al editar
- Editar un mensaje → rama; flechas ‹/› navegan alternativas sin perder ninguna.
- **Pruebas:** unit tree-store; E2E HUMANA: edito mensaje 2× → flechas navegan alternativas.

---

### Transversal (desde A.2)
- **Backup integral**: export/import de TODO el workspace en `.canvas-ai-backup` firmado ([SCHEMA-MAESTRO](../../SCHEMA-MAESTRO.md)) — "no pierdes nada".
- **Circuit breaker por proveedor**: key inválida/429/timeout/5xx → fallback controlado sin tumbar el chat ([C·C.3](./plan-c-reasonix-deepseek.md)).
- **i18n multilenguaje** desde el primer componente ([plan-i18n](./plan-i18n.md)).
- **Eventos de producto** emitidos al `event_stream` desde v0 ([PRODUCT-METRICS](../../PRODUCT-METRICS.md)).

## 🚪 GATE A (demo verificable)

Abro Canvas AI → creo proyecto → escribo "hola" → streaming → el mensaje aparece en el memory rail → medidor muestra el desglose → cierro y reabro → la sesión persiste → veo el costo acumulado → cambio de proyecto → vuelvo → todo intacto. Slash commands funcionan. Backup exportado e importado sin pérdida. Suite humana verde (móvil+desktop, es+en).
