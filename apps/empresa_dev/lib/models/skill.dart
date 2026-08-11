/// Modelo puro de una skill de agente (formato markdown + frontmatter
/// estilo opencode, compatible con `.opencode/skills/<name>/SKILL.md`).
class Skill {
  final String name;
  final String description;
  final List<String> triggers;
  final List<String> tags;
  final List<String> permissions;
  final String body;

  const Skill({
    required this.name,
    required this.description,
    this.triggers = const [],
    this.tags = const [],
    this.permissions = const [],
    this.body = '',
  });

  /// Serializa a markdown opencode: frontmatter con name + description
  /// (triggers inline, estilo `Trigger: "a", "b"`).
  String toMarkdown() {
    final desc = triggers.isEmpty
        ? description
        : '$description. Trigger: ${triggers.map((t) => '"$t"').join(', ')}';
    final fm = StringBuffer('---\nname: $name\ndescription: $desc\n');
    if (tags.isNotEmpty) fm.write('tags: [${tags.join(', ')}]\n');
    if (permissions.isNotEmpty) fm.write('permissions: [${permissions.join(', ')}]\n');
    fm.write('---\n\n');
    final bodyMd = body.trim();
    return '$fm${bodyMd.isEmpty ? '# $name\n' : bodyMd}\n';
  }

  /// Parsea markdown con frontmatter opencode. null si no hay frontmatter
  /// válido con `name`.
  static Skill? fromMarkdown(String text) {
    final fm = _parseFrontmatter(text);
    if (fm == null || fm['name'] == null) return null;
    final rawDescription = fm['description'] ?? '';
    final description = rawDescription.replaceAll(RegExp(r'\s*\.?\s*Trigger:.*$'), '');
    final bodyStart = text.indexOf('---', 4);
    final body = bodyStart == -1 ? '' : text.substring(bodyStart + 3).trim();

    return Skill(
      name: fm['name']!,
      description: description,
      triggers: _extractTriggers(rawDescription),
      tags: fm['tags'] ?? const [],
      permissions: fm['permissions'] ?? const [],
      body: body,
    );
  }

  /// Secciones `## Título` del body.
  List<String> bodySections() {
    final titles = <String>[];
    for (final m in RegExp(r'^## (.+)$', multiLine: true).allMatches(body)) {
      titles.add(m.group(1)!.trim());
    }
    return titles;
  }

  /// Contenido de una sección `## Título` (hasta la siguiente `##`).
  String section(String title) {
    final re = RegExp(r'^## ' + RegExp.escape(title) + r'\s*\n(.*?)(?=^## |\Z)',
        dotAll: true, multiLine: true);
    final m = re.firstMatch(body);
    return m == null ? '' : m.group(1)!.trim();
  }

  static List<String> _extractTriggers(String description) {
    final m = RegExp(r'Trigger\s*(?:keywords?)?\s*:\s*(.*)$')
        .firstMatch(description);
    if (m == null) return [];
    return m
        .group(1)!
        .split(',')
        .map((t) => t
            .trim()
            .replaceAll('"', '')
            .replaceAll("'", '')
            .replaceAll(RegExp(r'\.$'), ''))
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Mini-parser YAML de frontmatter: `key: valor` escalar o lista inline.
  static Map<String, dynamic>? _parseFrontmatter(String text) {
    if (!text.startsWith('---\n')) return null;
    final end = text.indexOf('\n---', 4);
    if (end == -1) return null;
    final raw = text.substring(4, end);
    final map = <String, dynamic>{};
    for (final line in raw.split('\n')) {
      final eq = line.indexOf(':');
      if (eq == -1) continue;
      final key = line.substring(0, eq).trim();
      final value = line.substring(eq + 1).trim();
      if (value.startsWith('[') && value.endsWith(']')) {
        map[key] = value
            .substring(1, value.length - 1)
            .split(',')
            .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ''))
            .where((e) => e.isNotEmpty)
            .toList();
      } else {
        map[key] = value.replaceAll('"', '').replaceAll("'", '');
      }
    }
    return map;
  }
}
