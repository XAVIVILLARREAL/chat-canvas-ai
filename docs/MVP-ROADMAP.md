# MVP ROADMAP — Canvas AI

> **Estado:** v1.0 · 2026-08-25 · Base: [PRD](./PRD.md) · Capa de tiempo sobre la [MATRIZ](./SDDs/SDD-001-plan-base/MATRIZ-FASES-PRUEBAS.md) (fuente de verdad de fases).
> **Regla:** cada MVP termina con su **gate humano Playwright** verde (clicks+teclado, móvil+desktop, video en `evidence/`). No se cierra sin gate.

---

## MVP-1 — "Base operativa" (semanas 1-6)

**Objetivo:** el usuario hace su primer encargo de punta a punta con un agente real y BYOK.

| Bloque | Fases | Entregable humano |
|---|---|---|
| Fundación | **Etapa 0** (schema maestro, event_stream, secretos BYOK, sandbox, persistencia real) | Migración SQLite+Postgres · key cifrada descifrable · evento append-only |
| Chat | Etapa 2 (A) | Chat con sesiones, streaming, slash, medidor de contexto |
| Runtime | Etapa 3 (C) | BYOK (DeepSeek/OpenRouter/Ollama), router, telemetría, circuit breaker |
| Editor | Etapa 8 (B, minimal) | Editor + árbol de archivos + live preview sandboxed |
| Excelencia | T.SEC / T.A11Y / i18n / T.ONB | Onboarding <5 min · i18n multilenguaje · a11y gates |

**Gate MVP-1:** persona "Dev builder" hace F1+F2+F3+F4+F5+F6 (PRD §3). Video completo en `evidence/`. **Exit: activación >0% medible.**

## MVP-2 — "Memoria + Skills + Resultados" (semanas 7-14)

**Objetivo:** el usuario crea un skill `.md`, lo reutiliza, y los agentes trabajan por resultados con evidencia.

| Bloque | Fases | Entregable humano |
|---|---|---|
| Skills | Etapa 5 (G) | Skill `.md` con avatar/emoji/bio, laboratorio, tool-gating |
| Memoria | Etapa 4 (D) | Memory rail, knowledge, human-tweak lock, decisiones |
| Pruebas | Etapa 7 (H) | Motor de pruebas + shadow workspace + escalado |
| Kanban | KR (tras H) | Tablero evidencia-first + autonomía prolongada |
| Oficina | F.0-F.2 (design system + canva base) | Canva 60fps, nodos vivos |
| i18n | Cobertura completa de strings | Todos los idiomas en los 3 MVPs |

**Gate MVP-2:** F7+F8+F9+F10+F11 (PRD §3) + Consejo de Expertos dogfood (opcional). **Exit: retención D7 y costo/entrega medibles.**

## MVP-3 — "Automatización + Multi-dispositivo + Mercado" (semanas 15-24)

**Objetivo:** flujos visuales multi-runtime, la nube 24/7 de pago, y el marketplace como motor de red.

| Bloque | Fases | Entregable humano |
|---|---|---|
| Automatización | Etapa 6 (F) | Canvas compiler, multi-runtime, deploy-spec |
| Nube 24/7 | N.7 + S (despliegue, costos) | Suscripción, workers Linux, digest al volver |
| Sync | L (multi-device) | Mismo estado en desktop+móvil |
| GitHub | M | feature→commit→push→PR sin terminal |
| Marketplace | O | Bundles firmados export/import 1-click |
| **Targets de entrega** | **Etapa 10 (MP.1-MP.6)** | **Servidor Linux desplegado + Windows/macOS/Linux instalables + Android en tienda + iOS (gen/apple) + Web/PWA** ([PLATAFORMAS-TARGETS](./PLATAFORMAS-TARGETS.md)) |
| Post-v1 (park) | CR completo, 3D/VR, voz K.1/K.2, dopamina U, Consejo VI | — (marcados en la MATRIZ) |

**Gate MVP-3:** F12+F13+F14+F15+F16 (PRD §3) + **servidor Linux desplegado** + **instalables Windows/macOS/Linux/Android/iOS/web** ([PLATAFORMAS-TARGETS](./PLATAFORMAS-TARGETS.md)). **Exit: v1.0 publicable (T.BIZ: legal + pricing flags).**

---

## Riesgos por MVP y mitigación

| MVP | Riesgo | Mitigación |
|---|---|---|
| 1 | Costo LLM descontrolado | Guardrail $/sesión desde A, badge en vivo |
| 1 | Sandbox frágil | Frontera numérica en modelo de amenazas + demo de aislamiento |
| 2 | Skills difíciles de crear | Editor visual + plantillas + ceremonia de creación |
| 3 | Nube no justifica precio | Free-tier con límites + digest/evidencia visible |
| 3 | Scope creep (voz/3D/dopamina) | Marcados post-v1; no entran a MVP-3 |

## Presupuesto por MVP

- APIs reales: **máx $20/gate** (regla de la MATRIZ). Resto mock-first.
- Costos de hosting: [plan-s](./SDDs/SDD-001-plan-base/plan-s-despliegue-costos.md#s1) (~$16-26/mes MVP).
