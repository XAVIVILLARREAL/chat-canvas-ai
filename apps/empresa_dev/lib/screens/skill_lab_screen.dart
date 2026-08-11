import 'package:flutter/material.dart';
import '../models/skill.dart';
import '../services/skill_lab.dart';
import '../services/dialect_exporter.dart';

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
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: matches.isEmpty
                ? const Center(
                    child: Text('sin coincidencias: ninguna skill se activa'),
                  )
                : ListView(
                    children: [
                      for (final r in matches)
                        ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                Colors.blue.withValues(alpha: r.confidence),
                            child: Text(
                              (r.confidence * 100).round().toString(),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          title: Text(r.skill.name),
                          subtitle: Text(
                            r.reasons.join(', '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.ios_share),
                            tooltip: 'Exportar',
                            onPressed: () => _export(context, r.skill),
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Export: genera el SKILL.md del dialecto seleccionado.',
                          style: TextStyle(fontSize: 12),
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
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Export ${skill.name} (${DialectExporter.dialects().firstWhere((d) => d.dialect == _dialect).label})'),
        content: SingleChildScrollView(
          child: SelectableText(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}