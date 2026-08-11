import 'dart:io';

import 'models.dart';

/// Escanea un árbol de proyecto y detecta relaciones entre archivos:
/// imports (Dart/Python) y `[[links]]` entre Markdown.
class RelationIndexer {
  static const _ignored = {'.git', 'build', 'node_modules', '.dart_tool', '.idea'};
  static const _extensions = ['.md', '.dart', '.py'];

  static Graph scan(String root) {
    final nodes = <String, GraphNode>{};
    final edges = <GraphEdge>[];

    void walk(Directory dir) {
      for (final e in dir.listSync()) {
        if (e is Directory) {
          if (_ignored.contains(e.uri.pathSegments.last)) continue;
          walk(e);
        } else if (e is File) {
          final rel = _rel(root, e.path);
          final node = _nodeFor(rel);
          if (node == null) continue;
          nodes[rel] = node;
          final lines = _readLinesSafe(e);
          edges.addAll(_edgesFor(rel, lines, physical: e));
        }
      }
    }

    walk(Directory(root));
    return Graph(nodes: nodes.values.toList(), edges: edges);
  }

  static String _rel(String root, String path) {
    final r = root.replaceAll('\\', '/').replaceFirst(RegExp(r'/$'), '');
    final p = path.replaceAll('\\', '/');
    return p.substring(r.length + 1);
  }

  static GraphNode? _nodeFor(String rel) {
    final label = rel.split('/').last;
    final kind = _kindOf(rel);
    if (kind == GraphNodeKind.other) return null;
    final cluster = rel.contains('/') ? rel.split('/').first : '';
    return GraphNode(id: rel, label: label, kind: kind, package: cluster);
  }

  static GraphNodeKind _kindOf(String rel) {
    if (rel.endsWith('.dart')) return GraphNodeKind.dart;
    if (rel.endsWith('.py')) return GraphNodeKind.python;
    if (rel.endsWith('.md')) return GraphNodeKind.markdown;
    return GraphNodeKind.other;
  }

  static List<String> _readLinesSafe(File f) {
    try {
      return f.readAsStringSync().split('\n');
    } catch (_) {
      return const [];
    }
  }

  static List<GraphEdge> _edgesFor(String from, List<String> lines,
      {File? physical}) {
    final edges = <GraphEdge>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('//') || trimmed.startsWith('#')) continue;

      final dart =
          RegExp(r"^\s*(?:import|export)\s+'([^']+)'", multiLine: true)
              .firstMatch(trimmed);
      if (dart != null) {
        final target = _resolveImport(from, dart.group(1)!);
        if (target != null) {
          edges.add(
              GraphEdge(from: from, to: target, kind: GraphEdgeKind.import));
        }
        continue;
      }

      final py = RegExp(
              r'^\s*(?:from\s+(\S+)\s+import|import\s+(\S+))',
              multiLine: true)
          .firstMatch(trimmed);
      if (py != null) {
        final mod = py.group(1) ?? py.group(2)!;
        final target = _resolvePythonImport(from, mod);
        if (target != null) {
          edges.add(
              GraphEdge(from: from, to: target, kind: GraphEdgeKind.import));
        }
        continue;
      }

      for (final m in RegExp(r'\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')
          .allMatches(trimmed)) {
        final dest = m.group(1)!.trim();
        if (dest.isEmpty) continue;
        final target = _resolveLink(from, dest, physical: physical);
        if (target != null) {
          edges.add(
              GraphEdge(from: from, to: target, kind: GraphEdgeKind.link));
        }
      }
    }
    return edges;
  }

  /// Resuelve imports Dart: `package:x/y.dart` → `packages/x/y.dart`
  /// (id de nodo virtual), relativo → ruta normalizada desde el origen.
  static String? _resolveImport(String from, String spec) {
    if (spec.startsWith('package:')) {
      return 'packages/${spec.substring(8)}';
    }
    final parts = _pathParts(from)..removeLast(); // dir del archivo fuente
    for (final seg in spec.split('/')) {
      if (seg == '..') {
        if (parts.isNotEmpty) parts.removeLast();
      } else if (seg != '.' && seg.isNotEmpty) {
        parts.add(seg);
      }
    }
    return parts.join('/');
  }

  /// Imports Python: stdlib conocida → null; módulos → `dir/mod.py`.
  static String? _resolvePythonImport(String from, String mod) {
    const stdlib = {'os', 'sys', 'json', 're', 'math', 'typing', 'logging', 'datetime'};
    if (stdlib.contains(mod) || mod.startsWith('package:')) return null;
    final named = mod.replaceAll('.', '/');
    final base = _pathParts(from);
    base.removeLast();
    return '${base.join('/')}/$named.py';
  }

  /// `[[dest]]`: sin `/` → relativo a la carpeta del archivo fuente;
  /// con `/` → relativo a la raíz del escaneo. Prueba .md/.dart/.py.
  static String? _resolveLink(String from, String dest, {File? physical}) {
    if (physical == null) return null;
    final root = physical.parent.parent; // raíz física del escaneo
    final base = _pathParts(from)..removeLast(); // dir del archivo en ids
    for (final ext in _extensions) {
      final rel = dest.contains('/')
          ? '$dest$ext'
          : '${base.join('/')}/$dest$ext';
      final clean = rel
          .replaceAll('//', '/')
          .replaceFirst(RegExp(r'^/'), '')
          .replaceAll(RegExp(r'\.\./'), '');
      final f = File('${root.path}${Platform.pathSeparator}${clean.replaceAll('/', '\\')}');
      if (f.existsSync()) return clean;
    }
    return null;
  }

  static List<String> _pathParts(String rel) =>
      rel.split('/').where((s) => s.isNotEmpty).toList();
}