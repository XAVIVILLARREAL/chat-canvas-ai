import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/skill.dart';
import '../theme/app_theme.dart';

const skillBlocks = ['Instrucciones', 'Ejemplos', 'Restricciones', 'Anti-patrones'];

/// Constructor visual de skills: form (name, description, triggers, tags,
/// permisos), bloques de cuerpo arrastrables y preview markdown en vivo.
class SkillBuilderScreen extends StatefulWidget {
  final Skill? initial;
  final ValueChanged<Skill> onSave;

  const SkillBuilderScreen({super.key, this.initial, required this.onSave});

  @override
  State<SkillBuilderScreen> createState() => _SkillBuilderScreenState();
}

class _SkillBuilderScreenState extends State<SkillBuilderScreen> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _trigger;
  late final TextEditingController _body;
  final _triggers = <String>[];
  final _addedBlocks = <String>[];

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _name = TextEditingController(text: s?.name ?? '');
    _description = TextEditingController(text: s?.description ?? '');
    _trigger = TextEditingController();
    _body = TextEditingController(text: s?.body ?? '');
    if (s != null) _triggers.addAll(s.triggers);
    _addedBlocks.addAll(_addedBlocksFromBody(_body.text));
  }

  List<String> _addedBlocksFromBody(String body) => skillBlocks
      .where((b) => body.split('\n').contains('## $b'))
      .toList();

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _trigger.dispose();
    _body.dispose();
    super.dispose();
  }

  void _addTrigger() {
    final t = _trigger.text.trim();
    if (t.isEmpty || _triggers.contains(t)) return;
    setState(() => _triggers.add(t));
    _trigger.clear();
  }

  void _toggleBlock(String block) {
    setState(() {
      if (_addedBlocks.contains(block)) {
        _addedBlocks.remove(block);
      } else {
        _addedBlocks.add(block);
      }
      final lines = _body.text
          .split('\n')
          .where((l) => l.trim() != '## $block')
          .join('\n');
      _body.text = lines.trimRight();
    });
    _rebuildBody();
  }

  void _rebuildBody() {
    final sections = [
      for (final b in _addedBlocks) '## $b\n\n',
    ].join('\n');
    _body.text = sections.trim();
  }

  void _save() {
    final skill = Skill(
      name: _name.text.trim(),
      description: _description.text.trim(),
      triggers: List.of(_triggers),
      body: _body.text,
    );
    widget.onSave(skill);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Skill "${skill.name}" guardada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Constructor de skills'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Guardar skill'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('skill-name'),
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'mi-skill',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('skill-description'),
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Descripción (qué hace)',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('skill-trigger'),
                  controller: _trigger,
                  onSubmitted: (_) => _addTrigger(),
                  decoration: const InputDecoration(
                    labelText: 'Trigger',
                    hintText: 'palabra que activa',
                  ),
                ),
              ),
              IconButton(
                key: const Key('add-trigger'),
                icon: const Icon(Icons.add),
                tooltip: 'Añadir trigger',
                onPressed: _addTrigger,
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final t in _triggers)
                InputChip(
                  label: Text(t),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => _triggers.remove(t)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Bloques del cuerpo (arrastra para ordenar)'),
          const SizedBox(height: 8),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldI, newI) {
              setState(() {
                if (newI > oldI) newI--;
                final b = _addedBlocks.removeAt(oldI);
                _addedBlocks.insert(newI, b);
              });
              _rebuildBody();
            },
            children: [
              for (final b in skillBlocks)
                ListTile(
                  key: ValueKey(b),
                  dense: true,
                  onTap: () => _toggleBlock(b),
                  leading: const Icon(Icons.drag_handle),
                  trailing: IconButton(
                    icon: Icon(_addedBlocks.contains(b)
                        ? Icons.check_box
                        : Icons.check_box_outline_blank),
                    onPressed: () => _toggleBlock(b),
                  ),
                  title: Text(b),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Cuerpo markdown'),
          const SizedBox(height: 8),
          TextField(
            key: const Key('skill-body'),
            controller: _body,
            maxLines: null,
            minLines: 6,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: '# Título\n\nContenido…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgPanel,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(12),
            child: MarkdownBody(data: _body.text),
          ),
        ],
      ),
    );
  }
}