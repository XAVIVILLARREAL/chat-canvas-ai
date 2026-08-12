import 'package:flutter/material.dart';
import '../models/skill.dart';
import '../services/skill_lab.dart';
import '../services/dialect_exporter.dart';
import '../theme/app_theme.dart';
import '../widgets/neon_dialog.dart';

/// Laboratorio sandbox: input → ranking en vivo de skills con confianza,
/// por qué, y exportación del resultado al dialecto elegido.
class SkillLabScreen extends StatefulWidget {
  final List<Skill> skills;
  final VoidCallback? onNewSkill;

  const SkillLabScreen({super.key, required this.skills, this.onNewSkill});

  @override
  State<SkillLabScreen> createState() => _SkillLabScreenState();
}

class _SkillLabScreenState extends State<SkillLabScreen> {
  final _input = TextEditingController();
  Dialect _dialect = Dialect.opencode;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  List<SkillLabResult> get _results =>
      SkillLab.evaluate(_input.text, widget.skills);

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final matches = results.where((r) => r.score > 0).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: const Text('Laboratorio de skills'),
        actions: [
          if (widget.onNewSkill != null)
            IconButton(
              key: const Key('new-skill'),
              icon: const Icon(Icons.add),
              tooltip: 'Nueva skill',
              onPressed: widget.onNewSkill,
            ),
          DropdownButton<Dialect>(
            value: _dialect,
            dropdownColor: AppColors.bgElevated,
            style: const TextStyle(color: Colors.white),
            iconEnabledColor: AppColors.neonCyan,
            items: [
              for (final d in DialectExporter.dialects())
                DropdownMenuItem(
                  value: d.dialect,
                  child: Text(d.label),
                ),
            ],
            onChanged: (d) => setState(() => _dialect = d ?? _dialect),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: const Key('lab-input'),
              controller: _input,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Prompt / comando',
                hintText: 'Escribe algo y mira qué skills se activarían…',
              ),
            ),
          ),
          Expanded(
            child: matches.isEmpty
                ? const Center(
                    child: Text('sin coincidencias: ninguna skill se activa'),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    children: [
                      for (final r in matches)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Material(
                            color: AppColors.bgPanel,
                            borderRadius:
                                BorderRadius.circular(AppRadii.input),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppRadii.input)),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.neonCyan
                                    .withValues(alpha: r.confidence * 0.7),
                                child: Text(
                                  (r.confidence * 100).round().toString(),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                              ),
                              title: Text(r.skill.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                r.reasons.join(', '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.ios_share),
                                tooltip: 'Exportar',
                                onPressed: () => _export(context, r.skill),
                              ),
                            ),
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Export: genera el SKILL.md del dialecto seleccionado.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.white38),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _export(BuildContext context, Skill skill) {
    final text = DialectExporter.render(skill, _dialect);
    final label = DialectExporter.dialects()
        .firstWhere((d) => d.dialect == _dialect)
        .label;
    showNeonDialog<void>(
      context: context,
      glow: AppColors.neonCyan,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Export $label · ${skill.name}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 320),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgPanel,
              borderRadius: BorderRadius.circular(AppRadii.input),
              border: Border.all(color: AppColors.border),
            ),
            child: SingleChildScrollView(
              child: SelectableText(text,
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 12, height: 1.4)),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ),
        ],
      ),
    );
  }
}