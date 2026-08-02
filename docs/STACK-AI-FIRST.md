# STACK AI-FIRST — ¿Es este el mejor stack para una empresa autónoma de generación de código?

> **Pregunta:** ¿React 19 + Vite + Hono + Bun + LangGraph + fork de opencode es el mejor stack posible para construir una app **AI-first**, moderna, rápida, eficiente, que mañana sea una **empresa autónoma de generación de código**?
>
> **Fecha de análisis:** 2026-08-02. **Veredicto:** Sí, con 3 ajustes concretos (ver §6).

---

## 1. Qué exige una "empresa autónoma de generación de código"

No es una app CRUD normal. El core es un **sistema de agentes que escribe código real y lo verifica**. Los requisitos que mandan:

| Requisito | Implicación técnica |
|---|---|
| **Long-running, stateful** | El agente trabaja durante minutos/horas → ejecución **durable** (sobrevive crashes), estado persistido |
| **Streaming en vivo** | El humano ve qué hace el agente en tiempo real → SSE/WebSocket de primera clase |
| **Human-in-the-loop** | El humano aprueba/revisa/redirige → el framework de orquestación debe soportar **interrupciones** |
| **Multi-agente** | Project Lead, Arquitecto, Implementador, UI Tester → **grafo de agentes**, no un loop simple |
| **Herramientas reales** | El agente corre código, edita archivos, navega Chrome → **tool-calling robusto + MCP** |
| **Verificación visual** | La UI se prueba en un navegador real con capturas → Chrome headless integrado |
| **Múltiples proyectos** | La "empresa" maneja N proyectos en paralelo → aislamiento, colas, workers |
| **Multi-cliente** (fase 4) | Muchos usuarios → escalar, multitenancy, billing |

## 2. Evaluación decisión a decisión

### 🟢 Hono (en vez de Express/Fastify) — **ACERTADO**

- Benchmark superior (Web Standard API, router RegExp), funciona en **cualquier runtime** (Bun, Node, Deno, Cloudflare, Lambda).
- **SSE/WebSocket nativos y de primera clase** → el streaming del agente (requisito #2) sin fricción.
- Adapters oficiales: Bun, Node, Cloudflare, Vercel. Portabilidad real si mañana migras a edge/serverless.
- Compatible con el **AI SDK de Vercel** (`hono` tiene adapter oficial) — puedes exponer streams estándar `textStream`/`toolCallStream`.
- Ecosistema de middleware menor que Express, pero todo lo crítico existe (auth, cors, rate-limit, compression, timeout).

### 🟢 Bun (runtime) — **ACERTADO con matiz**

- Arranque ~10x más rápido que Node, `bun:test`, `bun run`, bundler integrado → **DX excelente** para el agente que itera rápido.
- **El fork de opencode ya corre en Bun** (su repo usa `bun.lock` + `bunfig.toml`) → mismo runtime en todo el monorepo = coherencia.
- **Matiz:** para la cola de trabajos de los agentes (jobs largos) puede que quieras **workers separados** (Node o Bun) con resumibilidad — eso no es el runtime, es arquitectura (§6).

### 🟢 React 19 + Vite + TS + Tailwind v4 + shadcn/ui — **ACERTADO**

- React 19 + Vite = el estándar más productivo para SPA de herramienta (no SEO → no necesitas SSR).
- Tailwind v4 + shadcn/ui = diseño profesional rápido, componente-driven, mobile-first.
- El **canva** (React Flow) y el **kanban** (dnd-kit) ya están probados en tu base CanvaDev.

### 🟢 Zustand + TanStack Query — **ACERTADO**

- TanStack Query: cache/refetch/optimistic para datos; Zustand: UI state + stores por feature (eventos del agente).
- Regla que ya aplicas en el ERP: datos de servidor **nunca** en Zustand → React Query.

### 🟢 LangGraph (JS) — **ACERTADO, es el núcleo**

Es el framework **correcto** para esto. Lo que aporta coincide 1:1 con los requisitos:

- **Ejecución durable** (persistence store) → un agente que lleva 40 min trabajando **se recupera** de un crash, no se pierde.
- **Human-in-the-loop** (interrupts) → el humano aprueba el SDD, revisa el PR, redirige. Nuestro pipeline lo exige (Fase 1 aprobación humana).
- **Streaming** nativo → eventos por nodo → nuestro protocolo tipado (§5 de FUNDACION).
- **Grafo determinístico + agentes LLM mezclados** → etapas predecibles (typecheck→lint→test) + decisión flexible del agente.
- Correrá **como biblioteca dentro del proceso Bun/Node**, no como servicio externo → sin latencia extra.

**Advertencia:** LangGraph es *low-level* — no abstrae arquitectura. Tú defines el grafo de tu "empresa" (Project Lead → Implementadores → UI Tester → Reviewer). Eso es **exactamente lo que quieres**: control total. Complementos opcionales: LangSmith (observabilidad/tracing), LangChain agents (loop estándar de herramientas).

### 🟢 Fork de opencode (MIT) como motor — **ACERTADO, con un hallazgo importante**

- opencode es hoy un **monorepo Bun + turbo** (no solo un CLI): `packages/console`, `packages/web`, `packages/core`, `packages/llm`, `packages/server`…
- **Hallazgo:** ya incluye un **web console** (`packages/console`) y una **web app** (`packages/web`). No partimos de cero para la UI — reutilizamos sus componentes de chat/herramientas y solo construimos la capa de **canva + kanban + ventanitas**.
- Aprovechamos su stack probado: core (agente), llm (multi-proveedor), server (sesiones, streaming), tooling MCP.
- Licencia MIT → fork legítimo, con atribución. Su `CONTEXT.md`/`AGENTS.md` documentan la arquitectura (el propio opencode usa AGENTS.md — coherencia con nuestro workflow).

### 🟢 Chrome DevTools MCP + Playwright (verificación) — **ACERTADO**

- Es el **diferenciador**: el agente prueba la UI como humano y produce capturas como evidencia.
- Chrome headless ya corre en tu servidor (`CHROME_HOST/PORT` en el entorno). Integración con el pipeline (CI + UI Tester).

### 🟡 SQLite → Postgres — **ACERTADO, pero planifica el salto**

- SQLite+Drizzle para empezar es perfecto (simple, tipado, migraciones).
- **Pero** una empresa multi-agente multi-proyecto genera: sesiones, mensajes, eventos, jobs, colas, métricas. Planifica Postgres + `pgvector` (embeddings de codebase para RAG) como destino natural. Tu servidor ya tiene Postgres corriendo (ERP) — puedes saltar a Postgres desde la Etapa 2 sin drama.

## 3. Lo que el stack ya cubre (resumen contra requisitos)

| Requisito | Cubierto por |
|---|---|
| Long-running stateful | LangGraph (durable execution + persistence) |
| Streaming en vivo | Hono SSE/WS + protocolo tipado Zod |
| Human-in-the-loop | LangGraph interrupts + pipeline (SDD/PR/capturas) |
| Multi-agente | LangGraph (grafo) + roles definidos (AGENTES.md) |
| Herramientas reales | opencode core + MCP + Chrome DevTools MCP |
| Verificación visual | Chrome headless + Playwright + capturas |
| Multi-proyecto | Monorepo + kanban por proyecto (Fase 2) |
| Multi-cliente (fase 4) | Hono portable → edge/serverless; Postgres multitenant |

## 4. Alternativas consideradas (y por qué NO)

| Alternativa | Por qué no |
|---|---|
| **Next.js** | SSR innecesario (herramienta interna, no SEO). Vite es más simple y el fork de opencode usa Vite/web. Más acople de framework |
| **Elixir/Phoenix o Go** | Poderosos para realtime/concurrencia, pero romperían el **un solo lenguaje** (front+back+agentes TS) y alejan el fork de opencode |
| **Python para el backend** | LangGraph tiene versión Python, pero el fork opencode es TS; mantener dos lenguajes duplica el stack. TS es la elección coherente |
| **StackLLM / n8n / otros orquestadores** | Genéricos, no dan control fino del grafo de agentes; LangGraph es más adecuado |
| **Construir el agente desde cero (sin fork)** | Meses de trabajo; opencode ya resuelve core+llm+server+console. El fork acelera la Etapa 1 enormemente |

## 5. Stack FINAL recomendado (AI-first, empresa autónoma)

| Capa | Elección | Por qué |
|---|---|---|
| Frontend | React 19 + Vite + TS + Tailwind v4 + shadcn/ui | Estándar productivo, mobile-first |
| Canva / Kanban | React Flow + dnd-kit | Probados, táctiles |
| Estado | Zustand + TanStack Query | Separación datos/UI |
| Backend API | **Hono** + TS (Bun/Node) | Rápido, Web Standard, SSE/WS nativo |
| API tipada | @hono/zod-openapi | Contrato cliente/servidor |
| Motor de agente | **Fork opencode (Bun)** — core+llm+server+console reutilizados | Acelera Etapa 1; UI propia encima |
| Orquestación | **LangGraph JS** (durable, interrupts, streaming) | El núcleo de la "empresa" |
| Streaming | Hono SSE/WS + protocolo Zod | Eventos del agente tipados |
| **Voz (STT/TTS)** | Whisper local (servidor) + TTS local; WebSocket de audio; fallback Web Speech API | Hablar con la IA **sin abrir** la ventanita |
| **Evidencia por prompt** | Chrome headless (MCP) + capturas + veredicto ✅/❌ | Screenshot en cada respuesta de lo que hizo y probó |
| DB | SQLite+Drizzle → Postgres (+pgvector) | Simple → escalable + RAG |
| Verificación | Chrome DevTools MCP + Playwright headless | Evidencia visual real |
| Observabilidad | Langfuse o LangSmith (tracing de agentes) | Ver qué hace cada agente |
| Mobile | PWA | "Añadir a pantalla de inicio" |
| Túnel | Cloudflare → empresa-dev.xtremediagnostics.com | Ya configurado (localhost:7688) |
| CI/CD | GitHub Actions + capturas de UI como artefacto | DoD con evidencia |

## 6. Tres ajustes recomendados (v2 de FUNDACION)

1. **Reutilizar `packages/console` de opencode** en vez de construir la UI de chat desde cero. Solo creamos canva + kanban + ventanitas sobre su base. (Revisar `packages/console` y `packages/web` al hacer el fork.)
2. **Planificar una cola de trabajos durable** para los agentes (jobs que duran decenas de minutos). Opciones: Postgres como cola + workers, o Temporal/BullMQ+Redis. LangGraph ya da resumibilidad; la cola la da la capa de infraestructura. (Fase 2, no bloquea Etapa 1.)
3. **Observabilidad desde el día 1:** conectar Langfuse (ya lo usas en el ERP) o LangSmith para trazar cada ejecución de agente. Los bugs de agentes sin traces son imposibles de depurar.

---

*Análisis con información pública verificada (Hono docs, LangGraph.js docs, repositorio anomalyco/opencode, agosto 2026).*
*Decisiones registradas en `docs/ADRs/ADR-002-ai-first-stack.md`.*
