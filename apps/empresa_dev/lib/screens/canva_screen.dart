import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:canva_core/canva.dart';
import 'package:graph_core/graph_core.dart';
import 'package:vibecoding_core/vibecoding_core.dart';
import '../models/skill.dart';
import '../services/agent_runner.dart';
import '../services/agent_store.dart';
import '../services/canva_store.dart';
import '../services/docs_map_builder.dart';
import '../services/evidence_store.dart';
import '../services/project_service.dart';
import '../services/ssh_service.dart';
import '../services/sftp_service.dart';
import '../services/vibecoding_service.dart';
import '../services/vibecoding_store.dart';
import '../theme/app_theme.dart';
import '../widgets/diff_preview.dart';
import '../widgets/neon_dialog.dart';
import '../widgets/neon_sheet.dart';
import 'agent_chat_screen.dart';
import 'code_editor_screen.dart';
import 'md_node_screen.dart';
import 'project_graph_screen.dart';
import 'project_tree_screen.dart';
import 'proposal_node_screen.dart';
import 'skill_builder_screen.dart';
import 'skill_lab_screen.dart';
import 'terminal_screen.dart';
import 'sftp_screen.dart';
import 'vibecoding_screen.dart';

class CanvaScreen extends StatefulWidget {
  final List<SshHost> hosts;
  final SshService sshService;
  final CanvaStore store;
  final VibecodingStore? vibecodingStore;

  const CanvaScreen({
    super.key,
    required this.hosts,
    required this.sshService,
    required this.store,
    this.vibecodingStore,
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

  String _newId() => CanvasNodeId.generate().value;

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
    showNeonDialog<String>(
      context: context,
      glow: AppColors.neonAmber,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Nueva nota',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            autofocus: true,
            decoration: const InputDecoration(
                labelText: 'Texto', hintText: 'Escribe la nota…'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, _noteController.text),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Añadir'),
                ),
              ),
            ],
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
    } else if (node.type == CanvaNodeType.note) {
      _openMdNode(node);
    } else if (node.type == CanvaNodeType.proposal) {
      _openProposalNode(node);
    }
  }

  /// Color de nodo por estado de la propuesta (misma paleta que DiffPreview).
  String _hexForState(ProposalState state) => switch (state) {
        ProposalState.pending => '#F59E0B',
        ProposalState.applied => '#4ADE80',
        ProposalState.rejected => '#94A3B8',
        ProposalState.reverted => '#22D3EE',
        ProposalState.failed => '#F87171',
      };

  Future<void> _openProposalNode(CanvaNode node) async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nodo-diff disponible solo en desktop')),
      );
      return;
    }
    final store = widget.vibecodingStore ?? VibecodingStore();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProposalNodeScreen(
          proposalId: node.content ?? '',
          store: store,
        ),
      ),
    );
    final saved = await store.load();
    if (!mounted) return;
    final updated = saved.where((p) => p.id == node.content).firstOrNull;
    if (updated != null) {
      setState(() => node.colorHex = _hexForState(updated.state));
      _save();
    }
  }

  Future<void> _addProposalNode() async {
    final store = widget.vibecodingStore ?? VibecodingStore();
    final proposals = await store.load();
    if (!mounted) return;
    if (proposals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay propuestas — genera una desde Vibecoding primero')),
      );
      return;
    }
    showNeonSheet(
      context: context,
      glow: AppColors.neonAmber,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Propuestas del historial',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final p in proposals)
                  NeonSheetTile(
                    icon: Icons.difference,
                    iconColor: DiffPreview.color(p.state),
                    title: p.prompt,
                    subtitle:
                        '${DiffPreview.label(p.state)} · ${p.edits.length} archivos',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _state.nodes.add(CanvaNode(
                          id: _newId(),
                          type: CanvaNodeType.proposal,
                          x: 420 + (_state.nodes.length % 4) * 40,
                          y: 420 + (_state.nodes.length % 3) * 24,
                          label: p.prompt,
                          colorHex: _hexForState(p.state),
                          content: p.id,
                        ));
                      });
                      _save();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMdNode(CanvaNode node) async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nodos .md disponibles solo en desktop')),
      );
      return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MdNodeScreen(
          node: node,
          allNodes: _state.nodes,
          onSave: (updated) {
            setState(() {
              updated
                ..x = node.x
                ..y = node.y
                ..id = node.id;
              final idx = _state.nodes.indexOf(node);
              _state.nodes[idx] = updated;
            });
            _save();
          },
          onCreateLink: (title) => _createLinkedNode(node, title),
        ),
      ),
    );
  }

  void _createLinkedNode(CanvaNode from, String title) {
    setState(() {
      final created = CanvaNode(
        id: _newId(),
        type: CanvaNodeType.note,
        x: from.x + 40,
        y: from.y + 40,
        label: title,
        colorHex: '#F59E0B',
        content: '# $title\n\n',
      );
      _state.nodes.add(created);
      _state.edges.add(CanvaEdge(id: _newId(), fromNodeId: from.id, toNodeId: created.id));
    });
    _save();
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
    showNeonSheet(
      context: context,
      glow: AppColors.neonCyan,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Acciones del host',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
          NeonSheetTile(
            icon: Icons.terminal,
            iconColor: AppColors.neonGreen,
            title: 'Terminal',
            subtitle: 'Shell SSH en vivo',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => TerminalScreen(host: host, service: widget.sshService)));
            },
          ),
          NeonSheetTile(
            icon: Icons.folder_open,
            iconColor: AppColors.neonAmber,
            title: 'SFTP',
            subtitle: 'Navega y transfiere archivos',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => SftpScreen(host: host, sftp: SftpService(widget.sshService))));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.chip),
                gradient: AppGradients.neon,
              ),
              child: const Icon(Icons.layers, color: Color(0xFF062A33), size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Canva', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 12),
            _NodeCountChip(count: _state.nodes.length),
          ],
        ),
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
                                onDoubleTap:
                                    node.type == CanvaNodeType.note
                                        ? () => _openMdNode(node)
                                        : node.type == CanvaNodeType.agent &&
                                                _skillFromNode(node) != null
                                            ? () => _openSkillBuilder(
                                                initial: _skillFromNode(node))
                                            : null,
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
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.neonAmber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color:
                                    AppColors.neonAmber.withValues(alpha: 0.6)),
                            boxShadow: AppGlow.violet(strength: 0.3, blur: 20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.link,
                                  color: AppColors.neonAmber, size: 16),
                              SizedBox(width: 6),
                              Text('Conectando… toca el destino',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
    );
  }

  void _showAddMenu() {
    showNeonSheet(
      context: context,
      glow: AppColors.neonViolet,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Añadir al canva',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
          if (widget.hosts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No hay hosts. Agrégalos primero.',
                  style: TextStyle(color: Colors.white54)),
            )
          else
            ...widget.hosts.map((h) => NeonSheetTile(
                  icon: Icons.dns,
                  iconColor: AppColors.neonCyan,
                  title: h.name,
                  subtitle: '${h.username}@${h.host}',
                  onTap: () {
                    Navigator.pop(context);
                    _addHostNode(h);
                  },
                )),
          const Divider(height: 24),
          NeonSheetTile(
            icon: Icons.sticky_note_2,
            iconColor: AppColors.neonAmber,
            title: 'Nota',
            subtitle: 'Idea o fragmento en el canva',
            onTap: () {
              Navigator.pop(context);
              _addNote();
            },
          ),
          NeonSheetTile(
            icon: Icons.smart_toy,
            iconColor: AppColors.neonViolet,
            title: 'Agente IA (opencode)',
            subtitle: 'Solo desktop por ahora',
            onTap: () {
              Navigator.pop(context);
              _addAgent();
            },
          ),
          const Divider(height: 24),
          NeonSheetTile(
            icon: Icons.folder_open,
            iconColor: AppColors.neonGreen,
            title: 'Abrir proyecto',
            subtitle: 'File tree + editor',
            onTap: () {
              Navigator.pop(context);
              _openProject();
            },
          ),
          NeonSheetTile(
            icon: Icons.map_outlined,
            iconColor: Colors.tealAccent,
            title: 'Abrir docs (mapa .md)',
            subtitle: 'Carpeta de notas enlazadas',
            onTap: () {
              Navigator.pop(context);
              _openDocsMap();
            },
          ),
          const Divider(height: 24),
          NeonSheetTile(
            icon: Icons.science,
            iconColor: AppColors.neonCyan,
            title: 'Skills: constructor + laboratorio',
            subtitle: 'Crea skills visualmente y pruébalas',
            onTap: () {
              Navigator.pop(context);
              _openSkillLab();
            },
          ),
          NeonSheetTile(
            icon: Icons.hub_outlined,
            iconColor: AppColors.neonViolet,
            title: 'Grafo del proyecto',
            subtitle: 'Archivos, imports y links en 2D/3D',
            onTap: () {
              Navigator.pop(context);
              _openProjectGraph();
            },
          ),
          const Divider(height: 24),
          NeonSheetTile(
            icon: Icons.auto_fix_high,
            iconColor: AppColors.neonCyan,
            title: 'Vibecoding',
            subtitle: 'El agente IA propone cambios con nodo-diff',
            onTap: () {
              Navigator.pop(context);
              _openVibecoding();
            },
          ),
          NeonSheetTile(
            icon: Icons.difference,
            iconColor: AppColors.neonAmber,
            title: 'Propuesta vibecoding',
            subtitle: 'Nodo-diff del historial en el canva',
            onTap: () {
              Navigator.pop(context);
              _addProposalNode();
            },
          ),
        ],
      ),
    );
  }

  Skill? _skillFromNode(CanvaNode node) {
    final content = node.content;
    if (content == null || content.trim().isEmpty) return null;
    return Skill.fromMarkdown(content);
  }

  Future<void> _openProjectGraph() async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grafo disponible solo en desktop')),
      );
      return;
    }
    const repoDefine = String.fromEnvironment('EMPRESA_DEV_REPO');
    final repoEnv = Platform.environment['EMPRESA_DEV_REPO'];
    final dir = repoDefine.isNotEmpty
        ? repoDefine
        : (repoEnv != null && repoEnv.isNotEmpty)
            ? repoEnv
            : await FilePicker.getDirectoryPath();
    if (dir == null || dir.isEmpty || !mounted) return;
    final graph = RelationIndexer.scan(dir);
    final service = ProjectService(root: dir);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectGraphScreen(
          graph: graph,
          root: dir,
          onOpenFile: (path) {
            final file = File('$dir${Platform.pathSeparator}$path');
            if (!file.existsSync()) return;
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CodeEditorScreen(
                  path: path,
                  initialContent: file.readAsStringSync(),
                  service: service,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openVibecoding() async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vibecoding disponible solo en desktop')),
      );
      return;
    }
    const repoDefine = String.fromEnvironment('EMPRESA_DEV_REPO');
    final repoEnv = Platform.environment['EMPRESA_DEV_REPO'];
    final dir = repoDefine.isNotEmpty
        ? repoDefine
        : (repoEnv != null && repoEnv.isNotEmpty)
            ? repoEnv
            : await FilePicker.getDirectoryPath();
    if (dir == null || dir.isEmpty || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VibecodingScreen(
          projectPath: dir,
          runner: AgentCommandRunnerAdapter(),
        ),
      ),
    );
  }

  Future<void> _openSkillLab() async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skills disponible solo en desktop')),
      );
      return;
    }
    final dir = Directory(
        Platform.environment['EMPRESA_DEV_REPO'] ?? '../../.opencode/skills');
    final skills = <Skill>[];
    if (dir.existsSync()) {
      for (final sub in dir.listSync().whereType<Directory>()) {
        final f = File('${sub.path}/SKILL.md');
        if (!f.existsSync()) continue;
        final skill = Skill.fromMarkdown(f.readAsStringSync());
        if (skill != null) skills.add(skill);
      }
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SkillLabScreen(
          skills: skills,
          onNewSkill: () => _openSkillBuilder(),
        ),
      ),
    );
  }

  Future<void> _openSkillBuilder({Skill? initial}) async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SkillBuilderScreen(
          initial: initial,
          onSave: (skill) => _saveSkillToRepo(skill),
        ),
      ),
    );
  }

  Future<void> _saveSkillToRepo(Skill skill) async {
    final dir =
        Directory(Platform.environment['EMPRESA_DEV_REPO'] ?? '../../.opencode/skills');
    if (!dir.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se encontró .opencode/skills (usa EMPRESA_DEV_REPO)')),
      );
      return;
    }
    final target = Directory('${dir.path}/${skill.name}');
    target.createSync(recursive: true);
    File('${target.path}/SKILL.md').writeAsStringSync(skill.toMarkdown());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Skill "${skill.name}" guardada en .opencode/skills')),
    );
  }

  Future<void> _openDocsMap() async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mapa .md disponible solo en desktop')),
      );
      return;
    }
    final dir = await FilePicker.getDirectoryPath();
    if (dir == null || !mounted) return;
    final built = DocsMapBuilder.build(dir);
    setState(() {
      _state = built;
    });
    _save();
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

/// Contador de nodos del canva (chip de información en el AppBar).
class _NodeCountChip extends StatelessWidget {
  final int count;

  const _NodeCountChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text('$count nodos',
          style: const TextStyle(color: Colors.white54, fontSize: 11)),
    );
  }
}

class _DraggableNode extends StatefulWidget {
  final CanvaNode node;
  final bool connectMode;
  final void Function(double x, double y) onPositionChanged;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;

  const _DraggableNode({
    required this.node,
    required this.connectMode,
    required this.onPositionChanged,
    required this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  });

  @override
  State<_DraggableNode> createState() => _DraggableNodeState();
}

class _DraggableNodeState extends State<_DraggableNode> {
  Offset _dragStart = Offset.zero;
  double _baseX = 0;
  double _baseY = 0;
  bool _hovered = false;

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
    final isProposal = n.type == CanvaNodeType.proposal;
    final color = Color(n.colorValue);
    final icon = isHost
        ? Icons.dns
        : isAgent
            ? Icons.smart_toy
            : isProposal
                ? Icons.difference
                : Icons.sticky_note_2;
    final glowColor = isAgent
        ? AppColors.neonViolet
        : isHost
            ? AppColors.neonCyan
            : isProposal
                ? color
                : AppColors.neonAmber;

    return MouseRegion(
      cursor: SystemMouseCursors.move,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onLongPress: widget.onLongPress,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.easeOutCubic,
          width: isHost ? 180 : 156,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: widget.connectMode ? 0.35 : 0.18),
                color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: widget.connectMode
                  ? AppColors.neonAmber
                  : color.withValues(alpha: _hovered ? 0.9 : 0.5),
              width: widget.connectMode ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(
                    alpha: (widget.connectMode || _hovered) ? 0.3 : 0.15),
                blurRadius: _hovered ? 22 : 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, glowColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  n.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
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
    for (final e in edges) {
      final from = nodes.where((n) => n.id == e.fromNodeId).firstOrNull;
      final to = nodes.where((n) => n.id == e.toNodeId).firstOrNull;
      if (from == null || to == null) continue;
      final color = Color(from.colorValue);
      final a = Offset(from.x + 85, from.y + 28);
      final b = Offset(to.x + 85, to.y + 28);
      final paint = Paint()
        ..color = color.withValues(alpha: 0.45)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(a, b, paint);
      _drawArrow(canvas, a, b, Paint()
        ..color = color.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill);
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
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EdgesPainter oldDelegate) =>
      oldDelegate.edges != edges || oldDelegate.nodes != nodes;
}
