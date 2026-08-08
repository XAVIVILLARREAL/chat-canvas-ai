import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/models/canva.dart';

void main() {
  group('CanvaNode', () {
    test('serializa y deserializa un nodo host', () {
      final n = CanvaNode(
        id: 'n1',
        type: CanvaNodeType.host,
        x: 100,
        y: 200,
        label: 'pve',
        hostId: 'pve',
        colorHex: '#0EA5E9',
      );
      final json = n.toJson();
      final back = CanvaNode.fromJson(json);
      expect(back.id, 'n1');
      expect(back.type, CanvaNodeType.host);
      expect(back.x, 100);
      expect(back.y, 200);
      expect(back.hostId, 'pve');
      expect(back.colorValue, 0xFF0EA5E9);
    });

    test('serializa y deserializa un nodo nota', () {
      final n = CanvaNode(id: 'n2', type: CanvaNodeType.note, x: 5, y: 6, label: 'hola');
      final back = CanvaNode.fromJson(n.toJson());
      expect(back.type, CanvaNodeType.note);
      expect(back.hostId, isNull);
      expect(back.label, 'hola');
    });
  });

  group('CanvaState', () {
    test('roundtrip JSON preserva nodos y edges', () {
      final state = CanvaState(
        nodes: [
          CanvaNode(id: 'a', type: CanvaNodeType.host, x: 1, y: 2, label: 'a', hostId: 'a'),
          CanvaNode(id: 'b', type: CanvaNodeType.note, x: 3, y: 4, label: 'b'),
        ],
        edges: [CanvaEdge(id: 'e1', fromNodeId: 'a', toNodeId: 'b')],
      );
      final json = jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>;
      final back = CanvaState.fromJson(json);
      expect(back.nodes.length, 2);
      expect(back.edges.length, 1);
      expect(back.edges.first.fromNodeId, 'a');
      expect(back.edges.first.toNodeId, 'b');
    });

    test('empty es valido', () {
      final s = CanvaState.empty();
      expect(s.nodes, isEmpty);
      expect(s.edges, isEmpty);
    });
  });
}
