# SDD-121 — Etapa 8.6: Canva LOD — quad-tree culling + clusters por zoom

> **Proyecto:** empresa_dev — Etapa 8.6 del SUPER_PLAN (cola de innovación, priorizada al cierre de Etapa 7).
> **Fecha:** 2026-08-12. **Estado: ✅ Completado** — gate 8.6 cumplido (benchmark en `data/evidence/etapa86-benchmark.md`).

## Objetivo

El canva renderiza **todos** los nodos siempre: un `Stack` con un `Positioned` +
`_DraggableNode` (AnimatedContainer con sombras) por nodo, y `_EdgesPainter.paint`
hace `nodes.where(id == ...)` **por cada arista** (O(E×N)). Con 10.000 nodos eso es
inviable: miles de widgets y E×10.000 búsquedas por frame.

Gate del SUPER_PLAN 8.6: **10.000 nodos, zoom-out total, ≥ 30fps**, con baseline
registrado (el benchmark de Etapa 5 media la física del grafo, no la UI del canva;
este SDD crea el primer benchmark de UI).

## Arquitectura (reglas monorepo)

- **`packages/spatial_core`** (Dart puro, sin Flutter): `QuadTree` espacial genérico
  (puntos indexados por id, query por rect/círculo, rebalance automático). Es
  reutilizable (grafo 2D de Etapa 5, futuros juegos/colisiones).
- **`packages/canva_core`** (extensión, Dart puro): `CanvaCuller` (viewport en
  coordenadas del canva + margen → ids visibles vía QuadTree) y `CanvaClusterer`
  (escala → celdas → clusters con centroide + count + ids).
- **App** (`apps/empresa_dev/lib/screens/canva_screen.dart`): `TransformationController`
  propio en el `InteractiveViewer` (listener → rect visible en coords del canva),
  render solo de visibles, chips de cluster en zoom-out, y fix del painter con mapa
  `id → nodo` (O(E)).

## Slices (TDD, test rojo primero)

### 8.6.1 — `packages/spatial_core`: QuadTree (unit)

- `QuadTree.insert(x, y, data)` (punto con payload opcional, reindexable por id).
- `QuadTree.queryRect(minX, minY, maxX, maxY) → List<T>`; `queryCircle(cx, cy, r)`.
- `QuadTree.update(id, x, y)`, `remove(id)`.
- Rebalance: si una celda supera `capacity` (default 8), se subdivide; si un punto
  se aleja de los bounds, los bounds crecen (rebalance perezoso al query).
- Tests: 10k puntos aleatorios → queryRect devuelve exactamente los puntos dentro
  (comparado con fuerza bruta); update/remove consistentes; query en bounds vacíos
  → vacío.

### 8.6.2 — `canva_core`: CanvaCuller + CanvaClusterer (unit)

```dart
class CanvaCuller {
  CanvaCuller(this.nodes, {this.margin = 200});
  List<CanvaNode> visibleIn(Rect viewportInCanvaCoords);
  int get nodeCount;
}
class CanvaCluster {
  final double x, y; final int count; final List<String> nodeIds;
}
class CanvaClusterer {
  CanvaClusterer(this.nodes, {this.cellSize = 160});
  List<CanvaCluster> clustersFor(double scale); // cellSize/scale en coords canva
  List<CanvaNode> standaloneFor(double scale);  // nodos sueltos (cluster de 1)
}
```

- Culling: rect del viewport transformado a coords del canva (matriz inversa) +
  margen de 200px (nodos de 180px de ancho medio fuera de pantalla no parpadean).
- Clustering: con `scale < 0.6`, agrupar por celdas de `cellSize/scale` px; cluster
  con ≥ 2 nodos → `CanvaCluster` (centroide ponderado); con 1 → `standalone`.
- Tests: culling con 10k nodos en grid devuelve solo los del viewport; clusterer
  con zoom-out extremo (0.3) agrupa todo el grid en pocos clusters con counts
  correctos; nodos sueltos salen en `standalone`.

### 8.6.3 — canva_screen: integración culling + clusters + painter O(E) (widget)

- `TransformationController` propio + listener → `setState` (rebuild solo cuando
  pan/zoom cambia; el frame del canva es determinista).
- Si `nodes.length <= 300` → modo simple (sin culling, comportamiento actual).
- Si no: rect visible → `CanvaCuller.visibleIn` → nodos individuales + edges
  cuyos 2 extremos son visibles; si `scale < 0.6` → `CanvaClusterer` → chips de
  cluster (contador + glow) + standalone.
- `_EdgesPainter` recibe un `Map<String, CanvaNode>` construido 1 vez (O(E)).
- Tap en cluster → zoom-in 2x centrado en el centroide (animado vía `tc.value`).
- Tests widget: 1.000 nodos → con zoom-out total se renderizan pocos clusters
  (no 1.000 textos); con zoom 1.0 solo los nodos del viewport; los tests
  existentes del canva (2 nodos) pasan intactos; drag de nodo visible sigue
  funcionando; arista con extremos visibles se pinta.

### 8.6.4 — Benchmark de UI: 10.000 nodos zoom-out total ≥ 30fps (integration)

- `integration_test/canva_perf_test.dart` (patrón `graph_flow_test.dart`, `-d windows`):
  genera grid 100×100 (10.000 nodos) en el dominio 3000×2000, abre `CanvaScreen`,
  fuerza zoom-out total (escala mínima 0.3, ver el canva entero), captura
  `FrameTiming` vía `binding.addTimingsCallback` durante 3s, y exige:
  - media build+paint por frame ≤ 33.3 ms (30fps),
  - late frames (vsync) < 10%,
  - imprime el reporte (nodos renderizados vs total, clusters, ms/frame).
- Evidencia: `apps/empresa_dev/data/evidence/etapa86-benchmark.md` con los números
  reales (mismo patrón que `etapa5-benchmark.md`).
- Gate SUPER_PLAN 8.6: verificar el checkbox con los números.

## Contratos de integración

```dart
// canva_screen.dart (build)
final rect = MatrixUtils.transformRect(
  Matrix4.tryInvert(tc.value) ?? Matrix4.identity(), viewportRect);
final visible = culler.visibleIn(rect);      // o clusters en zoom-out
// painter
final byId = {for (final n in nodes) n.id: n};
```

## Notas de implementación

- `InteractiveViewer` mantiene `constrained: false`, `minScale 0.3`, `maxScale 3`,
  `boundaryMargin 4000` y dominio 3000×2000 — no cambia (compatibilidad).
- El `_DraggableNode` solo existe para nodos visibles; al arrastrar, el nodo
  podría salir del viewport → el drag sigue (los nodos fuera del rect pero dentro
  del margen de 200px no se descartan; el límite es de parpadeo).
- Clusters: `GestureDetector` → `tc.value = tc.value.clone()..translate(...)..scale(2)`
  (zoom in centrado); sin animación compleja (fácil de probar).
- El umbral 300 y el margen 200 y `cellSize 160` y `scale < 0.6` son constantes en
  `canva_screen.dart` (tuneables; los tests los fijan explícitamente).
- `melos.yaml` debe incluir `spatial_core` en bootstrap (verificar al añadirlo).

## Gate (SUPER_PLAN 8.6)

- [x] Índice espacial quad-tree sobre posiciones del canva (8.6.1).
- [x] Culling por viewport: solo se dibuja lo visible (8.6.2–3).
- [x] Clustering por zoom: agrupar por cercanía + contador (8.6.2–3).
- [x] Benchmark: 10.000 nodos, zoom-out total, ≥ 30fps + evidencia (8.6.4).

## Notas de cierre (2026-08-12)

- **Bug del engine (Flutter 3.32.2):** renderizar ~3.000 `_DraggableNode`
  (AnimatedContainer + sombra + GestureDetector) bajo el AppBar con
  `BackdropFilter` lanza `Invalid argument(s): mergeWith` del engine C++ y
  hace fallar el integration test. Aislado por bisect: NO ocurre con 299 nodos
  (modo simple), NO con 3.000 cajas simples/réplica exacta, NI con viewport
  pequeño (culler → pocos nodos). Ocurre solo combinando el canva completo +
  miles de nodos widget-pesados. **Solución:** en modo LOD los nodos se dibujan
  con UN solo `CustomPainter` (`_LodCanvasPainter`: RRect + borde, labels solo
  si ≤ 250 visibles), con hit-test manual (tap abre, long-press conecta en
  hosts). Trade-off documentado: en modo LOD (>300 nodos) no hay drag-por-nodo
  (zoom-in para interactuar); ≤300 conserva el comportamiento histórico.
- `FrameTiming` NO se exporta por `package:flutter/material.dart` → import
  `dart:ui show FrameTiming`. Los métodos `async` devuelven `Future<T>`.
- Gestos en tests: en Flutter **separar dedos = zoom-in** (scale = span actual /
  inicial) → para zoom-out la pinza va hacia adentro.
