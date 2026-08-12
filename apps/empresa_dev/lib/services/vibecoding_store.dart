import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:vibecoding_core/vibecoding_core.dart';

/// Historial persistente de propuestas vibecoding: lista JSON en
/// `vibecoding_proposals.json`. Sobrevive al cierre de la app; cada mutación
/// (proponer/aceptar/rechazar/revertir) vuelve a escribir el archivo.
/// [directory] permite apuntar a un directorio concreto (tests).
class VibecodingStore {
  final String? directory;

  VibecodingStore({this.directory});

  Future<File> _file() async {
    final dir = directory ?? (await getApplicationDocumentsDirectory()).path;
    return File('$dir/vibecoding_proposals.json');
  }

  Future<List<PatchProposal>> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return [];
      final raw = jsonDecode(await f.readAsString()) as List;
      return [
        for (final e in raw)
          PatchProposal.fromJson((e as Map).cast<String, Object?>()),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<PatchProposal> proposals) async {
    try {
      final f = await _file();
      await f.writeAsString(
        jsonEncode([for (final p in proposals) p.toJson()]),
      );
    } catch (_) {
      // un historial que no guarda no rompe el flujo principal
    }
  }
}
