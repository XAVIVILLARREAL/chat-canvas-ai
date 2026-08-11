import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graph_core/graph_core.dart';
import 'package:empresa_dev/screens/project_graph_3d_screen.dart';
import 'package:empresa_dev/screens/project_graph_screen.dart';

void main() {
  final graph = Graph(
    nodes: const [
      GraphNode(id: 'src/main.dart', label: 'main.dart', kind: GraphNodeKind.dart, package: 'src'),
      GraphNode(id: 'notes/index.md', label: 'index.md', kind: GraphNodeKind.markdown, package: 'notes'),
    ],
    edges: const [
      GraphEdge(from: 'src/main.dart', to: 'notes/index.md', kind: GraphEdgeKind.import),
    ],
  );

  testWidgets('en plataforma no-desktop el botón 3D no navega (fallback 2D)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(MaterialApp(
        home: ProjectGraphScreen(graph: graph, root: '.'),
      ));
      await tester.pump();

      await tester.tap(find.byTooltip('Ver grafo 3D'));
      await tester.pump();

      // SnackBar de fallback, sin nueva pantalla 3D
      expect(find.text('3D solo en desktop'), findsOneWidget);
      expect(find.byType(ProjectGraph3DScreen), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('ProjectGraph3DScreen en plataforma no soportada hace fallback', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(MaterialApp(
        home: ProjectGraph3DScreen(graph: graph),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // onNativeError → SnackBar + pop de la pantalla
      expect(find.text('3D solo en desktop — usando 2D'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('ProjectGraph3DScreen renderiza AppBar con título', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ProjectGraph3DScreen(graph: graph),
    ));
    await tester.pump();

    expect(find.text('Grafo 3D'), findsOneWidget);

    // limpiar timers pendientes del view (server/controller no arrancan en test)
    await tester.pumpWidget(const SizedBox());
  });
}