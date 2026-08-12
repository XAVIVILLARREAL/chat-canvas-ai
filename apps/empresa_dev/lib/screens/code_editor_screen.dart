import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/project_service.dart';
import '../theme/app_theme.dart';

enum _SaveState { saved, modified, saving, error }

class CodeEditorScreen extends StatefulWidget {
  final ProjectService service;
  final String path;
  final String initialContent;

  const CodeEditorScreen({
    super.key,
    required this.service,
    required this.path,
    required this.initialContent,
  });

  @override
  State<CodeEditorScreen> createState() => _CodeEditorScreenState();
}

class _CodeEditorScreenState extends State<CodeEditorScreen> {
  late final TextEditingController _controller;
  _SaveState _state = _SaveState.saved;
  String _fileName = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
    _fileName = widget.path.split(RegExp(r'[/\\]')).last;
    _controller.addListener(() {
      if (_state != _SaveState.modified) {
        setState(() => _state = _SaveState.modified);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _state = _SaveState.saving);
    try {
      await widget.service.write(widget.path, _controller.text);
      if (mounted) setState(() => _state = _SaveState.saved);
    } catch (_) {
      if (mounted) setState(() => _state = _SaveState.error);
    }
  }

  Future<void> _onKey(KeyEvent event) async {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyS &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      await _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateLabel = switch (_state) {
      _SaveState.saved => 'Guardado',
      _SaveState.modified => 'Modificado',
      _SaveState.saving => 'Guardando…',
      _SaveState.error => 'Error al guardar',
    };
    final stateColor = switch (_state) {
      _SaveState.saved => Colors.white38,
      _SaveState.modified => Colors.amber,
      _SaveState.saving => Colors.white70,
      _SaveState.error => Colors.redAccent,
    };
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: AppColors.bgDeep,
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.code, color: AppColors.neonCyan, size: 18),
              const SizedBox(width: 8),
              Text(_fileName, style: const TextStyle(fontSize: 15)),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(child: Text(stateLabel, style: TextStyle(color: stateColor, fontSize: 12))),
            ),
            IconButton(
              icon: const Icon(Icons.save_outlined, color: Colors.lightBlueAccent),
              tooltip: 'Guardar (Ctrl+S)',
              onPressed: _state == _SaveState.saving ? null : _save,
            ),
          ],
        ),
        body: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgPanel,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'monospace',
              height: 1.4,
            ),
            decoration: const InputDecoration(
              hintText: 'Archivo vacío',
              hintStyle: TextStyle(color: Colors.white24),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ),
    );
  }
}
