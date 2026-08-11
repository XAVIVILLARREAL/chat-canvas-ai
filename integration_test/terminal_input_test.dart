import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:empresa_dev/screens/terminal_screen.dart';
import 'package:empresa_dev/services/ssh_service.dart';

/// Prueba real del input del terminal: conecta a pve, escribe un comando
/// con el teclado (simulado) y verifica que la respuesta llega al terminal.
/// Esto valida el camino completo: tecla -> TerminalView -> onOutput -> shell.
/// Requiere: llave test/fixtures/app_test_key + pve (Tailscale).
/// Ejecutar: flutter test integration_test/terminal_input_test.dart -d windows
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('terminal SSH: escribir whoami con el teclado y recibir root',
      (tester) async {
    final key = _readKey();
    expect(key, isNotNull, reason: 'falta la llave test/fixtures/app_test_key');
    final host = SshHost(
      name: 'pve',
      host: '100.101.69.79',
      username: 'root',
      authType: SshAuthType.key,
      keyPem: key,
    );

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: TerminalScreen(host: host, service: SshService()),
    ));

    // Esperar conexión (el spinner tarda unos segundos)
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo conectar'), findsNothing);

    final state = tester.state<TerminalScreenState>(find.byType(TerminalScreen));
    expect(state.isConnected, isTrue, reason: 'el terminal debe estar conectado');

    // Escribir el comando con el teclado (como un humano)
    for (final ch in 'whoami'.split('')) {
      await tester.sendKeyEvent(_keyForChar(ch), character: ch);
      await tester.pump();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter, character: '\r');
    await tester.pump();

    // Esperar la respuesta del shell en el buffer del terminal
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    String text = _terminalText(state);
    while (DateTime.now().isBefore(deadline) && !text.contains('root')) {
      await tester.pump(const Duration(milliseconds: 300));
      text = _terminalText(state);
    }

    // Evidencia
    final dir = Directory('data/evidence');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    File('data/evidence/terminal-input-whoami.txt').writeAsStringSync(text);

    expect(text, contains('root'),
        reason: 'whoami debe devolver root tras escribir con el teclado');
    expect(text, contains('whoami'),
        reason: 'el comando tecleado debe aparecer (eco del shell)');
  }, timeout: const Timeout(Duration(seconds: 60)));
}

String _terminalText(TerminalScreenState state) {
  final lines = state.terminal.buffer.lines;
  final sb = StringBuffer();
  for (var i = 0; i < lines.length; i++) {
    sb.writeln(lines[i].getText());
  }
  return sb.toString();
}

LogicalKeyboardKey _keyForChar(String ch) {
  switch (ch) {
    case 'w':
      return LogicalKeyboardKey.keyW;
    case 'h':
      return LogicalKeyboardKey.keyH;
    case 'o':
      return LogicalKeyboardKey.keyO;
    case 'a':
      return LogicalKeyboardKey.keyA;
    case 'm':
      return LogicalKeyboardKey.keyM;
    case 'i':
      return LogicalKeyboardKey.keyI;
  }
  return LogicalKeyboardKey.keyW;
}

String? _readKey() {
  try {
    final f = File('test/fixtures/app_test_key');
    if (f.existsSync()) return f.readAsStringSync();
  } catch (_) {}
  return null;
}
