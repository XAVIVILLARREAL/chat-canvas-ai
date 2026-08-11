import 'dart:math' as math;

import 'models.dart';

class _Body {
  final GraphNode node;
  double x;
  double y;
  double vx = 0;
  double vy = 0;

  _Body(this.node, this.x, this.y);
}

/// Simulación de fuerzas estilo d3-force portada a Dart puro:
/// enlaces (spring), repulsión coulomb, centrado suave y cooling alpha.
class ForceSimulation {
  final List<_Body> _bodies;
  final Map<String, _Body> _byId;
  final Map<String, List<String>> _links; // fromId → [toId...]
  double _alpha = 1.0;
  static const _alphaMin = 0.001;
  static const _alphaDecay = 0.0228;

  ForceSimulation(List<GraphNode> nodes, List<GraphEdge> edges)
      : _bodies = _seed(nodes),
        _links = _index(edges),
        _byId = {} {
    for (final b in _bodies) {
      _byId[b.node.id] = b;
    }
  }

  int get nodeCount => _bodies.length;

  double x(String id) => _body(id).x;
  double y(String id) => _body(id).y;

  static List<_Body> _seed(List<GraphNode> nodes) {
    final n = nodes.length;
    final bodies = <_Body>[];
    final radius = 60 + math.sqrt(n) * 12;
    for (var i = 0; i < n; i++) {
      final a = 2 * math.pi * i / math.max(1, n);
      final r = (i % 2 == 0) ? radius : radius * 0.6;
      bodies.add(_Body(nodes[i], r * math.cos(a), r * math.sin(a)));
    }
    return bodies;
  }

  static Map<String, List<String>> _index(List<GraphEdge> edges) {
    final m = <String, List<String>>{};
    for (final e in edges) {
      m.putIfAbsent(e.from, () => []).add(e.to);
    }
    return m;
  }

  _Body _body(String id) => _byId[id] ?? _bodies[0];

  /// Avanza un tick de física. Devuelve el delta total de posición (si <
  /// umbral, la simulación ha convergido).
  double step([double dt = 1.0]) {
    const k = 0.06; // rigidez del resorte
    const center = 0.02; // atracción al origen

    final n = _bodies.length;
    if (n == 0) return 0;

    // Enlaces: aplicar spring a los pares conectados.
    for (final b in _bodies) {
      final targets = _links[b.node.id];
      if (targets == null) continue;
      for (final t in targets) {
        final other = _body(t);
        if (identical(other, b)) continue;
        final dx = other.x - b.x;
        final dy = other.y - b.y;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < 0.01) continue;
        final f = (dist - 40) * k; // distancia objetivo ~40
        b.vx += (dx / dist) * f;
        b.vy += (dy / dist) * f;
        other.vx -= (dx / dist) * f;
        other.vy -= (dy / dist) * f;
      }
    }

    // Repulsión coulomb aproximada con grid espacial O(n·k): cada nodo
    // repulsa contra los de su celda y las 8 vecinas (k ≈ 9·densidad).
    const repulsion = 900.0;
    const cellSize = 90.0;
    const gridSize = 1 << 20; // máscara para empaquetar (cx, cy)
    final grid = <int, List<int>>{};
    for (var i = 0; i < n; i++) {
      final b = _bodies[i];
      final cx = (b.x / cellSize).floor();
      final cy = (b.y / cellSize).floor();
      final key = (cx & 0x3FF) | ((cy & 0x3FF) << 10);
      grid.putIfAbsent(key, () => []).add(i);
    }
    var total = 0.0;
    for (var i = 0; i < n; i++) {
      final b = _bodies[i];
      final cx = (b.x / cellSize).floor();
      final cy = (b.y / cellSize).floor();
      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          final key = ((cx + dx) & 0x3FF) | (((cy + dy) & 0x3FF) << 10);
          final cell = grid[key];
          if (cell == null) continue;
          for (final j in cell) {
            if (j <= i) continue; // cada par una sola vez
            final other = _bodies[j];
            final ddx = b.x - other.x;
            final ddy = b.y - other.y;
            final d = math.max(math.sqrt(ddx * ddx + ddy * ddy), 1.0);
            final f = repulsion / d;
            b.vx += (ddx / d) * f;
            b.vy += (ddy / d) * f;
            other.vx -= (ddx / d) * f;
            other.vy -= (ddy / d) * f;
          }
        }
      }
    }

    // Integración semi-implícita + centrado + velocity decay fuerte.
    const decay = 0.85;
    for (final b in _bodies) {
      b.vx += -b.x * center;
      b.vy += -b.y * center;
      final speed = math.sqrt(b.vx * b.vx + b.vy * b.vy);
      const maxSpeed = 30.0;
      if (speed > maxSpeed) {
        b.vx = b.vx / speed * maxSpeed;
        b.vy = b.vy / speed * maxSpeed;
      }
      b.vx *= decay;
      b.vy *= decay;
      b.x += b.vx * dt;
      b.y += b.vy * dt;
      total += (b.vx.abs() + b.vy.abs());
    }
    _alpha = math.max(_alphaMin, _alpha - _alphaDecay);
    return total;
  }

  /// Ejecuta [steps] ticks (calentando si hace falta) y autofit final al
  /// viewport [width]x[height] (escala + centra, con padding 40).
  void layout(int steps, {double width = 800, double height = 600}) {
    for (final b in _bodies) {
      b.x += width / 2;
      b.y += height / 2;
    }
    for (var i = 0; i < steps; i++) {
      step(0.5);
    }
    final n = _bodies.length;
    if (n < 2) {
      if (n == 1) {
        _bodies[0].x = width / 2;
        _bodies[0].y = height / 2;
      }
      return;
    }
    var minX = _bodies[0].x, maxX = _bodies[0].x;
    var minY = _bodies[0].y, maxY = _bodies[0].y;
    for (final b in _bodies) {
      if (b.x < minX) minX = b.x;
      if (b.x > maxX) maxX = b.x;
      if (b.y < minY) minY = b.y;
      if (b.y > maxY) maxY = b.y;
    }
    const pad = 40.0;
    final spanX = math.max(maxX - minX, 1.0);
    final spanY = math.max(maxY - minY, 1.0);
    final s = math.min((width - 2 * pad) / spanX, (height - 2 * pad) / spanY);
    for (final b in _bodies) {
      b.x = (b.x - minX) * s + pad;
      b.y = (b.y - minY) * s + pad;
    }
  }
}