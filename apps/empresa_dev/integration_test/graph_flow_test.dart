import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:empresa_dev/main.dart' as app;

/// E2E del grafo del proyecto (Etapa 5): 2D + 3D con WebView2.
///
/// Ejecutar (necesita un directorio real:
///
/// ```
/// flutter test integration_test/graph_flow_test.dart -d windows `
///   --dart-define=EMPRESA_DEV_REPO=<abs>/test/fixtures/graph_demo
/// ```
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Screenshots solo con 'flutter drive' (con 'flutter test' se ignoran).
  Future<void> shot(String name) async {
    try {
      await binding.takeScreenshot(name);
    } catch (_) {}
  }

  testWidgets('grafo: menú → 2D con nodos → 3D cargado (WebView2)', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Vista Canva (el segmento del conmutador; el título repite el nombre)
    await tester.tap(find.widgetWithText(SegmentedButton<String>, 'Canva'));
    await tester.pumpAndSettle();

    // Menú "Añadir" → "Grafo del proyecto"
    await tester.tap(find.byTooltip('Añadir'));
    await tester.pumpAndSettle();
    expect(find.text('Grafo del proyecto'), findsOneWidget);
    await tester.ensureVisible(find.text('Grafo del proyecto'));
    await tester.pumpAndSettle();
    await shot('etapa5-3d-01-menu');

    await tester.tap(find.text('Grafo del proyecto'));
    await tester.pumpAndSettle();

    // Grafo 2D: nodos del fixture
    expect(find.text('Grafo del proyecto'), findsOneWidget);
    expect(find.text('main.dart'), findsOneWidget);
    expect(find.text('helper.dart'), findsOneWidget);
    expect(find.text('guia.md'), findsOneWidget);
    expect(find.text('script.py'), findsOneWidget);
    await shot('etapa5-3d-02-grafo2d');

    // Grafo 3D (WebView2 + Three.js)
    await tester.tap(find.byTooltip('Ver grafo 3D'));
    await tester.pump();

    var opened = false;
    for (var i = 0; i < 60 && !opened; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      opened = find.text('Grafo 3D').evaluate().isNotEmpty;
    }
    if (!opened) {
      debugDumpApp();
    }
    expect(opened, isTrue, reason: 'la pantalla 3D no abrió');

    // Esperar a que la webview cargue (servidor local + Three.js + controls)
    var loaded = false;
    for (var i = 0; i < 60 && !loaded; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      loaded = find.text('3D cargado').evaluate().isNotEmpty;
    }
    expect(loaded, isTrue, reason: 'la webview 3D no cargó en 30s');
    await shot('etapa5-3d-03-grafo3d');

    // ventana estable para captura externa de evidencia
    await tester.pump(const Duration(seconds: 8));

    await tester.pumpAndSettle();

    // Volver al 2D
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Grafo del proyecto'), findsOneWidget);
  });
}