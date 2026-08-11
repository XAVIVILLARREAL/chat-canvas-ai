import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/models/skill.dart';
import 'package:empresa_dev/services/dialect_exporter.dart';

void main() {
  final skill = Skill(
    name: 'terminal-sos',
    description: 'Ayuda con terminales',
    triggers: ['terminal', 'ssh'],
    tags: ['ops'],
    permissions: ['bash'],
    body: '# Terminal SOS\n\n## Instrucciones\n\nHaz cosas.',
  );

  group('DialectExporter', () {
    test('opencode → SKILL.md con frontmatter name/description', () {
      final out = DialectExporter.render(skill, Dialect.opencode);
      expect(out, startsWith('---\nname: terminal-sos\n'));
      expect(out, contains('description: Ayuda con terminales. Trigger: "terminal", "ssh"'));
      expect(out, contains('## Instrucciones'));
    });

    test('cursor → frontmatter .mdc con description y globs', () {
      final out = DialectExporter.render(skill, Dialect.cursor);
      expect(out, startsWith('---\ndescription: Ayuda con terminales. Trigger: "terminal", "ssh"\nglobs:'));
      expect(out, contains('---\n\n# Terminal SOS'));
      expect(out, contains('## Instrucciones'));
    });

    test('claude → frontmatter name/description estilo Claude Code', () {
      final out = DialectExporter.render(skill, Dialect.claude);
      expect(out, contains('---\nname: terminal-sos'));
      expect(out, contains('description: Ayuda con terminales'));
      expect(out, contains('## Instrucciones'));
    });

    test('continue → bloque de reglas YAML-ish', () {
      final out = DialectExporter.render(skill, Dialect.continue_);
      expect(out, contains('name: terminal-sos'));
      expect(out, contains('description: Ayuda con terminales'));
      expect(out, contains('## Instrucciones'));
    });

    test('codex → AGENTS.md frontmatter', () {
      final out = DialectExporter.render(skill, Dialect.codex);
      expect(out, startsWith('---\nname: terminal-sos\n'));
      expect(out, contains('description:'));
      expect(out, contains('## Instrucciones'));
    });

    test('dialects() devuelve los 5 con nombres', () {
      final dialects = DialectExporter.dialects();
      expect(dialects.length, 5);
      expect(dialects.map((d) => d.dialect), containsAll(Dialect.values));
      expect(dialects.firstWhere((d) => d.dialect == Dialect.opencode).label,
          'opencode');
    });
  });
}
