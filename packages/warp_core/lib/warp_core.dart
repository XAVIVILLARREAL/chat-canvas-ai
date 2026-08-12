/// Warp-mode (Etapa 8.5): historial de comandos por host, búsqueda fuzzy y
/// tracker de línea para el terminal. Dart puro (sin Flutter).
library;

import 'dart:convert';
import 'dart:io';

// ---------------------------------------------------------------------------
// CommandLineTracker: consume el input del usuario (Terminal.onOutput de
// xterm.dart) y emite las líneas de comando completas al pulsar Enter.
// ---------------------------------------------------------------------------

class CommandLineTracker {
  final void Function(String line)? onCommand;
  final StringBuffer _buffer = StringBuffer();

  CommandLineTracker({this.onCommand});

  /// Línea actual (lo tecleado hasta ahora, sin Enter).
  String get currentLine => _buffer.toString();

  /// Alimenta el tracker con el input del terminal (lo que se envía al shell).
  void feed(String input) {
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      switch (rune) {
        case 0x0d: // Enter
        case 0x0a: // LF
          final line = currentLine.trim();
          _buffer.clear();
          if (line.isNotEmpty) onCommand?.call(line);
          break;
        case 0x7f: // Backspace
        case 0x08:
          _backspace();
          break;
        case 0x03: // Ctrl-C: aborta la línea
          _buffer.clear();
          break;
        case 0x15: // Ctrl-U: borra la línea completa
          _buffer.clear();
          break;
        case 0x1b: // ESC: secuencia ANSI → se salta entera
          _skipEscape(input, rune);
          return;
        default:
          if (rune >= 0x20) _buffer.write(ch);
          break;
      }
    }
  }

  void _backspace() {
    final s = _buffer.toString();
    if (s.isEmpty) return;
    final runes = s.runes.toList()..removeLast();
    _buffer
      ..clear()
      ..write(String.fromCharCodes(runes));
  }

  /// Salta una secuencia de escape (CSI `\x1b[...A` o OSC `\x1b]...\x07`).
  void _skipEscape(String input, int startRune) {
    final rest = String.fromCharCodes(input.runes.skip(1));
    for (var i = 0; i < rest.length; i++) {
      final c = rest.codeUnitAt(i);
      if (c >= 0x40 && c <= 0x7e) return; // fin de CSI (`A`…`~`)
      if (c == 0x07) return; // fin de OSC
    }
  }

  /// Reinicia la línea sin emitir comando.
  void reset() => _buffer.clear();
}

// ---------------------------------------------------------------------------
// CommandHistoryStore: historial por host, persistente en JSON.
// ---------------------------------------------------------------------------

class CommandRecord {
  final String command;
  final DateTime at;

  const CommandRecord({required this.command, required this.at});

  Map<String, Object?> toJson() => {'command': command, 'at': at.toIso8601String()};

  static CommandRecord fromJson(Map<String, Object?> j) => CommandRecord(
        command: j['command'] as String,
        at: DateTime.parse(j['at'] as String),
      );
}

class CommandHistoryStore {
  /// Máximo de entradas por host (las más antiguas se descartan).
  static const maxPerHost = 500;

  final Directory? dir;
  final Map<String, List<CommandRecord>> _data = {};
  bool _loaded = false;

  CommandHistoryStore({this.dir});

  Future<Map<String, List<CommandRecord>>> _all() async {
    if (!_loaded) {
      await _load();
      _loaded = true;
    }
    return _data;
  }

  Future<void> _load() async {
    if (dir == null) return;
    final file = File('${dir!.path}/history.json');
    if (!file.existsSync()) return;
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      json.forEach((host, list) {
        _data[host] = [
          for (final e in (list as List))
            CommandRecord.fromJson((e as Map).cast<String, Object?>()),
        ];
      });
    } catch (_) {
      _data.clear();
    }
  }

  Future<void> _persist() async {
    if (dir == null) return;
    final file = File('${dir!.path}/history.json');
    final json = {
      for (final e in _data.entries)
        e.key: [for (final r in e.value) r.toJson()],
    };
    file.writeAsStringSync(jsonEncode(json));
  }

  /// Registra un comando para [host]. Deduplica consecutivos y aplica el cap.
  Future<void> add(String host, String command) async {
    final line = command.trim();
    if (line.isEmpty) return;
    final all = await _all();
    final list = all.putIfAbsent(host, () => []);
    if (list.isNotEmpty && list.last.command == line) return;
    list.add(CommandRecord(command: line, at: DateTime.now()));
    if (list.length > maxPerHost) {
      list.removeRange(0, list.length - maxPerHost);
    }
    await _persist();
  }

  Future<List<CommandRecord>> forHost(String host) async =>
      List.unmodifiable((await _all())[host] ?? const []);

  /// Busca fuzzy sobre el historial de [host]; query vacía → más reciente.
  Future<List<CommandRecord>> search(String host, String query) async {
    final finder = FuzzyFinder();
    return [
      for (final m in finder.rank(await forHost(host), query)) m.record,
    ];
  }

  /// Elimina todas las apariciones de [command] en [host].
  Future<void> remove(String host, String command) async {
    final all = await _all();
    final list = all[host];
    if (list == null) return;
    list.removeWhere((r) => r.command == command);
    await _persist();
  }

  Future<void> clear(String host) async {
    final all = await _all();
    all[host] = [];
    await _persist();
  }
}

// ---------------------------------------------------------------------------
// FuzzyFinder: ranking por subsecuencia + scoring (contigüidad, inicio de
// palabra) con recencia como desempate.
// ---------------------------------------------------------------------------

class FuzzyMatch {
  final CommandRecord record;
  final double score;

  const FuzzyMatch({required this.record, required this.score});
}

class FuzzyFinder {
  FuzzyFinder({this.fuzzy = true});

  final bool fuzzy;

  List<FuzzyMatch> rank(List<CommandRecord> records, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      final sorted = [...records]..sort((a, b) => b.at.compareTo(a.at));
      return [for (final r in sorted) FuzzyMatch(record: r, score: 0)];
    }
    final out = <FuzzyMatch>[];
    for (final r in records) {
      final score = _score(r, q);
      if (score > 0) out.add(FuzzyMatch(record: r, score: score));
    }
    out.sort((a, b) => b.score.compareTo(a.score));
    return out;
  }

  double _score(CommandRecord record, String q) {
    final cmd = record.command.toLowerCase();
    final positions = <int>[];
    var ci = 0;
    for (var i = 0; i < cmd.length && ci < q.length; i++) {
      if (cmd.codeUnitAt(i) == q.codeUnitAt(ci)) {
        positions.add(i);
        ci++;
      }
    }
    if (ci < q.length) return 0; // no es subsecuencia
    if (!fuzzy) return 1;

    var structural = 0.0;
    for (var k = 0; k < positions.length; k++) {
      final p = positions[k];
      final boundary = p == 0 ||
          cmd.codeUnitAt(p - 1) == 0x20 || // espacio
          cmd.codeUnitAt(p - 1) == 0x2f || // /
          cmd.codeUnitAt(p - 1) == 0x2d || // -
          cmd.codeUnitAt(p - 1) == 0x2e; // .
      final consecutive = k > 0 && positions[k] == positions[k - 1] + 1;
      structural += boundary ? 4 : (consecutive ? 2 : 1);
    }
    final hours = DateTime.now().difference(record.at).inHours;
    final recency = 0.5 * (1 - (hours / 720).clamp(0.0, 1.0));
    return structural + recency;
  }
}
