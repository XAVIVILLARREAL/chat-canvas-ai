import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/models/canvas_node.dart';
import 'package:empresa_dev/services/agent_detector.dart';

void main() {
  group('CanvasNodeId', () {
    test('genera IDs con formato w<sec>:w<ms>', () {
      final id = CanvasNodeId.generate();
      expect(id.value, matches(RegExp(r'^w\d+:\d+:\d+$')));
    });

    test('IDs consecutivos distintos', () {
      final a = CanvasNodeId.generate();
      final b = CanvasNodeId.generate();
      expect(a.value, isNot(b.value));
    });

    test('1000 generaciones sin colisión (IDs opacos únicos)', () {
      final seen = <String>{};
      for (var i = 0; i < 1000; i++) {
        seen.add(CanvasNodeId.generate().value);
      }
      expect(seen.length, 1000);
    });
  });

  group('CanvasNode', () {
    test('toJson/fromJson round-trip conserva todo', () {
      final node = CanvasNode(
        id: CanvasNodeId('w1:2'),
        label: 'PVE',
        kind: NodeKind.host,
        x: 10.5,
        y: -3,
        color: 0xFF1122334455,
        content: 'nota',
      );
      final restored = CanvasNode.fromJson(node.toJson());
      expect(restored.id.value, 'w1:2');
      expect(restored.label, 'PVE');
      expect(restored.kind, NodeKind.host);
      expect(restored.x, 10.5);
      expect(restored.y, -3);
      expect(restored.color, 0xFF1122334455);
      expect(restored.content, 'nota');
    });

    test('copyWith cambia solo el campo indicado y preserva el id', () {
      final node = CanvasNode(id: CanvasNodeId('w1:2'), label: 'A', kind: NodeKind.note);
      final moved = node.copyWith(x: 99);
      expect(moved.x, 99);
      expect(moved.id.value, node.id.value);
      expect(moved.label, 'A');
      expect(moved.kind, NodeKind.note);
    });

    test('el runtime del agente no vive en el modelo', () {
      final node = CanvasNode(id: CanvasNodeId('w1:2'), label: 'A', kind: NodeKind.agent);
      expect(node is AgentNodeRuntime, isFalse);
      expect(node.toJson().containsKey('running'), isFalse);
    });
  });

  group('AgentNodeRuntime', () {
    test('se actualiza el estado con el detector', () {
      final runtime = AgentNodeRuntime();
      runtime.buffer.write('esc to interrupt');
      runtime.detection = AgentDetector().detect(runtime.buffer.toString());
      expect(runtime.detection.state, AgentState.working);
      expect(runtime.running, isFalse);
    });
  });
}