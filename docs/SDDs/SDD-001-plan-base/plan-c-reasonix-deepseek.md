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

## 🚪 GATE C (demo verificable)

Tres sesiones desde la MISMA UI: chat directo (barato), tarea flash con tools, planificación reasoner. Costo acumulado visible y correcto contra métricas reales. Cancelar una tarea a mitad funciona y deja estado consistente. Matar el proceso serve → la app se recupera sola.

Evidencia: video + suites verdes.

---
[← Maestro](./README.md) · [← PLAN B](./plan-b-sidepanels-lovable.md) · [PLAN D →](./plan-d-memoria-v3code.md)
