import '../models/skill.dart';

class SkillLabResult {
  final Skill skill;
  final double score;
  final double confidence;
  final List<String> reasons;

  const SkillLabResult({
    required this.skill,
    required this.score,
    required this.confidence,
    required this.reasons,
  });
}

/// Laboratorio headless de skills: dado un input (prompt/comando), evalúa
/// cada skill y devuelve un ranking con confianza y razones.
class SkillLab {
  static List<SkillLabResult> evaluate(String input, List<Skill> skills) {
    final results = skills.map((s) => _score(input, s)).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  static SkillLabResult _score(String input, Skill skill) {
    final lower = input.toLowerCase();
    final matched = <String>[];
    var score = 0.0;

    for (final trigger in skill.triggers) {
      final t = trigger.toLowerCase();
      final wordMatch =
          RegExp('\\b${RegExp.escape(t)}\\b', caseSensitive: false)
              .hasMatch(lower);
      if (wordMatch || lower.contains(t)) {
        matched.add(trigger);
        score += wordMatch ? 2 : 1;
      }
    }

    final confidence = skill.triggers.isEmpty
        ? 0.0
        : (score / skill.triggers.length).clamp(0.0, 1.0);
    return SkillLabResult(
      skill: skill,
      score: score,
      confidence: confidence,
      reasons: matched,
    );
  }
}
