# PRODUCT-METRICS — North-star, activación, retención y telemetría

> **Producto:** Canvas AI · **Estado:** v1.0 · 2026-08-25
> Base: [PRD](./PRD.md) §4 · Complementa [T.BIZ](./SDDs/SDD-001-plan-base/plan-t-excelencia.md#tbiz)

---

## 1 · Jerarquía de métricas

### North-star (1)
> **Sesiones que terminan en ENTREGA** — una sesión termina en "entrega" cuando el humano **acepta evidencia de resultado** (diff aprobado, tests verdes, artefacto creado, PR abierto). NUNCA "tiempo en app".

| Métrica | Definición | Por qué |
|---|---|---|
| **Activación** | % de usuarios nuevos cuyo primer agente completa una tarea E2E en la sesión 1 | Predice retención a 7d |
| **Retención D7** | % de usuarios con ≥1 sesión reanudada en los días 2-7 tras la primera | Es la curva que manda para un tool |
| **Entrega/sesión** | nº de entregas aceptadas por sesión activa | Confirma el valor (north-star) |
| **Costo por entrega** | $ LLM gastado ÷ entregas aceptadas | Balancea valor vs margen (SDD-010) |

### Secundarias (para diagnóstico, no para celebrar)
- Sesiones activas/día · skills creados/uso por skill · agentes más invocados · tasa de error de proveedores · % sesiones con `/compact` (señal de contexto) · cuota de mercado del editor.

---

## 2 · Eventos instrumentados (desde v0 — contrato `event_stream`)

Todos los eventos de producto se emiten al **mismo `event_stream`** del [schema maestro](./SCHEMA-MAESTRO.md) (append-only, con `event_type`, `session_id`, `metadata`). Telemetría = proyección sobre ese stream.

| Evento | Campos clave | Dispara |
|---|---|---|
| `session.created` | session_id, mode (local/nube) | AB test / retención |
| `agent.invoked` | session_id, agent_id, model_tier | costo, uso |
| `message.streamed` | session_id, tokens, cost_usd, provider | badge, telemetría |
| `task.created` / `task.completed` | session_id, criterios, result | entregas |
| `delivery.accepted` | session_id, artifact_type, diff_stats | **north-star** |
| `skill.created` | skill_id, dialecto | activation de skills |
| `skill.ran` | skill_id, pass/fail, cost | skill value |
| `provider.error` | provider, error_type, retries | circuit breaker, salud |
| `nube.subscribed` | tenant_id, tier | negocio |
| `session.exported` | scope export | backup/retención |

## 3 · Telemetría

- **Opt-in ANÓNIMA por defecto off.** Nunca contenido, contexto, prompts ni diffs — solo IDs anónimos y contadores.
- **Local-first:** se recopila en el dispositivo (SQLite local `product_events`); el usuario decide si la exporta (pantalla "Compartir estadísticas anónimas" en Config).
- **Nube:** el tenant puede activarla/desactivarla; el servidor agrega sin PII.
- **Dashboard de producto:** contadores agregados (sin IDs) → sirve a T.BIZ y al roadmap.
- **Regla anti-dark-pattern:** jamás inflar métricas ni comparar usuarios en público (ver [plan-u](./SDDs/SDD-001-plan-base/plan-u-motivacion.md#u8)).

## 4 · Verificación de las métricas (Playwright humano)

Cada métrica tiene su gate humano:
| Métrica | Gate Playwright humano |
|---|---|
| Activación | E2E cronometrado: nuevo usuario → primera entrega <5 min ([T.ONB](./SDDs/SDD-001-plan-base/plan-t-excelencia.md#tonb)) |
| Entrega | Suite humana: aprobar diff + ver tests verdes + estado `done` en canva ([H·H.3](./SDDs/SDD-001-plan-base/plan-h-motor-pruebas.md)) |
| Costo/entrega | Badge de costo visible subiendo durante stream + total correcto ([A·A.7](./SDDs/SDD-001-plan-base/plan-a-chat-codex.md)) |

## 5 · Observabilidad del cliente (errores y crashes)

Profesional = saber cuándo algo se rompe, sin exponer datos:
- **ErrorBoundary por ventana** — nunca pantalla muerta; botón "reintentar" + "exportar diagnóstico" (sin secrets).
- **Error tracking OPT-IN** (igual que telemetría): `client.error` en el `event_stream` (tipo de error, ruta, versión, stack *anonimizado*, sin prompts ni contenido).
- **Crashes nube:** `tracing → OTLP` del gateway/workers; alertas en p99 TTFT, rate 5xx, cola de workers >5 min ([SLO-RELIABILITY](./SLO-RELIABILITY.md)).
- **Reporte desde la UI:** botón "Feedback" → plantilla prellenada con diagnóstico ([LAUNCH-CHECKLIST](./LAUNCH-CHECKLIST.md)).
- **Regla:** el error nunca contiene la API key ni diffs del usuario.

## 6 · Dashboard sugerido (post-MVP-2)

Una pantalla interna (dev/insights, no pública): north-star en tendencia 7/30d · activación por cohorte · retención D7 · costo por entrega · top skills · salud de proveedores. Fuente: `event_stream` agregado.
