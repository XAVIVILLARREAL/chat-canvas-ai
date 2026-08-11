@Tags(['integration'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';

/// Prueba de integración real de SFTP contra pve (gate Fase 1.2).
/// Requiere la llave test/fixtures/app_test_key instalada en /root/.ssh de pve.
void main() {
  final host = Platform.environment['SSH_TEST_HOST'] ?? '100.101.69.79';
  final port = int.tryParse(Platform.environment['SSH_TEST_PORT'] ?? '') ?? 22;
  final user = Platform.environment['SSH_TEST_USER'] ?? 'root';
  final keyPath = 'test/fixtures/app_test_key';

  Future<SftpClient> connect() async {
    final socket = await SSHSocket.connect(host, port);
    final client = SSHClient(
      socket,
      username: user,
      identities: [...SSHKeyPair.fromPem(File(keyPath).readAsStringSync())],
      disableHostkeyVerification: true,
    );
    await client.authenticated;
    return client.sftp();
  }

  test('SFTP: listar /root', () async {
    final sftp = await connect();
    final items = await sftp.listdir('/root');
    expect(items.any((it) => it.filename == '.ssh'), isTrue,
        reason: '/root debe contener .ssh (llave instalada)');
    await sftp.close();
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('SFTP: mkdir + upload + download + verify', () async {
    final sftp = await connect();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final dir = '/tmp/empresa-test-$ts';

    await sftp.mkdir(dir);
    final dirs = await sftp.listdir('/tmp');
    expect(dirs.any((it) => it.filename == 'empresa-test-$ts'), isTrue,
        reason: 'la carpeta debe crearse');

    // upload
    final content = 'hola desde sftp test $ts';
    final file = await sftp.open('$dir/prueba.txt',
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate);
    await file.writeBytes(Uint8List.fromList(content.codeUnits));
    await file.close();

    // list contiene el archivo
    final files = await sftp.listdir(dir);
    expect(files.any((it) => it.filename == 'prueba.txt'), isTrue);

    // read back
    final rf = await sftp.open('$dir/prueba.txt');
    final bytes = await rf.readBytes();
    await rf.close();
    expect(String.fromCharCodes(bytes), content);

    // cleanup
    await sftp.remove('$dir/prueba.txt');
    await sftp.rmdir(dir);
    await sftp.close();
  }, timeout: const Timeout(Duration(seconds: 30)));
}
