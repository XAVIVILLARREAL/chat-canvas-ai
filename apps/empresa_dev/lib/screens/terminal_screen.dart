import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';
import '../services/ssh_service.dart';
import '../theme/app_theme.dart';

class TerminalScreen extends StatefulWidget {
  final SshHost host;
  final SshService service;

  const TerminalScreen({super.key, required this.host, required this.service});

  @override
  State<TerminalScreen> createState() => TerminalScreenState();
}

class TerminalScreenState extends State<TerminalScreen> {
  final Terminal _terminal = Terminal(
    maxLines: 10000,
    onOutput: (data) {},
  );
  final FocusNode _termFocus = FocusNode();
  SSHSession? _shell;
  bool _connecting = true;
  String? _error;
  bool _showSshKeys = false;

  /// Acceso al emulador de terminal (para tests y extensión).
  Terminal get terminal => _terminal;
  SSHSession? get shell => _shell;
  bool get isConnected => _shell != null && !_connecting;

  /// Envía texto al shell como si el usuario lo escribiera.
  void sendInput(String text) {
    _shell?.write(Uint8List.fromList(utf8.encode(text)));
  }

  @override
  void initState() {
    super.initState();
    _terminal.onOutput = _onOutput;
    _connect();
  }

  void _onOutput(String data) {
    _shell?.write(Uint8List.fromList(utf8.encode(data)));
  }

  void _sendEscape(String seq) {
    if (_shell == null) return;
    _shell!.write(Uint8List.fromList(seq.codeUnits));
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

      // Pedir el foco tras conectar para poder escribir de inmediato
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _termFocus.requestFocus();
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
    _termFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.hostAvatar,
              ),
              child: const Icon(Icons.dns, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${widget.host.name} · ${widget.host.username}@${widget.host.host}',
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          _ConnStatusPill(connected: isConnected, connecting: _connecting),
          IconButton(
            icon: const Icon(Icons.keyboard, size: 18),
            onPressed: () => setState(() => _showSshKeys = !_showSshKeys),
            tooltip: 'Teclado SSH',
            color: _showSshKeys ? Colors.amber : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: _connect,
            tooltip: 'Reconectar (Ctrl+R)',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_connecting) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(height: 16),
            const Text('Estableciendo túnel SSH…',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(widget.host.host,
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontFamily: 'monospace')),
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
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 32),
              ),
              const SizedBox(height: 14),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _connect,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TerminalView(
              _terminal,
              focusNode: _termFocus,
              autofocus: true,
              backgroundOpacity: 1,
              // En desktop el teclado físico debe mandar directamente al
              // terminal (sin IME), si no, las letras se pierden y no se
              // puede escribir.
              hardwareKeyboardOnly: !Platform.isAndroid && !Platform.isIOS,
              onKeyEvent: (node, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                final logical = event.logicalKey;
                final ctrl = HardwareKeyboard.instance.isControlPressed;
                if (ctrl && logical == LogicalKeyboardKey.keyR) {
                  _connect();
                  return KeyEventResult.handled;
                }
                if (ctrl && logical == LogicalKeyboardKey.keyL) {
                  _sendEscape('\x1b[2J\x1b[H');
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
            ),
          ),
        ),
        if (_showSshKeys) _buildSshKeys(),
      ],
    );
  }

  Widget _buildSshKeys() {
    Widget key(String label, String seq) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Material(
              color: AppColors.bgPanel,
              borderRadius: BorderRadius.circular(AppRadii.chip),
              child: InkWell(
                onTap: () => _sendEscape(seq),
                borderRadius: BorderRadius.circular(AppRadii.chip),
                child: Center(
                  child: Text(label,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ),
            ),
          ),
        );

    return Container(
      color: AppColors.bgDeep,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            key('Esc', '\x1b'),
            key('Tab', '\t'),
            key('Ctrl', ''),
            key('↑', '\x1b[A'),
            key('↓', '\x1b[B'),
          ]),
          Row(children: [
            key('←', '\x1b[D'),
            key('→', '\x1b[C'),
            key('Ctrl-C', '\x03'),
            key('Ctrl-D', '\x04'),
            key('Enter', '\r'),
          ]),
        ],
      ),
    );
  }
}

/// Píldora de estado de conexión del terminal.
class _ConnStatusPill extends StatelessWidget {
  final bool connected;
  final bool connecting;

  const _ConnStatusPill({required this.connected, required this.connecting});

  @override
  Widget build(BuildContext context) {
    final (color, label) = connected
        ? (AppColors.neonGreen, 'CONECTADO')
        : connecting
            ? (AppColors.neonAmber, 'CONECTANDO')
            : (Colors.white38, 'DESCONECTADO');
    return Center(
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8)),
      ),
    );
  }
}

String utf8Decode(List<int> bytes) {
  return utf8.decode(bytes, allowMalformed: true);
}

