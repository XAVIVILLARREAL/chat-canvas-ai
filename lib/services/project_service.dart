import 'dart:convert';
import 'dart:io';

class FileNode {
  final String name;
  final String path;
  final bool isDir;
  final int size;
  final DateTime modified;

  const FileNode({
    required this.name,
    required this.path,
    required this.isDir,
    required this.size,
    required this.modified,
  });
}

enum _Encoding { utf8, utf8Bom, utf16leBom, utf16beBom }

class _Decoded {
  final String text;
  final _Encoding encoding;

  const _Decoded(this.text, this.encoding);
}

/// Operaciones sobre una carpeta de proyecto local: listar (lazy por nivel),
/// leer con encoding detectado (UTF-8 / UTF-8+BOM / UTF-16 LE / UTF-16 BE)
/// y escribir conservando el encoding original.
class ProjectService {
  final String root;

  ProjectService({required this.root});

  static const _ignored = {'.git', 'build', 'node_modules', '.dart_tool', '.idea'};

  String _nameOf(String path) {
    final parts = path.split(RegExp(r'[/\\]'));
    return parts.lastWhere((p) => p.isNotEmpty, orElse: () => path);
  }

  Future<List<FileNode>> list(String dir) async {
    final entries = Directory(dir).listSync();
    final nodes = <FileNode>[];
    for (final e in entries) {
      final name = _nameOf(e.path);
      if (_ignored.contains(name)) continue;
      if (e is Directory) {
        nodes.add(FileNode(
          name: name,
          path: e.path,
          isDir: true,
          size: 0,
          modified: e.statSync().modified,
        ));
      } else if (e is File) {
        final st = e.statSync();
        nodes.add(FileNode(
          name: name,
          path: e.path,
          isDir: false,
          size: st.size,
          modified: st.modified,
        ));
      }
    }
    nodes.sort((a, b) {
      if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return nodes;
  }

  Future<String> read(String path) async =>
      _decodeSync(File(path)).text;

  Future<void> write(String path, String content) async {
    final file = File(path);
    final current = _decodeSync(file);
    final bytes = switch (current.encoding) {
      _Encoding.utf8 => utf8.encode(content),
      _Encoding.utf8Bom => [0xEF, 0xBB, 0xBF, ...utf8.encode(content)],
      _Encoding.utf16leBom => [0xFF, 0xFE, ..._utf16leEncode(content)],
      _Encoding.utf16beBom => [0xFE, 0xFF, ..._utf16beEncode(content)],
    };
    file.writeAsBytesSync(bytes);
  }

  bool isBinary(String path) {
    try {
      final f = File(path).openSync();
      try {
        final bytes = f.readSync(1024);
        return bytes.any((b) => b == 0);
      } finally {
        f.closeSync();
      }
    } catch (_) {
      return false;
    }
  }

  _Decoded _decodeSync(File file) {
    final bytes = file.readAsBytesSync();
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      return _Decoded(_utf16leDecode(bytes.sublist(2)), _Encoding.utf16leBom);
    }
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      return _Decoded(_utf16beDecode(bytes.sublist(2)), _Encoding.utf16beBom);
    }
    if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
      return _Decoded(
        utf8.decode(bytes.sublist(3), allowMalformed: true),
        _Encoding.utf8Bom,
      );
    }
    return _Decoded(utf8.decode(bytes, allowMalformed: true), _Encoding.utf8);
  }

  String _utf16leDecode(List<int> bytes) {
    final codeUnits = <int>[];
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      codeUnits.add(bytes[i] | (bytes[i + 1] << 8));
    }
    return String.fromCharCodes(codeUnits);
  }

  String _utf16beDecode(List<int> bytes) {
    final codeUnits = <int>[];
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      codeUnits.add((bytes[i] << 8) | bytes[i + 1]);
    }
    return String.fromCharCodes(codeUnits);
  }

  List<int> _utf16leEncode(String text) {
    final out = <int>[];
    for (final unit in text.codeUnits) {
      out.add(unit & 0xFF);
      out.add((unit >> 8) & 0xFF);
    }
    return out;
  }

  List<int> _utf16beEncode(String text) {
    final out = <int>[];
    for (final unit in text.codeUnits) {
      out.add((unit >> 8) & 0xFF);
      out.add(unit & 0xFF);
    }
    return out;
  }
}
