import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:empresa_dev/screens/terminal_screen.dart';
import 'package:empresa_dev/services/ssh_service.dart';

/// Prueba real del terminal SSH: conecta a pve y verifica que la salida
/// del shell llega al terminal (evidencia de que escribir funciona).
/// Requiere: llave test/fixtures/app_test_key + pve (Tailscale).
/// Ejecutar: flutter test integration_test/terminal_test.dart -d windows
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('terminal SSH conecta y muestra el prompt', (tester) async {
    final key = _readKey();
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

    // No debe haber error de conexión
    expect(find.textContaining('No se pudo conectar'), findsNothing);

    // El terminal debe mostrar el prompt del shell (root@pve o similar)
    // El TerminalView de xterm renderiza texto; buscamos un indicador
    // de que se recibió salida (root@ o "# ").
    final textPresent = find.textContaining(RegExp('root|#')); 
    expect(textPresent, findsWidgets);
  });
}

String? _readKey() {
  try {
    final f = File('test/fixtures/app_test_key');
    if (f.existsSync()) return f.readAsStringSync();
  } catch (_) {}
  return null;
}
