# ADR-002 — Stack AI-first para empresa autónoma de generación de código

- **Estado:** Aceptado (2026-08-02)
- **Decisión:** El stack propuesto (React 19 + Vite + TS + Tailwind v4 + shadcn/ui + Hono + Bun + LangGraph JS + fork de opencode) es el **adecuado** para una app AI-first que evolucionará a empresa autónoma de generación de código. Se aplican 3 ajustes.
- **Tags:** stack, ai-first, orquestación, backend

## Contexto

La documentación inicial (FUNDACION, ADR-001) definió el stack. Se evaluó si es el mejor posible para el objetivo real: una app AI-first, moderna, rápida, eficiente, que sea mañana una empresa autónoma de generación de código (agentes multi-rol que escriben y verifican código real).

## Decisión

- **Validar** el stack de FUNDACION/ADR-001.
- **Ajuste 1:** reutilizar `packages/console` y `packages/web` del fork de opencode como base de la UI de chat; construir encima canva + kanban + ventanitas.
- **Ajuste 2:** planificar cola de trabajos durable para agentes largos (Postgres como cola + workers, o BullMQ+Redis/Temporal) en Fase 2.
- **Ajuste 3:** observabilidad de agentes desde el día 1 (Langfuse o LangSmith).

## Consecuencias

**Positivas:**
- LangGraph cubre durable execution, human-in-the-loop e interrupts — el núcleo de la empresa.
- Hono/Bun dan streaming nativo (SSE/WS) y un solo lenguaje en todo el stack.
- El fork de opencode acelera la Etapa 1 (no construir agente desde cero).
- SQLite→Postgres(+pgvector) da el camino de escalado + RAG.

**Negativas / a vigilar:**
- LangGraph es low-level: definir el grafo de la "empresa" es trabajo nuestro.
- Fork de opencode = mantenimiento del upstream (no seguirlo de cerca, pero conocerlo).
- Bun en edge cases: usar Node 22+ si algo no es estable.
- La cola de trabajos durable se pospone a Fase 2 — no bloquea Etapa 1.

## Alternativas descartadas

Next.js (SSR innecesario), Elixir/Go (rompe un solo lenguaje), Python backend (duplica stack), orquestadores genéricos (sin control fino), agente desde cero (lento).

## Referencias

- `docs/STACK-AI-FIRST.md` — análisis completo con evaluación por capa.
- `docs/FUNDACION.md` — decisiones base.
- `docs/ADRs/ADR-001-hono-backend.md` — backend Hono.
