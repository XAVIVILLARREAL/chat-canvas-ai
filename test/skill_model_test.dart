import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/models/skill.dart';

void main() {
  group('Skill serialización', () {
    test('round-trip toMarkdown/fromMarkdown conserva todo', () {
      final skill = Skill(
        name: 'dev',
        description: 'Guía de desarrollo por fases',
        triggers: ['dev', 'plan', 'siguiente fase'],
        tags: ['flujo', 'gates'],
        permissions: ['bash'],
        body: '# Skill dev\n\n## Instrucciones\n\nHaz las fases.',
      );
      final parsed = Skill.fromMarkdown(skill.toMarkdown())!;
      expect(parsed.name, 'dev');
      expect(parsed.description, 'Guía de desarrollo por fases');
      expect(parsed.triggers, ['dev', 'plan', 'siguiente fase']);
      expect(parsed.tags, ['flujo', 'gates']);
      expect(parsed.permissions, ['bash']);
      expect(parsed.body, contains('## Instrucciones'));
    });

    test('triggers se serializan dentro de la description (Trigger: ...)', () {
      final skill = Skill(
        name: 'x',
        description: 'Hace cosas',
        triggers: ['a', 'b'],
      );
      final md = skill.toMarkdown();
      expect(md, contains('description: Hace cosas. Trigger: "a", "b"'));
      expect(md, startsWith('---\nname: x\n'));
      expect(md, contains('\n---\n'));
    });

    test('parsea un SKILL.md real (formato dev del repo)', () {
      const real = '''---
name: dev
description: Guía de desarrollo por fases del proyecto Empresa Dev. Trigger: "dev", "super plan", "plan", "siguiente fase", "implementar", "gate".
---

# Skill dev

## 1. Saber dónde estamos

1. Leer `docs/SUPER_PLAN.md`.
''';
      final skill = Skill.fromMarkdown(real)!;
      expect(skill.name, 'dev');
      expect(skill.triggers, ['dev', 'super plan', 'plan', 'siguiente fase', 'implementar', 'gate']);
      expect(skill.body, contains('## 1. Saber dónde estamos'));
    });

    test('sin frontmatter → null', () {
      expect(Skill.fromMarkdown('hola sin frontmatter'), isNull);
    });

    test('frontmatter vacío → null', () {
      expect(Skill.fromMarkdown('---\n---\n# Solo cuerpo'), isNull);
    });
  });

  group('Bloques del body', () {
    test('bloques crean secciones y se reconocen', () {
      final skill = Skill(
        name: 's',
        description: 'd',
        body: '# S\n\n## Instrucciones\n\nhaz\n\n## Ejemplos\n\nasí\n\n## Restricciones\n\nno\n\n## Anti-patrónes\n\nevita\n',
      );
      expect(skill.bodySections(), containsAll(['Instrucciones', 'Ejemplos', 'Restricciones', 'Anti-patrónes']));
      expect(skill.section('Instrucciones'), 'haz');
      expect(skill.section('Restricciones'), 'no');
    });
  });
}
