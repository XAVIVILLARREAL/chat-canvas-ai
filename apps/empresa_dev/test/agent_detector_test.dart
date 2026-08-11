import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agent_core/agent_detector.dart';
import 'package:empresa_dev/widgets/agent_state_badge.dart';

AgentRule rule(String name, AgentState state, {List<String> contains = const [], List<String> regex = const [], List<String> lineRegex = const [], int priority = 0}) =>
    AgentRule(name: name, state: state, contains: contains, regex: regex, lineRegex: lineRegex, priority: priority);

void main() {
  group('AgentDetector', () {
    final workingRule = rule('opencode-working', AgentState.working,
        contains: ['esc to interrupt'], priority: 10);
    final blockedRule = rule('opencode-blocked', AgentState.blocked,
        contains: ['password:', 'waiting for user input'], priority: 20);

    late AgentDetector detector;
    setUp(() {
      detector = AgentDetector(rules: [workingRule, blockedRule]);
    });

    test('manifiesto empaquetado: "esc to interrupt" clasifica working', () {
      final d = AgentDetector().detect('> esc to interrupt to cancel\n> _');
      expect(d.state, AgentState.working);
      expect(d.matchedRule, 'interrupt_hint_working');
    });

    test('salida con "esc to interrupt" clasifica working', () {
      final d = detector.detect('  esc to interrupt  \n> _');
      expect(d.state, AgentState.working);
      expect(d.matchedRule, 'opencode-working');
    });

    test('salida con password: clasifica blocked', () {
      final d = detector.detect('host@server password: ');
      expect(d.state, AgentState.blocked);
    });

    test('salida sin match clasifica idle', () {
      final d = detector.detect('Welcome to Ubuntu');
      expect(d.state, AgentState.idle);
      expect(d.matchedRule, isNull);
    });

    test('la prioridad mayor gana cuando coinciden varias reglas', () {
      final d = detector.detect('password: esc to interrupt');
      expect(d.state, AgentState.blocked); // blocked tiene prioridad 20 > 10
    });

    test('lineRegex con prefijo (?i) se sanea a caseSensitive:false', () {
      final r = rule('open-interrupt', AgentState.working,
          lineRegex: [r'(?i).*opencode.*esc (again to )?interrupt'], priority: 40);
      final d = AgentDetector(rules: [r])
          .detect('OPENCODE esc again to interrupt');
      expect(d.state, AgentState.working);
    });

    test('lineRegex matchea solo en línea completa con ancla', () {
      final lineRule = rule('prompt-line', AgentState.idle,
          lineRegex: [r'^> _'], priority: 30);
      final d = AgentDetector(rules: [lineRule]).detect('texto\n> _\nfin');
      expect(d.state, AgentState.idle);
      expect(d.matchedRule, 'prompt-line');

      final d2 = AgentDetector(rules: [lineRule]).detect('foo > _ bar');
      expect(d2.state, AgentState.idle); // sin match → idle
      expect(d2.matchedRule, isNull);
    });
  });

  group('RuleTomlParser', () {
    test('parsea un manifiesto TOML fixture', () {
      const toml = '''
[rule.opencode]
state = "working"
priority = 10
contains = ["esc to interrupt", "esc to cancel"]

[rule.opencode-blocked]
state = "blocked"
priority = 20
contains = ["password:", "waiting for user input"]
''';
      final rules = RuleTomlParser.parse(toml);
      expect(rules.length, 2);
      expect(rules.first.name, 'opencode');
      expect(rules.first.state, AgentState.working);
      expect(rules.first.contains, ['esc to interrupt', 'esc to cancel']);
      expect(rules.last.priority, 20);
    });
  });

  group('AgentStateBadge', () {
    testWidgets('pinta icono y texto por estado', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AgentStateBadge(state: AgentState.working)),
      ));
      expect(find.text('working'), findsOneWidget);
      expect(find.byIcon(Icons.bolt), findsOneWidget);
    });
  });
}