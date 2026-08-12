import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:warp_core/warp_core.dart';

void main() {
  group('CommandLineTracker', () {
    test('acumula input y emite la línea completa al pulsar Enter', () {
      final lines = <String>[];
      final t = CommandLineTracker(onCommand: lines.add);
      t.feed('ls ');
      t.feed('-la');
      t.feed('\r');
      expect(t.currentLine, '');
      expect(lines, ['ls -la']);
    });

    test('backspace borra el último carácter', () {
      final t = CommandLineTracker();
      t.feed('abc');
      t.feed('\x7f');
      expect(t.currentLine, 'ab');
    });

    test('Ctrl-C resetea la línea sin emitir comando', () {
      final lines = <String>[];
      final t = CommandLineTracker(onCommand: lines.add);
      t.feed('killall');
      t.feed('\x03');
      expect(t.currentLine, '');
      expect(lines, isEmpty);
    });

    test('flechas y secuencias ANSI no contaminan el buffer', () {
      final t = CommandLineTracker();
      t.feed('ssh');
      t.feed('\x1b[A');
      t.feed('\x1b[D');
      t.feed(' server');
      expect(t.currentLine, 'ssh server');
    });

    test('la flecha ↑/↓ no rompe el buffer tras Enter', () {
      final lines = <String>[];
      final t = CommandLineTracker(onCommand: lines.add);
      t.feed('top\r');
      t.feed('\x1b[A'); // up: historia (no soportada localmente, se ignora)
      expect(t.currentLine, '');
      expect(lines, ['top']);
    });

    test('Enter vacío no emite comando', () {
      final lines = <String>[];
      final t = CommandLineTracker(onCommand: lines.add);
      t.feed('\r');
      expect(lines, isEmpty);
    });

    test('UTF-8 multibyte se conserva (rune-safe backspace)', () {
      final t = CommandLineTracker();
      t.feed('hola ñ');
      t.feed('\x7f');
      expect(t.currentLine, 'hola ');
    });

    test('Ctrl-U borra la línea completa', () {
      final t = CommandLineTracker();
      t.feed('sudo rm -rf /');
      t.feed('\x15');
      expect(t.currentLine, '');
    });
  });

  group('CommandHistoryStore', () {
    test('add + forHost conserva orden y deduplica consecutivos', () async {
      final store = CommandHistoryStore(); // dir null → memoria
      await store.add('pve', 'ls -la');
      await store.add('pve', 'ls -la'); // consecutivo → dedupe
      await store.add('pve', 'uptime');
      await store.add('pve', 'ls -la'); // repite no-consecutivo → se guarda
      await store.add('otro', 'whoami');

      final pve = await store.forHost('pve');
      expect(pve.map((r) => r.command), ['ls -la', 'uptime', 'ls -la']);
      expect((await store.forHost('otro')).single.command, 'whoami');
      expect(pve.first.at, isA<DateTime>());
    });

    test('cap 500 descarta los más antiguos', () async {
      final store = CommandHistoryStore();
      for (var i = 0; i < 520; i++) {
        await store.add('pve', 'cmd$i');
      }
      final all = await store.forHost('pve');
      expect(all.length, 500);
      expect(all.first.command, 'cmd20'); // los 20 más viejos se descartaron
    });

    test('persistencia JSON round-trip', () async {
      final dir = Directory.systemTemp.createTempSync('warp_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = CommandHistoryStore(dir: dir);
      await store.add('pve', 'git status');
      await store.add('pve', 'docker ps');

      final reloaded = CommandHistoryStore(dir: dir);
      final all = await reloaded.forHost('pve');
      expect(all.map((r) => r.command), ['git status', 'docker ps']);
      expect(jsonDecode(File('${dir.path}/history.json').readAsStringSync()),
          isA<Map>());
    });

    test('remove elimina un comando específico del host', () async {
      final store = CommandHistoryStore();
      await store.add('pve', 'a');
      await store.add('pve', 'b');
      await store.remove('pve', 'a');
      expect((await store.forHost('pve')).map((r) => r.command), ['b']);
    });

    test('clear limpia un host sin tocar otros', () async {
      final store = CommandHistoryStore();
      await store.add('pve', 'a');
      await store.add('otro', 'b');
      await store.clear('pve');
      expect(await store.forHost('pve'), isEmpty);
      expect((await store.forHost('otro')).single.command, 'b');
    });

    test('search devuelve vacío sin query y con query coincide', () async {
      final store = CommandHistoryStore();
      await store.add('pve', 'ssh server');
      await store.add('pve', 'docker compose up');
      expect((await store.search('pve', 'ssh')).single.command, 'ssh server');
      expect(await store.search('pve', 'zzz'), isEmpty);
    });
  });

  group('FuzzyFinder', () {
    List<CommandRecord> recs(List<String> cmds) => [
          for (var i = 0; i < cmds.length; i++)
            CommandRecord(command: cmds[i], at: DateTime(2026, 8, 1, 10, i)),
        ];

    test('subsecuencia contigua rankea por encima de no-contigua', () {
      final finder = FuzzyFinder();
      final ranked = finder.rank(recs(['ls -sa', 'ssh server']), 'ss');
      expect(ranked.first.record.command, 'ssh server');
      expect(ranked.first.score, greaterThan(ranked.last.score));
    });

    test('subsecuencia no contigua también encuentra', () {
      final finder = FuzzyFinder();
      final ranked = finder.rank(recs(['docker compose up', 'ls -la']), 'dc');
      expect(ranked.first.record.command, 'docker compose up');
    });

    test('recencia desempata con misma afinidad', () {
      final finder = FuzzyFinder();
      final ranked = finder.rank(
        [
          CommandRecord(command: 'git status', at: DateTime(2026, 8, 1, 9)),
          CommandRecord(command: 'git log', at: DateTime(2026, 8, 1, 10)),
        ],
        'g',
      );
      expect(ranked.first.record.command, 'git log');
    });

    test('query vacía → más reciente primero', () {
      final finder = FuzzyFinder();
      final ranked = finder.rank(recs(['a', 'b']), '');
      expect(ranked.first.record.command, 'b');
    });

    test('sin match → lista vacía', () {
      final finder = FuzzyFinder();
      expect(finder.rank(recs(['ls']), 'zz'), isEmpty);
    });
  });
}
