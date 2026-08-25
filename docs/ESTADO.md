# ESTADO ACTUAL

> Sesión: 2026-08-25 · Fase: **Visión híbrida ADR-006** · Plan Maestro v3.0

## Dónde estamos

**Canvas AI redefinido como herramienta de IA generalista híbrida (ADR-006):** local-first gratis (BYOK, Tauri + SQLite) + nube multi-tenant de pago para ejecución 24/7 (Postgres+RLS + workers Linux). Se eliminó el concepto y el código de "empresa autónoma" (`AgentTeam`, `Company`, `teams`). Skills = documentos `.md` con personalidad y cara animada. BYOK como Hermes Agent. Sandbox Linux como GrokBot.

**Estado del código**: Todo compila y funciona:
- Core Rust (canvas-ai-core) ✅
- Server Axum (canvas-ai-server) ✅
- Worker (canvas-ai-worker) ✅
- Tauri integration ✅
- Frontend React + Vite ✅ (dev server :1420)
- `pnpm typecheck` pasa sin errores
- Build completo exitoso
- Residuo "empresa autónoma" eliminado del código (core, server, shared-types, frontend) ✅

## Próximo paso (Etapa 0)

- [ ] **Schema maestro + migraciones** — el server aún vive en `HashMap` en memoria; conectar sqlx/sqlite + Postgres
- [ ] **Contrato `event_stream`** (ledger append-only)
- [ ] **Módulo de secretos BYOK** (keychain OS / cifrado por tenant)

## Gates pendientes

- [ ] Gate 0: Schema maestro + eventos + secretos + persistencia real
- [ ] Gate A: Chat con sesiones + streaming + persistencia
- [ ] Gate B: Editor de código + live preview
- [ ] Gate C: Runtime de agentes (BYOK: Reasonix, DeepSeek, OpenRouter, Ollama)
- [ ] Gate D: Memoria y knowledge base
- [ ] Gate E: Skills Lab (recetas `.md` + avatares + multi-agent loops)
- [ ] Gate F: Canvas de automatización (deploy-spec, compiler)
- [ ] Gate CR: Control Room (canvas de sesiones)
- [x] Gate 0.1: Setup Tauri + React + TypeScript + toolchain
- [x] Rename exitoso: plantilla-empresa-desarrollo → canvas-ai
- [x] ADR-006: visión híbrida aprobada; fantasma "empresa autónoma" borrado

## SDDs recientes

- SDD-001 v3.0: Plan Maestro — híbrido ADR-006, 0-10 etapas · `docs/SDDs/SDD-001-plan-base/README.md`
- ADR-006: Visión híbrida local-first + nube SaaS de pago · `docs/ADRs/ADR-006-vision-hibrida-local-nube.md`
- SDD-005 v2.0: Referencia de fusión · `docs/SDDs/SDD-005-plan-intermedio.md`
- SDD-013: GUI Visual Spec — Obsidian Glass · `docs/SDDs/SDD-013-gui-visual-spec.md`

## Últimos cambios

- 2026-08-25: **ADR-006** — visión híbrida (local-first + nube de pago, BYOK, skills `.md`, sandbox Linux, sin empresa autónoma)
- 2026-08-25: **Eliminado el fantasma "empresa autónoma"** — `AgentTeam`/teams/`Company` fuera del código (core Rust, server, shared-types, frontend) y del plan
- 2026-08-25: **README.md raíz + LICENSE (MIT)** añadidos; `package.json` → `canvas-ai`
- 2026-08-25: **Etapa 0 (Fundación)** añadida al plan: schema maestro, eventos, secretos, sandbox
- 2026-08-25: Fusión SDD-005 en plan base — CR→Etapa1, VI→segundo cerebro, KR→Plan F, 3D→VR-ready
- 2026-08-25: Reescritura masiva de planes para nueva dirección (herramienta IA generalista)
- 2026-08-25: Rename completado — folder, Cargo packages, Tauri config, Rust imports → canvas-ai
