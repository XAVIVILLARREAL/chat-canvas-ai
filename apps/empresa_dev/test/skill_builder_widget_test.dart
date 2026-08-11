import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/models/skill.dart';
import 'package:empresa_dev/screens/skill_builder_screen.dart';

void main() {
  testWidgets('el form crea un Skill con body con las secciones de los bloques',
      (tester) async {
    Skill? saved;
    await tester.pumpWidget(MaterialApp(
      home: SkillBuilderScreen(onSave: (s) => saved = s),
    ));

    await tester.enterText(find.byKey(const Key('skill-name')), 'mi-skill');
    await tester.enterText(
        find.byKey(const Key('skill-description')), 'Hace cosas');

    await tester.tap(find.widgetWithText(ListTile, 'Instrucciones'));
    await tester.pump();

    expect(saved, isNull);
    await tester.tap(find.text('Guardar skill'));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.name, 'mi-skill');
    expect(saved!.bodySections(), contains('Instrucciones'));
    expect(saved!.toMarkdown(), startsWith('---\nname: mi-skill\n'));
  });

  testWidgets('chips de triggers se agregan y quitan', (tester) async {
    Skill? saved;
    await tester.pumpWidget(MaterialApp(
      home: SkillBuilderScreen(onSave: (s) => saved = s),
    ));

    await tester.enterText(find.byKey(const Key('skill-trigger')), 'terminal');
    await tester.tap(find.byKey(const Key('add-trigger')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('skill-trigger')), 'ssh');
    await tester.tap(find.byKey(const Key('add-trigger')));
    await tester.pump();

    expect(find.text('terminal'), findsOneWidget);
    expect(find.text('ssh'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pump();

    await tester.tap(find.text('Guardar skill'));
    await tester.pump();
    expect(saved!.triggers, containsAll(['ssh']));
    expect(saved!.triggers, isNot(contains('terminal')));
  });

  testWidgets('preview muestra el markdown del body en vivo', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SkillBuilderScreen(onSave: (_) {}),
    ));

    await tester.enterText(
        find.byKey(const Key('skill-body')), '# Título de prueba\n\nCuerpo');
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byType(MarkdownBody),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.byType(MarkdownBody), findsOneWidget);
  });
}