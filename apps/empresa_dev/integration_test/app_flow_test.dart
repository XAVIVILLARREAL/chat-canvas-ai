import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:empresa_dev/main.dart' as app;

/// E2E del flujo principal en la plataforma real (desktop/Android).
/// Ejecutar: flutter test integration_test/app_flow_test.dart -d windows
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('flujo principal: tabs, canva y hub', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. Vista Tabs: host pve + conmutador
    expect(find.text('pve'), findsOneWidget);
    expect(find.text('Empresa Dev'), findsOneWidget);
    // conmutador Tabs | Canva
    expect(find.text('Tabs'), findsOneWidget);
    expect(find.text('Canva'), findsOneWidget);

    // botón hub presente (usa tooltip para ser preciso)
    expect(find.byTooltip('Hub de sync'), findsOneWidget);

    // 2. Cambiar a vista Canva
    await tester.tap(find.text('Canva'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);

    // volver a Tabs
    await tester.tap(find.text('Tabs'));
    await tester.pumpAndSettle();

    // 3. Abrir el hub
    await tester.tap(find.byTooltip('Hub de sync'));
    await tester.pumpAndSettle();
    expect(find.text('Hub de sincronización'), findsOneWidget);
    expect(find.text('Ser el hub (celular)'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
  });
}
