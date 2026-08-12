import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Cristal translúcido con blur y borde de luz en la esquina superior.
/// USO: paneles que cambian poco (header, diálogos, tarjetas fijas).
/// No usar dentro de listas con scroll infinito (BackdropFilter es costoso).
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadii.panel,
    this.glow,
    this.blur = 14,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? glow;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(color: const Color(0x22FFFFFF), width: 1);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: glow != null
            ? [
                BoxShadow(
                  color: glow!.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius - 1),
              gradient: AppGradients.glass,
              border: Border(
                top: BorderSide(color: AppColors.edgeLight, width: 1),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
