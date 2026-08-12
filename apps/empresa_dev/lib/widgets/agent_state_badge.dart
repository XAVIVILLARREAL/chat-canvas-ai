import 'package:flutter/material.dart';
import 'package:agent_core/agent_detector.dart';
import '../theme/app_theme.dart';

class AgentStateBadge extends StatelessWidget {
  final AgentState state;

  const AgentStateBadge({super.key, required this.state});

  (IconData, Color) get _visual => switch (state) {
        AgentState.working => (Icons.bolt, AppColors.neonGreen),
        AgentState.blocked => (Icons.pause_circle_outline, Colors.redAccent),
        AgentState.idle => (Icons.hourglass_empty, AppColors.neonCyan),
        AgentState.unknown => (Icons.help_outline, AppColors.textFaint),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _visual;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(state.name,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  letterSpacing: 0.4)),
        ],
      ),
    );
  }
}
