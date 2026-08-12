/// Índice espacial quad-tree en Dart puro (sin dependencias).
///
/// Indexa puntos por `id` y responde queries de rectángulo y círculo con poda
/// espacial (O(log n) esperado). Los bounds crecen dinámicamente (estilo
/// d3-quadtree `cover`): no requiere dominio conocido a priori.
///
/// Uso en el canva LOD (SDD-121): indexar posiciones de nodos y consultar qué
/// nodos caen dentro del viewport para renderizar solo esos.
library;

import 'dart:math' as math;

class _QPoint<T> {
  final String id;
  double x;
  double y;
  final T data;

  _QPoint(this.id, this.x, this.y, this.data);
}

class _QNode<T> {
  // Bounds REALES del subárbol (para poda correcta en queries y cover).
  double x0, y0, x1, y1;
  // Hoja: puntos almacenados hasta [capacity]; al llenarse se subdivide.
  final List<_QPoint<T>> points = [];
  _QNode<T>? nw, ne, sw, se;

  _QNode(this.x0, this.y0, this.x1, this.y1);

  // Hoja real: sin hijos. Un nodo interno post-`cover` puede tener UN solo
  // hijo (p.ej. solo `sw`), así que `nw == null` no basta.
  bool get isLeaf => nw == null && ne == null && sw == null && se == null;
}

/// Quad-tree espacial de puntos con payload genérico.
///
/// Todos los métodos con `id` son O(log n) esperado salvo rebalance por
/// expansión de bounds (perezoso, O(log n) nodos nuevos por expansión).
class QuadTree<T> {
  /// Máximo de puntos por hoja antes de subdividir.
  final int capacity;

  _QNode<T>? _root;
  final Map<String, _QPoint<T>> _byId = {};

  QuadTree({this.capacity = 8}) : assert(capacity >= 1);

  /// Número de puntos indexados.
  int get size => _byId.length;

  /// Inserta (o reemplaza) un punto. Si [id] es null se autogenera.
  void insert({required double x, required double y, required T data, String? id}) {
    final i = id ?? 'p${_byId.length}';
    if (_byId.containsKey(i)) {
      remove(i);
    }
    _cover(x, y);
    _insertInto(_root!, x, y, data, i);
    _byId[i] = _QPoint(i, x, y, data);
  }

  /// Reubica el punto [id] en (x, y). No-op si el id no existe.
  void update(String id, double x, double y) {
    final existing = _byId[id];
    if (existing == null) return;
    remove(id);
    insert(x: x, y: y, data: existing.data, id: id);
  }

  /// Elimina el punto [id]. No-op si no existe.
  void remove(String id) {
    final p = _byId.remove(id);
    if (p == null || _root == null) return;
    _removeFrom(_root!, p);
  }

  /// Devuelve los datos de los puntos dentro del rect (inclusive bordes).
  List<T> queryRect(double minX, double minY, double maxX, double maxY) {
    final out = <T>[];
    final root = _root;
    if (root == null) return out;
    _queryRect(root, minX, minY, maxX, maxY, out);
    return out;
  }

  /// Devuelve los datos de los puntos dentro del círculo (radio inclusive).
  List<T> queryCircle(double cx, double cy, double radius) {
    final out = <T>[];
    final root = _root;
    if (root == null) return out;
    final r2 = radius * radius;
    _queryCircle(root, cx, cy, radius, r2, out);
    return out;
  }

  // ---------------------------------------------------------------------------
  // Implementación
  // ---------------------------------------------------------------------------

  /// Expande los bounds de la raíz (creando nodos padre) hasta cubrir (x, y).
  /// Estilo d3-quadtree `cover`: el rect crece SIEMPRE por los 4 lados con el
  /// mismo factor (se mantiene cuadrado) y el árbol viejo cuelga del cuadrante
  /// opuesto al punto — así el viejo árbol SIEMPRE cabe entero en un cuadrante
  /// y la poda por bounds sigue siendo exacta.
  void _cover(double x, double y) {
    final root = _root;
    if (root == null) {
      final x0 = x.floorToDouble();
      final y0 = y.floorToDouble();
      _root = _QNode<T>(x0, y0, x0 + 1, y0 + 1);
      return;
    }
    var x0 = root.x0, y0 = root.y0, x1 = root.x1, y1 = root.y1;
    if (x >= x0 && x < x1 && y >= y0 && y < y1) return;
    var z = math.max(x1 - x0, y1 - y0);
    var node = root;
    while (x0 > x || x >= x1 || y0 > y || y >= y1) {
      // Cuadrante del punto respecto al rect viejo (0=nw,1=ne,2=sw,3=se).
      final i = (y < y0 ? 2 : 0) | (x < x0 ? 1 : 0);
      final parent = _QNode<T>(0, 0, 0, 0);
      z *= 2;
      switch (i) {
        case 0: // punto abajo-derecha: crecer hacia se; árbol viejo en nw
          parent.nw = node;
          parent
            ..x0 = x0
            ..y0 = y0
            ..x1 = x0 + z
            ..y1 = y0 + z;
          break;
        case 1: // punto abajo-izquierda: crecer hacia sw; árbol viejo en ne
          parent.ne = node;
          parent
            ..x0 = x1 - z
            ..y0 = y0
            ..x1 = x1
            ..y1 = y0 + z;
          break;
        case 2: // punto arriba-derecha: crecer hacia ne; árbol viejo en sw
          parent.sw = node;
          parent
            ..x0 = x0
            ..y0 = y1 - z
            ..x1 = x0 + z
            ..y1 = y1;
          break;
        case 3: // punto arriba-izquierda: crecer hacia nw; árbol viejo en se
          parent.se = node;
          parent
            ..x0 = x1 - z
            ..y0 = y1 - z
            ..x1 = x1
            ..y1 = y1;
          break;
      }
      x0 = parent.x0;
      y0 = parent.y0;
      x1 = parent.x1;
      y1 = parent.y1;
      node = parent;
    }
    _root = node;
  }

  void _insertInto(_QNode<T> n, double x, double y, T data, String id) {
    if (n.isLeaf) {
      if (n.points.length < capacity) {
        n.points.add(_QPoint(id, x, y, data));
        return;
      }
      // Hoja llena: subdividir y repartir los existentes.
      final old = List<_QPoint<T>>.from(n.points);
      n.points.clear();
      final mx = (n.x0 + n.x1) / 2;
      final my = (n.y0 + n.y1) / 2;
      n.nw = _QNode<T>(n.x0, n.y0, mx, my);
      n.ne = _QNode<T>(mx, n.y0, n.x1, my);
      n.sw = _QNode<T>(n.x0, my, mx, n.y1);
      n.se = _QNode<T>(mx, my, n.x1, n.y1);
      for (final p in old) {
        _insertInto(n, p.x, p.y, p.data, p.id);
      }
    }
    // Bajar al cuadrante del punto (bounds exactos de cada hijo).
    final mx = (n.x0 + n.x1) / 2;
    final my = (n.y0 + n.y1) / 2;
    final left = x < mx;
    final up = y < my;
    final child = left ? (up ? n.nw : n.sw) : (up ? n.ne : n.se);
    if (child != null) {
      _insertInto(child, x, y, data, id);
    } else {
      // Cuadrante vacío (tras un cover el punto cae en un hueco): crear la
      // hoja con los bounds exactos del cuadrante y colgarla del slot.
      final leaf = _QNode<T>(
        left ? n.x0 : mx,
        up ? n.y0 : my,
        left ? mx : n.x1,
        up ? my : n.y1,
      )..points.add(_QPoint(id, x, y, data));
      if (left) {
        if (up) {
          n.nw = leaf;
        } else {
          n.sw = leaf;
        }
      } else {
        if (up) {
          n.ne = leaf;
        } else {
          n.se = leaf;
        }
      }
    }
  }

  void _removeFrom(_QNode<T> n, _QPoint<T> p) {
    if (n.isLeaf) {
      n.points.removeWhere((e) => e.id == p.id);
      return;
    }
    final mx = (n.x0 + n.x1) / 2;
    final my = (n.y0 + n.y1) / 2;
    final child = p.x < mx ? (p.y < my ? n.nw : n.sw) : (p.y < my ? n.ne : n.se);
    if (child != null) {
      _removeFrom(child, p);
    }
  }

  void _queryRect(_QNode<T> n, double minX, double minY, double maxX, double maxY, List<T> out) {
    if (n.x1 < minX || n.x0 > maxX || n.y1 < minY || n.y0 > maxY) return;
    if (n.isLeaf) {
      for (final p in n.points) {
        if (p.x >= minX && p.x <= maxX && p.y >= minY && p.y <= maxY) {
          out.add(p.data);
        }
      }
      return;
    }
    if (n.nw != null) _queryRect(n.nw!, minX, minY, maxX, maxY, out);
    if (n.ne != null) _queryRect(n.ne!, minX, minY, maxX, maxY, out);
    if (n.sw != null) _queryRect(n.sw!, minX, minY, maxX, maxY, out);
    if (n.se != null) _queryRect(n.se!, minX, minY, maxX, maxY, out);
  }

  void _queryCircle(_QNode<T> n, double cx, double cy, double radius, double r2, List<T> out) {
    if (n.x1 < cx - radius || n.x0 > cx + radius || n.y1 < cy - radius || n.y0 > cy + radius) {
      return;
    }
    if (n.isLeaf) {
      for (final p in n.points) {
        final dx = p.x - cx;
        final dy = p.y - cy;
        if (dx * dx + dy * dy <= r2) out.add(p.data);
      }
      return;
    }
    if (n.nw != null) _queryCircle(n.nw!, cx, cy, radius, r2, out);
    if (n.ne != null) _queryCircle(n.ne!, cx, cy, radius, r2, out);
    if (n.sw != null) _queryCircle(n.sw!, cx, cy, radius, r2, out);
    if (n.se != null) _queryCircle(n.se!, cx, cy, radius, r2, out);
  }
}
