@Tags(['integration'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/services/ssh_service.dart';

/// Prueba de la terminal como humano: conecta a pve por SSH y verifica
/// que se puede escribir un comando y recibir la respuesta (root).
/// Evidencia de que el input del terminal llega al shell.
/// Ejecutar: flutter test test/ssh_terminal_test.dart
void main() {
  test('terminal SSH: escribir whoami y recibir root', () async {
    final key = File('test/fixtures/app_test_key').readAsStringSync();
    final host = SshHost(
      name: 'pve',
      host: '100.101.69.79',
      username: 'root',
      authType: SshAuthType.key,
      keyPem: key,
    );

    final service = SshService();
    final shell = await service.connectShell(host);

    // Buffer de salida
    final out = StringBuffer();
    final sub = shell.stdout.listen((data) => out.write(String.fromCharCodes(data)));
    shell.stderr.listen((data) => out.write(String.fromCharCodes(data)));

    // Escribir como humano: whoami + Enter
    shell.write(Uint8List.fromList('whoami\n'.codeUnits));

    // Esperar la respuesta
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (DateTime.now().isBefore(deadline) && !out.toString().contains('root')) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    await sub.cancel();

    expect(out.toString(), contains('root'), reason: 'whoami debe devolver root');

    // Evidencia
    final dir = Directory('data/evidence');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    File('data/evidence/terminal-whoami.txt').writeAsStringSync(out.toString());

    await service.disconnect();
  }, timeout: const Timeout(Duration(seconds: 30)));
}
