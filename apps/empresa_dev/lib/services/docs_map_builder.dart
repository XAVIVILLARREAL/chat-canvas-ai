import 'dart:io';
import 'package:canva_core/canva.dart';
import 'md_link_parser.dart';

/// Construye un canva de ideas a partir de una carpeta de `.md`:
/// nodo por archivo (título = nombre), edges por `[[links]]` entre ellos,
/// placeholders para destinos inexistentes, auto-layout en espiral.
class DocsMapBuilder {
  static CanvaState build(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return CanvaState.empty();

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.md'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final nodes = <CanvaNode>[];
    final edges = <CanvaEdge>[];
    final byTitle = <String, CanvaNode>{};

    var index = 0;
    for (final f in files) {
      final title = f.uri.pathSegments.last.replaceAll(RegExp(r'\.md$', caseSensitive: false), '');
      final content = f.readAsStringSync();
      final node = CanvaNode(
        id: CanvasNodeId.generate().value,
        type: CanvaNodeType.note,
        x: _spiralX(index),
        y: _spiralY(index),
        label: title,
        colorHex: '#34D399',
        content: content,
      );
      nodes.add(node);
      byTitle[title] = node;
      index++;
    }

    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      for (final link in MdLinkParser.parse(node.content ?? '')) {
        final target = byTitle[link.target];
        if (target == null) {
          final id = CanvasNodeId.generate().value;
          byTitle[link.target] = CanvaNode(
            id: id,
            type: CanvaNodeType.note,
            x: _spiralX(index),
            y: _spiralY(index),
            label: link.target,
            colorHex: '#F59E0B',
            content: null,
          );
          nodes.add(byTitle[link.target]!);
          index++;
          edges.add(CanvaEdge(id: CanvasNodeId.generate().value, fromNodeId: node.id, toNodeId: id));
        } else if (target.id != node.id) {
          edges.add(CanvaEdge(id: CanvasNodeId.generate().value, fromNodeId: node.id, toNodeId: target.id));
        }
      }
    }

    return CanvaState(nodes: nodes, edges: edges);
  }

  static double _spiralX(int i) => 300 + 120 * i * (i.isEven ? 1 : -1) * (0.5 + i * 0.15);
  static double _spiralY(int i) => 300 + 100 * ((i + 1) ~/ 2) * (i.isOdd ? 1 : -1);
}
