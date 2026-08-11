import '../models/skill.dart';

enum Dialect { opencode, cursor, claude, continue_, codex }

class DialectInfo {
  final Dialect dialect;
  final String label;
  final String extension;

  const DialectInfo(this.dialect, this.label, this.extension);
}

/// Exporta una skill a los dialectos de los agentes principales.
class DialectExporter {
  static List<DialectInfo> dialects() => const [
        DialectInfo(Dialect.opencode, 'opencode', '.md'),
        DialectInfo(Dialect.cursor, 'Cursor', '.mdc'),
        DialectInfo(Dialect.claude, 'Claude Code', '.md'),
        DialectInfo(Dialect.continue_, 'Continue', '.yaml'),
        DialectInfo(Dialect.codex, 'Codex', '.md'),
      ];

  static String render(Skill skill, Dialect dialect) {
    final desc = skill.triggers.isEmpty
        ? skill.description
        : '${skill.description}. Trigger: '
            '${skill.triggers.map((t) => '"$t"').join(', ')}';
    final body = skill.body.trim().isEmpty ? '# ${skill.name}\n' : skill.body;

    switch (dialect) {
      case Dialect.opencode:
        return '---\nname: ${skill.name}\ndescription: $desc\n---\n\n$body\n';
      case Dialect.cursor:
        return '---\ndescription: $desc\nglobs: **/*\n---\n\n$body\n';
      case Dialect.claude:
        final tools = skill.permissions.isEmpty
            ? ''
            : 'allowed-tools: ${skill.permissions.join(', ')}\n';
        return '---\nname: ${skill.name}\ndescription: $desc\n$tools---\n\n$body\n';
      case Dialect.continue_:
        return 'rules:\n  - name: ${skill.name}\n'
            '    description: ${skill.description}\n'
            '    match: ${skill.triggers.join(', ')}\n\n$body\n';
      case Dialect.codex:
        return '---\nname: ${skill.name}\ndescription: $desc\n---\n\n$body\n';
    }
  }
}
