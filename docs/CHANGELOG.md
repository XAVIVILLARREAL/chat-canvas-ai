# CHANGELOG

> Append-only. Cada sesion deja rastro. Nunca editar dias anteriores.

## 2026-08-23

- **SDD-003 Torneo de ideas**: 500 ideas generadas de productos de mercado (25 categorías × 20) → eliminatoria por categoría → 10 debates cruzados documentados → **20 ganadoras** con rúbrica Valor/Viabilidad/Mantenibilidad/Encaje ≥17
- Ganadoras clave base: prefijo estable caché + auto-compacción + dashboard cache_hit (Reasonix real), medidor/debug-view de contexto, cola de mensajes, @menciones, revisión por hunks, consola-preview→agente, blame-rung V3Code, checkpoints reset, golden outputs skills, cuarentena flaky, risk-score, merge train, best-of-N, ⌘K paleta
- Las 480 no ganadoras quedan como backlog vivo re-visible al cerrar cada etapa
- Confirmados los 3 pilares de la BASE: interfaz Codex completa / caché optimizado Reasonix / 6 capas memoria V3Code (mapeo capa→fase explícito en SDD-003)
- Nuevas fases planificadas: C.5, A.5, B.6-B.8, D.7, F.7, H.7-H.8 (+ampliaciones G.4/N.2/I.4) — cada ganadora con sus 4 capas de prueba definidas

- **SDD-001 v3.1 — robo de ideas ganadoras (ronda 2)**: incorporadas a los planes TODAS las ideas no usadas de copia.md + patrones hermanos
- Shadow Workspace (H.5) + bucle auto-corrección silencioso con rungs SELF_FIX y auto-purgado (H.6) — copia.md §Cursor/Capa1
- Fast Apply / escritura especulativa streaming (B.5) — copia.md §Cursor/Morph
- Gobernanza de decisiones varve: proposed→accepted→violated, evidencia obligatoria, scopes file-glob (D.4)
- Grafo dual semántico sqlite-vec acelerado con Ollama qwen3-embedding del ERP — sin servicios nuevos (D.5)
- Memory router fino + shards temáticos + aging policy + checkpoints git-backed V3Code (D.6)
- Approvals reviewer agéntico auto_review + reglas granulares por prefijo (I.4) — Codex
- Reflect: aprender lecciones de transcripciones pasadas sin LLM (I.5) — codevira
- Tool-gating estricto por rol en skills (G.2) — Cline/RooCode
- Worktrees paralelos por operativo + artefactos SOP tipados viajando por edges (N.2)
- MCP público del cerebro hacia agentes externos (O.2) — V3Code/Zed
- Sección "EL PRODUCTO" en README maestro: el flujo estrella que combina todas las features ganadoras
- Red re-verificada: 112 links entre 16 archivos, 33 anclajes usados / 49 definidos, 0 rotos

- **SDD-001 v3 MEGA-PLAN**: roadmap expandido a 15 etapas (~60 fases) tras investigación profunda de las 3 fuentes
- Investigación V3Code oficial (v3code.dev): memory rail rungs clicables, time scrubber, auto-router visible, checkpoints, agentes en workspace propio paralelo, MCP
- Descubiertos subagentes built-in de Reasonix: explore/research/review/security-review → integrados a etapas 9 (revisión auto) y 14 (empresas)
- Patrones robados a varve/codevira: gobernanza decisiones proposed→accepted, memory_pack con presupuesto tokens, locks content-aware por símbolo, decisions.md commiteado
- Nuevos planes: plan-f canva+oficina (ReactFlow+Animated Beams+Kanban), plan-g skills lab (compilador dialectos incl reasonix subagent), plan-h motor pruebas (sandbox+readiness checks), plan-i revisión auto+superposiciones, plan-j grafo3D repo-map pagerank, plan-k voz (Edge TTS/Web Speech), plan-l sync multi-device+Co-Work CRDT, plan-m GitHub nativo (device flow+PRs+decisions.md), plan-n empresas autónomas (jerarquía+presupuesto+kill-switch+dashboard), plan-o marketplace+v1.0
- README maestro reescrito con mapa 15 etapas, grafo dependencias, estimación global ~19-26 semanas
- Red de referencias verificada: 94 links entre 16 archivos, 16/16 anclajes usados resueltos

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

- Agregados recursos de diseno visual en 
eference/ (clones shallow, depth 1):
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

## 2026-08-22

- **Sesión servidor Linux headless**: clonado repo en /workspace, deps instaladas, auditoría INFRA completa
- Fix vite.config.ts: minify esbuild→oxc (Vite 8/Rolldown ya no bundla esbuild), __dirname→import.meta.dirname
- Instalado Rust 1.98 + deps sistema Tauri Linux (webkit2gtk-4.1, gtk-3, ayatana-appindicator, rsvg, xdo)
- Fix Cargo.toml: tauri-plugin-playwright deja de ser optional (tauri-build valida permiso playwright:default); runtime sigue gated por feature e2e-testing
- Fix lib.rs: migrado a API real tauri-specta rc25 (collect_commands!, specta_typescript::Typescript, invoke_handler(builder), mount_events en setup)
- Generados iconos Tauri completos (32x32→1024, icns/ico, android/ios) via @tauri-apps/cli icon
- Agregado vitest + vitest.config.ts (scoped src/**, --passWithNoTests) — antes tomaba specs de Playwright
- knip limpio: entry index.html, scope src+e2e, ignore @srsholmes/tauri-playwright (reservado modo tauri)
- Eliminado src/index.ts placeholder vacío; types.ts sin exports internos; removido devDep @vitejs/plugin-react-swc (sin uso)
- Verificación completa verde: typecheck/lint/lint:oxc/knip/vitest/build 198ms/cargo test/E2E chromium 4 passed
- Spike reasonix v1.23.0: default deepseek-v4-flash; modos serve (HTTP+SSE), acp (stdio), run --events-jsonl, task --json confirmados
- **Creado SDD-001-plan-base**: super plan en 5 planes (A chat Codex-core, B sidepanels Lovable, C Reasonix+DeepSeek runtime, D memoria V3Code 3 capas, E integración total) con fases, pruebas y gates verificables
- SDD-001 v2 optimizado tras investigación de las 3 fuentes: mapeo explícito de qué copiar de Codex (2 perillas, diff con feedback, slash commands), Reasonix verificado en vivo (eventos/metrics/trajectory/permisos) y V3Code (artefactos ausentes → fase D.0 restauración)
- Hallazgo clave: ~31k tokens base por run Reasonix ($0.0043 trivial) → enrutamiento por costo (simple→DeepSeekDirect, tools→flash, plan→reasoner); estimación total 4.5-6 semanas
- **Reestructurado SDD-001 a carpeta referenciada**: docs/SDDs/SDD-001-plan-base/ con README maestro + un archivo por plan (plan-a…plan-e), cross-links entre todos
- **Creado SDD-002-testing-spec-driven.md**: sistema de pruebas spec-driven con 4 capas (unit/integración/E2E funcional/E2E humano)
- **Infraestructura Playwright HUMANO**: e2e/playwright.human.config.ts (video siempre, secuencial, desktop+mobile) + e2e/human/human-fixture.ts (h.step con screenshot por paso, humanClick con hover+pausas, humanFill carácter a carácter 40-120ms, humanThink, humanWheel) + 4 suites: boot, create-agent, keyboard-nav, responsive — **12/12 passed** (desktop 1440 + Pixel 7)
- Fix UI real: botón "Crear primer agente" ahora conectado al store (addAgent) — era un botón muerto sin onClick
- Script nuevo: pnpm test:e2e:human · Reglas del SDD-001 actualizadas: cada gate exige suite humana ampliada
- Actualizado ESTADO.md e INDEX.md
