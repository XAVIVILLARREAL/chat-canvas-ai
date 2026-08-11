import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/models/skill.dart';
import 'package:empresa_dev/services/skill_lab.dart';

Skill skill(String name, List<String> triggers) => Skill(
      name: name,
      description: 'Desc de $name',
      triggers: triggers,
    );

void main() {
  group('SkillLab.evaluate', () {
    final skills = [
      skill('dev', ['dev', 'plan', 'siguiente fase', 'implementar']),
      skill('terminal', ['terminal', 'ssh']),
      skill('sin-triggers', []),
    ];

    test('trigger exacto en input → score alto y confidence > 0.5', () {
      final results = SkillLab.evaluate('implementar la siguiente fase', skills);
      final dev = results.firstWhere((r) => r.skill.name == 'dev');
      expect(dev.score, greaterThan(0));
      expect(dev.confidence, greaterThan(0.5));
      expect(dev.reasons, isNotEmpty);
    });

    test('sin matches → score 0 y sin razones', () {
      final results = SkillLab.evaluate('cocinar pasta', skills);
      final terminal = results.firstWhere((r) => r.skill.name == 'terminal');
      expect(terminal.score, 0);
      expect(terminal.confidence, 0);
      expect(terminal.reasons, isEmpty);
    });

    test('ranking ordenado por score descendente', () {
      final results = SkillLab.evaluate('implementar plan con dev', skills);
      final scores = results.map((r) => r.score).toList();
      for (var i = 0; i < scores.length - 1; i++) {
        expect(scores[i] >= scores[i + 1], isTrue, reason: 'orden desc');
      }
    });

    test('triggers múltiples suman (más matches → más score)', () {
      final one = SkillLab.evaluate('plan', [skills[0]]).first.score;
      final two = SkillLab.evaluate('plan dev', [skills[0]]).first.score;
      expect(two, greaterThan(one));
    });

    test('case-insensitive', () {
      final results = SkillLab.evaluate('TERMINAL', [skills[1]]);
      expect(results.first.reasons, ['terminal']);
      expect(results.first.score, greaterThan(0));
    });

    test('confianza por matches/triggers del skill', () {
      final few = SkillLab.evaluate('dev', [skills[0]]).first;
      final exact = SkillLab.evaluate('dev', [skill('s', ['dev'])]).first;
      expect(exact.confidence, greaterThan(few.confidence));
    });
  });
}
