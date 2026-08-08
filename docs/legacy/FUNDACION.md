# FUNDACION — Decisiones base del proyecto

> Decisiones que se definen **antes** de escribir código. Hacen que el proyecto quede rápido, moderno y con apariencia increíble. Este documento es el contrato de fundación: lo que se decide aquí no se cambia sin un ADR nuevo.

## 1. Estructura monorepo

```
empresa-desarrollo-autonoma/
├── apps/
│   ├── web/          → React 19 + Vite (frontend)
│   └── server/       → Hono + Bun (API + WebSocket/SSE)
├── packages/
│   ├── ui/           → componentes propios (shadcn/ui como base)
│   └── config/       → TS, ESLint, Prettier compartidos
├── agents/           → el fork de opencode + LangGraph
├── SDDs/             → un SDD.md por feature (regla #1 de AGENTS.md)
└── ADRs/             → decisiones de arquitectura y por qué
```

- Workspaces con **pnpm** (o **bun workspaces** si usamos Bun de extremo a extremo).
- El agente (fork de opencode) trabaja un package a la vez → cambios pequeños, CI rápido, menos contexto por tarea.

## 2. TypeScript estricto + tipado de extremo a extremo

- `tsconfig` con `strict: true`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`.
- **Rutas tipadas:** `Hono` + `@hono/zod-openapi` → el cliente se genera del servidor. Nada de adivinar el API.
- **Valida TODO con Zod** en el borde (request/response). Cero `any` en el código entregado.

## 3. Design system ANTES del primer componente

- **Tokens de diseño** (CSS variables): color, spacing 4px, radios, sombras, tipografía.
- **Dark mode por defecto** + light opcional.
- **Sistema de animación único** (`motion` + stagger con límite 20 items).
- **Componentes base propios** (Button, Card, Modal, Input) sobre shadcn/ui, 2-3 variantes máx. Un solo `design-system.tsx`.

## 4. Rendimiento con presupuesto (no "después")

- **Perf budget:** <100KB JS crítico, <2s carga inicial en 4G. Medido en CI (Lighthouse CI).
- **Virtual Scroll** para listas >50 items (canva y kanban crecerán).
- **Code-splitting por espacio** (Canva / Kanban / Sesión) con `React.lazy` + `Suspense`.
- **Realtime eficiente:** WebSocket/SSE con protocolo tipado (eventos con Zod), reconexión con backoff, stores zustand por feature.

## 5. Protocolo del agente (lo más importante)

Definir **antes** los eventos de streaming que emite el agente, con un esquema único (Zod):

| Evento | Qué contiene | UI dedicada |
|--------|--------------|-------------|
| `message.delta` | texto parcial del agente | chat streaming |
| `tool.started` | qué herramienta, args | log de herramientas |
| `tool.output` | resultado | log / colapso |
| `browser.screenshot` | base64 de captura | **tarjeta de evidencia en el prompt** |
| `evidence.result` | ✅/❌ veredicto + tests | tarjeta de evidencia (antes/después) |
| `voice.transcript` | texto transcrito (STT) | mini-hilo de voz en la ventanita |
| `voice.response` | audio TTS + texto | reproducción 🔊 sin abrir |
| `session.state` | en qué anda el agente | badge en la ventanita |
| `ci.status` | verde/rojo, detalle | estado del kanban/ticket |

Esto hace que el chat "ventanita" se vea profesional: cada evento con su UI dedicada, no texto crudo. **Voz y screenshots son eventos de primera clase**, no extras.

## 5b. Voz (STT/TTS) y evidencia — pilares de la Etapa 1

- **Voz sin abrir la ventanita:** STT (Whisper local en servidor, fallback Web Speech API) → la transcripción entra como mensaje normal; TTS (servidor local, fallback navegador) responde 🔊. El audio viaja por WebSocket. Objetivo: conversación natural <1s de latencia.
- **Screenshot por prompt:** cada respuesta del agente adjunta evidencia (código, terminal, UI vía Chrome headless, tests) con veredicto visual ✅/❌. La evidencia queda guardada en la sesión.
- El servidor ya tiene ollama → STT/TTS local sin mandar audio a terceros.

## 6. Persistencia

- **Etapa 1: SQLite + Drizzle ORM** (tipado, migraciones, zero config).
- Schema mínimo definido desde el día 1: `sesiones`, `canvas`, `mensajes`, `eventos`.
- Migrar a Postgres luego = cambiar la URL, no reescribir.

## 7. CI que verifica de verdad (doctrina UI Tester)

- Desde el día 1: `typecheck → lint → test → build`.
- **Playwright** para los tests del UI Tester (Chrome headless ya configurado en el servidor).
- Cada PR con **capturas de pantalla** como artefacto (GitHub Actions).

## 8. Primer "slice vertical" chiquito

No empezar por "todo el canva". Empezar por **una ventanita que abre un chat que responde "hola"** en el servidor Hono, visible por el túnel `empresa-dev.xtremediagnostics.com`. Eso valida front + server + túnel + CI en un día. Después se escala.

## Stack final (resumen)

> **Validación AI-first:** este stack fue evaluado para el objetivo de empresa autónoma de generación de código en [`STACK-AI-FIRST.md`](./STACK-AI-FIRST.md) y registrado en [`ADRs/ADR-002-ai-first-stack.md`](./ADRs/ADR-002-ai-first-stack.md). Incluye 3 ajustes: reutilizar `packages/console` del fork de opencode, cola de trabajos durable (Fase 2), y observabilidad desde el día 1.

| Capa | Elección |
|---|---|
| Frontend | React 19 + Vite + TS + Tailwind v4 + shadcn/ui |
| Estado | Zustand + TanStack Query |
| Canva | React Flow (xyflow) |
| Kanban | dnd-kit |
| Realtime | WebSocket/SSE tipado (Zod) — incluye eventos de **voz** y **evidencia** |
| Voz STT | Whisper local en servidor (fallback Web Speech API) |
| Voz TTS | TTS local en servidor (fallback navegador) |
| Backend | **Hono + Bun + TypeScript** (ver ADR-001) |
| API tipada | @hono/zod-openapi |
| DB | SQLite + Drizzle (etapa 1) → Postgres (etapa 4) |
| Motor de agente | Fork opencode MIT + LangGraph |
| UI testing | MCP Chrome DevTools / Playwright (headless servidor) |
| Mobile | PWA |
| Túnel | Cloudflare → `empresa-dev.xtremediagnostics.com` |
