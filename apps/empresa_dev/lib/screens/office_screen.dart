import 'package:flutter/material.dart';
import 'package:agent_core/office_state.dart';
import 'package:canva_core/canva.dart';
import '../theme/app_theme.dart';
import '../widgets/canva_view.dart';
import '../widgets/neon_sheet.dart';

/// Arista de dependencia entre agentes de la oficina (PM → dev, etc.).
class OfficeEdge {
  final String fromAgentId;
  final String toAgentId;

  const OfficeEdge({required this.fromAgentId, required this.toAgentId});
}

/// Oficina (Etapa 8.2): el canva como espejo vivo del estado de los agentes.
/// Una instancia de [CanvaView] (ADR-004) cuyo [CanvaView.nodeBuilder] pinta
/// glow por estado; la fuente de estados ([OfficeStatusSource]) lo anima en
/// vivo.
class OfficeScreen extends StatefulWidget {
  final OfficeStatusSource office;
  final List<OfficeEdge> edges;

  const OfficeScreen({super.key, required this.office, this.edges = const []});

  @override
  State<OfficeScreen> createState() => _OfficeScreenState();
}

class _OfficeScreenState extends State<OfficeScreen> {
  /// Posiciones arrastradas por el usuario (persisten entre rebuilds).
  final Map<String, Offset> _positions = {};

  @override
  void initState() {
    super.initState();
    widget.office.statuses.addListener(_onStatus);
    widget.office.start();
  }

  void _onStatus() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.office.statuses.removeListener(_onStatus);
    widget.office.stop();
    super.dispose();
  }

  static String hexFor(OfficeState s) => switch (s) {
        OfficeState.working => '#22D3EE',
        OfficeState.blocked => '#F87171',
        OfficeState.waitingApproval => '#F59E0B',
        OfficeState.done => '#4ADE80',
        OfficeState.failed => '#F87171',
        OfficeState.idle => '#94A3B8',
      };

  static Color colorFor(OfficeState s) => Color(int.parse('FF${hexFor(s).substring(1)}', radix: 16));

  static IconData iconFor(OfficeState s) => switch (s) {
        OfficeState.working => Icons.bolt,
        OfficeState.blocked => Icons.block,
        OfficeState.waitingApproval => Icons.hourglass_top,
        OfficeState.done => Icons.check_circle,
        OfficeState.failed => Icons.error_outline,
        OfficeState.idle => Icons.circle_outlined,
      };

  List<CanvaNode> _nodes() {
    final statuses = widget.office.statuses.value;
    final nodes = <CanvaNode>[];
    var i = 0;
    statuses.forEach((id, status) {
      final auto = Offset(200 + (i % 3) * 280.0, 150 + (i ~/ 3) * 160.0);
      final pos = _positions[id] ?? auto;
      nodes.add(CanvaNode(
        id: id,
        type: CanvaNodeType.agent,
        x: pos.dx,
        y: pos.dy,
        label: status.label,
        colorHex: hexFor(status.state),
      ));
      i++;
    });
    return nodes;
  }

  void _showAgent(String id) {
    final status = widget.office.statuses.value[id];
    if (status == null) return;
    showNeonSheet(
      context: context,
      glow: colorFor(status.state),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('${status.label} · ${status.state.name}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
          for (final t in status.transitions)
            ListTile(
              dense: true,
              leading: Icon(iconFor(t.state), color: colorFor(t.state), size: 18),
              title: Text(t.state.name,
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text('${t.at.toLocal()}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _nodes();
    final canvaEdges = [
      for (var i = 0; i < widget.edges.length; i++)
        CanvaEdge(
          id: 'oe$i',
          fromNodeId: widget.edges[i].fromAgentId,
          toNodeId: widget.edges[i].toAgentId,
        ),
    ];

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
              child: const Icon(Icons.badge, color: Color(0xFF062A33), size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Oficina', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
      body: CanvaView(
        nodes: nodes,
        edges: canvaEdges,
        onNodeTap: (n) => _showAgent(n.id),
        onNodeMoved: (node, x, y) {
          setState(() => _positions[node.id] = Offset(x, y));
        },
        nodeBuilder: (node, cb) => _AgentOfficeCard(
          label: node.label,
          state: widget.office.statuses.value[node.id]?.state ??
              OfficeState.idle,
          onTap: cb.onTap,
        ),
      ),
    );
  }
}

/// Card de agente-empleado: label + estado con glow neón por estado.
class _AgentOfficeCard extends StatelessWidget {
  final String label;
  final OfficeState state;
  final VoidCallback onTap;

  const _AgentOfficeCard({
    required this.label,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _OfficeScreenState.colorFor(state);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 150,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 14),
          ],
        ),
        child: Row(
          children: [
            Icon(_OfficeScreenState.iconFor(state), color: color, size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              state.name,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
