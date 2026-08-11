import 'dart:io';

import 'package:agent_core/agent.dart';

class EvidenceRecord {
  final String path;
  final String agentName;
  final String prompt;
  final DateTime at;

  const EvidenceRecord({
    required this.path,
    required this.agentName,
    required this.prompt,
    required this.at,
  });
}

/// Guarda y lista evidencia `.md` en `<docs>/evidencia/`.
/// Usa I/O síncrono: los volúmenes son pequeños y así funciona dentro de
/// FakeAsync en widget tests.
class EvidenceStore {
  final Directory? baseDir;

  EvidenceStore({this.baseDir});

  Directory _evidenciaDirSync() {
    final root = baseDir?.path ?? _defaultRoot();
    final dir = Directory('$root/evidencia');
    dir.createSync(recursive: true);
    return dir;
  }

  String _defaultRoot() {
    final profile = Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        Directory.current.path;
    return '$profile\\Documents';
  }

  String formatName(DateTime at, String agentName) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${at.year}-${two(at.month)}-${two(at.day)}_'
        '${two(at.hour)}${two(at.minute)}${two(at.second)}_$agentName.md';
  }

  /// Escribe la evidencia del prompt. Devuelve el path, o null si no hay
  /// respuesta de asistente que documentar.
  Future<String?> save(AgentSession session, {required String prompt}) async {
    final assistant = session.messages
        .where((m) => m.role == AgentRole.assistant)
        .map((m) => m.text)
        .join('\n\n')
        .trim();
    if (assistant.isEmpty) return null;

    final dir = _evidenciaDirSync();
    final now = DateTime.now();
    var name = formatName(now, session.agentName);
    var n = 1;
    while (File('${dir.path}/$name').existsSync()) {
      name = formatName(now, session.agentName).replaceFirst('.md', '_$n.md');
      n++;
    }

    final content = StringBuffer()
      ..writeln('# Agente ${session.agentName} — ${_fecha(now)}')
      ..writeln()
      ..writeln('**Sesión:** ${session.id} · **Fecha:** ${now.toIso8601String()}')
      ..writeln()
      ..writeln('## Prompt')
      ..writeln()
      ..writeln('> $prompt')
      ..writeln()
      ..writeln('## Respuesta')
      ..writeln()
      ..writeln(assistant);

    final file = File('${dir.path}/$name');
    file.writeAsStringSync(content.toString());
    return file.path;
  }

  Future<List<EvidenceRecord>> list() async {
    final dir = _evidenciaDirSync();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));

    return files.map((f) {
      final name = f.uri.pathSegments.last;
      final parts = name.split('_');
      final agentName =
          parts.length >= 3 ? parts.last.replaceAll('.md', '') : 'dev';
      String prompt = name;
      try {
        final content = f.readAsStringSync();
        final idx = content.indexOf('## Prompt');
        final start = content.indexOf('> ', idx == -1 ? 0 : idx);
        if (start != -1) {
          prompt = content.substring(start + 2, content.indexOf('\n', start))
              .trim();
          if (prompt.isEmpty) prompt = name;
        }
      } catch (_) {}
      return EvidenceRecord(
        path: f.path,
        agentName: agentName,
        prompt: prompt,
        at: f.statSync().modified,
      );
    }).toList();
  }

  String _fecha(DateTime at) =>
      '${at.year}-${at.month.toString().padLeft(2, '0')}-${at.day.toString().padLeft(2, '0')} '
      '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
}
