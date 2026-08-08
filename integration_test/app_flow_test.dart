import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:empresa_dev/main.dart' as app;

/// E2E del flujo principal en la plataforma real (desktop/Android).
/// Ejecutar: flutter test integration_test/app_flow_test.dart -d windows
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('flujo principal: hosts, canva y hub', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. Pantalla de hosts con pve
    expect(find.text('pve'), findsOneWidget);
    expect(find.text('Empresa Dev'), findsOneWidget);

    // Botones disponibles
    expect(find.byIcon(Icons.account_tree), findsOneWidget); // canva
    expect(find.byIcon(Icons.cell_tower), findsOneWidget); // hub

    // 2. Abrir el canva
    await tester.tap(find.byIcon(Icons.account_tree));
    await tester.pumpAndSettle();
    expect(find.text('Canva'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);

    // volver
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 3. Abrir el hub
    await tester.tap(find.byIcon(Icons.cell_tower));
    await tester.pumpAndSettle();
    expect(find.text('Hub de sincronización'), findsOneWidget);
    expect(find.text('Ser el hub (celular)'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
  });
}
