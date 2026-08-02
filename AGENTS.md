# AGENTS.md — Empresa de Desarrollo Autónoma

Guía de trabajo para los agentes (incluido este) en este proyecto. Léela antes de tocar código.

## Qué es este proyecto

Una **app web mobile-first** para dirigir una "empresa de desarrollo" de agentes de IA: un **canva de sesiones** (diagramas + ventanitas que abren un chat de agente), un **kanban de organización**, y la **verificación de cada feature en un Chrome real** con capturas como evidencia.

- Primer para los desarrollos propios de @javir; después potencial producto para otros.
- **Idea rectora:** *nuestro propio chat de agente web (fork de opencode MIT) + agentes especializados + un navegador real que verifica cada feature con capturas como evidencia.*
- Documentación del plan en `docs/` (PLAN, PRODUCTO, ARQUITECTURA, AGENTES, VERIFICACION, PIPELINE, ROADMAP, ETAPA1). Actualízalos cuando cambie una decisión.
- **`docs/FUNDACION.md`** = decisiones base del proyecto (monorepo, TS estricto, design system, perf budget, protocolo del agente, DB, CI, primer slice vertical). **Leer antes de codear.**
- **`docs/STACK-AI-FIRST.md`** = análisis: por qué este stack es el correcto para una empresa autónoma de generación de código + 3 ajustes clave (reusar console de opencode, cola durable, observabilidad). **Leer antes de codear.**
- **`docs/ADRs/`** = decisiones de arquitectura registradas (ADR-001: Hono, ADR-002: stack AI-first). Si tomas una decisión de arquitectura, crea un ADR.

## Reglas obligatorias de trabajo

1. **SDD (Software Design Document) por feature — antes de implementar.** Escribe `SDD.md` (objetivo, flujo, contratos, datos, errores, tests y verificación de UI) antes de tocar código. Se actualiza en el mismo PR. Si no existe SDD para una feature, créalo (o pídelo) — no se implementa a oscuras.
2. **TDD como orden:** primero el test que falla, después el código que lo pasa.
3. **Definition of Done**: CI verde (typecheck→lint→tests→build) + **UI verificado en navegador real con capturas** adjuntas. Sin evidencia no está terminado.
4. **CI y navegador de pruebas desde el día 1** de la fundación del proyecto, antes de las features.
5. **Comunicación por artefactos** (ticket, SDD, PR, capturas), no por charlas en vivo.
6. Máx 3 intentos por error antes de escalar al humano.

## Decisiones de arquitectura (ADRs resumidos)

- **Backend: Hono + TypeScript** (NO Express/Fastify).
  - JS/TS nativo, render super rápido (Web Standard API), tipado extremo (TypeScript-first, JSDoc types), mejores de middleware, WebSocket/SSE de primera clase — ideal para el streaming en vivo del agente.
  - Se ejecuta en **Bun** (runtime rápido, compatible) o Node 22+. Bun: arranque instantáneo, tooling integrado (bun:test, bun run).
- **Frontend:** React 19 + Vite + TypeScript + Tailwind CSS v4 + shadcn/ui + Zustand + TanStack Query; canva con **React Flow (xyflow)**; kanban con dnd-kit; realtime por **WebSocket** (SSE para log streaming).
- **Motor de agente:** fork de **opencode (MIT)** — core + llm + server reutilizados; **UI web propia** (no TUI). Mantener atribución MIT.
- **Orquestación multi-agente:** **LangGraph** (JS/TS) en Fase 2 — los agentes del plan (Project Lead, Arquitecto, Implementadores, UI Tester) se construyen sobre el fork.
- **UI testing:** **MCP Chrome DevTools** — Chrome **headless en el servidor**, probando como humano (navegar, clic, consola, red, DOM) con capturas como evidencia.
- **DB:** SQLite (local/etapa 1) → Postgres (multi-usuario, etapa 4).
- **Mobile:** PWA instalable.
- **Servidor de producción:** Proxmox `pve` — el código vive en `/opt/empresa-desarrollo-autonoma`, no local.
- **Túnel Cloudflare dedicado (configurado):**
  - URL pública: **`https://empresa-dev.xtremediagnostics.com`**
  - Túnel: `empresa-desarrollo-autonoma-tunnel` (id `9370425a-6ffd-48af-a73d-4bebfa7c74bf`)
  - Origen: `http://localhost:7688` en `pve`
  - Config en servidor: `/etc/cloudflared/empresa-config.yml` + `empresa-creds.json`
  - Servicio: `empresa-tunnel.service` (systemd, habilitado, protocol http2)
  - Para levantar la app: correr el servidor (Hono/Vite) en el puerto **7688** y quedará expuesto públicamente.

## Etapa 1 (lo primero)

Canva (React Flow, nodos: cajas/notas/flechas + **ventanitas de agente**) donde cada ventanita abre **nuestro chat de agente web** (fork opencode MIT, UI propia). Detalle en `docs/ETAPA1.md`.

## Convenios

- Commits en español, cortos y con contexto ("feat:", "fix:", "docs:", "chore:").
- Ramas por feature; PR con SDD actualizado.
- El repositorio se mantiene en `/opt/empresa-desarrollo-autonoma` y se push a GitHub (remote por SSH en el servidor).