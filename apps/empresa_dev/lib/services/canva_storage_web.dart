// Web-only deliberado: aislado por conditional import (storage_io es la
// contraparte VM/desktop). dart:html es la vía estable para localStorage;
// migrar a package:web si se moderniza la base mínima.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'canva_storage.dart';

/// Persistencia en localStorage (web). Misma clave que el archivo io.
class WebCanvaStorage implements CanvaStorage {
  static const _key = 'canva_state';

  @override
  Future<String?> read() async => html.window.localStorage[_key];

  @override
  Future<void> write(String data) async {
    html.window.localStorage[_key] = data;
  }
}

CanvaStorage defaultCanvaStorage() => WebCanvaStorage();
