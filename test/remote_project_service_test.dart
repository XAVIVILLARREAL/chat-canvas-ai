import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/services/remote_project_service.dart';
import 'package:empresa_dev/services/sftp_service.dart';
import 'package:empresa_dev/services/ssh_service.dart';

class FakeSftp extends SftpService {
  FakeSftp() : super(SshService());

  final Map<String, List<SftpEntry>> dirs = {};
  final Map<String, String> files = {};

  @override
  Future<List<SftpEntry>> list(String path) async => dirs[path] ?? [];

  @override
  Future<String?> read(String path) async => files[path];

  @override
  Future<void> upload(String localPath, String remotePath) async {
    files[remotePath] = File(localPath).readAsStringSync();
  }

  @override
  Future<void> mkdir(String path) async {}

  @override
  Future<void> close() async {}

  @override
  Future<bool> connect(SshHost host) async => true;

  @override
  Future<void> download(String remotePath, String localPath) async {
    File(localPath).writeAsStringSync(files[remotePath] ?? '');
  }
}

void main() {
  late FakeSftp sftp;
  late RemoteProjectService service;

  setUp(() {
    sftp = FakeSftp();
    service = RemoteProjectService(sftp);
    sftp.dirs['/proj'] = [
      SftpEntry(name: 'src', isDirectory: true, size: 0),
      SftpEntry(name: 'README.md', isDirectory: false, size: 42),
    ];
    sftp.files['/proj/README.md'] = '# Hola remoto';
  });

  test('list adapta SftpEntry a FileNode y ordena dirs primero', () async {
    final nodes = await service.list('/proj');
    expect(nodes.map((n) => n.name), ['src', 'README.md']);
    expect(nodes.first.isDir, isTrue);
    expect(nodes.last.size, 42);
  });

  test('read devuelve el contenido remoto', () async {
    expect(await service.read('/proj/README.md'), '# Hola remoto');
  });

  test('write sube el contenido al remoto', () async {
    await service.write('/proj/README.md', '# Editado');
    expect(sftp.files['/proj/README.md'], '# Editado');
  });
}