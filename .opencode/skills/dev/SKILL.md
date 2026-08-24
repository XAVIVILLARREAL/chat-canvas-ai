---
name: dev
description: Guía de desarrollo por fases del proyecto Empresa Dev. Usa cuando haya que implementar o continuar features, saber qué fase sigue, buscar el plan o sus pruebas de comprobación (gates), o iniciar una sesión de trabajo. Trigger: "dev", "super plan", "plan", "siguiente fase", "implementar", "gate", "probar", "progreso".
---

# Skill dev — Desarrollo por fases con pruebas de comprobación

Este proyecto se trabaja **por fases**, nunca a saltos. Cada fase del Plan Base (SDD-001) tiene su **gate** (pruebas de comprobación + suite humana). Cero código sin seguir esta rutina.

## 1. Saber dónde estamos

1. Leer `docs/SDDs/SDD-001-plan-base/README.md` (plan maestro + ORDEN de ejecución) y `docs/SDDs/SDD-001-plan-base/MATRIZ-FASES-PRUEBAS.md` (TODAS las fases con sus pruebas — regla #10: una fase sin fila en la matriz no se construye).
2. Leer `docs/ESTADO.md` (dónde quedamos) y `AGENTS.md` (reglas obligatorias: SDD-002, 4 capas, responsive total, client-first).
3. Determinar la fase/gate pendiente. Si el usuario pide algo que no es la fase actual, señalar el desvío antes de codificar.
4. Marcar avance en `docs/ESTADO.md` + `docs/CHANGELOG.md` conforme se cumpla (docs auto-gestionadas).

## 2. Rutina obligatoria por feature (spec-driven, SDD-002)

1. **SPEC primero:** la fase del SDD-001 ya define comportamiento observable + criterios. Si es feature nueva: mini-SDD en `docs/SDDs/SDD-XXX-nombre.md` antes de tocar código.
2. **TESTS primero:** escribir las 4 capas que fallan (Unit vitest · Integration cargo · E2E Playwright · HUMANA) antes que la implementación.
3. **IMPL:** código mínimo que pone TODO en verde.
4. **CI local al cerrar la feature:**
   ```bash
   pnpm check:all          # tsgo + biome + oxlint
   cargo test --workspace  # crates/core + crates/server
   pnpm test:e2e           # Playwright (chromium + webkit)
   pnpm test:e2e:human     # suite humana (gates)
   ```
5. Los tests con APIs reales (DeepSeek/GitHub/Ollama) van etiquetados y SOLO en gates (presupuesto máx $20/gate; el resto mock-first ~$0).

## 3. Cerrar una fase (gate)

- [ ] Todos los criterios de la fase en la MATRIZ cumplidos (4 capas).
- [ ] Fase GUI ⇒ E2E humano en móvil 375 Y desktop 1440 (RESPONSIVE TOTAL — no existe pantalla "solo desktop").
- [ ] Suite completa verde (check:all + cargo + e2e).
- [ ] Evidencia: video + `evidence/` + commit con la demo.
- [ ] ESTADO/CHANGELOG actualizados.
- [ ] Commit de cierre de fase con la evidencia adjunta.

La fase **no se cierra sin su gate**. Si un gate depende de algo externo (red, llaves, dispositivos), dejarlo pendiente documentado y continuar con lo que no bloquee.

## 4. Dogfood

Varias fases exigen **dogfood**: este mismo proyecto usado desde la app (editar el repo, definir skills, implementar features vía vibecoding). Cuando aplique, registrarlo explícitamente como evidencia del gate en el commit.

## 5. Fases en una línea (Plan Base SDD-001 v3.5)

| Etapa | Qué es | Gate clave |
|---|---|---|
| 1 (A) | Chat núcleo Codex + tenants | Chat real streaming + historial persistente + perillas |
| 2 (B) | Sidepanels Lovable | Archivos aparecen + preview en vivo |
| 3 (C) | Runtime Reasonix+DeepSeek+Ollama+API | 3 motores, costos visibles, cancelación robusta |
| 4 (D) | Memoria V3Code | Recuerda decisiones entre sesiones + gobernanza |
| 5 (E) | Cierre Base | Tag `plan-base-v0.1` — DoD completo |
| 6 (F) | Canva Oficina | Nodos-agentes animados en vivo |
| 7 (G) | Skills Lab | Crear/probar/exportar skills sin YAML |
| 8 (H) | Motor de pruebas | Agentes demuestran con tests, no promesas |
| 9 (I) | Revisión auto + Superposición | El sistema detecta y corrige solo |
| 10 (J) | Grafo 3D repo-map | Repo en <1000 tokens + visual 3D |
| 11 (K) | Voz | Hablas, los agentes responden |
| 12 (L) | Sync + Co-Work | Continúas donde dejaste en cualquier dispositivo |
| 13 (M) | GitHub nativo | Push/pull/PRs sin terminal |
| 14 (N) | Empresas autónomas | Empresa completa operada por agentes |
| 15 (O) | Marketplace + v1.0 | Empresas empaquetables, release 1.0 |
