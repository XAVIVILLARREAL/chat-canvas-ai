import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tarjeta con cristal + glow neón opcional (estado activo/conectado).
/// El glow usa BoxShadow (barato), NO BackdropFilter.
class NeonCard extends StatelessWidget {
  const NeonCard({
    super.key,
    required this.child,
    this.onTap,
    this.glow,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color = AppColors.bgPanel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? glow;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: const Color(0x22FFFFFF), width: 1),
        boxShadow: glow != null
            ? [
                BoxShadow(
                  color: glow!.withValues(alpha: 0.22),
                  blurRadius: 18,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: content,
      ),
    );
  }
}
