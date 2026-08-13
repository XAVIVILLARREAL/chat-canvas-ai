# ESTADO ACTUAL — Empresa Dev

> **Última actualización:** 2026-08-12 · Etapa 8 completa (8.1–8.6) ✅ · ADR-004/CanvaView ✅ · rama `main`.
> Fuente de verdad de fases/gates: `docs/SUPER_PLAN.md`. Las features se diseñan en `docs/SDDs/` (siguiendo `SDD-XXX`).
> Plan maestro consolidado (todo lo que falta, con gates): `plan.md` (raíz del repo).

## Resumen ejecutivo

La app (Flutter, `apps/empresa_dev`) es un reemplazo de Termius con canva visual
que evoluciona hacia un **IDE visual de vibecoding**: terminal SSH/SFTP real,
canva de nodos (hosts, notas `.md`, agentes, skills), editor de archivos, gestor
de skills con laboratorio, y **grafo del proyecto en 2D y 3D** (Two.js local +
WebView2 en Windows). La fase en curso según SUPER_PLAN es la **Etapa 7 —
SDD++ + Playwright E2E**: E2E web del flujo crítico verde con Playwright contra
`flutter build web` (canva → nota `.md` → editar → guardar → persiste tras
recarga), test patrol mobile versionado (gate manual) y job `e2e-web` en el CI.
El E2E destapó y arregló un bug real de accesibilidad (semántica web del
`showNeonDialog`). Todo el código automatizado de Etapas 1–6 está verde; quedan
**gates manuales** (listados abajo) que requieren mano humana.

**Visión empresa autónoma (CrewAI+LangGraph):** la **Fase 0 ya está committeada**
(`faf129f`, SDD-115): servicio Python `empresa_autonoma/` con grafo
`plan→implementar→revisar→aprobación→merge` testeable headless, roles de
oficina (`roles.py`) y `pytest` verde. Fases 1–5 pendientes (detalle en
`plan.md` §6). **Comunicación de agentes:** ADR-003 acepta **A2A** como
protocolo en la frontera orquestador↔runtimes (opencode/claude/codex/externos);
SDD-119 lo diseña para Fase 1 (Agent Cards + Task lifecycle → estados de la
oficina). CrewAI↔LangGraph siguen por canales nativos (mismo proceso).

## Estado por fase (2026-08-11)

| Fase | Estado | Pendiente |
|---|---|---|
| Terminal SSH + SFTP + Hub + Tabs + Canva base | ✅ automatizado | publicación (Play/Store), batería, túnel |
| Etapa 2 — Agentes IA + voz + evidencia | ✅ automatizado (legacy) | prueba manual voz real + 3 prompts capturados |
| Etapa 3 — File tree + editor + SFTP push | ✅ automatizado | Integration SFTP real + dogfood (editar este repo 2 sesiones) |
| Inyección copia.md (SDD-109/110/111) | ✅ 3 piezas + gates | — |
| Etapa 4 — Canva `.md` + backlinks + dogfood docs/ | ✅ automatizado | manual: 5 notas enlazadas cerrar/reabrir |
| Etapa 4b — Skills builder + lab + export + dogfood duro | ✅ automatizado (6 tests `--tags skills`) | manual: crear → probar → exportar → reiniciar opencode → trigger real |
| **Etapa 5 — Grafo 2D + 3D** | ✅ automatizado (`68f742a` + `2c88598`) | **manual: cargar este repo en desktop y navegar 2D/3D** (commits `68f742a`, `2c88598`) |
| **Etapa 6 — Vibecoding (SDD-118)** | ✅ automatizado + **dogfood ✅** | gates manuales abajo |
| **Etapa 7 — SDD++ + Playwright E2E (SDD-120)** | **E2E web ✅** (2026-08-12: `tool/e2e_web.ps1` + `playwright.config.js` + `e2e_web.spec.js`, chromium headless 12–14s); CI job `e2e-web` ✅; patrol test versionado ⬜ ejecución manual | **manual: patrol en Android real** |
| **Etapa 8.6 — Canva LOD (SDD-121)** | **✅ COMPLETADA 2026-08-12**: quad-tree (`packages/spatial_core`), `CanvaCuller`/`CanvaClusterer` (`packages/canva_core`), culling + clusters + canvas único en `canva_screen`, benchmark 10k @ 3.5/2.2 ms/frame. Evidencia `data/evidence/etapa86-benchmark.md`. Bug engine 3.32 (`mergeWith`) resuelto con render por CustomPainter en LOD | — |
| **Etapa 8.5 — Warp-mode (SDD-122)** | **✅ 8.5.1–3 2026-08-12**: `packages/warp_core` (tracker + historial JSON por host + fuzzy + snippets), terminal con Ctrl+R overlay + sugerencia inline + hoja de snippets, **sync LWW por el hub** (`SnippetRecord` en `SyncSnapshot`). 29 unit warp_core + 4 ssh_core + 7 widget. Pendiente: gate de red real (Tailscale) | — |
| **ADR-004 + SDD-123 — CanvaView** | **✅ 2026-08-12**: decisión "un solo motor de canva" + extracción de `CanvaView` (`lib/widgets/canva_view.dart`) reutilizable; `CanvaScreen` delega. 9 tests canva intactos + 3 de aislamiento; 166 tests + analyze 0 | — |
| **Etapa 8.2 — Oficina (SDD-124)** | **✅ 8.2.1–2 2026-08-12**: `agent_core` `OfficeState`/`AgentRuntimeStatus`/`StatusNotifier`/`SimulatedOffice`; `OfficeScreen` = `CanvaView` con glow por estado + menú Oficina. 9 unit + 2 widget. Pendiente: bridge hub→Python (8.2.3, Fase 1) | — |
| **Etapa 8.4 — SSH proxy (SDD-125)** | **✅ 2026-08-12**: `SshProxyService` + tokens efímeros (`ProxyTokenStore`) + relay WS en `hub_server` + `SshProxyClient`; la llave nunca sale del hub (solo texto). 10 unit + 3 relay localhost; 181 tests app. Pendiente: indicador canva directo/proxy y gate Tailscale real | — |
| **Etapa 8.3 — Hub failover (SDD-126)** | **✅ 8.3.1–2 2026-08-12**: `HubElection` (heartbeat + prioridad + takeover + batería) + `HubElectionService`/`ElectionTransport`. 9 tests. Pendiente: transporte Tailscale real + panel de estado | — |
| **Etapa 8.1 — Sync CRDT (SDD-127)** | **✅ evaluación + núcleo 2026-08-12**: `ydart` descartado, `crdt` 5.1.3 elegido; `packages/crdt_core` (`CanvaCrdt` = CanvaState↔MapCrdt, HLC) con gate de convergencia. 5 tests. Pendiente: migrar el sync del canva a deltas CRDT | — |
| **Visión Empresa Autónoma (SDD-115)** | **Fase 0 ✅** (`faf129f`); Fases 1–5 ⬜ | servicios/crews reales, paralelismo, oficina animada |

### Gates manuales pendientes (bloquean solo el cierre de fase, no el código)

- Etapa 7 (manual): `patrol test -d <device> patrol_test/canva_flow_test.dart` en Android real (mismo flujo crítico que el E2E web, con relanzamiento de app).
- Etapa 6 (manual): generar una propuesta desde la UI de Vibecoding de la app sobre un repo real y aceptarla. **Dogfood (código): ✅ hecho 2026-08-11** — `relativeTimeDetailed` en `vibecoding_core` generada por opencode real y aplicada; el dogfood arregló 3 bugs del pipeline (pubspec_overrides en copia, `.dart_tool/` como edits, prompts manglados por cmd — fix `--prompt-file` + argv-list).
- Etapa 4: crear 5 notas enlazadas, navegar backlinks, cerrar/reabrir persiste.
- Etapa 4b: ciclo real crear skill → probar → exportar a `.opencode/skills/` → reiniciar opencode → trigger.
- Etapa 5: `flutter run -d windows` → menú "Grafo del proyecto" → cargar **este repo** → navegar 2D y 3D.
- Etapa 3: integration SFTP hash real + dogfood 2 sesiones.
- Etapa 2: voz con micrófono real + captura de 3 prompts.
- Etapa 1: publicación pública + batería + E2E 2 plataformas.

## Monorepo (Estructura vigente)

```
apps/empresa_dev/       # ÚNICA app Flutter (UI, stores con path_provider, Riverpod)
packages/ssh_core/      # SshHost, DevSession, SyncSnapshot, HostRecord
packages/canva_core/    # CanvaNode/CanvaState, CanvasNode/CanvasNodeId/NodeKind
packages/agent_core/    # AgentMessage, AgentDetector, manifiestos
packages/graph_core/    # Graph/GraphNode/GraphEdge, RelationIndexer, ForceSimulation, buildGraph3dHtml
empresa_autonoma/       # Servicio Python CrewAI+LangGraph — **Fase 0 committeada** (`faf129f`): graph.py, roles.py, tests headless
melos.yaml              # orquestación (✅ YA versionado)
buzz/ herdr/ reference/zed/   # Repos de referencia (frescos 2026-08-11; buzz/herdr Apache-2.0, zed GPL-3.0 solo conceptos)
```

**Reglas:** la app nunca importa paquetes por ruta relativa; el código
reutilizable va a packages (Dart puro); dirección de dependencias
`apps → packages`; `melos analyze`/`melos test` desde la raíz.

## Comandos usados en esta sesión (verificados)

```powershell
# Suite automatizada (origen git: apps/empresa_dev)
flutter analyze                                        # 0 issues
flutter test --exclude-tags integration                # 143 tests verdes
flutter test --tags skills                             # dogfood 4b: laboratorio contra .opencode/skills reales
flutter test test/vibecoding_integration_test.dart     # E2E opencode real (vibe_demo), ~8s, requiere opencode
dart test     # en packages/graph_core (12 tests)      # unit core
dart run benchmark/graph_benchmark.dart                # 5.000 nodos ~8 ms/frame

# E2E grafo (Etapa 5) — Windows real con WebView2:
$env:PATH = "C:\tools\nuget;$env:PATH"                 # OBLIGATORIO (flutter_tts busca nuget)
Get-Process sshpro -ErrorAction SilentlyContinue | Stop-Process -Force   # evita LNK1104
flutter test integration_test/graph_flow_test.dart -d windows `
  --dart-define=EMPRESA_DEV_REPO=<abs>/apps/empresa_dev/test/fixtures/graph_demo

# Evidencia visual desktop (capturas nativas):
powershell -NoProfile -File tools\capture_app.ps1       # mientras corre el E2E (CopyFromScreen)

# APK Android:
flutter build apk --debug --no-tree-shake-icons

# Servicio empresa_autonoma (Fase 0, SDD-115):
cd empresa_autonoma && .venv/Scripts/python -m pytest     # tests headless del grafo
# .venv/Scripts/python -m uvicorn empresa_autonoma.server:app --port 8100  (cuando exista server.py)
```

## Infraestructura y lecciones duras (NO repetir errores)

- **WebView2 en Windows:** `webview_windows ^0.4.0` es Dart puro (MethodChannel)
  → compila en todas las plataformas; en runtime solo funciona en Windows
  (`ProjectGraph3DView.supportsPlatform`). El HTML 3D se sirve desde un
  HttpServer local (patrón hub server) con Three.js **local** en assets
  (`assets/graph3d/`, sin CDN → offline).
- **`--dart-define=EMPRESA_DEV_REPO=<dir>`** en `_openProjectGraph` evita el
  diálogo nativo de FilePicker → habilita E2E y prueba manual rápida.
- **E2E desktop:** `binding.takeScreenshot` exige `flutter drive` (con
  `flutter test` lanza MissingPluginException); la evidencia visual de desktop
  se hace con captura nativa (`tools/capture_app.ps1`).
- **Build Windows:** borrar `build/windows` implica re-pasar
  `-DCMAKE_INSTALL_PREFIX` (default `C:\Program Files` falla sin admin);
  `nuget` en PATH; si LNK1104 → matar `sshpro.exe` y reintentar.
- **Tests con plataforma override**: `debugDefaultTargetPlatformOverride` debe
  restaurarse dentro del cuerpo del test (los `addTearDown` corren después de
  la verificación del framework y lanzan el assert).
- **Menú canva**: el menú "Añadir" ya es scrollable (bug real de overflow
  corregido en Etapa 5).
- Detección de "3D cargado": `controller.loadingState == navigationCompleted`
  → indicador en AppBar (idempotente, usado por el E2E).

## Pendientes de infraestructura/repo (no bloquean desarrollo)

- ✅ **Resuelto:** `melos.yaml` y `packages/*/pubspec.yaml` YA están versionados
  (verificado 2026-08-11), aunque ESTADO/SUPER_PLAN anteriores decían lo contrario.
- ✅ **Resuelto (sísmica visual 2026-08-11):** toda la app migrada a Glassmorphism
  Neón (SDD-114): `app_theme.dart` ampliado (tokens/gradientes/glows + temas
  globales), `neon_dialog.dart`/`neon_sheet.dart` nuevos, `NeonCard` con luz de
  borde y hover, y rediseño de main/tabs/canva/hub/sftp/terminal/agente/editor/
  skills/grafo. `flutter analyze` 0 + 124 tests verdes. Pendiente: commitear.
- `AGENTS.md` tiene trabajo sin commitear (visión empresa autónoma extendida +
  retoque visual glassmorphism) — commitear deliberadamente cuando se decida.
- `sync_integration_test.dart` falla sin Tailscale (esperado).
- Origin de git lleva `x-access-token` en la URL — no exponer en logs.
- Repos de referencia verificados frescos (11-08-2026): `buzz` `be48ce9`,
  `herdr` `ddffb6e`, `reference/zed` `daec37b` (submodule).

## Cómo continuar (Etapa 6 — Vibecoding)

1. ✅ SDD-118 escrito y slices 6.1–6.4 cerrados (17+20 unit/widget + E2E real con
   opencode sobre `test/fixtures/vibe_demo/`).
2. ✅ **Dogfood (gate) — 2026-08-11:** `relativeTimeDetailed` implementada 100%
   vía vibecoding (opencode real sobre `packages/vibecoding_core` con
   `tool/vibecoding_dogfood.dart --prompt-file ... --apply`) → aplicada y suite
   verde (31 unit vibecoding_core + 143 app + analyze 0). El dogfood arregló 3
   bugs: (1) `pubspec_overrides.yaml` en la copia aislada; (2) `.dart_tool/` y
   `build/` generados por el agente entraban como edits; (3) prompts con `"`,
   `->` o `&` se manglaban por el argv de `dart.bat` y el escaping JSON vs cmd
   → `--prompt-file` (prompt por archivo UTF-8) + `AgentCommandRunnerAdapter`
   por argv-list al `opencode.exe` nativo (sin cmd; patrón `/s /c ""...""`
   solo para el shim `.cmd`).
3. Al cerrar: marcar SUPER_PLAN, CI local (analyze + tests + build), probar en
   ≥2 plataformas, evidencia, commit de cierre + push, y definir SDD-119 (Etapa 7).