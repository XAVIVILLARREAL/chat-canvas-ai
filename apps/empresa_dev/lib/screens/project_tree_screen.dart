import 'package:flutter/material.dart';
import '../services/project_service.dart';
import 'code_editor_screen.dart';

class ProjectTreeScreen extends StatefulWidget {
  final ProjectService service;
  final String title;

  const ProjectTreeScreen({super.key, required this.service, required this.title});

  @override
  State<ProjectTreeScreen> createState() => _ProjectTreeScreenState();
}

class _ProjectTreeScreenState extends State<ProjectTreeScreen> {
  List<FileNode>? _rootNodes;

  @override
  void initState() {
    super.initState();
    _loadRoot();
  }

  Future<void> _loadRoot() async {
    final nodes = await widget.service.list(widget.service.root);
    if (mounted) setState(() => _rootNodes = nodes);
  }

  Future<void> _openFile(FileNode node) async {
    if (widget.service.isBinary(node.path)) {
      _showBinaryDialog();
      return;
    }
    final content = await widget.service.read(node.path);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CodeEditorScreen(
          path: node.path,
          initialContent: content,
          service: widget.service,
        ),
      ),
    );
  }

  void _showBinaryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Archivo binario', style: TextStyle(color: Colors.white)),
        content: const Text('Este archivo no se puede editar desde el editor de texto.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.lightBlueAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _rootNodes;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
      ),
      body: nodes == null
          ? const Center(child: CircularProgressIndicator())
          : nodes.isEmpty
              ? const Center(
                  child: Text('Carpeta vacía', style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: nodes.length,
                  itemBuilder: (ctx, i) => _nodeTile(context, nodes[i]),
                ),
    );
  }

  Widget _nodeTile(BuildContext context, FileNode node) {
    final icon = node.isDir ? Icons.folder : _iconFor(node.name);
    final color = node.isDir ? Colors.amber.shade400 : _colorFor(node.name);
    if (!node.isDir) {
      return ListTile(
        dense: true,
        leading: Icon(icon, color: color, size: 20),
        title: Text(node.name,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        onTap: () => _openFile(node),
      );
    }
    return ExpansionTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(node.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
      iconColor: Colors.white54,
      collapsedIconColor: Colors.white38,
      maintainState: true,
      onExpansionChanged: (open) {
        if (open) _loadDir(node);
      },
      children: _dirChildren[node.path] ?? const [],
    );
  }

  final Map<String, List<Widget>> _dirChildren = {};

  Future<void> _loadDir(FileNode dir) async {
    if (_dirChildren.containsKey(dir.path)) return;
    List<FileNode> children;
    try {
      children = await widget.service.list(dir.path);
    } catch (_) {
      children = const [];
    }
    if (!mounted) return;
    setState(() {
      _dirChildren[dir.path] =
          children.map((c) => _nodeTile(context, c)).toList(growable: false);
    });
  }

  IconData _iconFor(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'dart' => Icons.code,
      'md' => Icons.article_outlined,
      'json' => Icons.data_object,
      'yaml' || 'yml' => Icons.settings,
      'txt' || 'log' => Icons.description_outlined,
      'png' || 'jpg' || 'jpeg' || 'svg' || 'ico' => Icons.image_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  Color _colorFor(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'dart' => Colors.lightBlueAccent,
      'md' => Colors.blueGrey.shade300,
      'json' => Colors.amber,
      'yaml' || 'yml' => Colors.orangeAccent,
      _ => Colors.white38,
    };
  }
}
