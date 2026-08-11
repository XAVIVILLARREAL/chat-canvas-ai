import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'ssh_service.dart';

class SftpEntry {
  final String name;
  final bool isDirectory;
  final int size;
  final int? mode;

  SftpEntry({
    required this.name,
    required this.isDirectory,
    required this.size,
    this.mode,
  });
}

class SftpService {
  SftpClient? _sftp;
  final SshService _ssh;

  SftpService(this._ssh);

  bool get isConnected => _sftp != null;

  Future<bool> connect(SshHost host) async {
    final sftp = await _ssh.connectSftp(host);
    _sftp = sftp;
    return sftp != null;
  }

  Future<List<SftpEntry>> list(String path) async {
    final s = _sftp;
    if (s == null) throw StateError('SFTP no conectado');
    final items = await s.listdir(path);
    final entries = items
        .map((it) => SftpEntry(
              name: it.filename,
              isDirectory: it.attr.type == SftpFileType.directory,
              size: it.attr.size ?? 0,
              mode: it.attr.mode?.value,
            ))
        .toList();
    entries.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return entries;
  }

  Future<void> upload(String localPath, String remotePath) async {
    final s = _sftp;
    if (s == null) throw StateError('SFTP no conectado');
    final file = await s.open(remotePath, mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate);
    final stream = File(localPath).openRead().map((c) => Uint8List.fromList(c));
    await file.write(stream);
    await file.close();
  }

  Future<void> download(String remotePath, String localPath) async {
    final s = _sftp;
    if (s == null) throw StateError('SFTP no conectado');
    final file = await s.open(remotePath);
    final out = File(localPath).openWrite();
    await file.downloadTo(out);
    await out.close();
    await file.close();
  }

  Future<void> mkdir(String path) async {
    final s = _sftp;
    if (s == null) throw StateError('SFTP no conectado');
    await s.mkdir(path);
  }

  Future<String?> read(String path) async {
    final s = _sftp;
    if (s == null) throw StateError('SFTP no conectado');
    try {
      final file = await s.open(path);
      final bytes = await file.readBytes();
      await file.close();
      return String.fromCharCodes(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<void> close() async {
    await _sftp?.close();
    _sftp = null;
  }
}
