import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/models/skill.dart';
import 'package:empresa_dev/screens/skill_lab_screen.dart';

void main() {
  final skills = [
    const Skill(
      name: 'dev',
      description: 'Guía por fases',
      triggers: ['dev', 'plan', 'implementar'],
    ),
    const Skill(
      name: 'terminal',
      description: 'Ayuda SSH',
      triggers: ['terminal', 'ssh'],
    ),
  ];

  testWidgets('el sandbox muestra ranking con confianza y por qué',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SkillLabScreen(skills: skills),
    ));

    await tester.enterText(
        find.byKey(const Key('lab-input')), 'implementar un plan');
    await tester.pump();

    expect(find.text('dev'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.textContaining('implementar'),
      ),
      findsWidgets,
    );
  });

  testWidgets('sin matches muestra empty state', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SkillLabScreen(skills: skills),
    ));

    await tester.enterText(find.byKey(const Key('lab-input')), 'zzz');
    await tester.pump();

    expect(find.textContaining('sin coincidencias'), findsOneWidget);
  });
}