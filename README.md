# Canvas AI

> Herramienta de IA generalista — multi-agente, visual, local-first. **Byok** (trae tu API key). Open-source.

Canvas AI es un entorno de trabajo donde humanos y agentes de IA colaboran en un mismo espacio visual: chat con sesiones, canvas de automatización, skills (recetas `.md` con personalidad), memoria persistente y editor integrado.

**Local-first por defecto (gratis).** Modo nube 24/7 (suscripción, multi-tenant) para quien lo necesite — solo en la nube quien lo pague.

## Vistas principales

1. **Control Room** — canvas infinito con sesiones/agentes vivos, métricas y alertas
2. **Chat con sesiones** — sidebar de sesiones, markdown vivo, streaming, slash commands
3. **Segundo Cerebro** — grafo de archivos del proyecto estilo Obsidian
4. **Canvas de Automatización** — workflow builder multi-runtime (Python/TS/Go/Bash/SQL) + Kanban de resultados

## Modelo

| | Local-first (desktop) | Nube (SaaS multi-tenant) |
|---|---|---|
| Costo | Gratis | Suscripción (solo quien lo paga) |
| Agentes | Corren en tu máquina | Workers Linux 24/7 |
| Modelos | Tu API key (BYOK) + Ollama local | Tu API key, ejecutada por el servidor |
| Datos | SQLite en tu dispositivo | PostgreSQL + RLS por tenant |

## Stack

- **Desktop:** Tauri 2 (Rust + webview)
- **Frontend:** React 19 + TypeScript + Vite + @xyflow/react + Zustand
- **Backend:** Rust (axum) — `crates/core` (dominio puro) · `crates/server` (gateway) · `crates/worker` (stateless)
- **Datos:** SQLite + SQLiteVec (local) · PostgreSQL + RLS (nube)
- **Agentes:** BYOK (trae tu API key) + ACP/MCP + Ollama local offline

## Documentación

| Documento | Contenido |
|---|---|
| [`AGENTS.md`](./AGENTS.md) | Guía de trabajo para agentes IA |
| [`docs/INDEX.md`](./docs/INDEX.md) | Mapa completo de docs |
| [`docs/SDDs/SDD-001-plan-base/README.md`](./docs/SDDs/SDD-001-plan-base/README.md) | Plan maestro |
| [`docs/ARQUITECTURA.md`](./docs/ARQUITECTURA.md) | Arquitectura |
| [`docs/ESTADO.md`](./docs/ESTADO.md) | Estado actual |
| [`docs/SDDs/SDD-001-plan-base/MATRIZ-FASES-PRUEBAS.md`](./docs/SDDs/SDD-001-plan-base/MATRIZ-FASES-PRUEBAS.md) | Matriz de fases y pruebas |

## Desarrollo

```bash
pnpm install
pnpm dev            # Tauri dev (o: pnpm dev:frontend para solo web en :1420)
pnpm typecheck      # tsgo
pnpm test           # vitest
pnpm test:e2e       # Playwright
cargo test          # tests Rust
```

## Estado

Scaffold completo: core Rust, server axum, worker, frontend React, canvas ReactFlow. Plan maestro con etapas en `docs/SDDs/SDD-001-plan-base/README.md`.

## Licencia

MIT — ver [`LICENSE`](./LICENSE).
