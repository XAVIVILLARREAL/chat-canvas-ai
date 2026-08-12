import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:dartssh2/src/ssh_channel.dart' show SSHChannel, SSHChannelController;
import 'package:empresa_dev/screens/terminal_screen.dart';
import 'package:empresa_dev/services/ssh_service.dart';
import 'package:warp_core/warp_core.dart';

/// Fakes para no tocar red: SshService que devuelve una SSHSession en memoria.
class _FakeService extends SshService {
  final _FakeSession session;
  _FakeService(this.session);

  @override
  Future<SSHSession> connectShell(SshHost host) async => session;
}

class _FakeSession implements SSHSession {
  final List<String> written = [];
  final _stdin = StreamController<Uint8List>();
  final _done = Completer<void>();
  late final SSHChannel _channel = SSHChannelController(
    localId: 1,
    localMaximumPacketSize: 32768,
    localInitialWindowSize: 2097152,
    remoteId: 1,
    remoteMaximumPacketSize: 32768,
    remoteInitialWindowSize: 2097152,
    sendMessage: (_) {},
  ).channel;

  @override
  StreamSink<Uint8List> get stdin => _stdin.sink;
  @override
  Stream<Uint8List> get stdout => const Stream.empty();
  @override
  Stream<Uint8List> get stderr => const Stream.empty();
  @override
  int? get exitCode => null;
  @override
  SSHSessionExitSignal? get exitSignal => null;
  @override
  Future<void> get done => _done.future;
  @override
  SSHChannel get channel => _channel;
  @override
  void write(Uint8List data) => written.add(String.fromCharCodes(data));
  @override
  Future<void> flush() async {}
  @override
  void resizeTerminal(int cols, int rows, [int pixelWidth = 0, int pixelHeight = 0]) {}
  @override
  void close() {}
  @override
  Future<int?> waitForExit({Duration? timeout}) async => 0;
  @override
  void kill(SSHSignal signal) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final host = SshHost(name: 'pve', host: '100.101.69.79', username: 'root');

  Future<_FakeSession> pumpTerminal(WidgetTester tester,
      {CommandHistoryStore? store, SnippetStore? snippetStore}) async {
    final session = _FakeSession();
    await tester.pumpWidget(MaterialApp(
      home: TerminalScreen(
        host: host,
        service: _FakeService(session),
        historyStore: store ?? CommandHistoryStore(),
        snippetStore: snippetStore ?? SnippetStore(),
      ),
    ));
    await tester.pumpAndSettle();
    return session;
  }

  group('Warp-mode (slice 8.5.2)', () {
    testWidgets('captura comandos tecleados en el historial por host',
        (tester) async {
      final store = CommandHistoryStore();
      await pumpTerminal(tester, store: store);

      // El input del usuario viaja por Terminal.onOutput (xterm no expone
      // onCommand): lo alimentamos como lo haría el teclado.
      final state =
          tester.state<TerminalScreenState>(find.byType(TerminalScreen));
      state.terminal.onOutput?.call('ls -la\r');

      expect((await store.forHost('pve')).map((r) => r.command), ['ls -la']);
    });

    testWidgets('Ctrl+R abre el overlay y la búsqueda fuzzy lista comandos',
        (tester) async {
      final store = CommandHistoryStore();
      await store.add('pve', 'docker compose up');
      await store.add('pve', 'ssh server');
      await pumpTerminal(tester, store: store);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget,
          reason: 'el overlay de búsqueda se abre con Ctrl+R');
      expect(find.text('ssh server'), findsOneWidget,
          reason: 'el historial aparece en el overlay');
    });

    testWidgets('escribir en el overlay filtra fuzzy y Enter ejecuta',
        (tester) async {
      final store = CommandHistoryStore();
      await store.add('pve', 'docker compose up');
      await store.add('pve', 'ssh server');
      final session = await pumpTerminal(tester, store: store);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'ssh');
      await tester.pumpAndSettle();
      expect(find.text('docker compose up'), findsNothing);
      expect(find.text('ssh server'), findsOneWidget);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(session.written.any((w) => w.startsWith('ssh server\r')), isTrue,
          reason: 'Enter envía el comando seleccionado al shell');
      expect(find.byType(TextField), findsNothing,
          reason: 'el overlay se cierra tras ejecutar');
    });

    testWidgets('la sugerencia inline aparece y Tab la acepta', (tester) async {
      final store = CommandHistoryStore();
      await store.add('pve', 'ls -la');
      final session = await pumpTerminal(tester, store: store);

      final state =
          tester.state<TerminalScreenState>(find.byType(TerminalScreen));
      state.terminal.onOutput?.call('ls');
      await tester.pumpAndSettle();

      expect(find.text('ls -la'), findsOneWidget,
          reason: 'la barra de sugerencia muestra el match');
      expect(find.byIcon(Icons.tab), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(session.written.any((w) => w.contains(' -la')), isTrue,
          reason: 'Tab envía el resto de la sugerencia (completa la línea)');
      expect(find.text('ls -la'), findsNothing,
          reason: 'la sugerencia desaparece al aceptarla');
    });

    testWidgets('Ctrl+Shift+R sigue reconectando', (tester) async {
      final store = CommandHistoryStore();
      final session = await pumpTerminal(tester, store: store);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(find.byType(TextField), findsNothing,
          reason: 'Ctrl+Shift+R no abre la búsqueda');
      expect(session.written, isEmpty);
    });
  });

  group('Snippets (slice 8.5.3)', () {
    testWidgets('el botón abre la hoja y tap inserta el snippet en el shell',
        (tester) async {
      final snippets = SnippetStore();
      await snippets.add('pve', name: 'logs', text: 'journalctl -f');
      final session = await pumpTerminal(tester, snippetStore: snippets);

      await tester.tap(find.byTooltip('Snippets'));
      await tester.pumpAndSettle();

      expect(find.text('logs'), findsOneWidget);
      expect(find.text('journalctl -f'), findsOneWidget);

      await tester.tap(find.text('logs'));
      await tester.pumpAndSettle();

      expect(session.written.any((w) => w.contains('journalctl -f')), isTrue,
          reason: 'tap en snippet escribe el comando en el prompt');
      expect(find.text('logs'), findsNothing,
          reason: 'la hoja se cierra al insertar');
    });

    testWidgets('crear snippet desde la hoja lo guarda por host',
        (tester) async {
      final snippets = SnippetStore();
      await pumpTerminal(tester, snippetStore: snippets);

      await tester.tap(find.byTooltip('Snippets'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sin snippets'), findsOneWidget);

      await tester.tap(find.text('Nuevo snippet'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Nombre'), 'status');
      await tester.enterText(
          find.widgetWithText(TextField, 'Comando'), 'git status');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('status'), findsOneWidget);
      expect((await snippets.list('pve')).single.text, 'git status');
    });
  });
}
