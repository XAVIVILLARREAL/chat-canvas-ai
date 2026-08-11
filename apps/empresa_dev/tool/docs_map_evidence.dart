import 'dart:convert';
import 'dart:io';

import 'package:empresa_dev/models/canva.dart';
import 'package:empresa_dev/services/docs_map_builder.dart';
import 'package:empresa_dev/services/md_link_parser.dart';

/// Evidencia del dogfood de Etapa 4: el mapa de ideas de este proyecto
/// (docs/) construido como canva navegable.
/// Uso: dart run tool/docs_map_evidence.dart
void main() {
  final state = DocsMapBuilder.build('docs');
  final refs = <String, int>{};
  for (final n in state.nodes) {
    for (final link in MdLinkParser.parse(n.content ?? '')) {
      refs[link.target] = (refs[link.target] ?? 0) + 1;
    }
  }

  final buffer = StringBuffer()
    ..writeln('# Evidencia Etapa 4 — mapa de docs/ como canva')
    ..writeln('')
    ..writeln('Generado: ${DateTime.now().toIso8601String()}')
    ..writeln('')
    ..writeln('- Nodos: ${state.nodes.length}')
    ..writeln('- Edges ([[links]]): ${state.edges.length}')
    ..writeln('- Destinos referenciados: ${refs.length}')
    ..writeln('')
    ..writeln('## Nodos')
    ..writeln('');
  for (final n in state.nodes) {
    buffer.writeln('- **${n.label}** (${n.content == null ? "placeholder" : "archivo"}) en (${n.x.toStringAsFixed(0)}, ${n.y.toStringAsFixed(0)})');
  }
  buffer
    ..writeln('')
    ..writeln('## Estado JSON (subset)')
    ..writeln('')
    ..writeln('```json')
    ..writeln(jsonEncode({
          'nodos': state.nodes.length,
          'edges': state.edges.length,
          'titulos': state.nodes.map((n) => n.label).toList(),
        }))
    ..writeln('```');

  final dir = Directory('data/evidence');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  File('data/evidence/etapa4-docs-map.md').writeAsStringSync(buffer.toString());
  stdout.writeln('Evidencia escrita: data/evidence/etapa4-docs-map.md');
  stdout.writeln('Nodos=${state.nodes.length} Edges=${state.edges.length}');
}
