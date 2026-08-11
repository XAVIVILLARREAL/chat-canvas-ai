import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graph_core/graph_core.dart';
import 'project_graph_3d_screen.dart';

/// Grafo del proyecto: nodos = archivos (cluster por paquete), aristas =
/// imports/links. Layout con física de fuerzas (headless, layout() síncrono).
/// Hover = preview; click = abre el archivo.
class ProjectGraphScreen extends StatefulWidget {
  final Graph graph;
  final String root;
  final void Function(String path)? onOpenFile;

  const ProjectGraphScreen({
    super.key,
    required this.graph,
    required this.root,
    this.onOpenFile,
  });

  @override
  State<ProjectGraphScreen> createState() => _ProjectGraphScreenState();
}

class _ProjectGraphScreenState extends State<ProjectGraphScreen> {
  late ForceSimulation _sim;
  String? _hoveredId;

  static const _palette = [
    Color(0xFF22D3EE),
    Color(0xFFA855F7),
    Color(0xFF4ADE80),
    Color(0xFFF59E0B),
    Color(0xFFF472B6),
    Color(0xFF60A5FA),
  ];

  @override
  void initState() {
    super.initState();
    _sim = ForceSimulation(widget.graph.nodes, widget.graph.edges);
    _sim.layout(200);
  }

  Color _colorFor(String package) {
    final stable = package.hashCode & 0x7FFFFFFF;
    return _palette[stable % _palette.length];
  }

  void _onNodeTap(String id) {
    widget.onOpenFile?.call(id);
  }

  void _open3D() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProjectGraph3DScreen(graph: widget.graph),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('3D solo en desktop')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nodes = widget.graph.nodes;
    if (nodes.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No hay archivos relevantes en el proyecto')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grafo del proyecto'),
        actions: [
          IconButton(
            tooltip: 'Ver grafo 3D',
            icon: const Icon(Icons.view_in_ar),
            onPressed: _open3D,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${nodes.length} nodos · ${widget.graph.edges.length} aristas · '
                'colores = paquete — hover preview, click abre',
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ),
          ),
        ),
      ),
      body: InteractiveViewer(
        constrained: false,
        minScale: 0.2,
        maxScale: 4,
        child: SizedBox(
          width: 1200,
          height: 900,
          child: Stack(
            children: [
              CustomPaint(
                size: const Size(1200, 900),
                painter: _EdgesPainter(
                  edges: widget.graph.edges,
                  pos: (id) => Offset(_sim.x(id), _sim.y(id)),
                ),
              ),
              for (final node in nodes)
                Positioned(
                  left: _sim.x(node.id),
                  top: _sim.y(node.id),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hoveredId = node.id),
                    onExit: (_) => setState(() => _hoveredId = null),
                    child: Tooltip(
                      message: node.id,
                      child: GestureDetector(
                        onTap: () => _onNodeTap(node.id),
                        child: _NodeChip(
                          label: node.label,
                          color: _colorFor(node.package),
                          highlighted: _hoveredId == node.id,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NodeChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool highlighted;

  const _NodeChip({
    required this.label,
    required this.color,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: highlighted ? 0.9 : 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? color : color.withValues(alpha: 0.6),
          width: highlighted ? 2 : 1,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          shadows: highlighted ? [Shadow(color: color, blurRadius: 6)] : null,
        ),
      ),
    );
  }
}

class _EdgesPainter extends CustomPainter {
  final List<GraphEdge> edges;
  final Offset Function(String id) pos;

  _EdgesPainter({required this.edges, required this.pos});

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in edges) {
      final a = pos(e.from);
      final b = pos(e.to);
      if (a == Offset.zero || b == Offset.zero) continue;
      final paint = Paint()
        ..color = e.kind == GraphEdgeKind.import
            ? const Color(0x5522D3EE)
            : const Color(0x55A855F7)
        ..strokeWidth = 1;
      canvas.drawLine(a + const Offset(30, 10), b + const Offset(30, 10), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgesPainter old) => old.edges != edges;
}