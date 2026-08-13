# SDD-123 — CanvaView: extraer el motor de canva reutilizable (ADR-004)

> **Proyecto:** empresa_dev — ADR-004 (un solo motor de canva).
> **Fecha:** 2026-08-12. **Estado: ✅ Completado** — `CanvaView` extraído y `CanvaScreen` delega; 9 tests canva intactos + 3 tests de aislamiento; 166 tests + analyze 0.

## Objetivo

`CanvaScreen` mezcla el motor de render (InteractiveViewer + culling + clusters
+ canvas LOD + painter de edges + drag) con la lógica de dominio (añadir hosts/
notas/agentes, conectar, abrir pantallas, docs-map). El ADR-004 manda **un solo
motor reutilizable** (`CanvaView`) que sirva a todos los dominios. Este SDD
extrae el motor a `apps/empresa_dev/lib/widgets/canva_view.dart` sin cambiar
comportamiento: los tests existentes del canva (modo simple + LOD) deben pasar
intactos.

## Contrato

```dart
class CanvaView extends StatefulWidget {
  final List<CanvaNode> nodes;
  final List<CanvaEdge> edges;
  /// Construye el widget de un nodo (modo simple, ≤ threshold). El motor
  /// provee los callbacks de gesto y posición.
  final Widget Function(CanvaNode node, CanvaNodeCallbacks cb) nodeBuilder;
  /// Tap sobre un nodo (también en modo LOD via hit-test del canvas).
  final void Function(CanvaNode node) onNodeTap;
  /// Long-press sobre un nodo en modo LOD (canvas).
  final void Function(CanvaNode node)? onNodeLongPress;
  /// Nodo en modo "conectar" (highlight).
  final String? connectModeId;
}

class CanvaNodeCallbacks {
  final bool connectMode;
  final void Function(double x, double y) onMoved;   // drag (modo simple)
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
}
```

- Umbrales (SDD-121): `_kLodThreshold = 300`, `_kClusterScale = 0.6`,
  `_kClusterCellSize = 160`, `_kLodNodeW/H = 150/44`, labels ≤ 250. Se mueven a
  `CanvaView` (privados).
- El motor conserva: `TransformationController` + listener, `CanvaCuller`,
  `_lodRender`, `_nodeAt`/hit-test, `_LodCanvasPainter`, `_ClusterChip`,
  `_EdgesPainter`, `_zoomToCluster`, drag vía `onMoved`.

## Slices (refactor con red de seguridad = tests existentes)

### 8.x.1 — Extracción mecánica

- Crear `canva_view.dart` con el motor (copia fiel del build/lógica de
  `canva_screen.dart`), parametrizado por el contrato.
- `CanvaScreen` pasa el body a `CanvaView`, manteniendo `_DraggableNode` (lo
  construye `nodeBuilder`) y toda la lógica de dominio.
- Los nodos del canvas LOD siguen genéricos (RRect + label).
- **Verificación:** los tests de `canva_widget_test.dart` (9) pasan intactos;
  `flutter analyze` 0.

### 8.x.2 — Test de aislamiento de CanvaView

- `test/canva_view_test.dart`: CanvaView aislado con `nodeBuilder` spy →
  renderiza los nodos en modo simple (≤300); en modo LOD usa el canvas y el
  `onNodeTap` llega vía hit-test; drag llama `onMoved`; cluster chip aparece en
  zoom-out (reusando el patrón de gestos de `canva_widget_test`).

## Gate

- [x] `canva_screen.dart` delega en `CanvaView` (sin lógica de motor).
- [x] `canva_widget_test.dart` verde sin cambios + `canva_view_test.dart` verde.
- [x] `flutter analyze` 0 + suite completa verde.

## Notas de cierre

- El culler de `CanvaView` se invalida por count (add/remove in-place) y por
  identidad de la lista (docs-map reemplaza la lista); los drags actualizan el
  índice vía `_culler.move`.
- En widget tests, el pan sintetizado lo gana el `InteractiveViewer` (mismo
  quirk del E2E de graph_flow) → el test de `onMoved` dispara el callback
  directamente en vez de un drag real.
