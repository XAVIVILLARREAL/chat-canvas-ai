# SDD-117 — Etapa 5: Grafo 3D (WebView + Three.js)

## Objetivo

Completar los pendientes de la Etapa 5 del SUPER_PLAN:

1. **Grafo 3D** con WebView + Three.js (solo desktop/web; fallback 2D en mobile),
   alimentado por el mismo `graph_core` que el grafo 2D.
2. **Gate manual operativo**: poder cargar un repo desde desktop y navegar su
   grafo completo — habilitado también por `--dart-define=EMPRESA_DEV_REPO`
   (permite automatización E2E sin diálogo nativo de FilePicker).

## Flujo

```
Canva → menú → "Grafo del proyecto"
  (EMPRESA_DEV_REPO dart-define > env var > FilePicker)
  → ProjectGraphScreen (2D, ya existe)
      AppBar ✦ botón "3D" (Icons.view_in_ar)
      → desktop: ProjectGraph3DScreen  (WebView2 + Three.js)
      → mobile/web: SnackBar "3D solo en desktop" (fallback = quedarse en 2D)

ProjectGraph3DScreen:
  HttpServer 127.0.0.1:puerto-aleatorio (dart:io, patrón hub server)
    GET /           → HTML generado por graph_core.buildGraph3dHtml(graph)
    GET /three.min.js → asset local (offline, sin CDN)
  WebviewController (webview_windows, import condicionado _windows/_stub)
    loadUrl(http://127.0.0.1:puerto/)
    onLoadCompleted → indicador "3D cargado" (idempotente para tests)
  dispose: controller del servidor + WebviewController.
```

## Contratos

```dart
// packages/graph_core/lib/graph3d_html.dart (Dart puro)
String buildGraph3dHtml(Graph graph)  // HTML + Three.js embebido de asset; JSON inyectado

// apps/empresa_dev/lib/views/project_graph_3d_view.dart
// (import condicionado: _windows.dart = webview_windows real, _stub.dart = no-op)
class ProjectGraph3DView extends StatefulWidget {
  final Graph graph;           // nodos/aristas a renderizar
  final Future<String> Function(String path) loadAsset; // rootBundle (inyectable en tests)
}

// lib/screens/project_graph_3d_screen.dart
class ProjectGraph3DScreen extends StatefulWidget { final Graph graph; }
// ProjectGraphScreen (2D) gana: AppBar action Icons.view_in_ar → 3D (desktop)
// canva_screen._openProjectGraph: EMPRESA_DEV_REPO dart-define > env > FilePicker
```

## Asset

- `apps/empresa_dev/assets/graph3d/three.min.js` — Three.js r128 minificado
  (MIT). Descargado una vez al repo; el servidor local lo sirve → sin red en
  runtime y evidencia reproducible. `pubspec.yaml`: añadir carpeta a `assets:`.

## Tests (TDD)

1. `packages/graph_core/test/graph3d_html_test.dart` (unit):
   - HTML contiene `<html>`, script Three, `OrbitControls`.
   - JSON inyectado contiene ids/labels/kinds/package y aristas from/to/kind.
2. `apps/empresa_dev/test/project_graph_3d_widget_test.dart` (widget):
   - En plataforma no-desktop (override), tap en el botón 3D del 2D → SnackBar
     "3D solo en desktop" y NO navega (fallback 2D).
   - `ProjectGraph3DView` con stub: servidor local responde `/` y
     `/three.min.js`, HTML contiene los nodos del graph (assert vía http get
     al puerto del estado — pendiente de diseño: exponer `Uri baseUrl` para
     tests).
3. `integration_test/graph_flow_test.dart` (E2E nuevo, área canva/grafo):
   - Se ejecuta con `--dart-define=EMPRESA_DEV_REPO=<fixture graph_demo>`.
   - Abre app → Canva → menú → "Grafo del proyecto" → nodos del fixture
     visibles → tap 3D → aparece "3D cargado" (WebView2 real) → screenshots.
   - Fixture: `apps/empresa_dev/test/fixtures/graph_demo/` (src/main.dart→helper,
     notes/index.md→main.dart, script.py).

## Gate (SUPER_PLAN)

- [x] Slices previos 2D (5.1–5.4) — commit `68f742a`.
- [x] NUEVO 3D: unit HTML, widget fallback, E2E desktop con WebView2 + screenshots.
- [ ] Manual (humano): `flutter run -d windows` → grafo de este repo (2D y 3D).
- [x] SUPER_PLAN: marcar tarea 3D + gate cuando pase.

## Notas de implementación

- **Motor 3D**: WebView2 (`webview_windows ^0.4.0`) + **Three.js r128 local**
  (`assets/graph3d/three.min.js` + `orbitcontrols.js`, sin CDN → offline). El
  HTML lo genera `graph_core.buildGraph3dHtml(graph, positions:)` (Dart puro,
  JSON inyectado `nodes/edges` + esferas, aristas LineSegments, sprites-label,
  OrbitControls, raycast hover → tooltip). `webview_windows` es Dart puro
  (MethodChannel) → compila en todas las plataformas; la vista se guarda con
  `ProjectGraph3DView.supportsPlatform` (solo Windows) y `onNativeError`.
- **Servidor local**: HttpServer `127.0.0.1:<puerto-efímero>` sirve `/`
  (HTML del graph) y los assets Three.js desde `rootBundle` (patrón hub
  server). Señal de carga: `controller.loadingState == navigationCompleted`
  → indicador "3D cargado" en el AppBar (idempotente para tests).
- **Fallback**: en android/iOS/web el botón "Ver grafo 3D" del AppBar 2D
  muestra SnackBar (fallback = quedarse en 2D); la pantalla 3D en plataforma
  no soportada notifica `onNativeError` → SnackBar + pop.
- **E2E sin FilePicker**: `_openProjectGraph` acepta
  `--dart-define=EMPRESA_DEV_REPO` (después env var, después FilePicker) —
  habilita `flutter test -d windows` + `flutter drive` con fixture
  `test/fixtures/graph_demo/`.
- **Bugs reales encontrados por /dev**: el menú "Añadir al canva" desbordaba
  (Column fijo, +155 px) → `SingleChildScrollView`; el item "Grafo del
  proyecto" quedaba bajo el fold → `ensureVisible` en el E2E.
- **Evidencia**: `data/evidence/etapa5-3d/grafo-3d-webview2.png` (captura
  nativa `tools/capture_app.ps1`, CopyFromScreen) — el modelo sin visión
  verificó la captura por análisis de píxeles (fondo #0F172A + violeta de
  aristas). `binding.takeScreenshot` con `flutter test` lanza
  MissingPlugin (exige `flutter drive`) → try/catch.
- **CI actual**: analyze 0 issues; 124 unit/widget verdes; E2E grafo (2D+3D)
  verde en Windows real; benchmark 5.000 nodos ~8 ms/frame.