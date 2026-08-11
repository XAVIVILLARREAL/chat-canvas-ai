import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/services/agent_command_runner.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('acr_test');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  File script(String name, String body) {
    final f = File('${tmp.path}\\$name.bat');
    f.writeAsStringSync(body);
    return f;
  }

  group('AgentCommandRunner', () {
    test('JSON válido en stdout + exit 0 → ok con json parseado', () async {
      final okScript = script('ok', '@echo {"state":"working","rule":"x"}');
      final r = await AgentCommandRunner().run(okScript.path);
      expect(SemanticExit.from(r.exitCode), SemanticExit.ok);
      expect(r.json, {'state': 'working', 'rule': 'x'});
      expect(r.stdout.trim(), contains('working'));
    });

    test('exit 1 + stderr → general con stderr capturado', () async {
      final errScript = script('err', '@echo boom 1>&2 & exit /b 1');
      final r = await AgentCommandRunner().run(errScript.path);
      expect(SemanticExit.from(r.exitCode), SemanticExit.general);
      expect(r.stderr.toLowerCase(), contains('boom'));
      expect(r.json, isNull);
    });

    test('binario inexistente → notFound (sin excepción)', () async {
      final r = await AgentCommandRunner()
          .run('C:\\ruta\\inexistente\\noexiste.exe --help');
      expect(SemanticExit.from(r.exitCode), SemanticExit.notFound);
      expect(r.stdout, isEmpty);
    });

    test('stdout no-JSON → json null, exit ok si el proceso es 0', () async {
      final plain = script('plain', '@echo hola mundo');
      final r = await AgentCommandRunner().run(plain.path);
      expect(r.exitCode, 0);
      expect(r.json, isNull);
    });

    test('timeout → timeout', () async {
      final slow = script('slow', '@ping -n 10 127.0.0.1 >nul');
      final r = await AgentCommandRunner().run(
        slow.path,
        timeout: const Duration(milliseconds: 200),
      );
      expect(SemanticExit.from(r.exitCode), SemanticExit.timeout);
    });
  });

  group('SemanticExit', () {
    test('mapea exit codes conocidos', () {
      expect(SemanticExit.from(0), SemanticExit.ok);
      expect(SemanticExit.from(1), SemanticExit.general);
      expect(SemanticExit.from(2), SemanticExit.usage);
      expect(SemanticExit.from(3), SemanticExit.notFound);
      expect(SemanticExit.from(4), SemanticExit.permission);
      expect(SemanticExit.from(5), SemanticExit.timeout);
      expect(SemanticExit.from(99), SemanticExit.general);
    });
  });
}