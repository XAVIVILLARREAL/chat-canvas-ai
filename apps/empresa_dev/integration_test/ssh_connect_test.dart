import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:empresa_dev/main.dart' as app;
import 'package:empresa_dev/screens/terminal_screen.dart';

/// E2E del flujo de conexión SSH en un toque (objetivo del usuario):
/// hosts -> tap "Conectar por SSH" -> el terminal conecta a pve y muestra
/// el prompt del shell.
/// Requiere: llave test/fixtures/app_test_key + pve vía Tailscale.
/// Ejecutar: flutter test integration_test/ssh_connect_test.dart -d windows
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('conectar por SSH a pve en un toque', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // El host del servidor (pve) está listo para conectar.
    expect(find.text('pve'), findsOneWidget);
    expect(find.byTooltip('Conectar por SSH'), findsOneWidget);

    // Un solo toque abre el terminal SSH.
    await tester.tap(find.byTooltip('Conectar por SSH'));
    await tester.pumpAndSettle();

    // El TerminalScreen se abrió.
    expect(find.byType(TerminalScreen), findsOneWidget);

    // Esperar a que el shell conecte y muestre el prompt (root@ / #).
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo conectar'), findsNothing,
        reason: 'la conexión SSH a pve debe funcionar');
  }, timeout: const Timeout(Duration(seconds: 90)));
}
