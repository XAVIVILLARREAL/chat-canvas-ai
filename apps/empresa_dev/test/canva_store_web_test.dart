import 'package:empresa_dev/services/canva_store.dart';
import 'package:canva_core/canva.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCanvaStorage implements CanvaStorage {
  String? stored;
  @override
  Future<String?> read() async => stored;
  @override
  Future<void> write(String data) async => stored = data;
}

void main() {
  group('CanvaStore con storage inyectado (base web/io)', () {
    test('save -> load round-trip conserva nodos y edges', () async {
      final storage = FakeCanvaStorage();
      final store = CanvaStore(storage: storage);

      final state = CanvaState(
        nodes: [
          CanvaNode(id: 'a', type: CanvaNodeType.note, x: 12, y: 34, label: 'nota'),
        ],
        edges: [CanvaEdge(id: 'e1', fromNodeId: 'a', toNodeId: 'b')],
      );
      await store.save(state);

      final loaded = await store.load();
      expect(loaded.nodes, hasLength(1));
      expect(loaded.nodes.first.label, 'nota');
      expect(loaded.nodes.first.type, CanvaNodeType.note);
      expect(loaded.edges, hasLength(1));
      expect(loaded.edges.first.fromNodeId, 'a');
    });

    test('load con storage vacío (null) -> CanvaState.empty()', () async {
      final store = CanvaStore(storage: FakeCanvaStorage());
      final loaded = await store.load();
      expect(loaded.nodes, isEmpty);
      expect(loaded.edges, isEmpty);
    });

    test('load con JSON corrupto -> CanvaState.empty() sin excepción', () async {
      final store = CanvaStore(storage: FakeCanvaStorage()..stored = '{{{no json');
      final loaded = await store.load();
      expect(loaded.nodes, isEmpty);
    });

    test('write falla -> save no revienta (mismo contrato que archivo)', () async {
      final store = CanvaStore(storage: _ThrowingStorage());
      await store.save(CanvaState.empty());
      // sin excepción = OK
    });

    test('defaultCanvaStorage devuelve impl no-null para la plataforma', () {
      // En VM/io resuelve a FileCanvaStorage; en web a WebCanvaStorage.
      expect(defaultCanvaStorage(), isNotNull);
    });
  });
}

class _ThrowingStorage implements CanvaStorage {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String data) async => throw Exception('disco lleno');
}
