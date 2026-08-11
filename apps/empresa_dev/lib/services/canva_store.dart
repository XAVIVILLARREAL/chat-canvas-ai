import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:canva_core/canva.dart';

class CanvaStore {
  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/canva_state.json');
  }

  Future<CanvaState> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return CanvaState.empty();
      final raw = await f.readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return CanvaState.fromJson(json);
    } catch (_) {
      return CanvaState.empty();
    }
  }

  Future<void> save(CanvaState state) async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode(state.toJson()));
    } catch (_) {
      // no guardar rompe nada en este slice
    }
  }
}
