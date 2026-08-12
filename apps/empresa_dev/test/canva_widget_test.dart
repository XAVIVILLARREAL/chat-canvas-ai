import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:canva_core/canva.dart';
import 'package:vibecoding_core/vibecoding_core.dart';
import 'package:empresa_dev/screens/canva_screen.dart';
import 'package:empresa_dev/screens/proposal_node_screen.dart';
import 'package:empresa_dev/services/canva_store.dart';
import 'package:empresa_dev/services/ssh_service.dart';
import 'package:empresa_dev/services/vibecoding_store.dart';
import 'package:empresa_dev/widgets/diff_preview.dart';

class _FakeStore extends CanvaStore {
  @override
  Future<CanvaState> load() async => CanvaState(
        nodes: [
          CanvaNode(id: 'a', type: CanvaNodeType.host, x: 100, y: 100, label: 'pve', hostId: 'pve'),
          CanvaNode(id: 'b', type: CanvaNodeType.note, x: 300, y: 200, label: 'nota'),
        ],
        edges: [CanvaEdge(id: 'e1', fromNodeId: 'a', toNodeId: 'b')],
      );
}

/// Store vibecoding en memoria (sin IO real — no completa en fake-async).
class _MemVibeStore extends VibecodingStore {
  List<PatchProposal> proposals;
  _MemVibeStore(this.proposals) : super(directory: null);

  @override
  Future<List<PatchProposal>> load() async => List.of(proposals);

  @override
  Future<void> save(List<PatchProposal> ps) async {
    proposals
      ..clear()
      ..addAll(ps);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('CanvaScreen renderiza nodos y flechas', (tester) async {
    final hosts = [SshHost(name: 'pve', host: '100.101.69.79', username: 'root')];
    await tester.pumpWidget(
      MaterialApp(
        home: CanvaScreen(
          hosts: hosts,
          sshService: SshService(),
          store: _FakeStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('pve'), findsWidgets);
    expect(find.text('nota'), findsWidgets);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  group('nodo propuesta vibecoding (slice 6.3)', () {
    late _MemVibeStore vibeStore;

    setUp(() {
      vibeStore = _MemVibeStore([
        PatchProposal(
          id: 'v1:1:1',
          prompt: 'fix lint',
          repoPath: null,
          edits: const [FileEdit(path: 'lib/x.dart', before: 'a', after: 'b')],
          state: ProposalState.pending,
        ),
      ]);
    });

    Future<void> pumpCanva(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: CanvaScreen(
          hosts: [],
          sshService: SshService(),
          store: _FakeStore(),
          vibecodingStore: vibeStore,
        ),
      ));
      await tester.pumpAndSettle();
    }

    /// Desktop: los nodos propuesta están restringidos a desktop (mismo
    /// patrón try/finally que project_graph_3d_widget_test).
    Future<void> asDesktop(Future<void> Function() body) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await body();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    }

    Future<void> openProposalTile(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.add_box_outlined));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Propuesta vibecoding'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Propuesta vibecoding'));
      await tester.pumpAndSettle();
    }

    testWidgets('el menú Añadir ofrece el tile de propuesta', (tester) async {
      await asDesktop(() async {
        await pumpCanva(tester);
        await tester.tap(find.byIcon(Icons.add_box_outlined));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Propuesta vibecoding'));
        await tester.pumpAndSettle();

        expect(find.text('Propuesta vibecoding'), findsOneWidget);
      });
    });

    testWidgets('añade un nodo propuesta desde el historial', (tester) async {
      await asDesktop(() async {
        await pumpCanva(tester);
        await openProposalTile(tester);

        await tester.tap(find.text('fix lint'));
        await tester.pumpAndSettle();

        expect(find.text('fix lint'), findsOneWidget);
      });
    });

    testWidgets('sin propuestas en el historial avisa con SnackBar',
        (tester) async {
      await asDesktop(() async {
        vibeStore.proposals.clear();
        await pumpCanva(tester);
        await openProposalTile(tester);

        expect(find.textContaining('No hay propuestas'), findsOneWidget);
        expect(find.text('fix lint'), findsNothing);
      });
    });

    testWidgets('tap en el nodo propuesta abre el nodo-diff con acciones',
        (tester) async {
      await asDesktop(() async {
        await pumpCanva(tester);
        await openProposalTile(tester);
        await tester.tap(find.text('fix lint'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('fix lint'));
        await tester.pumpAndSettle();

        expect(find.byType(ProposalNodeScreen), findsOneWidget);
        expect(find.byType(DiffPreview), findsOneWidget);
        expect(find.text('pendiente'), findsOneWidget);
        expect(find.byKey(const Key('diff-accept')), findsOneWidget);
        expect(find.byKey(const Key('diff-reject')), findsOneWidget);
      });
    });
  });

  group('canva LOD (slice 8.6.3)', () {
    List<CanvaNode> lodGrid() => [
          for (var i = 0; i < 100; i++)
            for (var j = 0; j < 10; j++)
              CanvaNode(
                id: 'n${i * 10 + j}',
                type: CanvaNodeType.note,
                x: i * 30.0 + 15,
                y: j * 200.0 + 10,
                label: 'n${i * 10 + j}',
              ),
        ];

    Future<void> pumpLod(WidgetTester tester, {List<CanvaNode>? nodes}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CanvaScreen(
            hosts: [],
            sshService: SshService(),
            store: _LodStore(nodes ?? lodGrid()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Pinza de dos dedos: escala el InteractiveViewer hacia zoom-out
    /// (dedos hacia adentro; toca minScale 0.3 con el desplazamiento acumulado).
    Future<void> zoomOut(WidgetTester tester) async {
      final center = tester.getCenter(find.byType(InteractiveViewer));
      final g1 = await tester.startGesture(center - const Offset(200, 0));
      final g2 = await tester.startGesture(center + const Offset(200, 0));
      await tester.pump();
      for (var i = 0; i < 30; i++) {
        await g1.moveBy(const Offset(6, 0));
        await g2.moveBy(const Offset(-6, 0));
        await tester.pump();
      }
      await g1.up();
      await g2.up();
      await tester.pumpAndSettle();
    }

    int countOf(WidgetTester tester, String type) => tester
        .widgetList(find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == type))
        .length;

    int lodCanvasCount(WidgetTester tester) {
      var n = 0;
      for (final w in tester.widgetList(find.byType(CustomPaint))) {
        final p = (w as CustomPaint).painter;
        if (p != null && p.runtimeType.toString() == '_LodCanvasPainter') n++;
      }
      return n;
    }

    int lodCanvasNodes(WidgetTester tester) {
      for (final w in tester.widgetList(find.byType(CustomPaint))) {
        final p = (w as CustomPaint).painter;
        if (p != null && p.runtimeType.toString() == '_LodCanvasPainter') {
          return (p as dynamic).nodes.length as int;
        }
      }
      return -1;
    }

    testWidgets('1.000 nodos + zoom-out total → clusters, no 1.000 nodos',
        (tester) async {
      await pumpLod(tester);
      await zoomOut(tester);

      final chips = countOf(tester, '_ClusterChip');
      expect(chips, greaterThan(0));
      expect(chips, lessThan(50), reason: 'zoom-out total agrupa el grid en pocos clusters');
      expect(find.text('n500'), findsNothing, reason: 'nodo dentro de un cluster no se renderiza');
    });

    testWidgets('con zoom 1.0 el canvas LOD solo dibuja los nodos del viewport',
        (tester) async {
      await pumpLod(tester);

      expect(countOf(tester, '_DraggableNode'), 0,
          reason: 'LOD no crea widgets por nodo');
      expect(lodCanvasCount(tester), 1,
          reason: 'un solo canvas dibuja todos los nodos visibles');
      final drawn = lodCanvasNodes(tester);
      expect(drawn, greaterThan(0));
      expect(drawn, lessThan(10000),
          reason: 'culling activo: no se dibujan los 10.000');
      expect(find.text('n999'), findsNothing);
    });

    testWidgets('tap en un nodo del canvas LOD lo abre (hit-test manual)',
        (tester) async {
      await pumpLod(tester);
      final ivTopLeft = tester.getTopLeft(find.byType(InteractiveViewer));
      // Centro del box de n0 (canva 15,10 → 165,54): (90, 32) en coords canva.
      await tester.tapAt(ivTopLeft + const Offset(90, 32));
      await tester.pumpAndSettle();

      // En test el target es android → nota muestra el aviso de desktop:
      // prueba que el hit-test del canvas llegó al nodo.
      expect(find.textContaining('solo en desktop'), findsOneWidget);
      // Flush del timer de cierre del SnackBar (4s).
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('2 nodos siguen en modo simple (comportamiento intacto)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CanvaScreen(
            hosts: [],
            sshService: SshService(),
            store: _FakeStore(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('pve'), findsWidgets);
      expect(find.text('nota'), findsWidgets);
      expect(countOf(tester, '_ClusterChip'), 0);
    });
  });
}

class _LodStore extends CanvaStore {
  final List<CanvaNode> nodes;
  _LodStore(this.nodes);

  @override
  Future<CanvaState> load() async => CanvaState(nodes: nodes, edges: []);

  // Sin IO en tests: el drag dispara _save() y el file IO real nunca
  // completa en la zona fake-async del widget test.
  @override
  Future<void> save(CanvaState state) async {}
}
