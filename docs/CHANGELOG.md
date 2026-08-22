# CHANGELOG

> Append-only. Cada sesion deja rastro. Nunca editar dias anteriores.

## 2026-08-21

- **RESET COMPLETO** — Migration de Flutter a Tauri (React + Rust)
- Nueva vision: sistema multiagente visual para crear empresas de desarrollo
- Archivado todo lo anterior en `_reciclaje/` (apps, packages, empresa_autonoma, SDDs, ADRs, docs obsoletos, buzz, herdr, build, tools, pubspec, melos)
- Reescrito AGENTS.md completo con nueva vision, stack y roadmap
- Nuevo roadmap en 5 fases (fundacion visual -> skills -> pruebas -> sync -> empresa autonoma)
- Docs que se mantienen: INDEX.md, CHANGELOG.md, ESTADO.md (reescritos para nuevo inicio)
- Actualizado .gitignore para Tauri (antes era Flutter)
- Actualizado .github/workflows/ci.yml para Tauri (npm + cargo test)
- Limpieza de restos de Flutter en raiz (.dart_tool, pubspec, melos, copia.md, plan.md)
- Agregado TypeScript-Go (tsgo) v7.0 como compilador de TypeScript
- Creado package.json con scripts (dev, build, lint, test, typecheck)
- Creado tsconfig.json para TypeScript-Go
- Creado src/index.ts placeholder
- Agregado Biome (lint + format, reemplaza ESLint+Prettier)
- Agregado oxc (parser/linter Rust complementario) → reemplazado por oxlint (CLI disponible)
- Agregado Zustand (estado global, 1KB)
- Agregado TanStack React Query (estado del server)
- Configurado biome.json para React + TypeScript
- Actualizado CI con biome + tsgo
- Actualizado package.json con todos los scripts
- Agregado React 19.2.8 + React DOM
- Agregado Vite 8.2.2 con Rolldown
- Agregado React Compiler via oxc-transform-react (Rust, 10x mas rapido que Babel)
- Agregado @vitejs/plugin-react 6.1.0
- Agregado tauri-specta para IPC type-safe (Rust -> TypeScript bindings)
- Agregado knip para detectar codigo muerto
- Creado vite.config.ts con React Compiler habilitado
- Creado index.html para Vite
- Creado src/ con estructura React (App, stores, hooks, components, types, styles)
- Creado src/stores/app-store.ts con Zustand (agents, tasks, skills)
- Creado src/styles.css con glassmorphism neon
- Creado src-tauri/ con Cargo.toml, lib.rs, main.rs, build.rs
- Creado src-tauri/tauri.conf.json con plugins esenciales
- Creado src-tauri/capabilities/default.json con permisos por ventana
- Configurado tauri-specta para generar bindings TypeScript automaticamente
- Corregido tsconfig.node.json (composite: true para referencias)
- Auto-fix de Biome (imports sorting, formatting)
- Fix de non-null assertion en main.tsx
- Verificacion: tsgo, biome, oxlint todos pasan sin errores
- Creado docs/INFRA.md con resumen de todas las mejoras de infraestructura
- Agregado Playwright E2E testing (@playwright/test v1.62.1)
- Agregado @srsholmes/tauri-playwright v0.4.1 para tests contra webview real
- Agregado tauri-plugin-playwright v0.4 (feature flag e2e-testing)
- Creado e2e/ con playwright.config.ts, fixtures.ts, tests/app.spec.ts
- Configurado 3 modos de testing: browser, tauri, cdp (Windows)
- Agregados scripts test:e2e, test:e2e:ui, test:e2e:chromium, test:e2e:webkit
- Agregado playwright:default a capabilities
- Actualizado INFRA.md con seccion de Skills de opencode (5 skills documentados)
- Actualizado AGENTS.md con flujo SDD obligatorio, fases/prefases, pruebas E2E Playwright CLI simulando clicks/teclado/debug
- Creado ADR-001: Responsive Design y Cross-Platform (decisiones de arquitectura)
- Creado docs/RESPONSIVE.md: guia practica con componentes, hooks y testing
- Agregada regla #7 "Responsive first" a Reglas de trabajo
- Agregada seccion "Diseno responsive" con 9 reglas clave
- Agregadas reglas #8-10: Simpleza, Orden, Sin deuda tecnica (aplican a TODO el proyecto)
- Actualizada seccion "Codigo limpio y ordenado" para enfatizar que aplica a todas las capas (React, Rust, tests, scripts)
- Creado ADR-002: Arquitectura Hibrida Monorepo (un solo codebase, Tauri mobile)
- Creado docs/ARQUITECTURA.md: documento maestro de arquitectura
- Creado packages/shared-types/: tipos TypeScript de dominio (agent, skill, task, canvas, company)
- Creada estructura services/python/ para Python service (CreadAI)
- Creada estructura src-tauri/src/platforms/ para logica por plataforma
- Agregadas 7 reglas de arquitectura a AGENTS.md
- Agregada seccion "Arquitectura hibrida" a INFRA.md
- Creado ADR-003: Voz y Sincronizacion (Web Speech API + Edge TTS + WebSocket)
- Creado ADR-004: Integracion GitHub (OAuth, repos, push/pull, PRs, issues)
- Agregadas features pendientes a AGENTS.md (GitHub, Voz, Sync)
- Actualizado ADR-003: Decision clara de NO implementar P2P/rsync, usar WebSocket + GitHub
- Agregados 3 items a la vision: Git nativo, revision de errores, superposiciones de agentes
- Agregada seccion "Codigo limpio y ordenado" con 6 reglas de orden, 6 de simpleza, anti-patrones y checklist

## 2026-08-21 (sesion 2)

- Agregados recursos de diseno visual en eference/ (clones shallow, depth 1):
  - apple-design-skill (dickwu) — auditor HIG multiplataforma (Tauri + Flutter), 53 guias
  - ui-ux-pro-max (nextlevelbuilder) — catalogo de 84 estilos, paletas y tipografia
  - impeccable (pbakaus) — lenguaje anti-estetica-IA-generica (polish, audit, animate)
  - liquid-glass-web (Zettersten) — Liquid Glass CSS/SVG real para el canva
- Nueva seccion "Recursos de diseno visual" en AGENTS.md con rutas y reglas de uso

## 2026-08-21 (sesion 3)

- Eliminada la identidad fija "glassmorphism neon": AGENTS.md ya no prescribe un estilo unico
- Nueva regla en AGENTS.md: la IA decide que skill/estilo usar por tarea (ui-ux-pro-max, impeccable, liquid-glass-web, apple-design-skill) buscando maximo impacto
- Actualizados El diferenciador visual, tabla de stack, Roadmap Fase 1, gate 0.3 en ESTADO.md

## 2026-08-21 (sesion 4)

- Descarga y clonado de artefactos de V3Code (v3code.dev) en `reference/v3code/`
- Análisis e ingeniería inversa de la arquitectura de memoria de 3 capas:
  - Capa 1: Editor Layer & Memory Rail (gutter con tintes de sesión y Human-Tweak Lock)
  - Capa 2: Workspace & Knowledge Graph (índice semántico local y relaciones de código)
  - Capa 3: Chat & Decision Ledger (rungs discretos con time scrubber & replay)
- Descargados componentes interactivos completos (`memory-heatmap.html`, `model-router.html`, `visual-edit.html`, tokens CSS y bundle React)
- Creado `reference/v3code/README.md` con especificación técnica de adopción para Tauri + React + Rust + Python
- Actualizado AGENTS.md con la referencia a V3Code

## 2026-08-21 (sesion 4)

- Clonados en reference/: magic-ui (22k estrellas, 150+ componentes animados con Border Beam / Animated Beam para el canva, incluye skill de agente) y react-bits (46k estrellas, componentes interactivos con skills propios)
- Referenciados ambos en la tabla de Recursos de diseno visual de AGENTS.md

## 2026-08-21 (sesion 5)

- Creación y consolidación del documento maestro `copia.md` sintetizando los mejores IDEs open source y la infraestructura SOTA de IA más avanzada del mundo:
  - **V3Code**: Memoria de 6 capas, carril de memoria en Monaco y Human-Tweak Lock (0 tokens).
  - **Cursor SOTA**: Shadow Workspace (pre-validación invisible en memoria) y Fast Apply / Speculative Diffs (+1.000 tokens/s).
  - **LightRAG & `sqlite-vec`**: RAG de grafo dual (código + arquitectura) con búsqueda vectorial nativa en SQLite embebido sin dependencias externas.
  - **Aider**: Repo-Map AST con Tree-sitter y PageRank (<1.000 tokens) + Dual-Model Mode.
  - **OpenHands**: EventStream pub/sub inmutable para Time-Travel y replay visual.
  - **Cline / Roo Code**: Custom modes por rol y Tool Gating para evitar saturación de prompts.
  - **MetaGPT & ChatDev**: SOPs y línea de montaje de artefactos verificables ("Code = SOP").
  - **DSPy**: Compiladores y optimizadores declarativos de prompts para el Skills Lab.
  - **Zed**: Context Servers over MCP y arquitectura de ultra-baja latencia en Rust.
- Esquema de base de datos SQLite + `sqlite-vec` consolidado en `copia.md` para persistencia en Tauri (`sqlx`).

## 2026-08-21 (sesion 5)

- Creado docs/"referencia de diseno.md": catalogo completo de los 6 skills de diseno instalados (links, estrellas, rutas locales, uso, actualizacion) + evaluados no instalados
- Actualizado INDEX.md con el nuevo documento
