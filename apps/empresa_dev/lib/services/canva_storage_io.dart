import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'canva_storage.dart';

/// Persistencia en archivo (desktop/mobile): `canva_state.json` en documents.
class FileCanvaStorage implements CanvaStorage {
  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/canva_state.json');
  }

  @override
  Future<String?> read() async {
    final f = await _file();
    if (!await f.exists()) return null;
    return f.readAsString();
  }

  @override
  Future<void> write(String data) async {
    final f = await _file();
    await f.writeAsString(data);
  }
}

CanvaStorage defaultCanvaStorage() => FileCanvaStorage();
