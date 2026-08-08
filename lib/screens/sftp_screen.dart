import 'dart:io';

import 'package:flutter/material.dart';
import '../services/ssh_service.dart';
import '../services/sftp_service.dart';

class SftpScreen extends StatefulWidget {
  final SshHost host;
  final SftpService sftp;

  const SftpScreen({super.key, required this.host, required this.sftp});

  @override
  State<SftpScreen> createState() => _SftpScreenState();
}

class _SftpScreenState extends State<SftpScreen> {
  String _cwd = '/';
  List<SftpEntry> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load('/');
  }

  Future<void> _load(String path) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.sftp.list(path);
      if (!mounted) return;
      setState(() {
        _items = items;
        _cwd = path;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo listar: $e';
      });
    }
  }

  Future<void> _upload() async {
    try {
      final picker = FilePickerHelper();
      final local = await picker.pickFile();
      if (local == null) return;
      final remotePath = '$_cwd/${local.split(Platform.pathSeparator).last}';
      await widget.sftp.upload(local, remotePath);
      if (mounted) _load(_cwd);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir: $e')));
      }
    }
  }

  Future<void> _download(SftpEntry entry) async {
    try {
      final local = await FilePickerHelper().saveFile(entry.name);
      if (local == null) return;
      await widget.sftp.download('$_cwd/${entry.name}', local);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Descargado a $local')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _mkdir() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Nueva carpeta', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Nombre', labelStyle: TextStyle(color: Colors.white54)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    try {
      await widget.sftp.mkdir('$_cwd/${name.trim()}');
      if (mounted) _load(_cwd);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Text('SFTP · ${widget.host.name}', style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _load(_cwd), tooltip: 'Refrescar'),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      _cwd,
                      style: const TextStyle(color: Colors.lightBlueAccent, fontFamily: 'monospace'),
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.create_new_folder, size: 20), onPressed: _mkdir, tooltip: 'Nueva carpeta'),
                IconButton(icon: const Icon(Icons.upload, size: 20), onPressed: _upload, tooltip: 'Subir archivo'),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => _load('/'), child: const Text('Volver a /')),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (ctx, i) {
        final it = _items[i];
        if (it.name == '.' || it.name == '..') return const SizedBox.shrink();
        return ListTile(
          dense: true,
          leading: Icon(
            it.isDirectory ? Icons.folder : Icons.insert_drive_file,
            color: it.isDirectory ? Colors.amber : Colors.lightBlueAccent,
            size: 20,
          ),
          title: Text(it.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
          subtitle: it.isDirectory ? null : Text(_fmt(it.size), style: const TextStyle(color: Colors.white38, fontSize: 11)),
          onTap: it.isDirectory
              ? () => _load('$_cwd/${it.name}')
              : null,
          trailing: it.isDirectory
              ? null
              : IconButton(
                  icon: const Icon(Icons.download, size: 18),
                  onPressed: () => _download(it),
                  tooltip: 'Descargar',
                ),
        );
      },
    );
  }

  String _fmt(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Helper mínimo de selección de archivos sin depender de file_picker en este slice.
class FilePickerHelper {
  Future<String?> pickFile() async {
    // Este slice usa una ruta de texto; file_picker se integra después.
    final controller = TextEditingController(text: '/tmp');
    final path = await showDialog<String>(
      context: navigatorKey.currentContext!,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Ruta local del archivo', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Subir')),
        ],
      ),
    );
    return (path == null || path.trim().isEmpty) ? null : path.trim();
  }

  Future<String?> saveFile(String name) async {
    final controller = TextEditingController(text: '/tmp/$name');
    final path = await showDialog<String>(
      context: navigatorKey.currentContext!,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Guardar en', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Guardar')),
        ],
      ),
    );
    return (path == null || path.trim().isEmpty) ? null : path.trim();
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
