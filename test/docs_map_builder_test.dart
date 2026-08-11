import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/services/docs_map_builder.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('docs_map');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  File md(String name, String body) {
    final f = File('${tmp.path}\\$name.md');
    f.writeAsStringSync(body);
    return f;
  }

  test('3 .md con [[links]] cruzados → nodos y edges correctos', () {
    md('plan', 'Mira [[meta]] y [[roadmap]]');
    md('meta', 'Objetivo, ver [[roadmap|Plan]]');
    md('roadmap', 'Fases');
    final state = DocsMapBuilder.build(tmp.path);
    expect(state.nodes.length, 3);
    expect(state.edges.length, 3);
    final plan = state.nodes.firstWhere((n) => n.label == 'plan');
    final meta = state.nodes.firstWhere((n) => n.label == 'meta');
    final road = state.nodes.firstWhere((n) => n.label == 'roadmap');
    expect(state.edges.where((e) => e.fromNodeId == plan.id).length, 2);
    expect(state.edges.where((e) => e.fromNodeId == meta.id).length, 1);
    expect(state.edges.every((e) => e.fromNodeId != e.toNodeId), isTrue);
    expect(road.content, 'Fases');
  });

  test('link a archivo inexistente → nodo placeholder', () {
    md('a', 'Habla de [[inexistente]]');
    final state = DocsMapBuilder.build(tmp.path);
    expect(state.nodes.length, 2);
    final placeholder = state.nodes.firstWhere((n) => n.label == 'inexistente');
    expect(placeholder.content, isNull);
    expect(state.edges.single.fromNodeId,
        state.nodes.firstWhere((n) => n.label == 'a').id);
    expect(state.edges.single.toNodeId, placeholder.id);
  });

  test('layout: posiciones distintas para nodos distintos', () {
    for (var i = 0; i < 5; i++) {
      md('nota$i', 'contenido $i');
    }
    final state = DocsMapBuilder.build(tmp.path);
    final positions = state.nodes.map((n) => '${n.x},${n.y}').toSet();
    expect(positions.length, 5);
  });

  test('carpeta sin .md → estado vacío', () {
    final state = DocsMapBuilder.build(tmp.path);
    expect(state.nodes, isEmpty);
    expect(state.edges, isEmpty);
  });

  test('carpeta inexistente → estado vacío sin lanzar', () {
    final state = DocsMapBuilder.build('${tmp.path}\\nope');
    expect(state.nodes, isEmpty);
  });
}
