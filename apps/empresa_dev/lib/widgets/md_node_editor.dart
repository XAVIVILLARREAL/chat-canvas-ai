import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/md_link_parser.dart';
import '../theme/app_theme.dart';

/// Editor de nodo `.md` con preview Markdown en vivo.
/// Los `[[links]]` del preview son clickables: [onOpenLink] si el destino
/// existe, [onCreateLink] si no (para crear la nota enlazada).
class MdNodeEditor extends StatefulWidget {
  final String initialBody;
  final Set<String> knownNodes;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onOpenLink;
  final ValueChanged<String> onCreateLink;

  const MdNodeEditor({
    super.key,
    required this.initialBody,
    required this.knownNodes,
    required this.onChanged,
    required this.onOpenLink,
    required this.onCreateLink,
  });

  @override
  State<MdNodeEditor> createState() => _MdNodeEditorState();
}

class _MdNodeEditorState extends State<MdNodeEditor> {
  late final TextEditingController _body;

  @override
  void initState() {
    super.initState();
    _body = TextEditingController(text: widget.initialBody);
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  void _onTapLink(String text, String? href, String title) {
    if (href == null || !href.startsWith('md://')) return;
    final target = Uri.decodeComponent(href.substring(5));
    if (widget.knownNodes.contains(target)) {
      widget.onOpenLink(target);
    } else {
      widget.onCreateLink(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 4,
          child: TextField(
            controller: _body,
            maxLines: null,
            expands: true,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
            decoration: const InputDecoration(
              hintText: 'Escribe Markdown… [[enlaces]] incluidos',
              hintStyle: TextStyle(color: Colors.white24),
            ),
            onChanged: (v) {
              setState(() {});
              widget.onChanged(v);
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgPanel,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(12),
            child: MarkdownBody(
              data: wikiToMarkdown(_body.text),
              selectable: true,
              onTapLink: _onTapLink,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
            ),
          ),
        ),
      ],
    );
  }
}
