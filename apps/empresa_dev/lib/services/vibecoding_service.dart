import 'dart:convert';
import 'dart:io';

import 'package:vibecoding_core/vibecoding_core.dart';

/// Adapta [AgentRunner] (contrato vibecoding_core) a opencode real.
///
/// NO pasa por `cmd`: el prompt se inyecta como argv-list al ejecutable
/// nativo (`opencode.exe` si existe) o al `.cmd` shim vía `cmd /s /c ""...""`
/// (patrón que preserva comillas/`>`/`&` intactos). El camino por `cmd /d /c`
/// con el JSON escapado manglea prompts con `->` o `"` (hallado en el dogfood
/// de Etapa 6: los primeros intentos llegaron truncados al agente).
class AgentCommandRunnerAdapter implements AgentRunner {
  final String opencodePath;

  AgentCommandRunnerAdapter({String? opencodePath})
      : opencodePath = opencodePath ?? _resolveOpenCode();

  static String _resolveOpenCode() {
    final npmDir = Platform.environment['APPDATA'];
    if (Platform.isWindows && npmDir != null) {
      final exe = '$npmDir\\npm\\node_modules\\opencode-ai\\bin\\opencode.exe';
      if (File(exe).existsSync()) return exe;
    }
    return 'opencode';
  }

  @override
  Future<RunResult> run(String command, {String? cwd}) async {
    final prompt = _extractPrompt(command);
    final argv = [if (prompt != null) prompt]..insertAll(0, ['run']);
    if (cwd != null) argv.addAll(['--dir', cwd]);

    final proc = await _start(argv, cwd);
    proc.stdin.close(); // opencode (node) muere con EUNKNOWN si stdin queda abierto
    final outBuf = StringBuffer();
    final errBuf = StringBuffer();
    final utf8Lenient = const Utf8Decoder(allowMalformed: true);
    final outSub = proc.stdout.transform(utf8Lenient).listen(outBuf.write);
    final errSub = proc.stderr.transform(utf8Lenient).listen(errBuf.write);
    final exit = await proc.exitCode;
    await outSub.cancel();
    await errSub.cancel();
    return RunResult(
      exitCode: exit,
      stdout: outBuf.toString(),
      stderr: errBuf.toString(),
    );
  }

  Future<Process> _start(List<String> argv, String? cwd) {
    // .exe nativo (PATH o APPDATA npm): argv-list directo, sin shell.
    if (!opencodePath.endsWith('.cmd')) {
      return Process.start(
        opencodePath,
        argv,
        workingDirectory: cwd,
      );
    }
    // shim .cmd: cmd mangla argv con comillas; /s + comillas externas
    // dobles es el patrón cmd-safe probado (todo llega intacto).
    final quoted = argv.map((a) => '"${a.replaceAll('"', '""')}"').join(' ');
    return Process.start(
      'cmd',
      ['/d', '/s', '/c', '""opencode run $quoted""'],
      workingDirectory: cwd,
    );
  }

  /// `opencode run "prompt json..."` -> prompt crudo (json decode).
  static String? _extractPrompt(String command) {
    const prefix = 'opencode run ';
    if (!command.startsWith(prefix)) return null;
    final jsonArg = command.substring(prefix.length).trim();
    if (!jsonArg.startsWith('"')) return null;
    try {
      final decoded = jsonDecode(jsonArg);
      return decoded is String ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}