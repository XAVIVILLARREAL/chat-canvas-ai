# PLAN C — Runtime Reasonix optimizado a DeepSeek

> [← Maestro](./README.md) · [← PLAN B](./plan-b-sidepanels-lovable.md) · [PLAN D →](./plan-d-memoria-v3code.md)
> Depende de: [PLAN A](./plan-a-chat-codex.md) (trait AgentProvider). Paralelizable con PLAN B.
> **Spike C.0 ya ejecutado 2026-08-22 en este servidor** — hallazgos abajo.

**Entregable:** el mismo chat corre sobre agentes Reasonix reales; costos medidos por sesión; cancelable; con enrutamiento inteligente que evita quemar tokens.

## Datos verificados (spike real, no supuestos)

| Hallazgo | Dato |
|---|---|
| Transporte interactivo | `reasonix serve --addr 127.0.0.1:8787 --auth token` (HTTP+SSE, Web UI incluida, balance visible) |
| Taxonomía de eventos capturada | `turn_started, stream_attempt, reasoning, text, message, tool_dispatch, tool_result, usage, notice, run_done` |
| Redacción | `--events-jsonl` viene REDACTADO (tool_name_1); fidelidad total solo `--trajectory` o vía serve |
| Métricas | `--metrics path` → JSON: `cost=$0.0043/run trivial`, prompt/completion tokens, `cache_hit_tokens`, steps, tool_calls, duration_ms, outcome |
| ⚠️ Overhead base | **~31k tokens inyectados por run** (contexto AGENTS.md+entorno) aunque la pregunta sea trivial |
| Modos permiso nativos | `manual\|ask\|auto\|acceptEdits\|dontAsk\|plan\|bypassPermissions` |
| Perfiles | `economy\|balanced\|delivery` + `--effort` + `--model` |
| Control de tareas | `task stop/cancel/monitor --json`; sesiones `--json` |

## Fases

<a id="c0"></a>
### C.0 — Residual del spike (medio día)
- Capturar muestra SSE real de `serve --auth token` (contrato de stream vs events-jsonl)
- Guardar fixtures JSONL/SSE en `src-tauri/tests/fixtures/reasonix/`
- **Pruebas:** fixtures versionados; script humo curl documentado

<a id="c1"></a>
### C.1 — ReasonixProvider
- Ciclo de vida del proceso serve: spawn (puerto libre, token efímero), health check, stop graceful + kill fallback
- Mapeo eventos→modelo interno unificado del trait ([A·A.3](./plan-a-chat-codex.md#a3)) — misma UI para ambos motores
- Para batch/headless: `run --trajectory` (fidelidad completa) como transporte alterno
- **Traducción de perillas** ([A·A.4](./plan-a-chat-codex.md#a4)) → flags `--permission-mode`
- **Pruebas:** Cargo test parser con fixtures reales de C.0

<a id="c2"></a>
### C.2 — Enrutamiento por costo + telemetría (el diferenciador)
- **Router** (patrón model-router V3Code):
  - Chat simple sin tools → `DeepSeekDirect` ([A·A.3](./plan-a-chat-codex.md#a3)) — sin overhead 31k
  - Tarea con tool-calls → Reasonix `deepseek-v4-flash` (perfil economy/balanced)
  - Planificación/tarea dura → `deepseek-reasoner` (`--model`); auto-escale flash→reasoner en doble fallo
- Perfiles economy/balanced/delivery expuestos en UI (mapea a `--profile`)
- Widget costo sesión vía `--metrics` — **por proyecto y con rollup global** ([A·A.0](./plan-a-chat-codex.md#a0)): "¿cuánto me cuesta ESTE proyecto?" es una pregunta de primer nivel (costo acumulado + tokens + cache hits)
- Indicador AGENTS.md cargado (Reasonix lo lee nativo — solo exponer qué archivos)
- **Pruebas:** unit router + cálculo costos. E2E: badge costo sube durante sesión real barata

<a id="c3"></a>
### C.3 — Robustez
- Reconexión si muere serve; cancelación en curso (`task stop`); timeouts por fase
- **Circuit breaker por proveedor (desde el día 1)**: key inválida, 429/rate-limit, timeout, 5xx → degradación controlada (fallback a otro provider del registro o modo local Ollama) sin tumbar el chat; estados `open/half-open/closed` con backoff; error accionable al usuario, la sesión nunca se pierde ([PRD](./PRD.md) F2)
- Fail-open: Reasonix no arranca → aviso claro + opción modo directo DeepSeekDirect
- **Sandbox dev (v3.8)**: docker socket del host montado SOLO en el worker (`crates/worker`), jamás en el gateway; red denegada por defecto ([H·H.9a](./plan-h-motor-pruebas.md#h9a))
- **Pruebas:** chaos integration kill -9 → recuperación automática; estado consistente post-cancel. Chaos: provider devuelve basura/429 → circuit breaker aísla y el chat sigue con fallback

<a id="c5"></a>
> **C.4 (reservada)**: el hueco es intencional — el "contexto/caché" que ocuparía se integró en C.5 (SDD-006 §1) y el registro de proveedores en C.7 (SDD-007). Los IDs de fase son estables y no se reutilizan.

### C.5 — Motor de Contexto y Caché configurable (SDD-006 §1)
- **Configurable en 5 scopes** ([A·A.6](./plan-a-chat-codex.md#a6)): Global → Proyecto → Equipo → Agente → Subagente, con vista de valor efectivo y origen ("definido en: Global")
- Knobs: `prefijo_estable` + warm-up al abrir proyecto · perfil cuantización KV (`fp16/fp8/int4/int2` + ventana residual 128) · eviction (`query-aware / sinks+recientes / H2O%`) · compresión tramo medio (`ninguna / ligera 2× / agresiva 5×`, reservar dígitos, umbral mínimo 2K tokens) · compacción (`aviso 70% / flush 100% / expulsar 50%`) · alerta si hash del system prompt cambia (caché inválida)
- **Presets por ROL**: PM (contexto amplio, compresión ligera) · QA (evidencia íntegra sin comprimir) · Dev (historial comprimido agresivo, código íntegro)
- Dashboard cache_hit + semáforo coste POR SCOPE; persistido en settings
- **Pruebas:** Unit hash/orden estable. Integration DeepSeek real: cache_hit>90% post warm-up; cambio de knob → aviso de caché fría. E2E humano: aplicar preset de rol en un click

<a id="c6"></a>
### C.6 — OllamaProvider local, ready-to-plug (SDD-006 §5)
- **Tercer driver** del trait ([A·A.3](./plan-a-chat-codex.md#a3)): reutiliza el cliente OpenAI-compatible (`/v1/chat/completions`) apuntando a `http://localhost:11434` en el SERVIDOR donde corre el sistema (self-host) o en la máquina del usuario en modo todo-local — mismo EventBus, misma UI
- **Detección automática**: al abrir settings, ping a `/api/tags`; si está instalado muestra modelos disponibles y estados; si no, guía de instalación por OS (nativo o Docker `-e`) sin salir de la app
- **Knobs de hardware conectados a [C·C.5](./plan-c-reasonix-deepseek.md#c5)** (verificados en docs oficiales v0.32):
  - `OLLAMA_KV_CACHE_TYPE`: `f16 (default) / q8_0 (~½ memoria, pérdida imperceptible — recomendado) / q4_0 (~¼, trade-off mayor)` — ⚠️ es GLOBAL del servidor y hace fallback SILENCIOSO a f16 en arquitecturas no soportadas: la UI lo advierte y verifica por consumo real de memoria
  - Flash attention: hoy 3-estado automático; `=1` solo como forzado para debug
  - `OLLAMA_CONTEXT_LENGTH` global y `num_ctx` por request (API nativa); `keep_alive` para mantener modelo cargado entre tareas
- **Presets por hardware** (detecta VRAM/RAM): GPU grande (f16 + ctx largo) · Laptop (q8_0 + ctx medio) · CPU-only (modelos cuantizados chicos) — editables como cualquier scope de [A·A.6](./plan-a-chat-codex.md#a6)
- **Embeddings plug-and-play**: `/api/embeddings` alimenta automáticamente el índice semántico dual ([D·D.5](./plan-d-memoria-v3code.md#d5)) cuando Ollama está presente; sin él, FTS5 sigue funcionando igual
- Venta diferencial: privacidad total y modo offline — agentes trabajando sin internet ni coste por token
- **Client-first**: en modo todo-local el modelo corre en la MÁQUINA DEL USUARIO (no en el servidor) — el servidor no paga CPU ni tokens por esos usuarios, solo sirve datos; escala con usuarios locales sin coste marginal
- **Pruebas:** Unit: detección/parsing de /api/tags y errores de conexión. Integration con Ollama real: chat streaming completo + embeddings generados; cambio de preset KV verificado por memoria consumida. E2E humano: conectar Ollama desde cero siguiendo la guía in-app

<a id="c7"></a>
### C.7 — Registro universal de proveedores API (análisis exhaustivo OpenCode/models.dev → [SDD-007](../SDD-007-analisis-opencode-modelsdev.md))

Para quien use APIs de cualquier empresa: **75+ proveedores sin escribir código**, copiando el sistema verificado de OpenCode.

- **Alcance por etapas (anti sobre-complicación)**: **v1 en Etapa 3** = a) registro declarativo + drivers genéricos `OpenAICompatProvider`/`AnthropicProvider` + catálogo models.dev con precios + blacklist/whitelist + picker con datos visibles (cubre DeepSeek/OpenRouter/Anthropic/Azure). **Post-base (C.7b)** = b) OAuth a suscripciones + d) `small_model` + lista verificada curada + actualización de catálogo sin tocar la app.

**a) Registro declarativo + catálogo models.dev**
- Esquema del registro por proveedor: `{id, tipo_api: openai-compat|anthropic|google, nombre, options{baseURL, headers}, auth{modo}, modelos{id:{nombre, contexto, max_output, precio_in/out, capacidades}}, blacklist/whitelist}`
- Catálogo **models.dev** (MIT, mismo equipo OpenCode) autocompleta precios/contexto/capacidades; snapshot cacheado offline + actualización sin tocar la app
- Drivers genéricos `OpenAICompatProvider` + `AnthropicProvider` cubren todo el mercado (DeepSeekDirect queda como caso particular)

**b) Flujo /connect unificado + OAuth a suscripciones**
- Comando "Conectar" con dos vías: pegar API key (guardada cifrada, separada del config — patrón auth.json) o **OAuth a suscripciones que el usuario ya paga**: ChatGPT Plus/Pro, GitHub Copilot device-flow, Claude Pro/Max donde el ToS lo permita
- baseURL override → Azure/proxies/gateways sin código; `options.headers` passthrough para gateways tipo Helicone/Cloudflare

**c) Selector /models con datos visibles + blacklist/whitelist**
- Picker de modelos mostrando precio in/out por M y tamaño de contexto (del catálogo) antes de elegir
- blacklist/whitelist por proveedor como scope [A·A.6](./plan-a-chat-codex.md#a6); estado por key (válida/cuota/error) con botón probar-conexión

**d) small_model + lista verificada**
- `small_model` separado para tareas internas baratas (títulos de sesión, resúmenes chicos, rung-resúmenes) — conecta al router [C·C.2](./plan-c-reasonix-deepseek.md#c2)
- Lista "Modelos verificados Canvas AI" curada por nosotros (patrón Zen) + guía proveedor-por-proveedor de obtención de key (alimenta plantillas [P·P.4](./plan-p-centro-mcp.md#p4))

- **Pruebas (matriz completa):**
  - Unit: parser/validador del registro · merge catálogo remoto↔local · blacklist/whitelist filter · small_model routing
  - Integration: 3 proveedores REALES vía el mismo trait (deepseek API-key + uno openai-compat genérico baseURL custom + anthropic si hay key) con streaming y precios correctos en telemetría · OAuth device-flow mockeado
  - E2E funcional: agregar proveedor desde JSON experto; selector muestra precio/contexto; small_model usado en tarea interna (verificado en request capturado)
  - Suite HUMANA @core-ampliada: no-programador conecta OpenRouter pegando solo su key y chatea <2 min · elige modelo viendo el precio · esconde modelos con whitelist
**⚠️ Condiciones NO negociables del runtime Reasonix (debate SDD-009):**
1. Cada sesión de agente corre dentro de **contenedor efímero** ([H·H.9a](./plan-h-motor-pruebas.md#h9a) — aislamiento mínimo que se ejecuta INMEDIATAMENTE tras esta fase C.3, antes de ninguna otra etapa) — el sandbox de Reasonix NO es kernel-level y toda la categoría (SymJack 2026) ha sido comprometida
2. Versión PINNEADA + job de CI que pruebe upgrades antes de adoptarlos (reescritura TS→Go en vuelo upstream)
3. Transcripts JSONL persistidos desde el día 1 ([D·D.1](./plan-d-memoria-v3code.md#d1)) — dataset de migración + auditoría
4. **Disparadores de migración a OwnLoopProvider** (base OSS mini-swe-agent/OpenHands SDK): volumen tokens justifique 1 FTE en loop · UX que sidecars no cubran · primer incidente no contenido · señal de churn (breaking/paid-tier)

## 🚪 GATE C (demo verificable)

Tres sesiones desde la MISMA UI: chat directo (barato), tarea flash con tools, planificación reasoner. Costo acumulado visible y correcto contra métricas reales. Cancelar una tarea a mitad funciona y deja estado consistente. Matar el proceso serve → la app se recupera sola.

Evidencia: video + suites verdes.

---
[← Maestro](./README.md) · [← PLAN B](./plan-b-sidepanels-lovable.md) · [PLAN D →](./plan-d-memoria-v3code.md)
