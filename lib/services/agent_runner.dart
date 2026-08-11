import 'dart:convert';
import 'dart:io';

class AgentRunLine {
  final String content;
  final bool isError;

  const AgentRunLine({required this.content, this.isError = false});
}

abstract class AgentRunner {
  /// Ejecuta el agente con el prompt y devuelve un stream de líneas
  /// (stdout como asistente, stderr como error).
  Stream<AgentRunLine> run(String prompt, {String? cwd});
}

class OpenCodeAgentRunner implements AgentRunner {
  final String executable;

  OpenCodeAgentRunner({this.executable = 'opencode'});

  @override
  Stream<AgentRunLine> run(String prompt, {String? cwd}) async* {
    final process = await Process.start(
      executable,
      ['run', prompt, '--dir', cwd ?? Directory.current.path],
    );
    final stdoutLines =
        process.stdout.transform(utf8.decoder).transform(const LineSplitter());
    final stderrLines =
        process.stderr.transform(utf8.decoder).transform(const LineSplitter());

    await for (final line in stdoutLines) {
      if (line.trim().isNotEmpty) {
        yield AgentRunLine(content: line.trim(), isError: false);
      }
    }
    await for (final line in stderrLines) {
      if (line.trim().isNotEmpty) {
        yield AgentRunLine(content: line.trim(), isError: true);
      }
    }
  }
}