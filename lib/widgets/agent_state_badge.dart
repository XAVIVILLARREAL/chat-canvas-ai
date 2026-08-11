import 'package:flutter/material.dart';
import '../services/agent_detector.dart';

class AgentStateBadge extends StatelessWidget {
  final AgentState state;

  const AgentStateBadge({super.key, required this.state});

  (IconData, Color) get _visual => switch (state) {
        AgentState.working => (Icons.bolt, Colors.lightGreenAccent),
        AgentState.blocked => (Icons.pause_circle_outline, Colors.redAccent),
        AgentState.idle => (Icons.hourglass_empty, Colors.blueGrey),
        AgentState.unknown => (Icons.help_outline, Colors.white38),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _visual;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(state.name,
            style: TextStyle(color: color, fontSize: 11, fontFamily: 'monospace')),
      ],
    );
  }
}
