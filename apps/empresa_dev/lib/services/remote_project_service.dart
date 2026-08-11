import 'dart:io';

import '../services/project_service.dart';
import '../services/sftp_service.dart';

/// Proyecto remoto sobre SFTP: mismas operaciones que [ProjectService] pero
/// contra el host conectado, reutilizando [SftpService].
class RemoteProjectService {
  final SftpService sftp;

  RemoteProjectService(this.sftp);

  Future<List<FileNode>> list(String dir) async {
    final entries = await sftp.list(dir);
    final nodes = entries
        .where((e) => e.name != '.' && e.name != '..')
        .map((e) => FileNode(
              name: e.name,
              path: '$dir/${e.name}',
              isDir: e.isDirectory,
              size: e.size,
              modified: DateTime.now(),
            ))
        .toList();
    nodes.sort((a, b) {
      if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return nodes;
  }

  Future<String> read(String path) async {
    final content = await sftp.read(path);
    if (content == null) throw StateError('No se pudo leer $path');
    return content;
  }

  Future<void> write(String path, String content) async {
    final tmp = File('${Directory.systemTemp.path}/empresa_dev_sftp_tmp');
    await tmp.writeAsString(content);
    await sftp.upload(tmp.path, path);
    await tmp.delete();
  }
}
