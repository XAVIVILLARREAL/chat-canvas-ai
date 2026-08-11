import 'dart:io';

import 'package:graph_core/models.dart';
import 'package:graph_core/relation_indexer.dart';
import 'package:test/test.dart';

void main() {
  final fixture = Directory('test/fixtures/graph_fixture');

  late Graph graph;
  setUpAll(() {
    graph = RelationIndexer.scan(fixture.path);
  });

  test('escanea archivos relevantes y asigna kind', () {
    final ids = graph.nodes.map((n) => n.id).toSet();
    expect(ids, contains('src/main.dart'));
    expect(ids, contains('src/helper.dart'));
    expect(ids, contains('src/script.py'));
    expect(ids, contains('notes/index.md'));
    expect(ids, contains('notes/guia.md'));
    final mainNode = graph.nodes.firstWhere((n) => n.id == 'src/main.dart');
    expect(mainNode.kind, GraphNodeKind.dart);
    expect(mainNode.label, 'main.dart');
  });

  test('detecta imports de dart: package: y relativo', () {
    final fromMain = graph.edges.where((e) => e.from == 'src/main.dart');
    expect(fromMain.where((e) => e.kind == GraphEdgeKind.import),
        containsAll([
          isA<GraphEdge>()
              .having((e) => e.to, 'to', 'packages/canva_core/canva.dart'),
        ]));
    final fromHelper = graph.edges.where((e) => e.from == 'src/helper.dart');
    expect(fromHelper.map((e) => e.to),
        containsAll(['packages/empresa_dev/models/skill.dart', 'src/main.dart']));
  });

  test('detecta imports de python', () {
    final fromScript = graph.edges.where((e) => e.from == 'src/script.py');
    expect(fromScript.map((e) => e.to), contains('src/helper.py'));
  });

  test('detecta [[links]] de markdown con y sin alias', () {
    final fromIndex = graph.edges.where((e) => e.from == 'notes/index.md');
    expect(fromIndex.map((e) => e.to), containsAll(['notes/guia.md', 'src/main.dart']));
    expect(fromIndex.every((e) => e.kind == GraphEdgeKind.link), isTrue);
    final fromGuia = graph.edges.where((e) => e.from == 'notes/guia.md');
    expect(fromGuia.map((e) => e.to), contains('notes/index.md'));
  });

  test('asigna cluster (package/directorio top-level)', () {
    final mainNode = graph.nodes.firstWhere((n) => n.id == 'src/main.dart');
    expect(mainNode.package, 'src');
  });
}
