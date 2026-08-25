# AGENTS.md — Canvas AI

> Guía de trabajo para agentes AI en este proyecto. Leer antes de tocar código.

## Qué es este proyecto

**Canvas AI** es una **herramienta de IA generalista** desktop (Tauri v2) para trabajar con múltiples agentes de IA de forma visual y organizada.

- **No es un chatbot** — es un entorno de trabajo con canvas visual, sesiones, skills, y automatizaciones
- **No es una empresa autónoma** — no gestiona presupuestos, roles ni jerarquías de "empleados IA"
- **Referencias**: Hermes Agent (ACP, subagents, MCP), GrokBot (sessions, chief of staff), ERP AI Canvas (deploy-spec, node types)
- **Documentación**: `docs/INDEX.md` — mapa completo
- **Estado**: `docs/ESTADO.md` — dónde estamos

## La visión

Un usuario puede:
1. **Ver todo en un Control Room** — canvas infinito con sesiones activas, agentes trabajando, resultados
2. **Chatear con sesiones** — sidebar con sesiones, panel derecho con markdown vivo, código, previews
3. **Crear skills visualmente** — formulario sin YAML, avatares generados por IA, multi-agent loops
4. **Automatizar workflows** — canvas visual tipo n8n mejorado, multi-runtime (Python/TS/Go/Bash/SQL)
5. **Usar voz** — STT/TTS para hablar con agentes
6. **Trabajar offline** — Ollama local como fallback

## Stack tecnológico

| Capa | Tecnología | Por qué |
|---|---|---|
| Desktop | **Tauri 2.0** | Rust + web frontend, bundles chicos |
| Frontend | **React 19 + TypeScript** | Ecosistema, React Compiler |
| Bundler | **Vite 8 (Rolldown)** | 10-30x más rápido |
| Canvas 2D | **@xyflow/react v12** | Nodos, edges, zoom, drag-and-drop |
| Estado | **Zustand + immer** | 1KB, immutable updates |
| Server state | **React Query v5** | Caching, reintentos |
| Editor | **Monaco Editor** | VS Code editor embebido |
| Backend | **Rust (Axum)** | Hub server, DB, seguridad |
| DB | **SQLite (sqlx)** | Persistencia rápida + SQLiteVec para embeddings |
| Agentes | **ACP Protocol** | Hermes Agent, subagent delegation |
| Herramientas | **MCP (stdio/HTTP/SSE)** | Integración con herramientas externas |

## Arquitectura

```
┌─────────────────────────────────────────────┐
│  Canvas AI Desktop (Tauri v2)               │
│  ┌─────────────┐  ┌──────────────────────┐  │
│  │  Rust Core   │  │  React Frontend      │  │
│  │  canvas-ai-  │  │  (@xyflow/react)     │  │
│  │  core (lib)  │  │  Zustand + immer     │  │
│  │             │  │  React Query          │  │
│  │  canvas-ai- │  │  Monaco Editor        │  │
│  │  server      │  │                      │  │
│  │  (Axum)      │  │                      │  │
│  │             │  │                      │  │
│  │  canvas-ai- │  │                      │  │
│  │  worker      │  │                      │  │
│  └─────────────┘  └──────────────────────┘  │
│  SQLite (SQLiteVec embeddings)              │
│  ACP Protocol (Hermes) para subagentes      │
│  MCP (stdio/HTTP/SSE) para herramientas    │
└─────────────────────────────────────────────┘
```

## Reglas arquitectónicas

1. **canvas-ai-core** NO tiene dependencias de Tauri ni HTTP — es puro dominio
2. **Un solo frontend** — todo React en `src/`, no `src-desktop/`
3. **IPC para frontend-backend** — comunicación via comandos Tauri
4. **Shared types** — tipos de dominio en `packages/shared-types/`
5. **VR-ready** — todo canvas con coordenadas 3D, 1 unidad = 1 metro, sin absolute CSS

## Reglas de trabajo

1. **SDD por feature** — antes de implementar, escribir el diseño
2. **TDD** — primero test que falla, después código que lo pasa
3. **CI desde día 1** — `pnpm typecheck` + `pnpm test` + `cargo test`
4. **Gate por fase** — cada fase tiene verificación; no se cierra sin gate
5. **Responsive first** — mobile-first, después desktop
6. **Simpleza ante todo** — no sobrecomplicar; YAGNI
7. **Sin deuda técnica** — no hacer "fix temporal"
8. **Orden en código** — imports ordenados, carpetas por dominio

## Estructura de carpetas

```
src/
  components/
    canvas/       — ReactFlow, nodos, edges
    chat/         — ChatPanel, SessionSidebar
    editor/       — Monaco, file explorer
    skills/       — SkillCard, SkillEditor
    ui/           — Button, Input, Modal
  hooks/
  stores/
  lib/
  types/
```

## Código limpio

1. Una responsabilidad por archivo
2. Imports ordenados (externos primero, internos después)
3. Carpetas por dominio, no por tipo
4. Nombres descriptivos (no `helper2`, `data1`)
5. Funciones < 50 líneas
6. Sin valores mágicos (constantes extraídas)
7. Sin `any` (tipos definidos)
8. Sin TODOs pendientes

## Flujo SDD obligatorio

1. Crear SDD en `docs/SDDs/SDD-XXX-nombre.md`
2. Definir fases: X.1 (unit), X.2 (integration), X.3 (E2E GUI), X.4 (responsive)
3. Cada fase tiene su gate — no se avanza sin gate anterior
4. E2E Playwright en mobile (375px) Y desktop (1440px)
5. Feature completada solo cuando: SDD ✓ + tests verdes + gate cerrado + commit

## Documentación

| Documento | Qué es |
|---|---|
| `docs/INDEX.md` | Mapa completo de docs |
| `docs/ESTADO.md` | Estado actual |
| `docs/SDDs/SDD-001-plan-base/README.md` | Plan maestro |
| `docs/SDDs/SDD-005-plan-intermedio.md` | Referencia de fusión (CR→Etapa1, VI→2do cerebro, KR→Plan F, 3D→VR-ready) |
| `docs/SDDs/SDD-011-integracion-hermes-agent.md` | Integración Hermes |
| `docs/SDDs/SDD-012-multi-agent-grokbot-patterns.md` | Patrones GrokBot |
| `docs/SDDs/SDD-013-gui-visual-spec.md` | Design system |

## VR-ready (regla transversal)

Todas las vistas canvas se diseñan para VR futuro:
1. Coordenadas 3D, 1 unidad = 1 metro
2. Sin tamaños absolutos en píxeles
3. Sin absolute positioning en canvas
4. `vr={{}}` preparado en ReactFlow
5. Animaciones: solo transform y opacity (GPU-friendly)
6. Profundidad Z planificada (capas para 3D)
7. Colores WCAG AAA (legibles en AR)

---

*Última actualización: 2026-08-25*
