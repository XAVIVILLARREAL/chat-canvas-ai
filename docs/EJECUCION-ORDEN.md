# EJECUCION-ORDEN — Checklist de construcción (orden exacto)

> **Producto:** Canvas AI · **Estado:** v1.0 · 2026-08-25
> Este documento es la **navegación** del plan: qué construir en qué orden, fase por fase, hasta v1.0. La fuente de verdad de cada fase es la [MATRIZ](./SDDs/SDD-001-plan-base/MATRIZ-FASES-PRUEBAS.md). Regla: **no avanzar sin cerrar el gate anterior** (gate = suite humana Playwright verde + evidencia).

## MVP-1 — Base operativa (semanas 1-6)

1. **Etapa 0** — 0.1 schema+migraciones → 0.2 event_stream → 0.3 secretos BYOK → 0.4 sandbox → 0.5 OpenAPI → 0.6 i18n infra
2. **Chat** — A.0 proyectos scope → A.1 appshell → A.2 persistencia → A.3 provider+BYOK → A.4 UX chat → A.5 medidor → A.6 config → A.7 encargo → A.8 resume → A.9 ramas
3. **Runtime** — C.1 Reasonix → C.2 router/telemetría → **C.3 robustez+circuit breaker** → **H.9a sandbox** → C.5 caché → C.6 Ollama → C.7 registro proveedores
4. **Editor (mínimo)** — B.1 workspace virtual → B.2 Monaco → B.3 live preview sandboxed → B.5 fast apply
5. **Transversales** — T.SEC / T.A11Y+i18n / T.ONB / I.1 review básico
6. **Cierre MVP-1** — E.1 E2E real + E.2 chaos + E.3 pulido → **GATE MVP-1** (PRD F1-F6)

## MVP-2 — Memoria + Skills + Resultados (semanas 7-14)

7. **Memoria** — D.1 ledger → D.2 knowledge+lock → D.3 memory rail → D.4 gobernanza → D.5 índice semántico → D.6 router+shards → D.7 blame-rung → D.8 memorias multi-tipo
8. **Skills** — G.1 CRUD → G.2 editor+tool-gating → G.3 compilador → G.4 laboratorio → G.6 rutinas → **G.7 identidad viva (avatares/bio)**
9. **Pruebas** — H.1 tareas+criterios → H.2 testrunner → H.5 shadow workspace → H.6 auto-corrección → H.3 resultados en canva → H.4 escalado → H.7 best-of-N → H.8 cuarentena → H.9b computadora persistente
10. **Kanban** — KR.1 tablero → KR.2 bloques animados → KR.4 evidencia → KR.5 filtros/salud (KR.3 tras N.7)
11. **Oficina** — F.0 design system → F.1 fundaciones ReactFlow → F.2 nodos vivos → F.4 tareas/kanban sobre canva → F.7 ⌘K → F.6 perf 60fps
12. **Cierre MVP-2** — E.2/E.3 re-corridos → **GATE MVP-2** (PRD F7-F11)

## MVP-3 — Automatización + Nube + Mercado (semanas 15-24)

13. **Automatización** — F.3 edges → F.5 identidad IA → (resto del Etapa 6 completo): deploy-spec, compiler, multi-runtime, conectores
14. **Nube 24/7** — N.1-N.6 orquestación + **N.7 modo nube** + **S.1/S.2 despliegue** + AUTH nube + RLS
15. **Sync** — L.1 SyncHub → L.2 cliente sync → L.4 push dispatcher
16. **GitHub** — M.1 auth/repos → M.2 ciclo git → M.3 PRs/issues
17. **Marketplace** — O.1 bundles → O.2 MCP público → **O.3 release v1.0**
18. **Targets** — MP.1 desktop CI → MP.2 iOS (gen/apple) → MP.3 Android release → MP.4 web → MP.5 servidor nube → MP.6 sync
19. **Cierre v1.0** — LAUNCH-CHECKLIST completo + T.BIZ + GATE T → **v1.0.0**

## Post-v1 (no bloquean — Q6)

Control Room completo (CR.1-5) · Segundo Cerebro profundo (VI) · Voz (K) · 3D/VR · Dopamina (U) · Consejo de Expertos (VI.5+). Se diseñan y referencian, pero **no entran** a MVP-1/2/3.

## Definición de "listo" (cada fase)

**DoR (antes de empezar):** mini-SDD o slice · fila en MATRIZ · filas en [COVERAGE-GUI](./COVERAGE-GUI.md) · ANALYZE con 5 sub-agentes en paralelo · contrato de pruebas.

**DoD (para cerrar):** SDD ✓ (si es feature) → fila en MATRIZ ✓ → tests unit/integration verdes → E2E humano (móvil+desktop, es+en) con video en `evidence/` → `pnpm check:all`+`cargo test` → CHANGELOG+ESTADO actualizados → commit semántico. **Resultado funcional operado por el humano (no "compila").**

**Milestone M0** (primera entrega): cerrar la [Etapa 0](./ETAPA-0-IMPLEMENTACION.md) — server persistente, ledger inmutable, BYOK, sandbox, OpenAPI, i18n infra. Es el primer hito que demuestra que la base técnica es real.
