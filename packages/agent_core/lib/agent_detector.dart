import 'agent_detector_manifests.dart';

enum AgentState { idle, working, blocked, unknown }

class AgentDetection {
  final AgentState state;
  final String? matchedRule;

  const AgentDetection(this.state, this.matchedRule);
}class AgentRule {
  final String name;
  final AgentState state;
  final List<String> contains;
  final List<String> regex;
  final List<String> lineRegex;
  final int priority;

  const AgentRule({
    required this.name,
    required this.state,
    this.contains = const [],
    this.regex = const [],
    this.lineRegex = const [],
    this.priority = 0,
  });

  bool matches(String output) {
    if (contains.any(output.contains)) return true;
    if (regex.any((r) => _compile(r).hasMatch(output))) return true;
    final lines = output.split('\n');
    return lineRegex.any((r) => lines.any((l) => _compile(r).hasMatch(l)));
  }

  /// Sanea regex estilo JS: el prefijo `(?i)` (Dart no lo soporta) →
  /// flag caseSensitive:false.
  static RegExp _compile(String pattern) {
    if (pattern.startsWith('(?i)')) {
      return RegExp(pattern.substring(4), caseSensitive: false);
    }
    return RegExp(pattern);
  }
}

/// Clasifica el estado de un agente según su salida, estilo herdr
/// (reglas con prioridad, matchers contains/regex/line_regex).
/// Fuente de conceptos: herdr (Apache-2.0) — código propio.
class AgentDetector {
  final List<AgentRule> rules;

  AgentDetector({List<AgentRule>? rules}) : rules = rules ?? defaultRules();

  AgentDetection detect(String output) {
    final sorted = [...rules]..sort((a, b) => b.priority.compareTo(a.priority));
    for (final rule in sorted) {
      if (rule.matches(output)) {
        return AgentDetection(rule.state, rule.name);
      }
    }
    return const AgentDetection(AgentState.idle, null);
  }

  static List<AgentRule> defaultRules() =>
      RuleTomlParser.parse(opencodeManifestToml);
}

/// Parser mínimo de los manifiestos de herdr (subset plano):
/// bloques `[rule.<id>]` o `[[rules]]` con state/priority/contains/regex/line_regex.
class RuleTomlParser {
  static List<AgentRule> parse(String toml) {
    final rules = <AgentRule>[];
    final lines = toml.split('\n');
    final blocks = <(String?, List<String>)>[];
    String? currentHeader;
    final currentBody = <String>[];
    void flush() {
      if (currentBody.isNotEmpty || currentHeader != null) {
        blocks.add((currentHeader, [...currentBody]));
        currentBody.clear();
      }
    }

    for (final line in lines) {
      final trimmed = line.trim();
      final header = RegExp(r'^\[rule\.([^\]]+)\]$').firstMatch(trimmed);
      if (header != null) {
        flush();
        currentHeader = header.group(1);
        continue;
      }
      if (trimmed == '[[rules]]') {
        flush();
        currentHeader = null;
        continue;
      }
      currentBody.add(line);
    }
    flush();

    for (final (header, body) in blocks) {
      final rule = _parseRule(body.join('\n'));
      rules.add(header != null && rule.name == 'rule'
          ? AgentRule(
              name: header,
              state: rule.state,
              contains: rule.contains,
              regex: rule.regex,
              lineRegex: rule.lineRegex,
              priority: rule.priority,
            )
          : rule);
    }
    return rules;
  }

  static AgentRule _parseRule(String block) {
    String? id;
    AgentState state = AgentState.unknown;
    int priority = 0;
    final contains = <String>[];
    final regex = <String>[];
    final lineRegex = <String>[];

    for (final rawLine in block.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final eq = line.indexOf('=');
      if (eq == -1) continue;
      final key = line.substring(0, eq).trim();
      final value = line.substring(eq + 1).trim();
      switch (key) {
        case 'id':
          id = value.replaceAll('"', '');
        case 'state':
          state = AgentState.values.firstWhere(
            (s) => s.name == value.replaceAll('"', ''),
            orElse: () => AgentState.unknown,
          );
        case 'priority':
          priority = int.tryParse(value) ?? 0;
        case 'contains' || 'regex' || 'line_regex':
          final list = _parseStringList(value);
          if (key == 'contains') contains.addAll(list);
          if (key == 'regex') regex.addAll(list);
          if (key == 'line_regex') lineRegex.addAll(list);
      }
    }

    return AgentRule(
      name: id ?? 'rule',
      state: state,
      contains: contains,
      regex: regex,
      lineRegex: lineRegex,
      priority: priority,
    );
  }

  static List<String> _parseStringList(String value) {
    final matches = RegExp(r'"([^"]*)"|' "'([^']*)'").allMatches(value);
    return matches.map((m) => m.group(1) ?? m.group(2) ?? '').toList();
  }
}
