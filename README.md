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
| [`docs/PRD.md`](./docs/PRD.md) | Producto: personas, JTBD, features → resultado medible |
| [`docs/PRODUCT-DIFFERENTIATORS.md`](./docs/PRODUCT-DIFFERENTIATORS.md) | Los 7 diferenciadores "increíbles" |
| [`docs/PRODUCT-METRICS.md`](./docs/PRODUCT-METRICS.md) | North-star, activación, retención, eventos |
| [`docs/MVP-ROADMAP.md`](./docs/MVP-ROADMAP.md) | MVP-1/2/3 time-boxed |
| [`docs/SCHEMA-MAESTRO.md`](./docs/SCHEMA-MAESTRO.md) | Modelo canónico de datos (Etapa 0) |
| [`docs/CONTRATO-SKILL.md`](./docs/CONTRATO-SKILL.md) | Formato `.md` de skills |
| [`docs/THREAT-MODEL.md`](./docs/THREAT-MODEL.md) | Amenazas, sandbox, BYOK |
| [`docs/SLO-RELIABILITY.md`](./docs/SLO-RELIABILITY.md) | SLOs medibles |
| [`docs/PERFORMANCE-BUDGETS.md`](./docs/PERFORMANCE-BUDGETS.md) | Presupuestos de rendimiento |
| [`docs/PRICING-TIERS.md`](./docs/PRICING-TIERS.md) | Free/Pro/Teams |
| [`docs/LAUNCH-CHECKLIST.md`](./docs/LAUNCH-CHECKLIST.md) | Lanzamiento profesional |
| [`docs/DEV-ENVIRONMENT.md`](./docs/DEV-ENVIRONMENT.md) | Cómo correr el stack |
| [`docs/PLATAFORMAS-TARGETS.md`](./docs/PLATAFORMAS-TARGETS.md) | Qué se instala dónde (servidor + 6 clientes) |
| [`docs/AUTH.md`](./docs/AUTH.md) | Auth: local sin cuenta · nube con RLS |
| [`docs/API.md`](./docs/API.md) | Inventario REST del gateway |
| [`docs/DATA-LIFECYCLE.md`](./docs/DATA-LIFECYCLE.md) | Migraciones, backup, GDPR |
| [`docs/FEATURE-FLAGS.md`](./docs/FEATURE-FLAGS.md) | Flags de pricing + dark-launch |
| [`docs/UX-STANDARDS.md`](./docs/UX-STANDARDS.md) | Atajos, estados UI, ayuda |
| [`docs/EJECUCION-ORDEN.md`](./docs/EJECUCION-ORDEN.md) | Qué construir en qué orden |
| [`docs/COVERAGE-GUI.md`](./docs/COVERAGE-GUI.md) | Cobertura 100% botón→test humano |
| [`docs/WORKFLOW-AGENTICO.md`](./docs/WORKFLOW-AGENTICO.md) | Loop: sub-agentes en paralelo + debug |
| [`docs/ETAPA-0-IMPLEMENTACION.md`](./docs/ETAPA-0-IMPLEMENTACION.md) | Plan accionable de la Etapa 0 (slices) |
| [`docs/GLOSARIO.md`](./docs/GLOSARIO.md) | Terminología canónica |
| [`docs/INDEX.md`](./docs/INDEX.md) | Mapa completo de docs |
| [`docs/SDDs/SDD-001-plan-base/README.md`](./docs/SDDs/SDD-001-plan-base/README.md) | Plan maestro |
| [`docs/ARQUITECTURA.md`](./docs/ARQUITECTURA.md) | Arquitectura |
| [`docs/ESTADO.md`](./docs/ESTADO.md) | Estado actual |
| [`docs/SDDs/SDD-001-plan-base/MATRIZ-FASES-PRUEBAS.md`](./docs/SDDs/SDD-001-plan-base/MATRIZ-FASES-PRUEBAS.md) | Matriz de fases y pruebas |

## Contribuir y seguridad

- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — guía de contribución (spec-driven + TDD + gate humano)
- [`SECURITY.md`](./SECURITY.md) — reportar vulnerabilidades · [`CODE_OF_CONDUCT.md`](./CODE_OF_CONDUCT.md)

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
