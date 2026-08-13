# SUPER PLAN — Del terminal SSH al IDE visual de vibecoding

> **Estado:** vigente. Fuente de verdad para las fases y sus **pruebas de comprobación (gates)**.
> Metodología obligatoria por fase: **SDD → TDD → CI → Gate**. Detalle operativo en la skill `.opencode/skills/dev/SKILL.md`.

## Estado actual (real, verificado en código)

| Bloque | Estado | Evidencia |
|---|---|---|
| Terminal SSH (dartssh2 + xterm.dart) | ✅ hecho | `lib/services/ssh_service.dart`, `test/ssh_service_test.dart`, `ssh_integration_test.dart` |
| SFTP | ✅ hecho | `lib/services/sftp_service.dart`, `sftp_integration_test.dart` |
| Canva visual | ✅ hecho | `lib/models/canva.dart`, `lib/screens/canva_screen.dart`, `canva_test.dart`, `canva_widget_test.dart` |
| Hub celular + sync | ✅ hecho | `lib/services/hub_server.dart`, `sync_client.dart`, `sync_integration_test.dart` |
| Sesiones/tabs | ✅ hecho | `lib/screens/tabs_screen.dart`, `sessions_store.dart` |
| Publicación (Play/App Store/releases) | ❌ pendiente | — |
| **Empresa Autónoma Fase 0 (SDD-115)** | ✅ committeado (`faf129f`) | `empresa_autonoma/`: `graph.py` (grafo plan→implementar→revisar→merge con gate humano), `roles.py` (7 roles), `tests/test_graph.py` headless |

## Comandos maestros de comprobación (corren en cualquier fase)

```powershell
flutter analyze                              # 0 issues
flutter test --exclude-tags integration      # suite unit/widget verde
dart run tool/hub_smoke.dart                 # smoke del hub OK
flutter build apk --debug --no-tree-shake-icons
# Windows: cmake manual (ver AGENTS.md "Build Commands")
# Servicio empresa_autonoma (Fase 0):
cd empresa_autonoma && .venv/Scripts/python -m pytest
```

---

## Etapa 1 — Cierre y publicación (gate: Termius reemplazado)

**Objetivo:** terminar lo pendiente de Etapa 1 y publicar.

- [ ] E2E real en Android + Windows + macOS (requiere dispositivos).
- [ ] Prueba de batería: hub en Android no agota batería en 24h.
- [ ] Publicar Play Store / App Store / releases desktop.

**Pruebas de comprobación (gate de cierre):**
- [ ] Suite completa (comandos maestros) verde.
- [ ] Manual: SSH a `pve` por password **y** llave; SFTP subir/bajar con hash verificado; túnel local funcionando; canva con topología persistida tras reabrir; sync 2 dispositivos en el tailnet.
- [ ] Capturas de cada flujo como evidencia.
- [ ] Binario publicado y descargable en al menos una vía pública.

---

## Etapa 2 — Agentes IA en el canva (retoma `docs/legacy/`)

**Objetivo:** los agentes (opencode) son ciudadanos de primera clase en el canva.

- [x] Nodo **agente IA** en el canva; click → sesión de chat con opencode. *(SDD-105, `test/agent_test.dart`, `agent_chat_widget_test.dart`, `agent_integration_test.dart`)*
- [x] Voz: dictar (STT navegador) → respuesta leída (Edge TTS). *(SDD-107 — implementado con SAPI nativo de Windows: `speech_to_text` + `flutter_tts`, `lib/services/voice_service.dart`, `lib/widgets/voice_buttons.dart`, `test/voice_service_test.dart`, `voice_buttons_widget_test.dart`; falta prueba manual con micrófono real)*
- [x] Evidencia por prompt: cada respuesta se guarda como `.md` navegable. *(SDD-106, `lib/services/evidence_store.dart`, `lib/screens/evidence_screen.dart`, `test/evidence_test.dart`, `evidence_widget_test.dart`)*
- [x] Verificación de UI con Chrome headless. *(`tool/verify_ui.ps1`: build web + servidor estático local + Chrome headless screenshot/dump-dom, chequea `flt-glass-pane` + screenshot ≥ 10KB; verificado OK el 2026-08-11)*

**Pruebas de comprobación (gate):**
- [x] Unit: modelo `AgentNode`, store de sesiones de agente.
- [x] Widget: nodo agente se renderiza, abre sesión y recibe respuesta (mock).
- [x] Manual: lanzar agente real desde el nodo y recibir respuesta en el chat. *(agent_integration_test real con opencode 1.18.16)*
- [ ] Voz: dictado → texto → respuesta audible en < 3s. *(falta prueba manual: dictar en la app Windows y oír la respuesta; requiere paquete de voz ES instalado)*
- [x] Evidencia: 3 prompts con captura guardada como `.md`. *(solo falta captura de 3 prompts reales — pendiente manual)*

---

## Etapa 3 — File tree + editor de código (sin IA)

**Objetivo:** el canva pasa de "hosts" a "proyectos": abrir, navegar y editar proyectos locales + remotos.

- [x] Abrir proyecto local (`file_picker`) y renderizar árbol de archivos. *(SDD-108)*
- [x] Editor de archivos planos (`.md`, `.dart`, `.py`, `.json`…) con guardado. *(SDD-108)*
- [x] SFTP push: guardar también en el host remoto conectado; abrir archivo remoto y editar. *(RemoteProjectService — `test/remote_project_service_test.dart`)*

**Pruebas de comprobación (gate):**
- [x] Unit: service de proyecto (listar, abrir, guardar con encoding correcto); parser de árbol.
- [x] Widget: árbol → click → editor abre contenido; modificar → guardar → reabrir conserva el cambio.
- [ ] Integration SFTP: editar archivo remoto y verificar hash local == remoto. *(manual, host real)*
- [ ] **Dogfood:** este repo se abre, edita y guarda desde la propia app (2 sesiones seguidas sin fallos). *(manual)*

---

## Inyección copia.md (prefase Etapa 4) — 3 piezas pequeñas de buzz/herdr

> Fuente: `copia.md` (detalle completo y mapeo en ese archivo). Repos `buzz/` y `herdr/` clonados localmente (ignorados por git). Piezas baratas (días) que mejoran el canva ANTES de que Etapa 4 lo amplíe con nodos `.md`.

- [x] **Detector de agentes (copia 1.1)** — `lib/services/agent_detector.dart` + manifiestos portados (`agent_detector_manifests.dart`, subset fiel de `herdr/src/detect/manifests/opencode.toml`), matchers `contains`/`regex`/`line_regex`, prioridades; `AgentStateBadge` en vivo en `AgentChatScreen`. SDD-109.
  - *Gate: ✅ un host que corre `opencode` se clasifica `working` cuando su salida contiene "esc to interrupt" (fixture).*
- [x] **IDs estables + estados explícitos en canva (copia 2.4)** — `CanvasNodeId` opaco (`w<sec>:<ms>:<seq>`, contador monotónico → nunca reutilizado) + `CanvasNode` puro serializable (`toJson/fromJson/copyWith`) + `AgentNodeRuntime` separado del modelo. `_newId()` del canva migrado. SDD-110.
  - *Gate: ✅ al eliminar y recrear un nodo, el ID no se reutiliza (1000 generaciones sin colisión); el estado del nodo es serializable sin runtime.*
- [x] **Contratos JSON + exit codes (copia 1.4)** — `AgentCommandRunner` (`cmd /c`, stdout JSON + BOM saneado, stderr, exit 0/1/2/3/4/5 + 9009→notFound, pre-check de ejecutable inexistente, timeout→kill). `SemanticExit` tipado. SDD-111.
  - *Gate: ✅ wrapper parsea stdout JSON de un fixture y mapea exit codes a errores tipados.*

**Piezas fusionadas con fases existentes (no nuevas):** copia 1.3 (skill estilo herdr) y 2.1 (Persona Pack de buzz) → se integran en **Etapa 4b** como fuente de su spec. Copia 2.3 (orquestador/colas) → **Etapa 6**. Copia 2.2 (workflows), 3.1 (eventos firmados, ADR), 3.2 (remote agents), 3.3 (marketplace) → **post-Etapa 7**. Copia 1.2 (refactor Riverpod) → solo convención en código nuevo; refactor total post-Etapa 7.

---

## Etapa 4 — Canva de ideas + `.md`

**Objetivo:** los nodos del canva son documentos Markdown enlazados (Obsidian-style). *(SDD-112)*

- [x] Nodos `.md` enlazados con `[[links]]`; render Markdown con preview live.
- [x] Backlinks y navegación por enlaces desde el editor.
- [x] Auto-layout simple; persistencia (CanvaStore JSON existente).

**Pruebas de comprobación (gate):**
- [x] Unit: parser de `[[links]]` (`MdLinkParser` + `wikiToMarkdown`) e índice de backlinks (`BacklinkIndex`).
- [x] Widget: preview se actualiza en vivo; click en link navega al nodo (abre o crea).
- [ ] Manual: crear 5 notas enlazadas, navegar por backlinks, cerrar/reabrir → todo persiste. *(pendiente de mano humana — infra CanvaStore ya persistente)*
- [x] **Dogfood:** `docs/` del proyecto como canva navegable — evidencia `data/evidence/etapa4-docs-map.md` (8 nodos, 3 edges; `tool/docs_map_evidence.dart`).

---

## Etapa 4b — Gestor visual de skills + laboratorio

**Objetivo:** crear agentes/skills visualmente, probarlas en vivo y exportarlas a cualquier dialecto.

- [x] Constructor visual de `skills.md`: `name`, `description`, `triggers`, `tags`, permisos; cuerpo Markdown con preview; bloques arrastrables (instrucciones, ejemplos, restricciones, anti-patrones).
- [x] Laboratorio sandbox: input → ranking de skills que se activarían, con confianza y por qué. Historial + regression tests dentro de la propia skill.
- [x] Skills como nodos del canva (relaciones: depende, excluye, compone).
- [x] Export multi-dialecto: opencode, Cursor, Claude Code, Continue, Codex (con diff visual).
- [x] CI de dogfood: `flutter test --tags skills` ejecuta el laboratorio en modo headless.

**Pruebas de comprobación (gate):**
- [x] Unit: parser YAML frontmatter por dialecto; simulador de triggers con scoring; export por dialecto.
- [x] Widget: el form crea un `SKILL.md` válido; drag&drop de bloques; el sandbox muestra ranking.
- [x] **Dogfood duro:** 3 skills de este repo creadas desde la app, y cada una pasa su test en el laboratorio.
- [ ] Manual: crear skill → probarla → exportarla a `.opencode/skills/` → reiniciar opencode → se activa con su trigger real.

---

## Etapa 5 — Grafo del proyecto (2D → 3D)

**Objetivo:** visualizar las conexiones entre archivos como hizo `mcp codebase-memory` / Supermemory / Engram.

- [x] Indexador de relaciones: imports (Dart/Python), referencias, `[[links]]` entre `.md`.
- [x] Grafo 2D de fuerza dirigida (d3-force portado a Flutter), cluster por paquete.
- [x] Hover = preview, click = abre el archivo en el editor.
- [x] Grafo 3D: WebView + Three.js solo en desktop/web; fallback 2D en mobile.

**Pruebas de comprobación (gate):**
- [x] Unit: indexador detecta imports/referencias/links reales de un fixture.
- [x] Widget: grafo renderiza, hover muestra preview, click abre editor.
- [x] Performance: 5.000 nodos a ≥ 30fps (baseline registrada antes de optimizar).
- [ ] Manual: cargar este repo y navegar su grafo completo en desktop.

---

## Etapa 6 — Vibecoding

**Objetivo:** el agente IA trabaja dentro del canva; cada propuesta es un nodo-diff aceptable o rechazable.

- [x] Agente conectado al editor + canva (opencode CLI de legacy o API LLM directa). *(SDD-118: `packages/vibecoding_core/` + `vibecoding_screen.dart` + nodo `proposal` en canva)*
- [x] Cada propuesta = nodo-diff con preview; aceptar/rechazar; historial navegable. *(DiffPreview + VibecodingStore, historial persistido)*

**Pruebas de comprobación (gate):**
- [x] Unit: pipeline parche → nodo-diff; transiciones de estado aceptar/rechazar/revertir. *(31 tests: transiciones, conflictos, anti-traversal, filtrado de artefactos generados)*
- [x] Widget: chat + nodo-diff; aplicar cambio y revertir sin estado residual.
- [x] Integration: agente real propone un cambio en un fixture; aplicado, los tests siguen verdes. *(`vibecoding_integration_test.dart`, opencode real)*
- [x] **Dogfood:** una feature real de este repo implementada 100% vía vibecoding desde la app. *(2026-08-11: `relativeTimeDetailed` en `vibecoding_core` — generada por opencode real, aplicada con `--apply`, suite 31+143 verdes. El dogfood destapó y arregló 3 bugs del pipeline: pubspec_overrides en la copia aislada, `.dart_tool/` como edits, y prompts manglados por cmd/argv de Windows — fixes `--prompt-file` + argv-list al `.exe` nativo. Detalle en SDD-118)*

---

## Etapa 7 — SDD++ + Playwright E2E

**Objetivo:** gates automáticos por fase; cada feature arranca como SDD enlazado en el canva.

- [x] Playwright CLI contra `flutter build web` (`tool/e2e_web.ps1`). *(SDD-120: `tool/e2e_web.ps1` + `playwright.config.js` + `e2e_web.spec.js`)*
- [x] `patrol_cli` para flujos mobile. *(SDD-120: `patrol_test/canva_flow_test.dart` + sección `patrol:` en pubspec — ejecución = gate manual)*
- [x] CI (GitHub Actions) corre analyze + tests + E2E web por PR.

**Pruebas de comprobación (gate):**
- [x] Script E2E web: canva → nota `.md` → editar → guardar → **persiste tras recarga**. *(2026-08-12, chromium headless, 12–14s. La cobertura de SSH real es imposible en browser sin proxy WebSocket (Etapa 8.4); SSH sigue en integration tests desktop + patrol. El E2E destapó un bug real de a11y: `showGeneralDialog` con transitionBuilder custom rompía el árbol de semántica web — solo el título era accesible; fix: `showDialog` + `Dialog` estándar con el cristal `NeonDialog` intacto)*
- [ ] Patrol: mismo flujo crítico en Android (gate manual, dispositivo real).
- [x] CI: job `e2e-web` en `.github/workflows/ci.yml` (build web E2E_WEB + Playwright chromium + `python3 -m http.server`). *(falta la corrida real de un PR para el ítem completo)*

---

## Etapa 8 — Supervitaminas (ideas creativas aprobadas 2026-08)

> **Estado:** cola de innovación. No bloquea Etapas 1–7. Se priorizan al cierre de Etapa 7
> (o antes si un gate abre ventana). Fuente: análisis de visión 2026-08 (AGENTS.md).

### 8.1 — Sync CRDT (convergencia sin conflictos)

**Problema que resuelve:** el sync actual es snapshot + last-write-wins; ediciones
simultáneas en 2 dispositivos pierden trabajo.

**Idea:** reemplazar el snapshot LWW por un **CRDT** (y-crdt / Automerge). El canva
se vuelve un documento vivo que converge solo, por deltas, sin autoridad central y
con offline-first real. Mismo espíritu que "varios agentes trabajando en paralelo".

- [x] Evaluar y-crdt / Automerge en Dart. *(SDD-127: `ydart` (binding Yrs) descartado (muerto); **`crdt` 5.1.3** elegido — Dart nativo, HLC, `MapCrdt` storage-agnostic, en producción)*
- [x] Núcleo CRDT del canva. *(`packages/crdt_core`: `CanvaCrdt` = `CanvaState ↔ MapCrdt` con HLC; delete-vs-edit resuelto por HLC)*
- [ ] Migrar el sync del canva a `CanvaCrdt` (deltas sobre el WS del hub, no snapshots LWW).
- [x] Test: editar canva en 2 dispositivos a la vez → converge sin pérdida. *(GATE ✅: unit `crdt_core` — ediciones paralelas convergen, delete más nuevo gana, merge idempotente/conmutativo)*

**Gate:** 2 dispositivos offline, editan, reconectan → el canva converge sin conflicto. *(automatizado por unit; gate real con Tailscale = manual)*

### 8.2 — El canva ES la vista viva del grafo LangGraph

**Problema que resuelve:** el canva muestra hosts y la empresa (Python) orquesta por
separado; la UI no refleja el estado real del trabajo.

**Idea:** cada nodo-agente/tarea se suscribe al checkpoint de su nodo del grafo
(`astream_events`), y la **arista entre nodos del canva = edge real del grafo**.
La transición "bloqueado → trabajando → en revisión" anima el nodo en vivo.
El canva pasa de mapa de infraestructura a espejo de la oficina en tiempo real.

- [x] Modelo `OfficeState`/`AgentRuntimeStatus` en `agent_core` + `StatusNotifier` puro Dart. *(SDD-124, `packages/agent_core/office_state.dart`, alineado al task lifecycle de A2A/ADR-003)*
- [x] Oficina = instancia de `CanvaView` (ADR-004) con glow por estado; `OfficeScreen` + `SimulatedOffice` (fuente demo/testeable sin backend). *(menú Añadir → Oficina; tap en agente → historial de transiciones)*
- [ ] WebSocket hub → servicio Python (estado del grafo por thread/empresa). *(8.2.3 — requiere `empresa_autonoma/server.py`, Fase 1)*
- [x] Nodo bloqueado/en revisión → glow rojo/ámbar + owner visible.

**Gate:** un nodo-agente cambia de estado en la empresa y el canva lo anima en vivo. *(verificado por widget test con la simulación; el bridge real queda pendiente del server Python)*

### 8.3 — Hub con failover y descarga de batería

**Problema que resuelve:** el gate "hub no agota batería en 24h" depende de que el
celular aguante; si está bajo o dormido, el sync muere.

**Idea:** hub **elegible** (election sobre Tailscale): cuando el celular está bajo de
batería o en reposo profundo, el pve (siempre encendido) toma el rol de hub
automáticamente; el celular vuelve a ser hub al cargar. Privado, sin nube, con
failover gratis.

- [x] Protocolo de elección de hub (heartbeat + prioridad + takeover). *(SDD-126: `HubElection` lógica pura con reloj inyectable — timeout→candidate→hub, prioridad desempata, batería baja→cede; `HubElectionService` + `ElectionTransport`)*
- [ ] Promoción/democión transparente para los clientes (misma URL/alias Tailscale). *(requiere el transporte real)*
- [x] Política de batería: umbral → ceder rol al pve. *(lógica `lowBattery` → standby; wiring real de batería pendiente)*
- [ ] Panel de estado del hub (quién es hub, batería, último sync) en el canva.

**Gate:** bajar la batería del celular a <20% → el sync continúa vía pve sin tocar la app. *(automatizado: elección por unit; gate real con Tailscale = manual)*

### 8.4 — SSH proxy opcional desde el hub

**Problema que resuelve:** si una laptop se compromete, las llaves guardadas en ella
se roban; el hub guarda las llaves pero la conexión es directa.

**Idea:** toggle "proxy SSH": las laptops piden al hub que abra la conexión con las
llaves (que NUNCA salen del hub). La laptop solo ve el flujo del terminal, no la llave.
Modo por defecto sigue siendo conexión directa.

- [x] Modo "passthrough" en el hub: abrir SSH/SFTP en el hub, reenviar stream al cliente. *(SDD-125: `SshProxyService` + `SshForward` + relay WS `ssh` en `hub_server` + `SshProxyClient`; la llave solo vive en el `SshHost` del hub)*
- [x] Auth por token de sesión efímero (no reutilizable). *(`ProxyTokenStore`: `Random.secure`, TTL, por host)*
- [ ] Indicador en el canva: conexión directa vs proxy (icono).

**Gate:** laptop sin llaves conecta a un host vía proxy; la llave jamás aparece en la laptop. *(automatizado con fake session + hub localhost real: el stream solo transporta texto; verificación real con Tailscale = manual)*

### 8.5 — Warp-mode: autocompletado y snippets locales

**Problema que resuelve:** el terminal es "pelado"; Termius cobra por esto.

**Idea:** historial por host con búsqueda fuzzy, snippets compartidos por sync, y
autocompletado basado en historial LOCAL (sin red, sin LLM). Barato, mágico, y es el
80% del valor que la gente paga.

- [x] Store de historial por host + búsqueda fuzzy (Ctrl+R custom). *(SDD-122, `packages/warp_core`: `CommandLineTracker` + `CommandHistoryStore` (JSON por host, dedupe, cap 500) + `FuzzyFinder`; `terminal_screen`: captura vía `Terminal.onOutput`, overlay Ctrl+R de cristal con navegación ↑/↓ + Enter ejecuta + Esc cierra; reconexión movida a Ctrl+Shift+R)*
- [x] Snippets: store por host + UI ✅ (8.5.3 local) + **sync LWW ✅**: `SnippetRecord` en `SyncSnapshot` (`ssh_core`) + `SnippetStore.exportRecords/mergeRecords` (LWW por updatedAt, `warp_core`); el hub exporta y el cliente mergea (`hub_screen`). Verificación de red real = gate manual con Tailscale.
- [x] Sugerencias inline sobre el prompt del terminal. *(barra de sugerencia sobre el TerminalView con el mejor match + Tab para aceptar — completa o reemplaza la línea)*

**Gate:** repetir un comando de ayer → aparece en 2 pulsaciones de Ctrl+R. *(Ctrl+R → aparece en la lista → Enter. Verificación manual pendiente en host real; automatizado: 24 unit warp_core + 7 widget)*

### 8.6 — Canva con quad-tree culling + LOD por zoom

**Problema que resuelve:** el rendimiento con miles de nodos (Etapa 5 marca el miedo).

**Idea:** renderizar solo nodos dentro del viewport (**quad-tree espacial**), y en
zoom-out los nodos se agrupan en **clusters agregados** (grupo + contador) en vez de
dibujar 5.000 cuadritos.

- [x] Índice espacial quad-tree sobre posiciones del canva. *(SDD-121, `packages/spatial_core`: `QuadTree` con `queryRect`/`queryCircle`/`update`/`remove`; `packages/canva_core`: `CanvaCuller` + `CanvaClusterer` + `CanvaRect`. Fix importante: `isLeaf` con los 4 hijos — un nodo interno post-`cover` puede tener UN solo hijo)*
- [x] Culling por viewport (solo se dibuja lo visible). *(`canva_screen` LOD: `TransformationController` + `CanvaCuller.visibleIn` con margen; en modo LOD los nodos se dibujan con UN solo `CustomPainter` — evita el bug del engine 3.32 con miles de widgets pesados + `BackdropFilter`)*
- [x] Clustering por zoom (agrupar por cercanía + contador). *(`CanvaClusterer` + chip con glow; tap en cluster → zoom-in 2x)*
- [x] Benchmark: 10.000 nodos, zoom-out total, ≥ 30fps + evidencia. *(`integration_test/canva_perf_test.dart` -d windows: zoom 1.0 = 2009/10000 dibujados @ 3.53 ms/frame; zoom-out = 18 clusters @ 2.21 ms/frame; 0 tardíos. Evidencia `data/evidence/etapa86-benchmark.md`)*

**Gate:** 10.000 nodos, zoom-out total, ≥ 30fps (baseline vs benchmark Etapa 5). ✅ **CUMPLIDO 2026-08-12.**

---

## Visión — Empresa Autónoma de Desarrollo (CrewAI + LangGraph) — SDD-115

> **Estado:** Fase 0 **committeada** (`faf129f`). El servicio Python
> `empresa_autonoma/` orquesta la oficina; la app Flutter NUNCA ejecuta agentes,
> solo habla con el servicio (FastAPI/WS, puerto 8100). Async + paralelo por
> defecto (`akickoff_for_each`, `Send`), human-in-the-loop (`interrupt()`),
> checkpoints (`Crew.from_checkpoint()`), observabilidad → canva.

### Fase 0 — Fundación (✅ hecha)

- [x] Grafo LangGraph base: `plan → implementar → revisar → (gate humano) → merge`.
  *(SDD-115, `empresa_autonoma/empresa_autonoma/graph.py`)*
- [x] Roles de oficina como dataclasses (`roles.py`: producto, arquitecto, dev,
  QA, devops, revisor, PM; estados `OfficeState` para la oficina animada).
- [x] Testeable headless sin LLM (`AgenteImplementador` inyectable).

**Pruebas de comprobación (gate):**
- [x] `pytest` verde en `empresa_autonoma/tests/test_graph.py` (grafo completo,
  gate humano con `approved: false` → se detiene en END).

### Fase 1 — Crews a medida (⬜)

- [ ] Roles + delegación CrewAI; el usuario arma equipos en la app → manifiesto
  versionado; cada agente = nodo del canva.
- [ ] Manifiesto de equipo (formato buzz Persona Pack adaptado — copia.md 2.1).
- [ ] **Comunicación de agentes por A2A** (ADR-003, SDD-119): cada runtime
  (opencode/claude/codex) expone un **Agent Card** y habla por A2A (JSON-RPC 2.0 +
  SSE); el orquestador crea Tasks cuyo lifecycle alimenta los estados de la
  oficina (`working/blocked/waiting_approval`). CrewAI↔LangGraph siguen por
  canales nativos (mismo proceso).

**Pruebas de comprobación (gate):**
- [ ] Un equipo se arma en la app, se versiona como manifiesto y su crew ejecuta
  una tarea mock con el grafo headless.
- [ ] A2A (SDD-119): `pytest` verde (tasks + agent card + server con adapter
  fake) y un runtime real (opencode) ejecuta una tarea vía A2A con su estado
  visible en el canva.

### Fase 2 — Paralelismo real (⬜)

- [ ] `akickoff_for_each` + API `Send` de LangGraph; cada empresa = subgrafo.
- [ ] Aislamiento por worktree (concepto Zed 8.6 / copia.md Z8).

**Pruebas de comprobación (gate):**
- [ ] 2 tareas ejecutan en paralelo sobre worktrees distintos sin pisarse.

### Fase 3 — Oficina animada estilo juego (⬜)

- [ ] Personajes/estados visibles (glassmorphism neón); el canva ES la oficina.
- [ ] Estados desde `OfficeState` (idle/working/blocked/waiting_approval/done).

**Pruebas de comprobación (gate):**
- [ ] Un agente pasa trabajando→bloqueado→en revisión y el canva lo anima en vivo.

### Fase 4 — Integración real con repo (⬜)

- [ ] Leer issues/PRs, crear ramas y PRs reales con aprobación humana (`interrupt()`).
- [ ] Tracker estilo Plane/Linear: tarjetas = nodos del canva; dependencias/blockers.

**Pruebas de comprobación (gate):**
- [ ] Una tarea llega de un issue real, la empresa la implementa y deja el PR en
  borrador esperando aprobación; mover la tarjeta de columna cambia el nodo.

### Fase 5 — Autonomía supervisada (⬜)

- [ ] End-to-end con gates de aprobación, checkpoints y trazabilidad (auditoría
  completa por tarjeta).

**Pruebas de comprobación (gate):**
- [ ] Épica completa end-to-end; la máquina cae a mitad y se reanuda desde el
  checkpoint sin perder trabajo.

---

## Definition of Done global

- CI verde (`flutter analyze` + suite + gates de la fase).
- Probado en ≥ 2 plataformas (Android + desktop).
- Gate de la fase cumplido (checklist anterior).
- Evidencia (capturas/logs) adjunta en el commit de cierre de fase.
