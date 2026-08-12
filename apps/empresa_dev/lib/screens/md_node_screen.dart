import 'package:flutter/material.dart';
import 'package:canva_core/canva.dart';
import '../services/md_link_parser.dart';
import '../theme/app_theme.dart';
import '../widgets/md_node_editor.dart';

/// Pantalla de edición de un nodo `.md`: editor + preview live,
/// backlinks, y navegación por `[[links]]` (abrir o crear).
class MdNodeScreen extends StatefulWidget {
  final CanvaNode node;
  final List<CanvaNode> allNodes;
  final void Function(CanvaNode updated) onSave;
  final void Function(String title) onCreateLink;

  const MdNodeScreen({
    super.key,
    required this.node,
    required this.allNodes,
    required this.onSave,
    required this.onCreateLink,
  });

  @override
  State<MdNodeScreen> createState() => _MdNodeScreenState();
}

class _MdNodeScreenState extends State<MdNodeScreen> {
  late CanvaNode _node;
  Set<String> _known = {};

  @override
  void initState() {
    super.initState();
    _node = widget.node;
    _known = widget.allNodes.map((n) => n.label).toSet();
  }

  Future<void> _openOrCreate(String target) async {
    final existing =
        widget.allNodes.where((n) => n.label == target).firstOrNull;
    if (existing == null) {
      widget.onCreateLink(target);
      return;
    }
    if (!mounted) return;
    setState(() {
      _node = existing;
      _known = widget.allNodes.map((n) => n.label).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final backlinks = BacklinkIndex.build({
      for (final n in widget.allNodes) n.label: n.content ?? '',
    })[_node.label]!;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.sticky_note_2, color: AppColors.neonAmber, size: 18),
            const SizedBox(width: 8),
            Text(_node.label, style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined, color: Colors.white70, size: 20),
            tooltip: 'Guardar',
            onPressed: () => widget.onSave(_node),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: MdNodeEditor(
                initialBody: _node.content ?? '',
                knownNodes: _known,
                onChanged: (body) {
                  _node.content = body;
                },
                onOpenLink: _openOrCreate,
                onCreateLink: _openOrCreate,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bgPanel,
                borderRadius: BorderRadius.circular(AppRadii.input),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: Colors.white38, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: backlinks.isEmpty
                        ? const Text('Sin backlinks',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 12))
                        : Text(
                            'Backlinks: ${backlinks.join(', ')}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
