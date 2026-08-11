# SDD-116 — Etapa 5: Grafo del proyecto (2D → 3D)

> **Proyecto:** empresa_dev — Etapa 5 del SUPER_PLAN.
> **Fecha:** 2026-08-11. **Estado:** En implementación.

## Objetivo

Visualizar las conexiones entre archivos de un proyecto como `mcp codebase-memory`
/ Supermemory / Engram: imports (Dart/Python), `[[links]]` entre `.md` y referencias.
Grafo 2D de fuerza dirigida (d3-force portado a Dart puro) clusterizado por paquete;
hover = preview, click = abre el archivo en el editor. Grafo 3D (WebView + Three.js)
queda como item manual/opcional con fallback 2D en mobile.

## Arquitectura (reglas monorepo)

- **`packages/graph_core`** (Dart puro, sin Flutter): modelos `GraphNode`/`GraphEdge`,
  `RelationIndexer` (escaneo + detección de relaciones) y `ForceSimulation`
  (física de fuerzas d3-style). Tests unit + benchmark headless.
- **App** (`apps/empresa_dev`): `ProjectGraphScreen` + painter (CustomPaint), hover
  preview y click → editor. Entrada desde el menú del canva ("Grafo del proyecto").

## Slices

### 5.1 — Modelos + RelationIndexer (unit, graph_core)

- `GraphNode {id (path relativo), label, kind: dart|python|markdown|other, package (cluster)}`.
- `GraphEdge {from, to, kind: import|link|ref}`.
- `RelationIndexer.scan(root)`:
  - recorre el árbol ignorando `.git`, `build`, `node_modules`, `.dart_tool`, `.idea`;
  - `.dart`: `import '...'`/`export '...'` (package: y relativos) → edges `import`;
  - `.py`: `import x`, `from x import y` → edges `import`;
  - `.md`: `[[destino]]` y `[[destino|alias]]` → edges `link`;
  - `package`: para Dart, el `package:` destino; cluster = directorio top-level
    (o `package:` si aplica).
- Test fixture: `test/fixtures/graph_fixture/` con 2 dart + 1 py + 2 md enlazados.

### 5.2 — ForceSimulation d3-force (unit, graph_core)

- Fuerzas: enlace (spring), repulsión coulomb entre todos, centrado suave y
  vórtice para evitar colapso. Paso semi-implícito con `dt`; `step()` iterativo.
- `layout2D(nodes, edges, size)` → asigna `x,y` estables tras N pasos.
- Test: no NaN; nodos conectados convergen más cerca que los desconectados;
  el layout converge (delta de energía decrece).

### 5.3 — ProjectGraphScreen (widget, app)

- `ProjectGraphScreen(root)`: lanza `RelationIndexer.scan` (headless, síncrono,
  lección FakeAsync) y pinta con `CustomPainter` (nodos coloreados por cluster,
  aristas con alpha por tipo). `InteractiveViewer` para pan/zoom.
- Hover (MouseRegion por nodo) → tarjeta preview (nombre, package, primeras líneas
  del archivo vía `ProjectService.read`). Click → abre `CodeEditorScreen` con el
  archivo. Entrada: menú canva "Grafo del proyecto" (desktop).
- Fallback: si el root no existe, SnackBar.

### 5.4 — Performance: benchmark 5.000 nodos (bench)

- `tool/graph_benchmark.dart`: genera 5.000 nodos (cadena + aleatorios),
  `ForceSimulation.step()` ×60, mide ms y escribe baseline en
  `data/evidence/etapa5-benchmark.md`. Gate 30fps ⇒ objetivo < 16 ms/step para
  5.000 nodos (headless); si no, barrido de fuerzas o grid de repulsión.

## Contratos

```dart
// packages/graph_core
enum GraphNodeKind { dart, python, markdown, other }
class GraphNode { String id; String label; GraphNodeKind kind; String package; }
class GraphEdge { String from; String to; GraphEdgeKind kind; }
class Graph { List<GraphNode> nodes; List<GraphEdge> edges; }
class RelationIndexer { static Graph scan(String root); }

class ForceSimulation {
  ForceSimulation(this.nodes, this.edges);
  void step([double dt = 1]);       // avanza un tick
  void layout(int steps, {double width, double height}); // calienta y enfría
  Point2 pos(String id);
}
```

## Tests (TDD)

- `packages/graph_core/test/relation_indexer_test.dart`: fixture detecta
  imports dart (package: y relativo), import py, `[[links]]` md con alias.
- `packages/graph_core/test/force_simulation_test.dart`: convergencia, sin NaN,
  conectados más cerca.
- `apps/empresa_dev/test/project_graph_widget_test.dart`: grafo renderiza N nodos,
  hover muestra preview, click invoca callback de apertura.
- `packages/graph_core/benchmark/` (opcional CI): 5.000 nodos, baseline.

## Gate (SUPER_PLAN)

- [x] Unit: indexador detecta imports/referencias/links reales de un fixture.
- [x] Widget: grafo renderiza, hover muestra preview, click abre editor.
- [x] Performance: 5.000 nodos a ≥ 30fps (baseline registrada antes de optimizar).
- [ ] Manual: cargar este repo y navegar su grafo completo en desktop.
- [ ] (opcional) Grafo 3D WebView + Three.js desktop/web; fallback 2D mobile.

## Notas de implementación

- **Monorepo:** nuevo package `packages/graph_core` (Dart puro, análisis con
  exclusiones `build/**` y `test/fixtures/**`); la app usa `path:` en pubspec.
- **5.1 Indexador:** IDs = ruta relativa (única); imports `package:` Dart →
  id virtual `packages/...` (se resuelven contra la raíz si existen); stdlib
  Python ignorada (os, sys, json, re, math, typing, logging, datetime);
  `[[links]]` md con alias → se resuelven probando `.md/.dart/.py` en FS
  (relativa al archivo si no lleva `/`, raíz-relative si lleva). Regex con
  `multiLine: true` (sin él solo detectaba la línea 1); `_resolveImport`
  requiere `removeLast()` (sacar el archivo fuente del path).
- **5.2 Física:** repulsión con **grid espacial O(n·k)** (cellSize 90, clave
  empaquetada 10 bits, 9 celdas vecinas — intento O(n²) dio 145 ms/frame);
  enlaces resueltos con **mapa id→body** (firstWhere O(n) era el segundo
  cuello: 37M búsquedas/step) → **7.28 ms/frame** con 5.000 nodos (3/60 late),
  objetivo <16 ms cumplido.
- **5.3 Widget:** `ProjectGraphScreen` (CustomPaint aristas + nodos con
  MouseRegion/Tooltip/GestureDetector, InteractiveViewer pan/zoom, paleta por
  paquete con `package.hashCode` estable, glow neón al hover); entrada en el
  menú del canva "Grafo del proyecto" (desktop, FilePicker → scan → layout →
  pantalla); click → `CodeEditorScreen` leyendo con `File.readAsStringSync`.
- **Tests:** hover con `tester.createGesture(kind: PointerDeviceKind.mouse)` +
  `moveTo` (no existe `tester.hover`); `layout()` es síncrono y headless.
- **Benchmark:** `packages/graph_core/benchmark/graph_benchmark.dart` (5.000
  nodos = cadena de enlaces + aleatorios, 60 frames dt 0.5, exit ≠0 si ≥50%
  late) → evidencia en `apps/empresa_dev/data/evidence/etapa5-benchmark.md`.
- **CI:** `flutter analyze` 0 issues, `flutter test --exclude-tags integration`
  121 verdes (119 previos + 3 del grafo), build Windows Debug OK.
