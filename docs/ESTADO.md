# ESTADO ACTUAL

> Sesion: 2026-08-23 . Fase: Mega-Roadmap SDD-001 v3 aprobado (15 etapas) — arranca PLAN A . SDD mas reciente: SDD-005

## Donde estamos

Infra 100% verde + sistema spec-driven con suite humano 12/12 (SDD-002). **ADR-005 aceptado Y D1 EJECUTADO:** workspace Cargo vivo (crates/core + crates/server axum:3030 + src-tauri shell fino) — el mismo dominio Rust corre por IPC y por HTTP; Plan Base README define el modelo mental multiplataforma+sync. **Multiplataforma cerrado (SDD-005):** proyecto Android nativo versionado en `src-tauri/gen/android/` (toolchain instalada en servidor: JDK 21 + SDK 34 + NDK r27), CI con matriz desktop ubuntu/windows/macos en cada push, workflow manual "Android Build" para APK debug, y `docs/MULTIPLATAFORMA.md` con comandos por plataforma (iOS requiere Mac para `ios init`). Siguiente paso: mini-SDD técnico PLAN A y Fase A.1.

## Gates pendientes

- [ ] Gate A (SDD-001): chat real DeepSeek + streaming + historial persistente + aprobar/rechazar tool-call (+ suite humana de chat)
- [ ] Gate B: sidepanels Lovable — archivos aparecen y preview renderiza en vivo
- [ ] Gate C: motor Reasonix con DeepSeek, costos visibles, cancelación robusta
- [ ] Gate D: memoria 3 capas V3Code — recuerda decisiones entre sesiones
- [ ] Gate E = DoD Plan Base: suites verdes + demo E2E humana completa + tag plan-base-v0.1
- [x] Gate 0.1: Setup Tauri + React + TypeScript + toolchain funcionando (2026-08-22)
- [x] Sistema de pruebas SDD-002 operativo: 4 capas + suite humano 12/12 (2026-08-23)
- [x] Multiplataforma verificable: Android versionado + CI 3 SO + APK por demanda (2026-08-23)

## ADRs recientes

- ADR-005: Modelo de Despliegue Dual — crates Rust, GitService gitoxide+GitHub, sesiones CRDT resumibles, sandboxes Docker (2026-08-23)

## SDDs recientes

- SDD-005: Cierre Multiplataforma (2026-08-23) · docs/SDDs/SDD-005-cierre-multiplataforma.md
- SDD-001: Plan Base v3 — maestro de 15 etapas · docs/SDDs/SDD-001-plan-base/README.md

## Ultimos cambios

- 2026-08-23: ADR-005 D1 ejecutado — workspace Cargo con servidor axum de prueba viva; Plan Base README sección plataforma/sync
- 2026-08-23: ADR-005 despliegue dual aceptado (crates/core+server, repos bare gitoxide, sandboxes Docker, 3 modos)
- 2026-08-23: SDD-005 multiplataforma — gen/android versionado, CI matriz 3 SO, workflow APK manual, MULTIPLATAFORMA.md
- 2026-08-23: SDD-003 Torneo de ideas (500 → 20 ganadoras) + SDD-001 v3.1 con ideas robadas ronda 2
- 2026-08-22: Infra auditada y reparada (8 fixes): API tauri-specta rc25, iconos Tauri, vitest+config, knip limpio
- 2026-08-22: Rust 1.98 instalado en servidor; cargo test verde; E2E chromium 4/4 passed
- 2026-08-22: Spike reasonix v1.23: default deepseek-v4-flash; modos serve/acp/run --events-jsonl confirmados
