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
}
