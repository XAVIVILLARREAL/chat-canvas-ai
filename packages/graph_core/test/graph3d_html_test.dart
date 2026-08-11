import 'package:graph_core/graph_core.dart';
import 'package:test/test.dart';

void main() {
  final graph = Graph(
    nodes: const [
      GraphNode(id: 'src/main.dart', label: 'main.dart', kind: GraphNodeKind.dart, package: 'src'),
      GraphNode(id: 'notes/index.md', label: 'index.md', kind: GraphNodeKind.markdown, package: 'notes'),
    ],
    edges: const [
      GraphEdge(from: 'notes/index.md', to: 'src/main.dart', kind: GraphEdgeKind.link),
    ],
  );

  test('buildGraph3dHtml genera un HTML válido con Three.js', () {
    final html = buildGraph3dHtml(graph, positions: const {
      'src/main.dart': Offset2(100, 200),
      'notes/index.md': Offset2(300, 400),
    });

    expect(html, contains('<html'));
    expect(html, contains('three.min.js'));
    expect(html, contains('OrbitControls'));
    expect(html, contains('</html>'));
  });

  test('el JSON inyectado contiene nodos con posición y aristas', () {
    final html = buildGraph3dHtml(graph, positions: const {
      'src/main.dart': Offset2(100, 200),
      'notes/index.md': Offset2(300, 400),
    });

    expect(html, contains('"id":"src/main.dart"'));
    expect(html, contains('"label":"main.dart"'));
    expect(html, contains('"kind":"dart"'));
    expect(html, contains('"package":"src"'));
    expect(html, contains('"x":100.0'));
    expect(html, contains('"y":200.0'));
    expect(html, contains('"from":"notes/index.md"'));
    expect(html, contains('"kind":"link"'));
  });

  test('grafo vacío genera HTML con grafo vacío', () {
    final html = buildGraph3dHtml(Graph(nodes: const [], edges: const []));
    expect(html, contains('nodes:[]'));
    expect(html, contains('edges:[]'));
  });
}