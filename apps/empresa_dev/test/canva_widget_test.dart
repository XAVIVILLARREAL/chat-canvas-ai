import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:canva_core/canva.dart';
import 'package:empresa_dev/screens/canva_screen.dart';
import 'package:empresa_dev/services/canva_store.dart';
import 'package:empresa_dev/services/ssh_service.dart';

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
}
