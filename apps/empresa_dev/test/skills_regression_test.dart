@Tags(['skills'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/models/skill.dart';
import 'package:empresa_dev/services/skill_lab.dart';

/// Regression del laboratorio contra las skills reales del repo
/// (`.opencode/skills/*/SKILL.md` del monorepo): cada skill debe activarse
/// con su trigger de prueba. Tag `skills` para CI headless.
void main() {
  final skillsDir = _findSkillsDir();
  final skillFiles = skillsDir == null
      ? <File>[]
      : skillsDir
          .listSync()
          .whereType<Directory>()
          .map((d) => File('${d.path}/SKILL.md'))
          .where((f) => f.existsSync())
          .toList();

  for (final f in skillFiles) {
    final skill = Skill.fromMarkdown(f.readAsStringSync());
    if (skill == null) continue;

    test('lab: skill "${skill.name}" se activa con su trigger de prueba',
        () {
      final first = skill.triggers.isEmpty ? null : skill.triggers.first;
      expect(first, isNotNull, reason: 'skill ${skill.name} sin triggers');
      final results =
          SkillLab.evaluate(first!, [skill]).where((r) => r.score > 0).toList();
      expect(results, isNotEmpty,
          reason: 'trigger "$first" no activó la skill ${skill.name}');
      expect(results.first.skill.name, skill.name);
      expect(results.first.confidence, greaterThan(0));
    });
  }

  test('lab: el repo tiene al menos 3 skills (dogfood duro)', () {
    expect(skillFiles.length, greaterThanOrEqualTo(3),
        reason: 'CI de dogfood: se requieren 3 skills (2 actuales)');
  });
}

Directory? _findSkillsDir() {
  final candidates = [
    '../../.opencode/skills',
    '.opencode/skills',
    '../.opencode/skills',
  ];
  for (final cand in candidates) {
    final d = Directory(cand);
    if (d.existsSync()) return d;
  }
  return null;
}