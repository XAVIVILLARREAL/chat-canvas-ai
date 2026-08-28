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

## Próximo paso (Etapa 0 — ya concretada y con plan de implementación)

- [ ] **Implementar la Etapa 0 por slices** ([ETAPA-0-IMPLEMENTACION](./ETAPA-0-IMPLEMENTACION.md)): ~~0.1 migraciones+repos SQLite~~ ✅ → ~~0.2 Postgres+RLS~~ ✅ → ~~0.3 event_stream~~ ✅ → ~~0.4 secretos BYOK~~ ✅ → ~~0.5 sandbox~~ ✅ → ~~0.6 OpenAPI~~ ✅ → ~~0.7 i18n~~ ✅ → **0.8 GATE 0 ✅ (2026-08-27)**.
  - ✅ **Slice 0.7 (i18n) COMPLETADO 2026-08-27** — I.1-I.5 completos (12 locales + RTL árabe + Intl), suite humana verde. Commit `f87b26c`. Ver [plan.md](../plan.md).
  - ✅ **Slice 0.1 (SQLite) COMPLETADO 2026-08-27** — migraciones + repos + server rewired ([ADR-007](./ADRs/ADR-007-mapping-dominio-sqlite.md)). Tests 9/9. Commits `ad46ac8`, `aaf4486`.
  - ✅ **Slice 0.2 (Postgres + RLS) COMPLETADO 2026-08-27** — migraciones por dialecto (`migrations/{sqlite,postgres}/`) · `0003_rls.sql`: RLS **fail-closed** en 13 tablas (ENABLE + FORCE + políticas `project_id = app_tenant()`; mensajes/event_stream/skill_versions/document_links vía EXISTS) · `repo::connect_postgres` con migrador runtime · tests `rls_postgres.rs` contra Postgres real (skip sin `CANVAS_TEST_PG_URL`): aislamiento 2 tenants ✅ · sin tenant → 0 filas ✅ · cross-tenant UPDATE/DELETE → 0 filas ✅ · WITH CHECK impide crear filas ajenas ✅ · up/down/up PG ✅ · 14 políticas verificadas ✅.
  - ✅ **Slice 0.3 (event_stream) COMPLETADO 2026-08-27** — `0004_append_only` (UPDATE/DELETE/TRUNCATE rechazados en ambos dialectos) · taxonomía de rungs como tipos Rust (`Rung`: PROMPT/PHASE/DIFF/TEST_RESULT/DECISION/ESCALATION/DELIVERY) · constantes `product_events` (PRODUCT-METRICS §2) · `emit_event()` tipado · **auto-emisión al crear datos**: session→`session.created`, message→`message.streamed` (tokens/costo), skill→`skill.created` (ancla de sesión) · tests: append-only sqlite+PG ✅ · seed project→session→message→rung ✅ · commit `39aa766`.
  - ✅ **Slice 0.4 (BYOK vault) COMPLETADO 2026-08-27** — `0005_vault` (tabla cifrada, ambos dialectos) · `core::vault`: envelope **AES-256-GCM** (KEK→DEK→secreto, nonce aleatorio por sello) · `EnvKeyStore` (CANVAS_KEK base64 32B; keychain OS deferred al shell Tauri) · validación roundtrip de proveedor (mock local en tests, free-first) · scanner+redactor de secretos · server: `POST/GET/DELETE /api/providers` + `/:id/test` — **la key JAMÁS en respuestas ni en el dump de SQLite** · tests: cifrado/descifrado + KEK distinta falla + dump limpio + revocación + roundtrip + scanner (19/19 workspace). 
  - ✅ **Slice 0.5 (sandbox Linux) COMPLETADO 2026-08-27** — `canvas_ai_worker::sandbox` (bollard/docker API): contrato **CPU 1 · RAM 512MB · pids 128 · red OFF · rootfs read-only · non-root (1000:1000) · no-new-privileges · cap_drop ALL · tmpfs /tmp 64MB · timeout duro** · `run_sandboxed` (spawn→wait select→kill→logs→remove SIEMPRE) + `start/kill/cleanup` para chaos · `inspect_limits`/`inspect_contract` (provable) · exit codes ≠0 vía DockerContainerWaitError (idiosincrasia bollard) · tests 5/5 contra Docker real: eco ✅ · timeout mata 137 ✅ · red denegada ✅ · contrato provable ✅ · chaos: kill a mitad → nuevo sandbox arranca ✅ · fork-bomb contenida por pids-limit ✅. Workspace **24/24** (2 corridas limpias).
  - ✅ **Slice 0.6 (OpenAPI) COMPLETADO 2026-08-27** — `build_openapi()` en api.rs: inventario de 40 paths + 41 schemas desde los structs Rust (fuente ÚNICA con JsonSchema) · artefacto `docs/openapi.json` · test gate `openapi_generado_sin_errores` (todo $ref resuelve) · bin `export-openapi` genera TAMBIÉN `src/types/api-generated.ts` (105 tipos, mapper JSON Schema→TS propio; openapi-typescript descartado por incompatibilidad con TS7 del workspace) · `src/types/api.ts` bridge + aliases · `pnpm typecheck` (tsgo) verde contra los tipos generados · `packages/shared-types` DEPRECADO (sin imports en el frontend). 
  - ✅ **Slice 0.8 GATE 0 — ETAPA 0 CERRADA 2026-08-27**: 25/25 tests Rust (SQLite+PG real) · sandbox 5/5 Docker real · append-only verificado · vault sin key en claro · OpenAPI 40 paths + tipos TS + typecheck/build verde · i18n 12 locales. Evidencia completa: [evidence/gate-0/GATE-0.md](../evidence/gate-0/GATE-0.md). Deuda legacy documentada: 15 lints preexistentes (17 antes).
- **SIGUIENTE EN ORDEN: Etapa 1** — [plan-a-chat-codex](./SDDs/SDD-001-plan-base/plan-a-chat-codex.md) A.0 "Proyectos como SCOPE" (fundación multi-proyecto).
- **SIGUIENTE EN ORDEN: slice 0.2** — Postgres + RLS fail-closed (mismas migraciones a Postgres, seed, 2 tenants aislados).
- El server aún vive en `HashMap` en memoria; conectar sqlx/sqlite + Postgres ([SCHEMA-MAESTRO](./SCHEMA-MAESTRO.md)) ← **SIGUIENTE EN ORDEN (slice 0.1)**
- Contrato `event_stream` (ledger append-only) + eventos de producto ([PRODUCT-METRICS](./PRODUCT-METRICS.md))
- Módulo de secretos BYOK (keychain OS / cifrado por tenant) ([THREAT-MODEL](./THREAT-MODEL.md))
- Frontera del sandbox Linux (números) ([THREAT-MODEL](./THREAT-MODEL.md))
- OpenAPI del gateway (specta) ([SCHEMA-MAESTRO](./SCHEMA-MAESTRO.md))

## Optimización lógica del plan (2026-08-25)

- **FEATURE-BACKLOG** (`docs/FEATURE-BACKLOG.md`) — análisis de funciones del producto: **12 funciones AGREGADAS** (F17-F28: tools web nativas, visión multimodal, comparador A/B, share público, puentes WhatsApp/Telegram/Discord, quick capture, dashboard de costos, forecast pre-envío, import ChatGPT/Claude, papelera, perfiles BYOK, export PDF), post-v1 marcado y **rechazadas con razón** (anti-scope). MATRIZ +5 fases (A.10/C.8/C.9/N.8/O.4) → **154 fases**; COVERAGE-GUI 64 elementos.
- **GLOSARIO** (`docs/GLOSARIO.md`) — terminología canónica + anti-glosario ("empresa autónoma", "tenants en local", "compila").
- **INDEX reestructurado en 6 niveles lógicos** (Producto → Arquitectura → Plan/Ejecución → Calidad → Lanzamiento → Estado).
- **README maestro v3.1** — sección "Cómo usar este plan" (orden de lectura), **Definition of Ready/Done**, **Milestone M0**.
- **ETAPA-0-IMPLEMENTACION** (`docs/ETAPA-0-IMPLEMENTACION.md`) — Etapa 0 en 9 slices accionables (0.0-0.8) con tests y mini-gates, listos para arrancar con el loop agéntico.
- **MVP-ROADMAP** — estimación de esfuerzo por MVP (horas orientativas) + regla de slices si una fase tarda 2×.

## Nueva capa de producto (2026-08-25)

- **PRD** (`docs/PRD.md`) — personas + JTBD + features→resultado medible Playwright humano
- **PRODUCT-METRICS** (`docs/PRODUCT-METRICS.md`) — north-star "sesiones que terminan en ENTREGA", activación, retención, eventos, telemetría opt-in
- **PRODUCT-DIFFERENTIATORS** (`docs/PRODUCT-DIFFERENTIATORS.md`) — los 7 diferenciadores que hacen el producto "increíble"
- **MVP-ROADMAP** (`docs/MVP-ROADMAP.md`) — MVP-1 (base) / MVP-2 (memoria+skills+resultados) / MVP-3 (automatización+nube+mercado)
- **SCHEMA-MAESTRO** (`docs/SCHEMA-MAESTRO.md`) — Etapa 0 concreta (sessions/messages/event_stream/skills/providers/settings + DDL)
- **CONTRATO-SKILL** (`docs/CONTRATO-SKILL.md`) — frontmatter `.md` exacto + ejemplo + roles
- **THREAT-MODEL** (`docs/THREAT-MODEL.md`) — amenazas por capa + frontera sandbox + flujo BYOK
- **SLO-RELIABILITY** (`docs/SLO-RELIABILITY.md`) — TTFT <1s, uptime 99.9%, RTO ≤1h / RPO ≤15min, error budget
- **PERFORMANCE-BUDGETS** (`docs/PERFORMANCE-BUDGETS.md`) — arranque <2s, bundle <250KB, 60fps, streaming
- **PRICING-TIERS** (`docs/PRICING-TIERS.md`) — Free local gratis / Pro $29 / Teams $99, BYOK en todos
- **LAUNCH-CHECKLIST** (`docs/LAUNCH-CHECKLIST.md`) — distribución, feedback loop, legal, growth
- **DEV-ENVIRONMENT** (`docs/DEV-ENVIRONMENT.md`) — 3 comandos para correr el stack
- **PLATAFORMAS-TARGETS** (`docs/PLATAFORMAS-TARGETS.md`) — matriz canónica "qué se instala dónde": servidor Linux 24/7 + clientes Windows/macOS/Linux/Android/iOS/web. **Cierra la duda "¿el plan construye el servidor o los clientes?": construye AMBOS.** iOS es el único entregable pendiente de generar (`tauri ios init` en un Mac → `src-tauri/gen/apple/`); Etapa 10 y MATRIZ MP.1-MP.6 lo hacen explícito; release.yml ahora builda los 3 desktops.

## Loop humano exhaustivo (2026-08-25)

- **Suite humana: 17/17 verdes** (móvil 375 + desktop 1440, video por paso) — temas, idioma, drawer, boot, create-agent (con modal NUEVO), keyboard-nav, responsive
- **7 bugs reales cazados y arreglados por el loop** (React Compiler vs i18n, doble drawer, tabs desbordadas, a11y de listas, carrera de sidebar, z-index móvil, foco de dropdown)
- COVERAGE-GUI: 82 elementos (8 ✅ verificados, 74 ⬜ de fases futuras)

## Temas + i18n + responsive FUNCIONALES (2026-08-25)

- **Temas**: dark/light reales con persistencia y modo system (`src/theme.ts` + tokens light)
- **i18n**: es/en implementados (`src/i18n/`), selector en Header/Config
- **Responsive**: móvil 375 operativo (drawer sidebar, header compacto, targets 44px) — evidencia en capturas Playwright
- Fixes: ReactFlowProvider faltante (crash negro), dropdowns siempre visibles, title stale

## Calidad visual Liquid Glass → VR (2026-08-25)

- **Provider de pruebas GRATIS** (regla free-first): OpenRouter `:free` (**ox-alpha free**) como provider por defecto de TODOS los tests con LLM real — $0 ilimitado desde C.1; setup en [DEV-ENVIRONMENT](./DEV-ENVIRONMENT.md) + `.env.example`. APIs de pago solo para capacidades específicas (≤$20/gate).

- **SDD-013 §8** — Escalera visual: **L1 Liquid Glass 2D (hoy) → L2 Espacial (SpatialMeta, post-v1) → L3 VR/AR gafas**; reglas por componente (SpatialMeta obligatoria, tokens oklch solo, transform/opacity, renderer-agnóstico, Z planificada, contraste progresivo AA→AAA) + camino a VR por hitos (F.0 → 3D.1 → J.3 → 3D.2 → WebXR).
- **Enforcement en CI**: `pnpm test:visual` (`scripts/check-visual.mjs`) con baseline — hex hardcodeado y `position:absolute` en canvas NO pueden crecer (49 violaciones heredadas registradas; la deuda solo baja).
- AGENTS.md / README maestro / MATRIZ alineados a SDD-013 §8 como fuente canónica visual.

## Auditoría completa del plan (2026-08-25)

- **23 links rotos arreglados** en docs (rutas relativas mal calculadas + nombre stale `plan-m-voz-texto`→`plan-m-github`). Verificador: 0 rotos.
- **Código sin rastros de "empresa"**: `lib.rs` (greet) → "Canvas AI"; Android re-empaquetado `com.empresa_dev.app` → `com.canvas.ai.app` (namespace, applicationId, manifest, theme, MainActivity movido). El `empresa-dev-server` del smoke era un zombie de la carpeta vieja en :3030, no de este repo (el crate ya era `canvas-ai-server`).
- **Regla dura COBERTURA GUI 100%** (`AGENTS.md` + `SDD-002` + `MATRIZ`): todo botón/función/feature tiene su prueba humana Playwright (clicks+teclado); sin prueba = no existe. Tabla maestra: [COVERAGE-GUI](./COVERAGE-GUI.md) (≥50 elementos mapeados MVP-1/2/3).
- **Loop de desarrollo agéntico** ([WORKFLOW-AGENTICO](./WORKFLOW-AGENTICO.md)): por fase → ANALYZE (5 sub-agentes en paralelo: spec/tests/riesgo/seguridad/UX) → DECIDE → MODIFY (TDD humano) → TEST (Playwright humano + debug en tiempo real) → ITERATE (máx 5) → DECIDE. Enfoque en **resultados funcionales** (video evidencia), no "compila".
- **Nuevos docs (cierran huecos de auditoría)**:
  - `AUTH.md` — local SIN cuenta; nube = cuenta+sesión+RLS fail-closed
  - `API.md` — inventario REST canónico (~40 endpoints) + convenciones
  - `DATA-LIFECYCLE.md` — migraciones sqlx, backup/restore B2, GDPR (export/erasure/retención)
  - `FEATURE-FLAGS.md` — mapa de flags (tiers + dark-launch), enforcement server-side
  - `UX-STANDARDS.md` — atajos, estados de UI obligatorios, ayuda in-app
  - `EJECUCION-ORDEN.md` — checklist de construcción en orden exacto (MVP-1/2/3)
  - `PRODUCT-METRICS` +sección 5 (observabilidad/errores del cliente)
- **plan-i18n** (`docs/SDDs/SDD-001-plan-base/plan-i18n.md`) — multilenguaje simple desde el día 1 (es/en/pt/de/fr/it)
- **Fix de usabilidad:** frontend ya conecta con el gateway (proxy Vite `/api`→:3030 + `VITE_API_BASE`) — antes el frontend no podía hablar con su backend en dev
- **Repo profesionalizado:** SECURITY.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md, plantillas de issue/PR, release workflow, .editorconfig
- **Consistencia:** INFRA.md y ADR-002 realineados a ADR-006 (local-first, adiós "web-first"); scope "Equipo" → "Sesión"; Plan A realineado A.0-A.9 (BYOK, projects como scope); circuit breaker + backup integral

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
