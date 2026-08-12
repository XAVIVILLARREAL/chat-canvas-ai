import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:path_provider/path_provider.dart';
import 'package:warp_core/warp_core.dart';
import 'package:xterm/xterm.dart';
import '../services/ssh_service.dart';
import '../theme/app_theme.dart';

class TerminalScreen extends StatefulWidget {
  final SshHost host;
  final SshService service;

  /// Historial de comandos por host (Warp-mode, Etapa 8.5). Inyectable para
  /// tests (memoria); por defecto se persiste en documents/history.json.
  final CommandHistoryStore? historyStore;

  const TerminalScreen({
    super.key,
    required this.host,
    required this.service,
    this.historyStore,
  });

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

  // Warp-mode (Etapa 8.5): historial por host + búsqueda fuzzy + sugerencia.
  late final CommandLineTracker _tracker =
      CommandLineTracker(onCommand: _onCommandCaptured);
  CommandHistoryStore? _history;
  bool _showHistorySearch = false;
  String? _suggestion;

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
    _history = widget.historyStore;
    if (_history == null) _initHistory();
    _connect();
  }

  Future<void> _initHistory() async {
    final dir = await getApplicationDocumentsDirectory();
    if (!mounted) return;
    _history = CommandHistoryStore(dir: Directory('${dir.path}/warp'));
  }

  void _onOutput(String data) {
    if (_shell != null) {
      _shell!.write(Uint8List.fromList(utf8.encode(data)));
    }
    _tracker.feed(data);
    _updateSuggestion();
  }

  void _onCommandCaptured(String line) {
    if (_shell == null) return;
    _history?.add(widget.host.name, line);
    _updateSuggestion();
  }

  Future<void> _updateSuggestion() async {
    final history = _history;
    final current = _tracker.currentLine;
    if (history == null || current.isEmpty || _shell == null) {
      if (_suggestion != null && mounted) setState(() => _suggestion = null);
      return;
    }
    final results = await history.search(widget.host.name, current);
    final best = results.isNotEmpty && results.first.command != current
        ? results.first.command
        : null;
    if (!mounted) return;
    final next = best;
    if (next != _suggestion) setState(() => _suggestion = next);
  }

  /// Acepta la sugerencia: completa la línea actual (o la reemplaza).
  void _acceptSuggestion() {
    final s = _suggestion;
    final current = _tracker.currentLine;
    final shell = _shell;
    if (s == null || shell == null) return;
    if (s.startsWith(current)) {
      final tail = s.substring(current.length);
      shell.write(Uint8List.fromList(utf8.encode(tail)));
      _tracker.feed(tail);
    } else {
      shell.write(Uint8List.fromList(utf8.encode('\x15$s')));
      _tracker
        ..reset()
        ..feed(s);
    }
    _updateSuggestion();
  }

  void _executeHistoryCommand(String command) {
    final shell = _shell;
    if (shell == null) return;
    shell.write(Uint8List.fromList(utf8.encode('$command\r')));
    _history?.add(widget.host.name, command);
    setState(() => _showHistorySearch = false);
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
            tooltip: 'Reconectar (Ctrl+Shift+R)',
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
    return Stack(
      children: [
        Column(
          children: [
            if (_suggestion != null) _buildSuggestionBar(),
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
                    final shift = HardwareKeyboard.instance.isShiftPressed;
                    if (ctrl && shift && logical == LogicalKeyboardKey.keyR) {
                      _connect();
                      return KeyEventResult.handled;
                    }
                    if (ctrl && !shift && logical == LogicalKeyboardKey.keyR) {
                      if (!_showHistorySearch) {
                        setState(() => _showHistorySearch = true);
                      }
                      return KeyEventResult.handled;
                    }
                    if (logical == LogicalKeyboardKey.tab &&
                        _suggestion != null) {
                      _acceptSuggestion();
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
        ),
        if (_showHistorySearch && _history != null)
          Positioned.fill(
            child: _HistorySearchOverlay(
              store: _history!,
              host: widget.host.name,
              onExecute: _executeHistoryCommand,
              onClose: () => setState(() => _showHistorySearch = false),
            ),
          ),
      ],
    );
  }

  /// Barra de sugerencia inline: muestra el mejor match del historial.
  Widget _buildSuggestionBar() {
    return Material(
      color: AppColors.bgPanel,
      child: InkWell(
        onTap: _acceptSuggestion,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.tab, size: 14, color: AppColors.neonCyan),
              const SizedBox(width: 8),
              const Text('Tab',
                  style: TextStyle(
                      color: AppColors.neonCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _suggestion!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
      ),
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

/// Overlay de búsqueda fuzzy del historial por host (Ctrl+R, Warp-mode).
/// TextField + lista de resultados; ↑/↓ navegan, Enter ejecuta, Esc cierra.
class _HistorySearchOverlay extends StatefulWidget {
  final CommandHistoryStore store;
  final String host;
  final void Function(String command) onExecute;
  final VoidCallback onClose;

  const _HistorySearchOverlay({
    required this.store,
    required this.host,
    required this.onExecute,
    required this.onClose,
  });

  @override
  State<_HistorySearchOverlay> createState() => _HistorySearchOverlayState();
}

class _HistorySearchOverlayState extends State<_HistorySearchOverlay> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  List<CommandRecord> _results = const [];
  int _selected = -1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _focus.onKeyEvent = _onKey;
    _focus.addListener(() {
      if (!_focus.hasFocus) widget.onClose();
    });
    _search('');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final results = await widget.store.search(widget.host, query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _selected = results.isEmpty ? -1 : 0;
      _loading = false;
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onClose();
      return KeyEventResult.handled;
    }
    if (_results.isEmpty) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _selected = (_selected + 1) % _results.length);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() =>
          _selected = (_selected - 1 + _results.length) % _results.length);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: 520,
            constraints: const BoxConstraints(maxHeight: 420),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgPanelHi,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.border),
              boxShadow: AppGlow.violet(strength: 0.25, blur: 30),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: true,
                  onChanged: _search,
                  onSubmitted: (value) {
                    if (_selected >= 0 && _selected < _results.length) {
                      widget.onExecute(_results[_selected].command);
                    } else if (value.trim().isNotEmpty) {
                      widget.onExecute(value.trim());
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar comando (Ctrl+R)…',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: const Icon(Icons.north_west, size: 14),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _results.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Sin resultados',
                                  style: TextStyle(color: Colors.white54)),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _results.length,
                              itemBuilder: (context, i) => InkWell(
                                onTap: () =>
                                    widget.onExecute(_results[i].command),
                                child: Container(
                                  color: i == _selected
                                      ? AppColors.neonViolet
                                          .withValues(alpha: 0.22)
                                      : null,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  child: Row(
                                    children: [
                                      Icon(
                                        i == _selected
                                            ? Icons.north_west
                                            : Icons.subdirectory_arrow_right,
                                        size: 14,
                                        color: i == _selected
                                            ? AppColors.neonViolet
                                            : Colors.white38,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _results[i].command,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontFamily: 'monospace',
                                            fontWeight: i == _selected
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

