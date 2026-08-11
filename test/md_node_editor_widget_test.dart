import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/widgets/md_node_editor.dart';

void main() {
  Widget wrap(MdNodeEditor editor) => MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(8), child: editor),
        ),
      );

  testWidgets('preview renderiza markdown del body en vivo', (tester) async {
    await tester.pumpWidget(wrap(MdNodeEditor(
      initialBody: '# Título\n\nTexto [[docs]] aquí',
      knownNodes: {'docs'},
      onChanged: (_) {},
      onOpenLink: (_) {},
      onCreateLink: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('Título'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '# Cambiado');
    await tester.pumpAndSettle();
    expect(find.text('Título'), findsNothing);
    expect(find.text('Cambiado'), findsOneWidget);
  });

  testWidgets('click en link de nodo existente → onOpenLink', (tester) async {
    String? opened;
    await tester.pumpWidget(wrap(MdNodeEditor(
      initialBody: '[[docs|Plan]]',
      knownNodes: {'docs'},
      onChanged: (_) {},
      onOpenLink: (t) => opened = t,
      onCreateLink: (_) {},
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plan', findRichText: true));
    await tester.pumpAndSettle();
    expect(opened, 'docs');
  });

  testWidgets('click en link de nodo inexistente → onCreateLink', (tester) async {
    String? created;
    await tester.pumpWidget(wrap(MdNodeEditor(
      initialBody: '[[idea nueva]]',
      knownNodes: const {},
      onChanged: (_) {},
      onOpenLink: (_) {},
      onCreateLink: (t) => created = t,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('idea nueva', findRichText: true));
    await tester.pumpAndSettle();
    expect(created, 'idea nueva');
  });
}
