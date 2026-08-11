import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/screens/tabs_screen.dart';
import 'package:empresa_dev/screens/terminal_screen.dart';
import 'package:empresa_dev/services/sessions_store.dart';
import 'package:empresa_dev/services/ssh_service.dart';

class _FakeStore extends SessionsStore {
  @override
  Future<void> load() async {}

  @override
  Future<void> save() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TabsScreen: la tarjeta del host conecta por SSH en un toque',
      (tester) async {
    final hosts = [
      SshHost(
        name: 'Servidor 2',
        host: '100.101.69.79',
        port: 22,
        username: 'root',
        authType: SshAuthType.key,
      ),
    ];
    await tester.pumpWidget(MaterialApp(
      home: TabsScreen(
        hosts: hosts,
        sshService: SshService(),
        store: _FakeStore(),
      ),
    ));
    await tester.pump();

    // La tarjeta del host y el botón "Conectar por SSH" están presentes.
    expect(find.text('Servidor 2'), findsOneWidget);
    expect(find.byTooltip('Conectar por SSH'), findsOneWidget);
    expect(find.byTooltip('SFTP'), findsOneWidget);

    // Tocar la tarjeta navega al terminal SSH (flujo de un toque).
    await tester.tap(find.byTooltip('Conectar por SSH'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Debe abrirse el TerminalScreen (conectando o con error, pero no crash).
    expect(find.byType(TerminalScreen), findsOneWidget);
  });
}
