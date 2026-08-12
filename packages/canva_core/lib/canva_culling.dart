import 'package:spatial_core/spatial_core.dart';
import 'canva.dart';

/// Rectángulo puro Dart (sin dart:ui) en coordenadas del canva.
class CanvaRect {
  final double x, y, width, height;

  const CanvaRect({required this.x, required this.y, required this.width, required this.height});

  double get left => x;
  double get top => y;
  double get right => x + width;
  double get bottom => y + height;

  bool containsPoint(double px, double py) =>
      px >= left && px <= right && py >= top && py <= bottom;

  CanvaRect expand(double amount) => CanvaRect(
        x: x - amount,
        y: y - amount,
        width: width + amount * 2,
        height: height + amount * 2,
      );
}

/// Culling por viewport vía [QuadTree]: devuelve solo los nodos cuyo rect
/// (visible + [margin], márgenes de nodos a medio render) intersecta el
/// viewport. El índice se construye 1 vez en el constructor; los drags usan
/// [move] (O(log n)) sin reconstruir.
class CanvaCuller {
  final double margin;
  final QuadTree<CanvaNode> _tree = QuadTree<CanvaNode>();

  CanvaCuller(List<CanvaNode> nodes, {this.margin = 200}) {
    for (final n in nodes) {
      _tree.insert(x: n.x, y: n.y, data: n, id: n.id);
    }
  }

  int get nodeCount => _tree.size;

  List<CanvaNode> visibleIn(CanvaRect viewportInCanvaCoords) {
    final r = viewportInCanvaCoords.expand(margin);
    return _tree.queryRect(r.left, r.top, r.right, r.bottom);
  }

  /// Reubica un nodo en el índice (drag en curso) — O(log n).
  void move(String id, double x, double y) {
    _tree.update(id, x, y);
  }
}

/// Cluster de nodos agrupados por celda en zoom-out.
class CanvaCluster {
  final double x, y; // Centroide ponderado (coords del canva).
  final int count;
  final List<String> nodeIds;

  const CanvaCluster({required this.x, required this.y, required this.count, required this.nodeIds});
}

/// Agrupa nodos por celdas de `cellSize/scale` (coords del canva) cuando el
/// zoom está alejado: cada celda con ≥ 2 nodos se convierte en un
/// [CanvaCluster] (centroide ponderado + contador); con 1 nodo sale en
/// [standaloneFor].
class CanvaClusterer {
  final List<CanvaNode> nodes;
  final double cellSize;

  CanvaClusterer(this.nodes, {this.cellSize = 160});

  double _cell(double scale) => cellSize / scale;

  List<CanvaCluster> clustersFor(double scale) {
    final cell = _cell(scale);
    final buckets = <String, List<CanvaNode>>{};
    for (final n in nodes) {
      final key = '${(n.x / cell).floor()},${(n.y / cell).floor()}';
      (buckets[key] ??= []).add(n);
    }
    return [
      for (final b in buckets.values)
        if (b.length >= 2)
          CanvaCluster(
            x: b.fold<double>(0, (s, n) => s + n.x) / b.length,
            y: b.fold<double>(0, (s, n) => s + n.y) / b.length,
            count: b.length,
            nodeIds: [for (final n in b) n.id],
          ),
    ];
  }

  List<CanvaNode> standaloneFor(double scale) {
    final cell = _cell(scale);
    final buckets = <String, List<CanvaNode>>{};
    for (final n in nodes) {
      final key = '${(n.x / cell).floor()},${(n.y / cell).floor()}';
      (buckets[key] ??= []).add(n);
    }
    return [
      for (final b in buckets.values)
        if (b.length < 2) ...b,
    ];
  }
}