# ESTADO ACTUAL — Empresa Dev

> **Última actualización:** 2026-08-11 · último commit `2c88598` (Etapa 5 = grafo 2D+3D) · rama `main`, push OK.
> Fuente de verdad de fases/gates: `docs/SUPER_PLAN.md`. Las features se diseñan en `docs/SDDs/` (siguiendo `SDD-XXX`).

## Resumen ejecutivo

La app (Flutter, `apps/empresa_dev`) es un reemplazo de Termius con canva visual
que evoluciona hacia un **IDE visual de vibecoding**: terminal SSH/SFTP real,
canva de nodos (hosts, notas `.md`, agentes, skills), editor de archivos, gestor
de skills con laboratorio, y **grafo del proyecto en 2D y 3D** (Two.js local +
WebView2 en Windows). La fase en curso según SUPER_PLAN es la **Etapa 6 —
Vibecoding** (no iniciada). Todo el código automatizado de Etapas 1–5 está
verde; quedan **gates manuales** (listados abajo) que requieren mano humana.

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
| Etapa 6 — Vibecoding | ⬜ **siguiente fase** | — |
| Etapa 7 — SDD++ + Playwright | ⬜ no iniciada | — |

### Gates manuales pendientes (bloquean solo el cierre de fase, no el código)

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
melos.yaml              # orquestación (SIN commitear aún: reorg ajeno pendiente de versionar)
```

**Reglas:** la app nunca importa paquetes por ruta relativa; el código
reutilizable va a packages (Dart puro); dirección de dependencias
`apps → packages`; `melos analyze`/`melos test` desde la raíz.

## Comandos usados en esta sesión (verificados)

```powershell
# Suite automatizada (origen git: apps/empresa_dev)
flutter analyze                                        # 0 issues
flutter test --exclude-tags integration                # 124 tests verdes
flutter test --tags skills                             # dogfood 4b: laboratorio contra .opencode/skills reales
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

- `melos.yaml`, `packages/*/pubspec.yaml`, `.gitmodules`, `reference/`:
  untracked del reorg monorepo hecho fuera de sesión — **versionarlos
  deliberadamente** cuando se decida (commit ajeno mezclado con Etapa 4b en
  `784eb4b`, no reescribir historia).
- `AGENTS.md` tiene trabajo sin commitear (visión empresa autónoma extendida).
- `sync_integration_test.dart` falla sin Tailscale (esperado).
- Origin de git lleva `x-access-token` en la URL — no exponer en logs.

## Cómo continuar (Etapa 6 — Vibecoding)

1. Leer `docs/SDDs/` y escribir `SDD-118-etapa6-vibecoding.md` (SDD primero).
2. Pipeline: propuesta del agente (opencode CLI vía `AgentCommandRunner`) →
   parche → nodo-diff (aceptar/rechazar/revertir) → historial.
3. TDD: unit pipeline + widget chat/nodo-diff + integration agente real sobre
   fixture + **dogfood: una feature real de este repo implementada 100% vía
   vibecoding desde la app** (gate).
4. Al cerrar: marcar SUPER_PLAN, CI local (analyze + tests + build), probar en
   ≥2 plataformas, evidencia, commit de cierre + push.