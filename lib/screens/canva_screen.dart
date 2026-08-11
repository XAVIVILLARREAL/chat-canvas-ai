import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/canva.dart';
import '../services/agent_runner.dart';
import '../services/agent_store.dart';
import '../services/canva_store.dart';
import '../services/evidence_store.dart';
import '../services/project_service.dart';
import '../services/ssh_service.dart';
import '../services/sftp_service.dart';
import 'agent_chat_screen.dart';
import 'project_tree_screen.dart';
import 'terminal_screen.dart';
import 'sftp_screen.dart';

class CanvaScreen extends StatefulWidget {
  final List<SshHost> hosts;
  final SshService sshService;
  final CanvaStore store;

  const CanvaScreen({
    super.key,
    required this.hosts,
    required this.sshService,
    required this.store,
  });

  @override
  State<CanvaScreen> createState() => _CanvaScreenState();
}

class _CanvaScreenState extends State<CanvaScreen> {
  CanvaState _state = CanvaState.empty();
  bool _loading = true;
  String? _connectModeFromId;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await widget.store.load();
    if (!mounted) return;
    setState(() {
      _state = s;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await widget.store.save(_state);
  }

  String _newId() => 'n${DateTime.now().microsecondsSinceEpoch}';

  void _addHostNode(SshHost host) {
    setState(() {
      _state.nodes.add(CanvaNode(
        id: _newId(),
        type: CanvaNodeType.host,
        x: 200 + _state.nodes.length * 30,
        y: 200 + _state.nodes.length * 20,
        label: host.name,
        hostId: host.name,
        colorHex: '#0EA5E9',
      ));
    });
    _save();
  }

  void _addNote() {
    showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Nota', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _noteController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Texto', labelStyle: TextStyle(color: Colors.white54)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _noteController.text),
            child: const Text('Añadir'),
          ),
        ],
      ),
    ).then((text) {
      if (text != null && text.trim().isNotEmpty) {
        setState(() {
          _state.nodes.add(CanvaNode(
            id: _newId(),
            type: CanvaNodeType.note,
            x: 400,
            y: 200 + _state.nodes.length * 20,
            label: text.trim(),
            colorHex: '#F59E0B',
          ));
        });
        _save();
      }
    });
  }

  void _addAgent({String agentName = 'dev'}) {
    setState(() {
      _state.nodes.add(CanvaNode(
        id: _newId(),
        type: CanvaNodeType.agent,
        x: 600,
        y: 200 + _state.nodes.length * 20,
        label: agentName,
        hostId: agentName,
        colorHex: '#A855F7',
      ));
    });
    _save();
  }

  void _startConnect(String fromId) {
    setState(() => _connectModeFromId = fromId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Toca el nodo destino para conectar')),
    );
  }

  void _onNodeTap(CanvaNode node) {
    if (_connectModeFromId != null) {
      if (_connectModeFromId == node.id) {
        setState(() => _connectModeFromId = null);
        return;
      }
      setState(() {
        _state.edges.add(CanvaEdge(id: _newId(), fromNodeId: _connectModeFromId!, toNodeId: node.id));
        _connectModeFromId = null;
      });
      _save();
      return;
    }
    if (node.type == CanvaNodeType.host) {
      final host = widget.hosts.where((h) => h.name == node.hostId).firstOrNull;
      if (host == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Host no configurado')),
        );
        return;
      }
      _openHostActions(host);
    } else if (node.type == CanvaNodeType.agent) {
      _openAgentChat(node);
    }
  }

  Future<void> _openAgentChat(CanvaNode node) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agentes IA disponibles solo en desktop')),
      );
      return;
    }
    final store = AgentStore();
    final session = await store.getOrCreate(node.hostId ?? 'dev');
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgentChatScreen(
          session: session,
          store: (sessions) => store.save(sessions),
          runner: OpenCodeAgentRunner(),
          evidenceStore: EvidenceStore(),
        ),
      ),
    );
  }

  void _openHostActions(SshHost host) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.terminal, color: Colors.lightBlueAccent),
              title: const Text('Terminal', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(ctx, MaterialPageRoute(builder: (_) => TerminalScreen(host: host, service: widget.sshService)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open, color: Colors.amber),
              title: const Text('SFTP', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(ctx, MaterialPageRoute(builder: (_) => SftpScreen(host: host, sftp: SftpService(widget.sshService))));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text('Canva', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, size: 20),
            onPressed: _showAddMenu,
            tooltip: 'Añadir',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    constrained: false,
                    minScale: 0.3,
                    maxScale: 3,
                    boundaryMargin: const EdgeInsets.all(4000),
                    child: SizedBox(
                      width: 3000,
                      height: 2000,
                      child: Stack(
                        children: [
                          // conexiones
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _EdgesPainter(
                                edges: _state.edges,
                                nodes: _state.nodes,
                              ),
                            ),
                          ),
                          // nodos
                          for (final node in _state.nodes)
                            Positioned(
                              left: node.x,
                              top: node.y,
                              child: _DraggableNode(
                                node: node,
                                connectMode: _connectModeFromId == node.id,
                                onPositionChanged: (dx, dy) {
                                  node.x = dx;
                                  node.y = dy;
                                  _save();
                                },
                                onTap: () => _onNodeTap(node),
                                onLongPress: node.type == CanvaNodeType.host
                                    ? () => _startConnect(node.id)
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: _connectModeFromId != null
                      ? Chip(
                          label: Text('Conectando… toca destino', style: const TextStyle(color: Colors.white)),
                          backgroundColor: Colors.amber.shade700,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
    );
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Añadir al canva', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            if (widget.hosts.isEmpty)
              const ListTile(
                title: Text('No hay hosts. Agrégalos primero.', style: TextStyle(color: Colors.white54)),
              )
            else
              ...widget.hosts.map((h) => ListTile(
                    leading: const Icon(Icons.dns, color: Colors.lightBlueAccent),
                    title: Text(h.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${h.username}@${h.host}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _addHostNode(h);
                    },
                  )),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.sticky_note_2, color: Colors.amber),
              title: const Text('Nota', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _addNote();
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.smart_toy, color: Colors.purpleAccent),
              title: const Text('Agente IA (opencode)', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Solo desktop por ahora', style: TextStyle(color: Colors.white38, fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                _addAgent();
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.folder_open, color: Colors.greenAccent),
              title: const Text('Abrir proyecto', style: TextStyle(color: Colors.white)),
              subtitle: const Text('File tree + editor', style: TextStyle(color: Colors.white38, fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                _openProject();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openProject() async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abrir proyecto disponible solo en desktop')),
      );
      return;
    }
    final dir = await FilePicker.getDirectoryPath();
    if (dir == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectTreeScreen(
          service: ProjectService(root: dir),
          title: dir.split(Platform.pathSeparator).last,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}

class _DraggableNode extends StatefulWidget {
  final CanvaNode node;
  final bool connectMode;
  final void Function(double x, double y) onPositionChanged;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _DraggableNode({
    required this.node,
    required this.connectMode,
    required this.onPositionChanged,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_DraggableNode> createState() => _DraggableNodeState();
}

class _DraggableNodeState extends State<_DraggableNode> {
  Offset _dragStart = Offset.zero;
  double _baseX = 0;
  double _baseY = 0;

  void _onPanStart(DragStartDetails d) {
    _dragStart = d.localPosition;
    _baseX = widget.node.x;
    _baseY = widget.node.y;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    widget.onPositionChanged(
      _baseX + (d.localPosition.dx - _dragStart.dx),
      _baseY + (d.localPosition.dy - _dragStart.dy),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.node;
    final isHost = n.type == CanvaNodeType.host;
    final isAgent = n.type == CanvaNodeType.agent;
    final icon = isHost
        ? Icons.dns
        : isAgent
            ? Icons.smart_toy
            : Icons.sticky_note_2;
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      child: Container(
        width: isHost ? 170 : 150,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Color(n.colorValue).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.connectMode ? Colors.amber : Color(n.colorValue),
            width: widget.connectMode ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Color(n.colorValue),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                n.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EdgesPainter extends CustomPainter {
  final List<CanvaEdge> edges;
  final List<CanvaNode> nodes;

  _EdgesPainter({required this.edges, required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey.shade300
      ..strokeWidth = 2;
    for (final e in edges) {
      final from = nodes.where((n) => n.id == e.fromNodeId).firstOrNull;
      final to = nodes.where((n) => n.id == e.toNodeId).firstOrNull;
      if (from == null || to == null) continue;
      final a = Offset(from.x + 85, from.y + 20);
      final b = Offset(to.x + 85, to.y + 20);
      canvas.drawLine(a, b, paint);
      _drawArrow(canvas, a, b, paint);
    }
  }

  void _drawArrow(Canvas canvas, Offset a, Offset b, Paint paint) {
    final dir = (b - a);
    if (dir.distance < 1) return;
    final norm = dir / dir.distance;
    final perp = Offset(-norm.dy, norm.dx);
    const size = 8.0;
    final tip = b;
    final p1 = tip - norm * size + perp * size * 0.7;
    final p2 = tip - norm * size - perp * size * 0.7;
    final path = Path()..moveTo(tip.dx, tip.dy)..lineTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _EdgesPainter oldDelegate) =>
      oldDelegate.edges != edges || oldDelegate.nodes != nodes;
}
