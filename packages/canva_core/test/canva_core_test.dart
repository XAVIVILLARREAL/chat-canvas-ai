import 'package:test/test.dart';
import 'package:canva_core/canva.dart';

void main() {
  test('CanvaNodeId.generate produce IDs únicos', () {
    final a = CanvasNodeId.generate();
    final b = CanvasNodeId.generate();
    expect(a, isNot(equals(b)));
  });

  test('CanvasNode serializa round-trip', () {
    final n = CanvasNode(
      id: CanvasNodeId('w1:2:0'),
      label: 'nodo',
      kind: NodeKind.note,
      x: 5,
      y: 7,
    );
    final json = n.toJson();
    expect(json['label'], 'nodo');
  });

  test('CanvaState round-trip JSON preserva nodos y edges', () {
    final state = CanvaState(
      nodes: [
        CanvaNode(id: 'a', type: CanvaNodeType.host, x: 100, y: 100, label: 'pve', hostId: 'pve'),
        CanvaNode(id: 'b', type: CanvaNodeType.note, x: 300, y: 200, label: 'nota'),
      ],
      edges: [CanvaEdge(id: 'e1', fromNodeId: 'a', toNodeId: 'b')],
    );
    final back = CanvaState.fromJson(state.toJson());
    expect(back.nodes.length, 2);
    expect(back.edges.length, 1);
  });
}
