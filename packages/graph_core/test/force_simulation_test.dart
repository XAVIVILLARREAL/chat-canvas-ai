import 'dart:math' as math;

import 'package:graph_core/force_simulation.dart';
import 'package:graph_core/models.dart';
import 'package:test/test.dart';

GraphNode node(String id) =>
    GraphNode(id: id, label: id.split('/').last, kind: GraphNodeKind.dart);

void main() {
  group('ForceSimulation', () {
    test('sin NaN tras pasos', () {
      final nodes = [for (var i = 0; i < 20; i++) node('n$i')];
      final sim = ForceSimulation(nodes, const []);
      for (var i = 0; i < 50; i++) {
        sim.step();
      }
      for (final n in nodes) {
        expect(sim.x(n.id).isNaN, isFalse);
        expect(sim.y(n.id).isNaN, isFalse);
        expect(sim.x(n.id).isInfinite, isFalse);
      }
    });

    test('nodos conectados convergen más cerca que los desconectados', () {
      final nodes = [for (var i = 0; i < 10; i++) node('n$i')];
      final edges = [
        for (var i = 0; i < 4; i++)
          GraphEdge(from: 'n$i', to: 'n${i + 1}', kind: GraphEdgeKind.import),
      ];
      final sim = ForceSimulation(nodes, edges);
      sim.layout(120);
      double dist(String a, String b) =>
          math.sqrt(math.pow(sim.x(a) - sim.x(b), 2) +
              math.pow(sim.y(a) - sim.y(b), 2));
      final connected = dist('n0', 'n1');
      final disconnected = dist('n0', 'n8');
      expect(connected, lessThan(disconnected));
    });

    test('converge: delta de movimiento decrece con alpha', () {
      final nodes = [for (var i = 0; i < 30; i++) node('n$i')];
      final edges = [
        for (var i = 0; i < 20; i++)
          GraphEdge(from: 'n${i % 30}',
              to: 'n${(i * 7 + 1) % 30}',
              kind: GraphEdgeKind.import),
      ];
      final sim = ForceSimulation(nodes, edges);
      final d1 = sim.step();
      for (var i = 0; i < 40; i++) {
        sim.step();
      }
      final d2 = sim.step();
      expect(d2, lessThan(d1));
    });

    test('layout autofit: posiciones dentro del viewport', () {
      final nodes = [for (var i = 0; i < 15; i++) node('n$i')];
      final sim = ForceSimulation(nodes, const []);
      sim.layout(100, width: 400, height: 300);
      for (final n in nodes) {
        expect(sim.x(n.id), inInclusiveRange(0, 400));
        expect(sim.y(n.id), inInclusiveRange(0, 300));
      }
    });
  });
}