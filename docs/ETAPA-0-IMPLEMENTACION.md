# ETAPA-0-IMPLEMENTACION — Plan accionable de la Fundación (slices + tests)

> **Producto:** Canvas AI · **Estado:** v1.0 · 2026-08-25 · Contrato: [SCHEMA-MAESTRO](./SCHEMA-MAESTRO.md) · Orden: [EJECUCION-ORDEN](./EJECUCION-ORDEN.md) · Loop: [WORKFLOW-AGENTICO](./WORKFLOW-AGENTICO.md)
> **Objetivo:** llevar el server de `HashMap` en memoria a **persistencia real** (SQLite local + Postgres nube), con eventos, secretos, sandbox y OpenAPI. Cada slice = mini-gate (suite humana cuando toca UI; aquí es mayormente backend → cargo tests + integration).

## Contexto del estado actual

- El server (`crates/server`) guarda todo en `Arc<RwLock<HashMap>>` — se pierde al reiniciar.
- `crates/core` ya es dominio puro (tipos + reglas), `packages/shared-types` expone tipos TS manuales.
- `cargo check -p core -p server -p worker` compila (warnings preexistentes).
- No hay migraciones, no hay DB conectada, no hay secretos reales, no hay sandbox provisionado.

## Slices de implementación (orden estricto)

### 0.0 — Fundamento del slice (cada slice arranca con esto)
1. **ANALYZE** (5 sub-agentes en paralelo): spec del slice / tests a crear / riesgo de romper lo verde / seguridad (secretos, path) / UX si aplica.
2. **DoR**: contrato de pruebas definido (qué cargo/vitest/test humano exige) + fila en la MATRIZ.
3. Implementar TDD (test que falla → código → verde).

### 0.1 — Migraciones + repos SQLite (a) — ✅ COMPLETADO 2026-08-27
> **Estado:** ✅ SQLite completo. Migraciones `0001_init` (11 tablas canónicas) + `0002_workspace` (canvas/agent/mcp payload JSON — [ADR-007](./ADRs/ADR-007-mapping-dominio-sqlite.md)) · repos CRUD en `canvas-ai-core::repo` · server rewired de `HashMap` a SQLite (refactor lib+api, `CANVAS_AI_DB` env) · tests 9/9 (up/down/up, CRUD aislado por project_id, FK cascade, persistencia tras reinicio a nivel repo y HTTP). La mitad Postgres de esta fila de la MATRIZ se cumple en el slice 0.2.

- **Qué:** `crates/core/migrations/0001_*.sql` (sessions, messages, event_stream, skills, providers, settings, documents, executions) con up+down; `sqlx` connectado a SQLite; repos CRUD.
- **Tests:** cargo test repos (CRUD por project_id) en SQLite + migración up/down/up idempotente.
- **Mini-gate:** `cargo test -p canvas-ai-core` verde; la data sobrevive a reinicio del server.

### 0.2 — Postgres (nube) + RLS fail-closed (b) — ✅ COMPLETADO 2026-08-27
> **Estado:** ✅ Migraciones por dialecto (`migrations/{sqlite,postgres}/`) · `0003_rls.sql` con RLS fail-closed (ENABLE + FORCE + `current_setting('app.project_id', true)` — sin tenant → 0 filas; superusers bypasean → producción jamás conecta como superuser) · `repo::connect_postgres` (migrador runtime) · tests `crates/core/tests/rls_postgres.rs` contra Postgres 16 real (`CANVAS_TEST_PG_URL`, skip silencioso en CI sin PG): aislamiento 2 tenants por SQL directo ✅ · cross-tenant UPDATE/DELETE → 0 filas ✅ · sin contexto → 0 filas ✅ · WITH CHECK bloquea INSERT de filas ajenas ✅ · up/down/up PG ✅ · 14 políticas `tenant_*` verificadas ✅. Nota: usuario PG de test NO-superuser/NO-bypassrls.

- **Qué:** mismas migraciones a Postgres; `pre_request` RLS fail-closed (sin tenant → 0 filas); script de seed.
- **Tests:** cargo test contra Postgres (Compose); 2 tenants → datos aislados (SQL directo, no solo UI).
- **Mini-gate:** integración Postgres verde; RLS verificado.

### 0.3 — event_stream + eventos de producto (c) — ✅ COMPLETADO 2026-08-27
> **Estado:** ✅ `0004_append_only` en sqlite+postgres (UPDATE/DELETE/TRUNCATE rechazados por trigger) · taxonomía de rungs en `repo::Rung` (sin CHECK SQL: conviven rungs y eventos de producto dot-namespace) · `emit_event()` tipado + auto-emisión al crear datos (session.created / message.streamed con tokens-costo / skill.created con ancla de sesión) · tests: append-only sqlite+PG, seed project→session→message→rung, producto events. Commit `39aa766`.
- **Qué:** taxonomía de rungs (PROMPT/PHASE/DIFF/TEST_RESULT/DECISION/ESCALATION/DELIVERY); trigger append-only (UPDATE/DELETE rechazados); helper `emitEvent()`; eventos de producto ([PRODUCT-METRICS](./PRODUCT-METRICS.md)).
- **Tests:** cargo test: append-only rechazado; seed project→session→message→rung; cada evento de producto emitido al crear datos.
- **Mini-gate:** ledger inmutable verificado.

### 0.4 — Secretos BYOK + vault (d) — ✅ COMPLETADO 2026-08-27
> **Estado:** ✅ `0005_vault` (ambos dialectos) · `core::vault` envelope AES-256-GCM: KEK (env/keychain) envuelve DEK por proyecto, secreto cifrado con DEK · `EnvKeyStore` (CANVAS_KEK); keychain OS deferred al shell Tauri (nota TODO en vault.rs) · `validate_provider_key()` roundtrip GET /models (formato de key por proveedor + 401/403 → rechazo; mock axum en tests) · `scan_for_secrets()`/`redact_secrets()` (openai/anthropic/openrouter/aws/github/slack/google) · server `POST/GET/DELETE /api/providers` + `/:id/test` — key NUNCA en respuestas · gate: dump sqlite sin key en claro ✅ · KEK distinta → DecryptFailed ✅ · revocación ✅.
- **Qué:** crate `keyring` (local) + envelope AES-GCM por tenant (nube) con KEK/DEK; `providers.key_ref`; validación del proveedor al pegar la key (roundtrip mínimo); scanner de secretos antes de enviar contexto.
- **Tests:** cargo test: key cifra/descifra con la correcta; nunca en claro al webview; dump de SQLite no revela la key.
- **Mini-gate:** flujo BYOK verificado + threat-model checkbox.

### 0.5 — Frontera del sandbox Linux (e) — ✅ COMPLETADO 2026-08-27
> **Estado:** ✅ `crates/worker/src/sandbox.rs` con bollard — contrato de contenedor aplicado en HostConfig (nano_cpus=1, memory=512MB, pids_limit=128, network_mode=none, readonly_rootfs, user 1000:1000, no-new-privileges, cap_drop ALL, tmpfs /tmp 64MB; disk 1GB best-effort por storage driver, `SANDBOX_DISK_OPT`) · `run_sandboxed` con timeout duro + cleanup garantizado · tests 5/5 contra Docker real (eco/timeout-137/red-denegada/contrato-provable/chaos-recovery+fork-bomb). Worker refactor a lib+main delgado. Nota bollard: exits ≠0 llegan como DockerContainerWaitError{code}.
- **Qué:** contrato del contenedor Ubuntu (CPU 1 · RAM 512MB · disco 1GB · pids 128 · timeout 60s · red off · mounts read-only · non-root · seccomp) vía docker API en el worker; spawn/kill/timeout.
- **Tests:** cargo test spawn/kill/timeout con fixture; chaos: matar contenedor a mitad → agente se recupera; red denegada verificada.
- **Mini-gate:** sandbox provable (H.9a adelantado a Etapa 0).

### 0.6 — OpenAPI del gateway + tipos generados (f)
- **Qué:** specta → JSON schema → OpenAPI (`docs/openapi.yml`); frontend consume tipos generados (openapi-typescript), se elimina el mantenimiento manual de `packages/shared-types` como fuente.
- **Tests:** OpenAPI generado sin errores; frontend compila contra tipos generados.
- **Mini-gate:** artefacto OpenAPI + build TS verde.

### 0.7 — i18n infraestructura + pipeline de traducción (g)
- **Qué:** diccionarios JSON (en/es/zh-CN/pt-BR/de/fr/it), hook `useI18n`, detección, fallback `en`, `scripts/translate.ts` (pipeline AI: OpenAI/Ollama, batch 50 keys), `scripts/i18n-check.mjs` (CI: falla si hay claves faltantes), selector idioma en Settings ([plan-i18n](./SDDs/SDD-001-plan-base/plan-i18n.md)).
- **Tests:** unit del hook + snapshot diccionario + fallback + translate.ts genera locale válido + i18n-check detecta missing keys.
- **Mini-gate:** `useI18n` unit verde · 7 locales generados · i18n-check CI verde.
- **Regla transversal:** toda feature nueva (Etapa 1+) DEBE incluir sus strings en en.json + locale objetivo en el mismo PR. El gate de fase rechaza PR sin strings i18n.

### 0.8 — Cierre de Etapa 0 (h)
- **GATE 0:** `cargo test` SQLite+Postgres verde · migración idempotente · append-only verificado · key cifrada/descifrable · sandbox provable · OpenAPI generado · i18n infra lista. `pnpm check:all` verde. Evidencia en `evidence/`.

## Reglas

1. Cada slice es **un commit semántico**; el siguiente no arranca sin el mini-gate del anterior.
2. Las migraciones **nunca se editan** tras aplicarse; se agregan nuevas.
3. Presupuesto de APIs reales: **$0 en Etapa 0** (todo mock/local; Ollama opcional).
4. Sin deuda nueva: biome limpio en lo tocado, 0 TODOs sin responsable.
5. El loop agéntico (5 sub-agentes en paralelo) corre en CADA slice antes de codificar.
