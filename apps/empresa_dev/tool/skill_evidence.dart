import 'dart:io';

import 'package:empresa_dev/models/skill.dart';
import 'package:empresa_dev/services/dialect_exporter.dart';
import 'package:empresa_dev/services/skill_lab.dart';

/// Dogfood Etapa 4b: crea 3 skills del repo con el modelo `Skill`,
/// las evalúa en el laboratorio y escribe la evidencia del gate.
/// Uso: dart run tool/skill_evidence.dart
void main() {
  final repoSkillsDir = Directory('../../.opencode/skills');
  final evidenceFile = File('data/evidence/etapa4b-skills.md');
  final evidence = StringBuffer();

  evidence.writeln('# Evidencia Etapa 4b — Gestor visual de skills + laboratorio');
  evidence.writeln();
  evidence.writeln('> Generado por `dart run tool/skill_evidence.dart` '
      '(dogfood headless con el modelo `Skill` + `SkillLab`).');
  evidence.writeln();

  final skills = <Skill>[
    const Skill(
      name: 'dev-4b',
      description: 'Resumen de estado de la Etapa 4b y cómo continuarla',
      triggers: ['4b', 'etapa 4b', 'skills'],
      body: '# Skill dev-4b\n\n'
          '## Instrucciones\n\n'
          'Resumir el SDD-113, los slices completos, el CI y el gate '
          'pendiente de la Etapa 4b.\n',
    ),
    const Skill(
      name: 'terminal-sos',
      description: 'Ayuda rápida con problemas de terminal SSH/SFTP',
      triggers: ['terminal', 'ssh', 'sftp'],
      body: '# Skill terminal-sos\n\n'
          '## Instrucciones\n\n'
          'Diagnosticar conectividad y errores comunes de dartssh2.\n',
    ),
    const Skill(
      name: 'commit-es',
      description: 'Redacta commits cortos en español con contexto',
      triggers: ['commit', 'mensaje de commit'],
      body: '# Skill commit-es\n\n'
          '## Restricciones\n\n'
          '- Prefijos: feat:, fix:, docs:, chore:.\n'
          '- Máximo 72 caracteres.\n',
    ),
  ];

  var allPass = true;
  for (final skill in skills) {
    final trigger = skill.triggers.first;
    final results = SkillLab.evaluate(trigger, [skill]);
    final r = results.first;
    final passed = r.score > 0 && r.confidence > 0;
    allPass = allPass && passed;

    evidence.writeln('## ${skill.name}');
    evidence.writeln();
    evidence.writeln('- Trigger de prueba: `$trigger`');
    evidence.writeln('- Score: ${r.score} — Confidence: ${r.confidence.toStringAsFixed(2)}');
    evidence.writeln('- Por qué: ${r.reasons.join(', ')}');
    evidence.writeln('- Resultado: ${passed ? 'APROBADA' : 'FALLÓ'}');
    evidence.writeln();

    final dir = Directory('${repoSkillsDir.path}/${skill.name}');
    dir.createSync(recursive: true);
    File('${dir.path}/SKILL.md').writeAsStringSync(skill.toMarkdown());
    stdout.writeln('${passed ? 'OK ' : 'FAIL'} ${skill.name} '
        '(score ${r.score}, confidence ${r.confidence.toStringAsFixed(2)})');

    final opencode = DialectExporter.render(skill, Dialect.opencode);
    evidence.writeln('### Export opencode → `.opencode/skills/${skill.name}/SKILL.md`');
    evidence.writeln();
    evidence.writeln('```markdown\n$opencode```');
    evidence.writeln();
  }

  final commites = skills[2];
  evidence.writeln('## Exports multi-dialecto (${commites.name})');
  evidence.writeln();
  for (final d in DialectExporter.dialects()) {
    final out = DialectExporter.render(commites, d.dialect);
    evidence.writeln('### ${d.label} (${d.extension})');
    evidence.writeln();
    evidence.writeln('```\n$out```');
    evidence.writeln();
  }

  evidence.writeln('## Resultado global');
  evidence.writeln();
  evidence.writeln(allPass ? '- **3/3 skills aprobadas en el laboratorio.**'
      : '- **FALLÓ**: revisar antes de cerrar el gate.');
  evidence.writeln();

  evidenceFile.parent.createSync(recursive: true);
  evidenceFile.writeAsStringSync(evidence.toString());

  stdout.writeln('Evidencia escrita en ${evidenceFile.path}');
  exit(allPass ? 0 : 1);
}