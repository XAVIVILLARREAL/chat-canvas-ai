import 'package:flutter/material.dart';
import 'package:canva_core/canva.dart';

/// Callbacks que el motor provee para construir el widget de un nodo en modo
/// simple (≤ umbral LOD).
class CanvaNodeCallbacks {
  final bool connectMode;
  final void Function(double x, double y) onMoved;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;

  const CanvaNodeCallbacks({
    required this.connectMode,
    required this.onMoved,
    required this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  });
}

/// Motor de canva reutilizable (ADR-004): renderiza CUALQUIER lista de
/// [CanvaNode] sobre un InteractiveViewer con culling por viewport, clusters
/// por zoom (SDD-121) y canvas LOD para miles de nodos. Sin lógica de dominio:
/// la pantalla decide qué nodo se toca, se arrastra o se conecta.
class CanvaView extends StatefulWidget {
  final List<CanvaNode> nodes;
  final List<CanvaEdge> edges;

  /// Construye el widget de un nodo (modo simple). El motor provee los
  /// callbacks de gesto/posición; la pantalla decide el estilo y las acciones.
  final Widget Function(CanvaNode node, CanvaNodeCallbacks cb) nodeBuilder;

  /// Tap sobre un nodo (modo simple y modo LOD vía hit-test del canvas).
  final void Function(CanvaNode node) onNodeTap;

  /// Doble tap sobre un nodo (solo modo simple; el canvas LOD no lo soporta).
  final void Function(CanvaNode node)? onNodeDoubleTap;

  /// Long-press sobre un nodo (modo simple y modo LOD).
  final void Function(CanvaNode node)? onNodeLongPress;

  /// Drag: el motor actualizó el índice espacial; la pantalla persiste.
  final void Function(CanvaNode node, double x, double y) onNodeMoved;

  /// Nodo en modo "conectar" (highlight).
  final String? connectModeId;

  const CanvaView({
    super.key,
    required this.nodes,
    required this.edges,
    required this.nodeBuilder,
    required this.onNodeTap,
    required this.onNodeMoved,
    this.onNodeDoubleTap,
    this.onNodeLongPress,
    this.connectModeId,
  });

  @override
  State<CanvaView> createState() => _CanvaViewState();
}

class _CanvaViewState extends State<CanvaView> {
  // Umbrales LOD (SDD-121): tuneables; los tests fijan explícitamente la escala.
  static const _kLodThreshold = 300;
  static const _kClusterScale = 0.6;
  static const _kClusterCellSize = 160.0;
  // Tamaño del card de nodo en coords del canva (dibujado en el canvas LOD).
  static const _kLodNodeW = 150.0;
  static const _kLodNodeH = 44.0;

  late final TransformationController _tc =
      TransformationController()..addListener(_onTransformChanged);
  CanvaCuller? _culler;
  /// Nodos del último frame LOD (para hit-test manual sobre el canvas).
  List<CanvaNode>? _lastLodNodes;

  void _onTransformChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant CanvaView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // docs-map sustituye la lista entera (misma longitud posible): reconstruir.
    if (!identical(oldWidget.nodes, widget.nodes)) {
      _culler = null;
    }
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  /// Nodos a renderizar en este frame (culling + clusters por zoom).
  /// Modo simple (≤ [ _kLodThreshold]) = widgets por nodo (vía [nodeBuilder]).
  ({List<CanvaNode> nodes, List<CanvaCluster> clusters}) _lodRender(Rect viewport) {
    final nodes = widget.nodes;
    if (nodes.length <= _kLodThreshold) {
      _culler = null;
      _lastLodNodes = null;
      return (nodes: nodes, clusters: const []);
    }
    // Reconstruir el índice si cambió la cantidad (add/remove in-place) o es
    // la primera vez.
    if (_culler == null || _culler!.nodeCount != nodes.length) {
      _culler = CanvaCuller(nodes);
    }
    final inv = Matrix4.tryInvert(_tc.value) ?? Matrix4.identity();
    final rect = MatrixUtils.transformRect(inv, viewport);
    final visible = _culler!.visibleIn(CanvaRect(
      x: rect.left,
      y: rect.top,
      width: rect.width,
      height: rect.height,
    ));
    final scale = _tc.value.getMaxScaleOnAxis();
    if (scale < _kClusterScale) {
      final clusterer = CanvaClusterer(visible, cellSize: _kClusterCellSize);
      final standalone = clusterer.standaloneFor(scale);
      _lastLodNodes = standalone;
      return (
        nodes: standalone,
        clusters: clusterer.clustersFor(scale),
      );
    }
    _lastLodNodes = visible;
    return (nodes: visible, clusters: const []);
  }

  /// Hit-test manual sobre el canvas LOD (coords del canva).
  CanvaNode? _nodeAt(Offset p) {
    final nodes = _lastLodNodes;
    if (nodes == null) return null;
    for (final n in nodes) {
      if (p.dx >= n.x &&
          p.dx <= n.x + _kLodNodeW &&
          p.dy >= n.y &&
          p.dy <= n.y + _kLodNodeH) {
        return n;
      }
    }
    return null;
  }

  void _onLodNodeTap(Offset canvaPos) {
    final n = _nodeAt(canvaPos);
    if (n != null) widget.onNodeTap(n);
  }

  void _onLodNodeLongPress(Offset canvaPos) {
    final n = _nodeAt(canvaPos);
    if (n != null) widget.onNodeLongPress?.call(n);
  }

  /// Zoom-in 2x centrado en el centroide del cluster.
  void _zoomToCluster(CanvaCluster c) {
    final m = Matrix4.identity()
      ..translate(c.x, c.y)
      ..scale(2.0)
      ..translate(-c.x, -c.y);
    _tc.value = _tc.value.clone()..multiply(m);
  }

  CanvaNodeCallbacks _callbacksFor(CanvaNode node) => CanvaNodeCallbacks(
        connectMode: node.id == widget.connectModeId,
        onMoved: (x, y) {
          _culler?.move(node.id, x, y);
          widget.onNodeMoved(node, x, y);
        },
        onTap: () => widget.onNodeTap(node),
        onDoubleTap: widget.onNodeDoubleTap == null
            ? null
            : () => widget.onNodeDoubleTap!(node),
        onLongPress: widget.onNodeLongPress == null
            ? null
            : () => widget.onNodeLongPress!(node),
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Offset.zero & constraints.biggest;
        final render = _lodRender(viewport);
        final byId = {
          for (final n in render.nodes) n.id: n,
        };
        final visibleEdges = [
          for (final e in widget.edges)
            if (byId.containsKey(e.fromNodeId) &&
                byId.containsKey(e.toNodeId))
              e,
        ];
        return InteractiveViewer(
          transformationController: _tc,
          constrained: false,
          minScale: 0.3,
          maxScale: 3,
          boundaryMargin: const EdgeInsets.all(4000),
          child: SizedBox(
            width: 3000,
            height: 2000,
            child: Stack(
              children: [
                // conexiones (solo extremos visibles)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _EdgesPainter(edges: visibleEdges, byId: byId),
                  ),
                ),
                // clusters en zoom-out
                for (final c in render.clusters)
                  Positioned(
                    left: c.x - 22,
                    top: c.y - 22,
                    child: _ClusterChip(
                      count: c.count,
                      onTap: () => _zoomToCluster(c),
                    ),
                  ),
                // nodos: modo simple = widget por nodo (drag fino); LOD =
                // canvas único (miles de nodos sin widgets pesados → evita el
                // bug del engine 3.32 y mantiene 30fps).
                if (widget.nodes.length <= _kLodThreshold)
                  for (final node in render.nodes)
                    Positioned(
                      left: node.x,
                      top: node.y,
                      child: widget.nodeBuilder(node, _callbacksFor(node)),
                    )
                else
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) => _onLodNodeTap(d.localPosition),
                      onLongPressStart: (d) =>
                          _onLodNodeLongPress(d.localPosition),
                      child: CustomPaint(
                        painter: _LodCanvasPainter(nodes: render.nodes),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Render LOD de miles de nodos con UN solo CustomPainter: dibuja los cards
/// (RRect + borde) y los labels SOLO si hay pocos nodos visibles. Evita
/// construir miles de widgets pesados (sombras/AnimatedContainer), que rompen
/// el engine 3.32 con `BackdropFilter` y matan los fps.
class _LodCanvasPainter extends CustomPainter {
  final List<CanvaNode> nodes;

  // Labels como texto de canvas solo si hay pocos nodos visibles.
  static const _labelMax = 250;

  _LodCanvasPainter({required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    final drawLabels = nodes.length <= _labelMax;
    for (final n in nodes) {
      final color = Color(n.colorValue);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(n.x, n.y, 150, 44),
        const Radius.circular(10),
      );
      canvas.drawRRect(rrect, Paint()..color = color.withValues(alpha: 0.65));
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      if (drawLabels) {
        final tp = TextPainter(
          text: TextSpan(
            text: n.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          maxLines: 1,
          ellipsis: '…',
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 150 - 12);
        tp.paint(canvas, Offset(n.x + 8, n.y + (44 - tp.height) / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LodCanvasPainter oldDelegate) =>
      oldDelegate.nodes != nodes;
}

/// Chip de cluster (zoom-out): círculo con contador + glow; tap = zoom-in 2x.
class _ClusterChip extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _ClusterChip({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFA855F7).withValues(alpha: 0.8),
              Color(0xFF22D3EE).withValues(alpha: 0.35),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA855F7).withValues(alpha: 0.45),
              blurRadius: 18,
            ),
          ],
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EdgesPainter extends CustomPainter {
  final List<CanvaEdge> edges;
  final Map<String, CanvaNode> byId;

  _EdgesPainter({required this.edges, required this.byId});

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in edges) {
      final from = byId[e.fromNodeId];
      final to = byId[e.toNodeId];
      if (from == null || to == null) continue;
      final color = Color(from.colorValue);
      final a = Offset(from.x + 85, from.y + 28);
      final b = Offset(to.x + 85, to.y + 28);
      final paint = Paint()
        ..color = color.withValues(alpha: 0.45)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(a, b, paint);
      _drawArrow(canvas, a, b, Paint()
        ..color = color.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill);
    }
  }

  void _drawArrow(Canvas canvas, Offset a, Offset b, Paint paint) {
    final dir = (b - a);
    if (dir.distance < 1) return;
    final norm = dir / dir.distance;
    final perp = Offset(-norm.dy, norm.dx);
    const size = 8.0;
    final tip = b;
    final p1 = tip - norm * size + perp * size * 0.7;
    final p2 = tip - norm * size - perp * size * 0.7;
    final path = Path()..moveTo(tip.dx, tip.dy)..lineTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EdgesPainter oldDelegate) =>
      oldDelegate.edges != edges || oldDelegate.byId != byId;
}
