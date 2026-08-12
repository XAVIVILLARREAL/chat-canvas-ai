import 'dart:convert';

import 'package:canva_core/canva.dart';

import 'canva_storage.dart';
import 'canva_storage_stub.dart'
    if (dart.library.html) 'canva_storage_web.dart'
    if (dart.library.io) 'canva_storage_io.dart'
    as platform;

export 'canva_storage.dart' show CanvaStorage;

CanvaStorage defaultCanvaStorage() => platform.defaultCanvaStorage();

class CanvaStore {
  CanvaStore({CanvaStorage? storage}) : _storage = storage ?? defaultCanvaStorage();

  final CanvaStorage _storage;

  Future<CanvaState> load() async {
    try {
      final raw = await _storage.read();
      if (raw == null) return CanvaState.empty();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return CanvaState.fromJson(json);
    } catch (_) {
      return CanvaState.empty();
    }
  }

  Future<void> save(CanvaState state) async {
    try {
      await _storage.write(jsonEncode(state.toJson()));
    } catch (_) {
      // no guardar rompe nada en este slice
    }
  }
}
