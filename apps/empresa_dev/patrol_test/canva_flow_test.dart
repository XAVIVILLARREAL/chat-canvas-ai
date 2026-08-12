import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:empresa_dev/main.dart' as app;

/// E2E mobile del flujo crítico (Etapa 7, SDD-120) con patrol_cli.
/// Mismo flujo que tool/e2e_web.spec.js pero en Android real:
/// canva -> nota -> editar body -> guardar -> RELANZAR app -> persiste.
///
/// Gate manual (requiere dispositivo/emulador Android real):
///   cd apps/empresa_dev
///   flutter pub get
///   patrol test -d 'device_id' patrol_test/canva_flow_test.dart
void main() {
  patrolTest(
    'canva: nota -> editar -> guardar -> relanzar -> persiste (patrol)',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      // 1. Ir a la vista Canva
      await $.tap(find.text('Canva'));
      await $.pumpAndSettle();

      // 2. Añadir nota: botón "Añadir" -> sheet -> tile "Nota" -> diálogo
      await $.tap(find.text('Añadir').first);
      await $.pumpAndSettle();
      await $.tap(find.text('Nota'));
      await $.pumpAndSettle();
      await $.enterText(find.byType(TextField).first, 'nota patrol');
      await $.tap(find.widgetWithText(FilledButton, 'Añadir'));
      await $.pumpAndSettle();

      // 3. El nodo aparece en el canva
      expect(find.text('nota patrol'), findsOneWidget);

      // 4. Editar la nota (MdNodeScreen) y guardar
      await $.tap(find.text('nota patrol'));
      await $.pumpAndSettle();
      await $.enterText(find.byType(TextField).first, '# editada\nbody nuevo');
      await $.tap(find.byTooltip('Guardar'));
      await $.pumpAndSettle();
      await $.tap(find.byTooltip('Back'));
      await $.pumpAndSettle();

      // 5. RELANZAR la app (la cierra y la reabre): persistencia real en disco.
      // Patrol 4.x: $.platform.mobile.openApp() es la API moderna (sin appId
      // usa el package de la config `patrol:` del pubspec).
      await $.platform.mobile.openApp();
      await $.pumpAndSettle();

      // 6. La nota sigue tras el relanzamiento (storage io en Android)
      await $.tap(find.text('Canva'));
      await $.pumpAndSettle();
      expect(find.text('nota patrol'), findsOneWidget);
    },
  );
}