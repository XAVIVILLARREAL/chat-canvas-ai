@Tags(['integration'])
library;

import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';

/// Prueba de integración real: conecta por SSH a pve (Tailscale) con llave
/// y ejecuta comandos. Es el gate de la Fase 1.1.
///
/// Se ejecuta solo cuando está habilitada (no en CI normal):
///   dart test test/ssh_integration_test.dart
void main() {
  test('conexión SSH real a pve con llave ed25519', () async {
    final host = Platform.environment['SSH_TEST_HOST'] ?? '100.101.69.79';
    final port = int.tryParse(Platform.environment['SSH_TEST_PORT'] ?? '') ?? 22;
    final user = Platform.environment['SSH_TEST_USER'] ?? 'root';
    final keyPath = 'test/fixtures/app_test_key';

    final keyPem = File(keyPath).readAsStringSync();

    final socket = await SSHSocket.connect(host, port);
    final client = SSHClient(
      socket,
      username: user,
      identities: [
        ...SSHKeyPair.fromPem(keyPem),
      ],
      disableHostkeyVerification: true,
    );

    await client.authenticated;
    expect(client.remoteVersion, isNotEmpty);

    final result = await client.runWithResult('echo INTEGRATION-OK && whoami && hostname');
    expect(result.exitCode, 0);
    final stdout = String.fromCharCodes(result.stdout);
    expect(stdout, contains('INTEGRATION-OK'));
    expect(stdout, contains('root'));
    expect(stdout.trim().split('\n').length, 3);

    client.close();
    socket.close();
  }, timeout: const Timeout(Duration(seconds: 30)));
}
