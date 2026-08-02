# ROADMAP — Fases de construcción del producto

> Prioridad: **lo que se construye primero es la Etapa 1 — canva de diagramas con ventanitas de agente** (lo que faltaba y es la base de todo). Después se escala hacia la verificación visual autonoma y la empresa multi-agente.

## ✅ Etapa 1 — Canva de diagramas + ventanitas de agente (PRIMERO)

**Qué:** un canva libre donde dibujas diagramas/esquemas y **insertas ventanitas** que al click/touch abren un **chat con un agente de código estilo terminal** (opencode / antigravity / goose). Detalles en [ETAPA1.md](./ETAPA1.md).

- [ ] Canva libre (React Flow): cajas, notas, flechas, colores, zoom, touch.
- [ ] Insertar **ventanita de agente** → abre sesión real (click/touch).
- [ ] Ventana chat estilo terminal: streaming + logs de tools + código coloreado (+ voz opcional).
- [ ] Motor del agente: **opencode** (MIT) servidor headless vía SDK/WebSocket.
- [ ] Varias ventanitas = varias sesiones simultáneas, cada una en su propio directorio real.
- [ ] La sesión sigue aunque cierres la ventanita (mini-estado en el canva).
- [ ] Persistencia: posiciones, esquemas, conexiones, referencias de sesión (SQLite).
- [ ] Auth básica + mobile responsive (PWA).

**Objetivo:** la app es útil el día 1: diagramas + agentes trabajando reales, controlados desde el canva.

## ⏭️ Fase 2 — LangGraph: la empresa multi-agente

**El motor del agente de la Etapa 1 (opencode) es la base de partida.** En esta fase construyes tu **propio orquestador con LangGraph** pensado para desarrollo **autónomo sin humanos**, que controla a los agentes y da los roles de la empresa:

- [ ] **LangGraph**: grafo con nodos (Project Lead, Implementador, QA, UI Tester, Reviewer), checkpoints e interrupts.
- [ ] opencode (o los motores que uses) pasan a ser **ejecutores** dirigidos por el grafo.
- [ ] **Kanban**: tablero por proyecto conectado al grafo (tickets = ejecuciones; estados en vivo). Las ventanas de agente del canva muestran las ejecuciones.
- [ ] Retry + límite de intentos + escala al humano.
- [ ] Human-in-the-loop: aprobaciones en hitos dentro del grafo.
- [ ] Memoria del proyecto: SPEC/SDD/ADRs consultables por los agentes.

**Objetivo:** el sistema desarrolla una feature completa sola: planifica, implementa, prueba la UI y la deja lista para tu revisión.

## ⏭️ Fase 3 — Verificación autonoma con Chrome DevTools MCP

- [ ] UI Tester con **Chrome headless en el servidor** que prueba la app como humano (navega, clic, escribe, lee consola/red/DOM) y deja **capturas como evidencia**.
- [ ] Bucle: error real de consola/UI → vuelve al implementador (máx 3) → escala al humano.
- [ ] CI del proyecto (typecheck → lint → tests → build) conectado al gráfico.
- [ ] Deploy a staging automático + **verificación post-deploy en el navegador**.
- [ ] Producción con aprobación humana.

**Objetivo:** los agentes no dicen "funciona": lo **prueban** como humanos, con capturas adjuntas a cada PR.

## ⏮️ Fase 4 — Autonomía y producto

- [ ] Agente de Investigación y DevOps.
- [ ] Métricas en el kanban: bugs capturados vs. bugs en producción, capturas aprobadas a la primera.
- [ ] Optimización de costos: modelos por rol.
- [ ] Multi-usuario: auth real, proyectos por usuario, despliegue en servidor.
- [ ] Onboarding: plantilla de proyecto (scaffold + CI + navegador + convenciones).
- [ ] Planes/precios (si aplica) y límites de uso.

## Stack

| Necesidad | Elección | Estado |
|---|---|---|
| Frontend | React 19 + Vite + TS + Tailwind v4 + shadcn/ui | Etapa 1 |
| Canva | React Flow (xyflow) + nodos personalizados (ventanitas) | Etapa 1 |
| **Motor de agente** | **Fork opencode (MIT)** — core + llm + server; UI web propia | Etapa 1 |
| Orquestación | **LangGraph** (agentes propios sobre el fork) | Fase 2 |
| Kanban | dnd-kit / react-kanban | Fase 2 |
| UI testing | **MCP Chrome DevTools** (headless servidor) | Fase 3 |
| Backend | **Hono + TypeScript** en Bun (WebSocket/SSE, streaming) | Etapa 1 |
| DB | SQLite → Postgres | Etapa 1 → 4 |
| Realtime | WebSocket | Etapa 1 |
| Mobile | PWA | Etapa 1 |

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Fork de opencode evoluciona en el upstream (difícil de seguir) | No esperamos seguirlo de cerca; nuestro fork es la base, el core es estable y mit. Actualización manual si hace falta |
| Chrome DevTools MCP inestable o lento en CI | Entorno dedicado (headless con capturas); reintentos; flujos pequeños |
| Agente loopea corrigiendo | Límite de intentos + escala al humano |
| UI Tester "aprueba" sin probar de verdad | Evidencia obligatoria: capturas adjuntas al PR; reviewer las revisa |
| CI sin tests = falso verde | QA escribe tests antes (TDD) + revisión de calidad del test |
| Costo alto de modelos (más agentes + más verificación) | Modelos por rol; capturas baratas; límites por ticket |
| App web demasiado pesada en móvil | Vistas bajo demanda, PWA, animaciones sutiles |
