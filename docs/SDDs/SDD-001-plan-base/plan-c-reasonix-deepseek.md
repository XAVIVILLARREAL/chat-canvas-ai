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
- Fail-open: Reasonix no arranca → aviso claro + opción modo directo DeepSeekDirect
- **Pruebas:** chaos integration kill -9 → recuperación automática; estado consistente post-cancel

<a id="c5"></a>
### C.5 — Motor de Contexto y Caché configurable (SDD-006 §1)
- **Configurable en 5 scopes** ([A·A.6](./plan-a-chat-codex.md#a6)): Global → Proyecto → Equipo → Agente → Subagente, con vista de valor efectivo y origen ("definido en: Global")
- Knobs: `prefijo_estable` + warm-up al abrir proyecto · perfil cuantización KV (`fp16/fp8/int4/int2` + ventana residual 128) · eviction (`query-aware / sinks+recientes / H2O%`) · compresión tramo medio (`ninguna / ligera 2× / agresiva 5×`, reservar dígitos, umbral mínimo 2K tokens) · compacción (`aviso 70% / flush 100% / expulsar 50%`) · alerta si hash del system prompt cambia (caché inválida)
- **Presets por ROL**: PM (contexto amplio, compresión ligera) · QA (evidencia íntegra sin comprimir) · Dev (historial comprimido agresivo, código íntegro)
- Dashboard cache_hit + semáforo coste POR SCOPE; persistido en settings
- **Pruebas:** Unit hash/orden estable. Integration DeepSeek real: cache_hit>90% post warm-up; cambio de knob → aviso de caché fría. E2E humano: aplicar preset de rol en un click

<a id="c6"></a>
### C.6 — OllamaProvider local, ready-to-plug (SDD-006 §5)
- **Tercer driver** del trait ([A·A.3](./plan-a-chat-codex.md#a3)): reutiliza el cliente OpenAI-compatible (`/v1/chat/completions`) apuntando a `http://localhost:11434` — mismo EventBus, misma UI
- **Detección automática**: al abrir settings, ping a `/api/tags`; si está instalado muestra modelos disponibles y estados; si no, guía de instalación por OS (nativo o Docker `-e`) sin salir de la app
- **Knobs de hardware conectados a [C·C.5](./plan-c-reasonix-deepseek.md#c5)** (verificados en docs oficiales v0.32):
  - `OLLAMA_KV_CACHE_TYPE`: `f16 (default) / q8_0 (~½ memoria, pérdida imperceptible — recomendado) / q4_0 (~¼, trade-off mayor)` — ⚠️ es GLOBAL del servidor y hace fallback SILENCIOSO a f16 en arquitecturas no soportadas: la UI lo advierte y verifica por consumo real de memoria
  - Flash attention: hoy 3-estado automático; `=1` solo como forzado para debug
  - `OLLAMA_CONTEXT_LENGTH` global y `num_ctx` por request (API nativa); `keep_alive` para mantener modelo cargado entre tareas
- **Presets por hardware** (detecta VRAM/RAM): GPU grande (f16 + ctx largo) · Laptop (q8_0 + ctx medio) · CPU-only (modelos cuantizados chicos) — editables como cualquier scope de [A·A.6](./plan-a-chat-codex.md#a6)
- **Embeddings plug-and-play**: `/api/embeddings` alimenta automáticamente el índice semántico dual ([D·D.5](./plan-d-memoria-v3code.md#d5)) cuando Ollama está presente; sin él, FTS5 sigue funcionando igual
- Venta diferencial: privacidad total y modo offline — agentes trabajando sin internet ni coste por token
- **Pruebas:** Unit: detección/parsing de /api/tags y errores de conexión. Integration con Ollama real: chat streaming completo + embeddings generados; cambio de preset KV verificado por memoria consumida. E2E humano: conectar Ollama desde cero siguiendo la guía in-app

<a id="c7"></a>
### C.7 — Registro universal de proveedores API (patrón OpenCode/models.dev)
- Para quien use APIs de CUALQUIER empresa, sin escribir código nuevo: **registro declarativo de proveedores** — cada uno = `{id, tipo_api: openai-compat|anthropic|google, baseURL, api_key cifrada, modelos: {id: {nombre, contexto, max_output, precio_in/out por M tokens, capacidades: tools/reasoning/vision}}}`
- **Catálogo models.dev integrado** (open-source MIT, mismo equipo que OpenCode): consumimos su `api.json` público para autocompletar automáticamente precios/contexto/capacidades de 75+ proveedores y cientos de modelos; snapshot local cacheado → funciona offline; actualizable sin tocar la app
- Dos drivers genéricos cubren el mercado entero: `OpenAICompatProvider` (ya existe como DeepSeekDirect, ahora parametrizado por baseURL/key) + `AnthropicProvider` (API de mensajes propia) — cualquier proveedor nuevo = una entrada del registro, NO código
- **UI doble en [A·A.6](./plan-a-chat-codex.md#a6)→Proveedores**: tarjetas 1-click para no-programadores (pegas tu API key → los modelos se autodescubren del catálogo con precios reales) + modo experto JSON crudo validado; botón "probar conexión" con llamada mínima; estado por key (válida/cuota/error)
- Integración total con lo existente: router de costo ([C·C.6](./plan-c-reasonix-deepseek.md#c5)) usa precios REALES del registro; knobs de caché ([C·C.5](./plan-c-reasonix-deepseek.md#c5)) respetan capacidades del modelo (soporta caching/reasoning/vision); keys cifradas por scope ([A·A.0](./plan-a-chat-codex.md#a0): global o por proyecto)
- **Pruebas:** Unit: parser/validador del registro + merge catálogo-remoto vs local. Integration: 3 proveedores reales (deepseek + anthropic + uno openai-compat genérico) vía el MISMO trait; precios correctos en telemetría. E2E humano: no-programador agrega OpenRouter/OpenAI pegando solo su key y chatea <2 min

## 🚪 GATE C (demo verificable)

Tres sesiones desde la MISMA UI: chat directo (barato), tarea flash con tools, planificación reasoner. Costo acumulado visible y correcto contra métricas reales. Cancelar una tarea a mitad funciona y deja estado consistente. Matar el proceso serve → la app se recupera sola.

Evidencia: video + suites verdes.

---
[← Maestro](./README.md) · [← PLAN B](./plan-b-sidepanels-lovable.md) · [PLAN D →](./plan-d-memoria-v3code.md)
