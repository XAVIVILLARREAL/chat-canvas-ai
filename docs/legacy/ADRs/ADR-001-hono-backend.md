# ADR-001 — Backend con Hono en vez de Express/Fastify

- **Estado:** Aceptado (2026-08-02)
- **Decisión:** El backend del proyecto usa **Hono + TypeScript** ejecutado en **Bun** (o Node 22+), en lugar de Express o Fastify.
- **Tags:** backend, api, realtime

## Contexto

El proyecto es una app web mobile-first que necesita: un API REST, WebSocket/SSE para streaming en vivo del agente, tipado de extremo a extremo, y un runtime rápido. La documentación inicial mencionaba Express/Fastify como opción.

## Decisión

- **Framework:** Hono.
- **Runtime:** Bun (arranque instantáneo, tooling integrado: `bun:test`, `bun run`). Node 22+ como alternativa compatible.
- **API tipada:** `@hono/zod-openapi` para generar el contrato del cliente desde el servidor.

## Consecuencias

**Positivas:**
- JS/TS nativo con Web Standard API → super rápido (benchmarks por encima de Express/Fastify).
- TypeScript-first extremo (JSDoc types), middleware estándar, WebSocket/SSE de primera clase.
- Ideal para el streaming del agente (SSE/WebSocket sin fricción).
- Un solo lenguaje en frontend y backend.
- Compatible con el ecosistema opencode fork (server basado en Node) vía capa de adaptación.

**Negativas / a vigilar:**
- Ecosistema de middleware menor que Express (raro que falte algo, y Hono es compatible con estándares web).
- Bun aún madura en algunos edge cases (usar Node 22+ si algo no es estable).
- La comunidad tiende a Express → documentación de terceros a veces hay que traducirla a Hono.

## Alternativas consideradas

| Alternativa | Por qué se descartó |
|---|---|
| Express | Verboso, menos rendimiento, tipado débil, WebSocket no nativo |
| Fastify | Mejor que Express pero más pesado y con menos integración Web Standard |
| Node puro (http) | Demasiado bajo nivel para el volumen de rutas/eventos del agente |

## Referencias

- `docs/FUNDACION.md` — decisiones base del proyecto (stack).
- `AGENTS.md` — reglas obligatorias (SDD, TDD, UI verificado).
