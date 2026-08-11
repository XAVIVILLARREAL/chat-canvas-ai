import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graph_core/graph_core.dart';
import 'package:empresa_dev/screens/project_graph_screen.dart';

void main() {
  final graph = Graph(
    nodes: const [
      GraphNode(id: 'src/main.dart', label: 'main.dart', kind: GraphNodeKind.dart, package: 'src'),
      GraphNode(id: 'src/helper.dart', label: 'helper.dart', kind: GraphNodeKind.dart, package: 'src'),
      GraphNode(id: 'notes/index.md', label: 'index.md', kind: GraphNodeKind.markdown, package: 'notes'),
    ],
    edges: const [
      GraphEdge(from: 'src/main.dart', to: 'src/helper.dart', kind: GraphEdgeKind.import),
      GraphEdge(from: 'notes/index.md', to: 'src/main.dart', kind: GraphEdgeKind.link),
    ],
  );

  testWidgets('renderiza los nodos del grafo', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ProjectGraphScreen(graph: graph, root: '.'),
    ));
    await tester.pump();

    expect(find.text('main.dart'), findsOneWidget);
    expect(find.text('helper.dart'), findsOneWidget);
    expect(find.text('index.md'), findsOneWidget);
  });

  testWidgets('hover muestra el preview del nodo', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ProjectGraphScreen(graph: graph, root: '.'),
    ));
    await tester.pump();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('main.dart')));
    await tester.pump();

    expect(find.textContaining('src/main.dart'), findsWidgets);
  });

  testWidgets('click en un nodo invoca onOpenFile', (tester) async {
    String? opened;
    await tester.pumpWidget(MaterialApp(
      home: ProjectGraphScreen(
        graph: graph,
        root: '.',
        onOpenFile: (path) => opened = path,
      ),
    ));
    await tester.pump();

    await tester.tap(find.text('main.dart'));
    await tester.pump();

    expect(opened, 'src/main.dart');
  });
}