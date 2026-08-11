import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/screens/code_editor_screen.dart';
import 'package:empresa_dev/screens/project_tree_screen.dart';
import 'package:empresa_dev/services/project_service.dart';

void main() {
  late Directory tempDir;
  late ProjectService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('project_tree_widget');
    Directory('${tempDir.path}/lib').createSync(recursive: true);
    Directory('${tempDir.path}/docs').createSync(recursive: true);
    File('${tempDir.path}/lib/main.dart').writeAsStringSync('void main() {}');
    File('${tempDir.path}/docs/PLAN.md').writeAsStringSync('# Plan del proyecto');
    service = ProjectService(root: tempDir.path);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  testWidgets('el árbol renderiza archivos y el click abre el editor', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ProjectTreeScreen(service: service, title: 'Proyecto test'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('lib'), findsOneWidget);
    expect(find.text('docs'), findsOneWidget);

    await tester.tap(find.text('lib'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('main.dart'));
    await tester.pumpAndSettle();

    expect(find.text('void main() {}'), findsOneWidget);
  });

  testWidgets('editar marca modificado, Ctrl+S guarda en disco y muestra Guardado', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ProjectTreeScreen(service: service, title: 'Proyecto test'),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('docs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PLAN.md'));
    await tester.pumpAndSettle();

    expect(find.text('Guardado'), findsOneWidget);

    final editor = find.byType(TextField);
    await tester.enterText(editor, '# Plan actualizado');
    await tester.pump();

    expect(find.text('Modificado'), findsOneWidget);

    // Ctrl+S
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.text('Modificado'), findsNothing);
    expect(File('${tempDir.path}/docs/PLAN.md').readAsStringSync(), '# Plan actualizado');
  });

  testWidgets('archivo binario muestra aviso y no abre editor', (tester) async {
    File('${tempDir.path}/logo.bin').writeAsBytesSync([0, 1, 2, 255]);
    await tester.pumpWidget(MaterialApp(
      home: ProjectTreeScreen(service: service, title: 'Proyecto test'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('logo.bin'));
    await tester.pumpAndSettle();

    expect(find.textContaining('binario'), findsOneWidget);
    expect(find.byType(CodeEditorScreen), findsNothing);
  });
}