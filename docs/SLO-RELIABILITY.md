# SLO & RELIABILITY — Objetivos de nivel de servicio

> **Producto:** Canvas AI · **Estado:** v1.0 · 2026-08-25 · Complementa [plan-s](./SDDs/SDD-001-plan-base/plan-s-despliegue-costos.md) y [THREAT-MODEL](./THREAT-MODEL.md)
> Regla: SLO se mide, no se declara. Cada SLO tiene su **gate automático o humano** en la MATRIZ.

## 1 · SLO de experiencia (medibles en local y nube)

| Métrica | SLO | Cómo se mide |
|---|---|---|
| **Tiempo a primer token (TTFT)** | **< 1s** desde Enter (p50); < 3s p95 | instrumentado en `event_stream` (`message.streamed`) |
| **Velocidad de streaming** | ≥ 30 tokens/s sostenido (p50) | idem |
| **Arranque de la app** (local) | **< 2s** a UI interactiva en SSD | bench CI (cold start) |
| **Interfaz 60fps** | canvas con 100 nodos + 150 edges a 60fps | [PERFORMANCE-BUDGETS](./PERFORMANCE-BUDGETS.md) |
| **Guardrail de costo** | nunca excede el presupuesto configurado (corte duro por sesión/día) | [PRD](./PRD.md) F2, plan-a A.7 |
| **Persistencia** | 0 pérdida de sesión por cierre inesperado (autosave + WAL) | chaos E.2 |

## 2 · SLO de disponibilidad (solo nube — modo de pago)

| Métrica | SLO | Nota |
|---|---|---|
| Disponibilidad del gateway | **99.9%** mensual | error budget 43 min/mes |
| Uptime de workers 24/7 | ≥ 99% de tareas completadas en plazo | cola durable + retry |
| **RTO** (recuperación) | **≤ 1 h** tras desastre | drill trimestral desde backup B2 ([plan-s](./SDDs/SDD-001-plan-base/plan-s-despliegue-costos.md)) |
| **RPO** (pérdida máx) | **≤ 15 min** | WAL + backups B2 cada 15 min |
| Latencia API p95 | < 300 ms (sin LLM) | — |

## 3 · Circuit breaker y degradación (ya en C.3)

| Fallo | Comportamiento | SLO afectado |
|---|---|---|
| Provider 429/5xx/timeout | fallback a otro provider o Ollama local; error accionable | chat sigue, sesión intacta |
| Gateway caído (nube) | SPA muestra banner offline + outbox local; al volver, re-sync | disponibilidad percibida |
| Sandbox muere a mitad | tarea se reencola desde último snapshot (H.9b) | 0 trabajo perdido |

## 4 · Error budget y release

- Error budget mensual de disponibilidad (43 min) se consume en incidentes reales; **si se agota, no se lanza release** hasta resolver la causa raíz.
- Todo incidente → **post-mortem** en `docs/INCIDENTES/` (append-only) con causa raíz + acción preventiva (patrón del ERP: `INCIDENTE-WHATSAPP-403`).
- Monitoreo nube: `tracing → OTLP` + alertas en p99 TTFT, rate de 5xx, workers en cola >5 min.

## 5 · Verificación

- **Chaos suite (E.2):** 6/6 recuperaciones verificadas (kill -9, red, key inválida, cancel, doble instancia, prompt gigante).
- **Drill de backup (S.2):** restore completo en máquina limpia ≤ 30 min, automatizado trimestral.
- **Perf CI:** budgets de [PERFORMANCE-BUDGETS](./PERFORMANCE-BUDGETS.md) medidos en cada gate.
