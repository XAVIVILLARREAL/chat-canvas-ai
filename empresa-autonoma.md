# Empresa Autónoma de Desarrollo con IA — Plan anterior (Etapa 2, archivado)

> **Estado:** ARCHIVADO (2026-08). El plan principal actual es el **terminal SSH Flutter con supervitaminas** (ver `PLAN.md`). Este documento conserva el plan anterior completo por si se retoma en el futuro como **Etapa 2** (agentes IA como cuadritos del canva).

## La idea (tal como era)

Construir **tu propia empresa de desarrollo con IA dentro de una app**: un canva de sesiones, agentes multi-rol (LangGraph) que desarrollan y **prueban la interfaz en un Chrome real como un humano** (MCP Chrome DevTools), con capturas como evidencia.

> Idea rectora: *nuestro propio chat de agente web (fork de opencode MIT) + agentes especializados + un navegador real que verifica cada feature con capturas como evidencia.*

## Estado alcanzado (todo verificado y EN VIVO)

Se construyó una **app web funcional** (React 19 + Vite + Hono) con los 3 pilares funcionando:

1. **Canva = mapa de sesiones** — React Flow con "ventanitas" de agente (cajas/notas/flechas, zoom, minimap, persistencia).
2. **Voz (STT/TTS)** — Edge TTS en servidor (voz es-MX) + STT Web Speech API del navegador; hablar/oir sin abrir la ventanita.
3. **Evidencia por prompt** — el proxy Hono captura eventos reales de opencode (text/tool/screenshot) y los muestra como log de herramientas + tarjetas de imagen.

**Y además (Fases 2 y 3):**
- **Orquestador LangGraph** (`packages/orchestrator`): grafo `planner → implementer → tester → reviewer` que ejecuta tickets completos.
- **UI Tester con Chrome headless** (Playwright): navega la app real y captura screenshots como evidencia.
- **Kanban** en la UI: crea tickets, ve estados, expande resultados.
- **Pipeline completo probado**: un ticket "crear nota-fase3.txt" se completó solo (plan→implement→UI test→review "APROBADO"), creando el archivo real y documentando su propia verificación.

## Stack que se usó

| Capa | Elección |
|---|---|
| Frontend | React 19 + Vite + TypeScript + Tailwind v4 + shadcn/ui + Zustand + TanStack Query |
| Canva | React Flow (xyflow) |
| Backend | Hono + TypeScript (Bun/Node), SSE/WebSocket |
| Motor de agente | **Fork de opencode (MIT)** — core + llm + server |
| Orquestación | **LangGraph** (JS/TS) |
| Voz | Edge TTS (servidor) + Web Speech API (navegador) |
| UI testing | Playwright + Chrome headless (MCP Chrome DevTools) |
| DB | SQLite → Postgres (planificado) |
| Despliegue | Servidor Proxmox `pve` (32GB) + Cloudflare Tunnel `empresa-dev.xtremediagnostics.com` |

## Decisiones clave que quedaron

- **Fork opencode (MIT)**: reutilizar core+llm+server, construir UI propia web.
- **Hono** en vez de Express (ADR-001 legacy): rápido, Web Standard, SSE/WS nativo.
- **Frontend React** (no Svelte/Solid): por la reutilización del fork (ADR-003 legacy).
- **React Compiler** activado para rendimiento.

## Cómo se retomaría como Etapa 2

Los nodos de **agente IA** se integran como cuadritos del canva del terminal SSH Flutter:
- Una ventanita de agente = una sesión de opencode que desarrolla, ejecuta y verifica.
- Reutilizar: voz (Edge TTS + STT), evidencia por prompt, LangGraph, UI Tester.
- La infra (opencode serve, docker, túnel) ya existe y sigue funcionando en `pve`.

## Referencias de código (archivadas)

- Antes: `apps/web`, `apps/server`, `packages/orchestrator` (eliminados del repo principal).
- Docs legacy: `docs/legacy/` (eliminados; este documento los resume).
