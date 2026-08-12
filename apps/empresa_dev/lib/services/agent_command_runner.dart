import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Exit codes semánticos (estilo buzz/herdr).
enum SemanticExit {
  ok(0),
  general(1),
  usage(2),
  notFound(3),
  permission(4),
  timeout(5);

  final int code;

  const SemanticExit(this.code);

  static SemanticExit from(int exitCode) => switch (exitCode) {
        0 => SemanticExit.ok,
        1 => SemanticExit.general,
        2 => SemanticExit.usage,
        3 => SemanticExit.notFound,
        4 => SemanticExit.permission,
        5 => SemanticExit.timeout,
        9009 => SemanticExit.notFound, // Windows: comando no encontrado (cmd)
        _ => SemanticExit.general,
      };
}

class AgentCommandResult {
  final int exitCode;
  final String stdout;
  final String stderr;
  final Map<String, Object?>? json;

  const AgentCommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    this.json,
  });
}

/// Ejecuta comandos de agente bajo un contrato máquina:
/// JSON en stdout, errores en stderr, exit code semántico.
class AgentCommandRunner {
  final String? opencodePath;
  final Map<String, String>? env;

  AgentCommandRunner({this.opencodePath, this.env});

  Future<AgentCommandResult> run(
    String command, {
    Duration? timeout,
    String? workingDirectory,
  }) async {
    final notFound = _missingExecutable(command);
    if (notFound != null) {
      return AgentCommandResult(
        exitCode: SemanticExit.notFound.code,
        stdout: '',
        stderr: 'comando no encontrado: $notFound',
      );
    }
    try {
      final proc = await Process.start(
        'cmd',
        ['/d', '/c', command],
        environment: env,
        workingDirectory: workingDirectory,
      );
      // opencode (node) muere con EUNKNOWN si stdin queda en pipe abierto sin
      // TTY: cerramos para que detecte EOF (mismo fix que OpenCodeAgentRunner).
      proc.stdin.close();
      final outBuf = StringBuffer();
      final errBuf = StringBuffer();
      final utf8Lenient = const Utf8Decoder(allowMalformed: true);
      final outSub = proc.stdout.transform(utf8Lenient).listen(outBuf.write);
      final errSub = proc.stderr.transform(utf8Lenient).listen(errBuf.write);
      final done = proc.exitCode.then((code) => code).timeout(
            timeout ?? const Duration(minutes: 5),
            onTimeout: () {
              proc.kill();
              return SemanticExit.timeout.code;
            },
          );
      final exit = await done;
      await outSub.cancel();
      await errSub.cancel();
      return AgentCommandResult(
        exitCode: exit,
        stdout: outBuf.toString(),
        stderr: errBuf.toString(),
        json: tryParseJson(outBuf.toString()),
      );
    } on ProcessException catch (e) {
      return AgentCommandResult(
        exitCode: SemanticExit.notFound.code,
        stdout: '',
        stderr: e.message,
      );
    } on TimeoutException {
      return AgentCommandResult(
        exitCode: SemanticExit.timeout.code,
        stdout: '',
        stderr: 'timeout',
      );
    }
  }

  static Map<String, Object?>? tryParseJson(String stdout) {
    var trimmed = stdout.replaceAll('\uFEFF', '').trim();
    if (trimmed.isEmpty) return null;
    try {
      final decoded = jsonDecode(trimmed);
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// Si el primer token del comando es una ruta absoluta de ejecutable que
  /// no existe, devuelve ese token (→ notFound). null = no se puede saber.
  static String? _missingExecutable(String command) {
    final token = command.trimLeft().split(RegExp(r'\s+')).first;
    if (token.contains('\\') || token.contains('/')) {
      final exe = File(token.trim());
      if (!exe.existsSync()) return token;
    }
    return null;
  }
}
