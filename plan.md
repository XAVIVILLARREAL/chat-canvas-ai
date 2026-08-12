# PLAN MAESTRO — Empresa Dev (de terminal SSH a empresa autónoma de desarrollo)

> **Propósito:** mapa único de ejecución. Fuente de verdad de fases/gates:
> `docs/SUPER_PLAN.md` (verificable). Rutina obligatoria por fase (skill `dev`):
> **SDD → TDD → CI → Gate**. Cero código sin seguir esta rutina.
> Última verificación de código: **2026-08-11** (commit `2c88598`; docs ESTADO y SUPER_PLAN desactualizados respecto a `empresa_autonoma/`).

---

## 0. Realidad verificada hoy (base del plan)

- ✅ Etapas 1–5 automatizadas y verdes (terminal/SFTP/hub/canva, agentes voice/evidencia, editor, canva `.md`, skills+lab, grafo 2D/3D — 124 tests, analyze 0, E2E WebView2, benchmark 5.000 nodos ~8 ms).
- ✅ **Repos de referencia frescos y completos** (Apache-2.0 buzz y herdr → copiable; zed GPL-3.0 → solo conceptos): herdr `ddffb6e`, buzz `be48ce9`, zed `daec37b` (submodule).
- ✅ **`empresa_autonoma/` ya tiene Fase 0 committeada** (`faf129f`, SDD-115): grafo LangGraph plan→implementar→revisar→aprobación→merge, roles, tests headless. **ESTADO.md/SUPER_PLAN.md no lo reflejan** (lo dicen "(reservado)") — corregir al cerrar esta tarea.
- ✅ De `copia.md` ya implementado: 1.1 (detector), 1.4 (contratos JSON), 2.4 (IDs estables), 1.3/2.1/Z4 (skills en Etapa 4b).
- ⬜ Etapa 6 (Vibecoding) = siguiente; Etapa 7 no iniciada; Etapa 8 en cola.
- ⬜ Gates manuales pendientes (mano humana, no bloquean código): ver §2.

---

## 1. Rutina obligatoria (skill dev)

1. Leer AGENTS.md y SUPER_PLAN antes de tocar código.
2. **SDD primero:** `docs/SDDs/SDD-<next>-<nombre>.md` (objetivo, flujo, contratos, tests).
3. **TDD:** test que falla → código que lo pasa.
4. **CI local:** `flutter analyze` (0 issues) + `flutter test --exclude-tags integration` (+ `melos analyze`/`melos test` si toca packages).
5. Integration real → `@Tags(['integration'])`, no corre en CI.
6. Cerrar fase solo con **gate cumplido + evidencia + prueba en ≥2 plataformas**.

---

## 2. Acciones inmediatas (no bloqueantes, 1 sesión)

- [x] **Actualizar `docs/ESTADO.md` y `docs/SUPER_PLAN.md`** con la Fase 0 real de `empresa_autonoma/` (commit `faf129f`) y material de referencia verificado. *(2026-08-11)*
- [x] Versionar deuda del monorepo: `melos.yaml`, `packages/*/pubspec.yaml` — **verificado YA versionados** (no había deuda real; docs antiguos engañaban).
- [x] **SDD-118 Etapa 6 vibecoding escrito** (`docs/SDDs/SDD-118-etapa6-vibecoding.md`) con slices TDD 6.1–6.4.
- [ ] Gates manuales de fases ya verdes (evidencia para cerrar fases):
  - Etapa 4: 5 notas enlazadas + backlinks + persistencia tras reabrir.
  - Etapa 4b: ciclo real skill (crear → probar → exportar → reiniciar opencode → trigger).
  - Etapa 5: cargar este repo en desktop y navegar grafo 2D/3D.
  - Etapa 3: integration SFTP hash real + dogfood 2 sesiones.
  - Etapa 2: voz con micrófono real + 3 prompts capturados.
  - Etapa 1: batería 24h + publicación (Play/Store/releases).

---

## 3. Etapa 6 — Vibecoding (⬜ **en curso: slice 6.1 ✅ hecho**)

**Objetivo:** el agente IA trabaja dentro del canva; cada propuesta = nodo-diff aceptable/rechazable. (SDD-118 escrito.)

- [x] SDD-118 + package `vibecoding_core` **slice 6.1** (17 tests verdes, analyze 0,
      melos analyze/test OK): `DiffParser` (unified diff puro), `PatchProposal`
      (serializable, transiciones pending→applied/rejected/reverted/failed),
      `VibecodingPipeline` (aislamiento por copia, conflictos, anti-traversal).
- [x] **Slice 6.2** ✅ — `DiffPreview` + `VibecodingScreen` (chat + nodo-diff con
      Aceptar/Rechazar/Revertir), adaptador `AgentCommandRunnerAdapter`,
      `workingDirectory` en AgentCommandRunner, menú "Vibecoding" en el canva.
      8 tests nuevos — app 132 verdes, analyze 0, melos OK. *(2026-08-11)*
- [x] **Slice 6.3** ✅ — `VibecodingStore` (historial JSON, dir override para
      tests), VibecodingScreen carga/persiste, nodo `proposal` en el canva
      (tile en menú, color por estado, tap → `ProposalNodeScreen` con
      Aceptar/Rechazar/Revertir). 11 tests nuevos — app 143 verdes, analyze 0,
      melos analyze/test OK.
- [x] **Slice 6.4** ✅ — `vibecoding_integration_test.dart` (`@Tags(['integration'])`):
      opencode real sobre fixture `test/fixtures/vibe_demo/` → propuesta →
      aplicar → `dart run test/todo_check.dart` pasa. Fix: `AgentCommandRunner`
      cierra stdin (EUNKNOWN de node). Z6 documentado como cubierto (aislamiento
      + diff + anti-traversal). *(2026-08-11)*
- [ ] **Dogfood:** una feature real de **este repo** implementada 100% vía vibecoding.

**Fases de comprobación (gate):**
- [ ] Unit: pipeline parche→nodo-diff; transiciones aceptar/rechazar/revertir sin estado residual.
- [ ] Widget: chat + nodo-diff; aplicar y revertir.
- [ ] Integration: agente real propone cambio sobre fixture → tests siguen verdes.
- [ ] **Dogfood:** una feature real de **este repo** implementada 100% vía vibecoding desde la app.

---

## 4. Etapa 7 — SDD++ + Playwright E2E (⬜)

**Objetivo:** gates automáticos por fase; cada feature arranca como SDD enlazado en el canva.

- [ ] Playwright CLI contra `flutter build web` (`tool/e2e_web.ps1`).
- [ ] `patrol_cli` para flujos mobile.
- [ ] CI GitHub Actions: analyze + tests + E2E web por PR.
- [ ] Refactor Riverpod (copia 1.2, post-Etapa 7) y motor de workflows YAML (copia 2.2 / `buzz-workflow`).

**Fases de comprobación:**
- [ ] E2E web automático sin intervención humana (conectar SSH → abrir → editar → guardar).
- [ ] Patrol: mismo flujo crítico en Android.
- [ ] CI: un PR con feature + SDD + tests + E2E pasa completo.

---

## 5. Etapa 8 — Supervitaminas (cola aprobada 2026-08)

| # | Idea | Gate |
|---|---|---|
| 8.1 | Sync CRDT (y-crdt/Automerge en Dart) | 2 dispositivos offline editan → convergen sin pérdida |
| 8.2 | Canva = espejo en vivo del grafo LangGraph | Nodo-agente cambia estado y el canva lo anima en vivo |
| 8.3 | Hub elegible con failover (batería <20% → pve toma el rol) | Sync continúa vía pve sin tocar la app |
| 8.4 | SSH proxy opcional desde el hub (llaves nunca salen del hub) | Laptop sin llaves conecta vía proxy; llave jamás aparece |
| 8.5 | Warp-mode: historial fuzzy + snippets sync + autocompletado local | Comando de ayer aparece en 2 pulsaciones de Ctrl+R |
| 8.6 | Canva quad-tree culling + LOD/clustering por zoom | 10.000 nodos, zoom-out total, ≥30fps |

**Comprobación transversal:** ADR antes de 8.1 y 8.3 (modelo de eventos de buzz ARQ vs RPC de zed `collab/` → alimenta ADR 3.1 de copia.md).

---

## 6. Visión — Empresa Autónoma de Desarrollo (CrewAI + LangGraph) 🏢

> **Estado:** Fase 0 **ya existe y está committeada** (`faf129f`, SDD-115). La app NUNCA ejecuta agentes; solo habla con este servicio (`empresa_autonoma/`, FastAPI+WS puerto 8100).

### Fase 0 — Fundación (✅ hecha, falta registrar en docs)
Grafo base `plan→implementar→revisar→aprobación→merge`, roles, tests headless sin LLM.
**Comprobación:** `pytest` verde en `empresa_autonoma/tests/test_graph.py`.

### Fase 1 — Crews a medida (⬜)
Roles (producto, dev, QA, devops) + delegación; usuario arma equipos en la app → **manifiesto versionado**; cada agente = nodo del canva.
**Comprobación:** un equipo se arma en la app, se versiona como manifiesto y un crew ejecuta una tarea mock con su grafo headless.

### Fase 2 — Paralelismo real (⬜)
`akickoff_for_each` + API `Send` de LangGraph; aislamiento por worktree; cada empresa = subgrafo paralelo.
**Comprobación:** 2 tareas ejecutan en paralelo sobre worktrees distintos sin pisarse.

### Fase 3 — Oficina animada estilo juego (⬜)
Vista estilo juego con personajes/estados (glassmorphism neón del proyecto). El canva ES la oficina.
**Comprobación:** un agente pasa trabajando→bloqueado→en revisión y la animación se ve en vivo.

### Fase 4 — Integración real con repo (⬜)
Leer issues/PRs, crear ramas y PRs reales — **todo con aprobación humana** (`interrupt()`).
**Comprobación:** una tarea llega de un issue real, la empresa la implementa y deja el PR en borrador esperando aprobación.

### Fase 5 — Autonomía supervisada (⬜)
End-to-end con gates de aprobación, checkpoints (`Crew.from_checkpoint()`) y trazabilidad completa.
**Comprobación:** la empresa ejecuta una épica completa end-to-end; cae la máquina a mitad y se reanuda desde el checkpoint sin perder trabajo.

### Tracker tipo Plane/Linear (transversal)
Backlog→sprint→tablero; cada tarjeta = nodo del canva (To do→Doing→Review→Done); dependencias/blockers visibles; multi-empresa en paralelo sobre worktrees.
**Comprobación:** mover una tarjeta de columna cambia el estado del nodo y dispara el grafo.

---

## 7. Horizonte post-visión — IDE visual de vibecoding (exploración, sin código)

- Etapa H1: file tree + editor básico local/SFTP (base ya existe).
- Etapa H2: canva de ideas `.md` + backlinks (base ya existe).
- Etapa H3: gestor visual de skills + laboratorio (base ya existe) + **grafo de skills con dependencias/exclusiones**.
- Etapa H4: grafo del proyecto 2D → 3D (base ya existe; 3D = WebView + Three.js en desktop, fallback 2D mobile).
- Etapa H5: vibecoding full (Etapa 6 del plan) + diff del agente como nodo-canva.
- Etapa H6: SDD++ + Playwright E2E por feature.
- **Regla:** nada de esto bloquea Etapas 6–8; se rediscute al cerrar la visión grande.

---

## 8. Material de referencia por fase (repos clonados)

| Fase | Fuente | Uso |
|---|---|---|
| Etapa 6 | `buzz/crates/buzz-acp/` · `reference/zed/crates/streaming_diff/` · `zed/docs/src/ai/*.md` | Colas, nodo-diff, permisos/sandbox, ACP, worktrees |
| Etapa 7 | — | Playwright CLI + patrol_cli |
| Etapa 8 | `buzz/ARCHITECTURE.md` · `zed/crates/collab/` (concepto) | ADR hub eventos firmados (3.1 de copia.md) |
| Visión 1–5 | `buzz/crates/buzz-persona/PERSONA_PACK_SPEC.md` · `herdr/src/remote.rs` · `herdr/workers/plugin-marketplace/` | Manifiestos de equipo, agents remotos, marketplace (2.1/3.2/3.3 de copia.md) |
| ADR 3.1 | `buzz/ARCHITECTURE.md` (Nostr eventos) vs `zed/crates/collab/` + `crates/proto/` (RPC/WS) | Decidir modelo de eventos del hub |

**Licencias:** buzz/herdr Apache-2.0 (atribuir origen en cada archivo). zed GPL-3.0 → SOLO conceptos/decisiones, cero código crudo.

---

## 9. Definition of Done global

- [ ] CI verde (analyze + suite + gate de la fase).
- [ ] Probado en ≥2 plataformas (Android + desktop).
- [ ] Gate de la fase cumplido (checklist arriba).
- [ ] Evidencia (capturas/logs) adjunta en el commit de cierre.
- [ ] `docs/ESTADO.md` y `docs/SUPER_PLAN.md` actualizados al final de cada sesión.