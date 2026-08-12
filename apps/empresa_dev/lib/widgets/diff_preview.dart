import 'package:flutter/material.dart';
import 'package:vibecoding_core/vibecoding_core.dart';
import '../theme/app_theme.dart';

/// Vista del nodo-diff: antes/después con resaltado de +/-, badge de estado
/// y acciones Aceptar/Rechazar/Revertir según el estado de la propuesta.
/// Sin BackdropFilter (dentro de listas con scroll — regla de rendimiento).
class DiffPreview extends StatelessWidget {
  final PatchProposal proposal;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onRevert;

  const DiffPreview({
    super.key,
    required this.proposal,
    this.onAccept,
    this.onReject,
    this.onRevert,
  });

  static String label(ProposalState state) => switch (state) {
        ProposalState.pending => 'pendiente',
        ProposalState.applied => 'aplicado',
        ProposalState.rejected => 'rechazado',
        ProposalState.reverted => 'revertido',
        ProposalState.failed => 'fallido',
      };

  static Color color(ProposalState state) => switch (state) {
        ProposalState.pending => AppColors.neonAmber,
        ProposalState.applied => AppColors.neonGreen,
        ProposalState.rejected => AppColors.textTertiary,
        ProposalState.reverted => AppColors.neonCyan,
        ProposalState.failed => Colors.redAccent,
      };

  @override
  Widget build(BuildContext context) {
    final glow = color(proposal.state);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        gradient: AppGradients.glass,
        border: Border.all(color: glow.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.12),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  proposal.prompt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                  color: glow.withValues(alpha: 0.15),
                  border: Border.all(color: glow.withValues(alpha: 0.4)),
                ),
                child: Text(
                  label(proposal.state),
                  style: TextStyle(
                    color: glow,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final edit in proposal.edits) _editCard(context, edit),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (proposal.state == ProposalState.pending) ...[
                if (onAccept != null)
                  FilledButton(
                    key: const Key('diff-accept'),
                    onPressed: onAccept,
                    child: const Text('Aceptar'),
                  ),
                const SizedBox(width: AppSpacing.sm),
                if (onReject != null)
                  OutlinedButton(
                    key: const Key('diff-reject'),
                    onPressed: onReject,
                    child: const Text('Rechazar'),
                  ),
              ],
              if (proposal.state == ProposalState.applied && onRevert != null)
                OutlinedButton(
                  key: const Key('diff-revert'),
                  onPressed: onRevert,
                  child: const Text('Revertir'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _editCard(BuildContext context, FileEdit edit) {
    final icon = edit.isCreation
        ? Icons.add_circle_outline
        : edit.isDeletion
            ? Icons.delete_outline
            : Icons.edit_outlined;
    final iconColor = edit.isCreation
        ? AppColors.neonGreen
        : edit.isDeletion
            ? Colors.redAccent
            : AppColors.neonCyan;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card - 4),
        color: AppColors.bgPanel,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  edit.path,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
              if (edit.isCreation)
                const Text('nuevo',
                    style: TextStyle(
                        color: AppColors.neonGreen, fontSize: 11))
              else if (edit.isDeletion)
                const Text('borrado',
                    style: TextStyle(color: Colors.redAccent, fontSize: 11)),
            ],
          ),
          if (!edit.isCreation) ...[
            const SizedBox(height: AppSpacing.xs),
            _linesPanel(edit.before, removed: true),
          ],
          if (!edit.isDeletion) ...[
            const SizedBox(height: AppSpacing.xs),
            _linesPanel(edit.after, removed: false),
          ],
        ],
      ),
    );
  }

  Widget _linesPanel(String content, {required bool removed}) {
    if (content.isEmpty) return const SizedBox.shrink();
    final color = removed ? Colors.redAccent : AppColors.neonGreen;
    final prefix = removed ? '− ' : '＋ ';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.input - 4),
        color: color.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in content.split('\n'))
            if (line.isNotEmpty)
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: prefix, style: TextStyle(color: color)),
                    TextSpan(
                      text: line,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                ),
              ),
        ],
      ),
    );
  }
}