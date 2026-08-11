import 'package:flutter/material.dart';
import 'package:graph_core/graph_core.dart';
import '../views/project_graph_3d_view.dart';

/// Pantalla del grafo 3D (WebView2 + Three.js).
///
/// Solo desktop Windows: si la plataforma no soporta la vista (mobile/web),
/// muestra fallback: mensaje + botón para volver al 2D (el grafo 2D ya es el
/// fallback de navegación en esas plataformas).
class ProjectGraph3DScreen extends StatefulWidget {
  final Graph graph;

  const ProjectGraph3DScreen({super.key, required this.graph});

  @override
  State<ProjectGraph3DScreen> createState() => _ProjectGraph3DScreenState();
}

class _ProjectGraph3DScreenState extends State<ProjectGraph3DScreen> {
  late Map<String, Offset2> _positions;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final sim = ForceSimulation(widget.graph.nodes, widget.graph.edges)
      ..layout(200);
    _positions = {
      for (final n in widget.graph.nodes) n.id: Offset2(sim.x(n.id), sim.y(n.id)),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grafo 3D'),
        actions: [
          if (_loaded)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                    SizedBox(width: 6),
                    Text('3D cargado', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: ProjectGraph3DView(
        graph: widget.graph,
        positions: _positions,
        onLoaded: () {
          if (mounted && !_loaded) setState(() => _loaded = true);
        },
        onNativeError: () => _showFallback(),
      ),
    );
  }

  void _showFallback() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('3D solo en desktop — usando 2D')),
    );
    Navigator.of(context).maybePop();
  }
}