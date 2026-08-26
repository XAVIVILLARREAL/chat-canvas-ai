# Entorno local de desarrollo

> **Producto:** Canvas AI · **Base:** [ADR-006](./ADR-006-vision-hibrida-local-nube.md), [SCHEMA-MAESTRO](./SCHEMA-MAESTRO.md)
> Objetivo: en 3 comandos tienes el stack completo corriendo y conectado (frontend → gateway Rust).

## Stack hoy (scaffold)

| Pieza | Puerto | Comando |
|---|---|---|
| Frontend (Vite dev) | :1420 | `pnpm dev:frontend` |
| Gateway Rust (axum, in-memory) | :3030 | `cargo run -p canvas-ai-server` |
| Desktop Tauri (dev) | :1420 | `pnpm dev` (compila Rust + abre la webview) |
| Tests | — | `pnpm test` · `pnpm test:e2e` · `cargo test` |

> ⚠️ El gateway aún guarda en `HashMap` en memoria (Etapa 0 pendiente). Persistencia real = Etapa 0 ([SCHEMA-MAESTRO](./SCHEMA-MAESTRO.md)).

## Cómo correrlo conectado (dev)

```bash
pnpm install
# Terminal 1: gateway Rust
cargo run -p canvas-ai-server          # http://0.0.0.0:3030  (/healthz, /api/...)
# Terminal 2: frontend
pnpm dev:frontend                       # http://localhost:1420
# Vite proxya /api → :3030 (vite.config.ts). Abre la app y verás datos reales del server.
```

Si quieres apuntar el frontend a otro backend (nube/CI):
```bash
VITE_API_BASE=https://api.example.com pnpm dev:frontend
```

## Stack objetivo (tras Etapa 0 / nube)

- **Local-first:** SQLite local (Tauri) — sin infra.
- **Nube (de pago):** `docker-compose.yml` con Postgres + gateway + workers Linux (plan-s). Postgres en Compose desde el día 1 para probar RLS real ([ARQUITECTURA](./ARQUITECTURA.md)).

## Comandos útiles

```bash
pnpm typecheck        # tsgo
pnpm check:all        # typecheck + lint + oxlint
pnpm build:frontend   # vite build → dist/
pnpm test:e2e:human   # suite humana Playwright (clicks+teclado, es-MX)
pnpm test:e2e:human:core
cargo check --workspace
cargo test -p canvas-ai-core
```

## Gotchas conocidos

1. **Caché de Cargo y rutas absolutas:** si mueves/renombras la carpeta del repo, `cargo build` falla con paths viejos → `rm -rf target` y reconstruye.
2. **`cargo build` completo tarda >5 min** (trae webkit2gtk); para iterar rápido usa `cargo check -p canvas-ai-core -p canvas-ai-server -p canvas-ai-worker`.
3. **La deuda biome es preexistente** (~126 errores de estilo en `src/`); no añadas más (mi cambio bajó 38→32 en los archivos tocados).
4. **Server en memoria:** los datos se pierden al reiniciar `canvas-ai-server` (normal hasta la Etapa 0).
