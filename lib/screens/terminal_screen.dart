import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';
import '../services/ssh_service.dart';

class TerminalScreen extends StatefulWidget {
  final SshHost host;
  final SshService service;

  const TerminalScreen({super.key, required this.host, required this.service});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final Terminal _terminal = Terminal(
    maxLines: 10000,
    onOutput: (data) {},
  );
  SSHSession? _shell;
  bool _connecting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _terminal.onOutput = _onOutput;
    _connect();
  }

  void _onOutput(String data) {
    _shell?.write(Uint8List.fromList(utf8.encode(data)));
  }

  Future<void> _connect() async {
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      final shell = await widget.service.connectShell(widget.host);
      if (!mounted) return;
      setState(() {
        _shell = shell;
        _connecting = false;
      });

      // stdout del shell → terminal
      shell.stdout.listen((data) {
        if (mounted) _terminal.write(utf8Decode(data));
      });
      // stderr del shell → terminal
      shell.stderr.listen((data) {
        if (mounted) _terminal.write(utf8Decode(data));
      });
      // resize de ventana
      _terminal.onResize = (w, h, pw, ph) {
        if (_shell != null) {
          _shell!.resizeTerminal(w, h);
        }
      };
      shell.done.then((_) {
        if (mounted) {
          setState(() => _shell = null);
          _terminal.write('\r\n\x1b[1;31m[conexión cerrada]\x1b[0m\r\n');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = 'No se pudo conectar: $e';
      });
    }
  }

  @override
  void dispose() {
    widget.service.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.dns, size: 18, color: Colors.lightBlueAccent),
            const SizedBox(width: 8),
            Text(
              '${widget.host.name} · ${widget.host.username}@${widget.host.host}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: _connect,
            tooltip: 'Reconectar',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_connecting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Conectando…', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }
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
              FilledButton(onPressed: _connect, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TerminalView(
        _terminal,
        backgroundOpacity: 1,
        autofocus: true,
      ),
    );
  }
}

String utf8Decode(List<int> bytes) {
  return utf8.decode(bytes, allowMalformed: true);
}
