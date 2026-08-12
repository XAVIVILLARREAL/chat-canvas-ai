import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Diálogo de cristal con borde de luz y glow neón opcional.
/// Sustituye los `AlertDialog` planos (directiva Glassmorphism Neón).
///
/// No usa BackdropFilter: el fondo es un degradado oscuro translúcido con
/// borde de luz superior + glow, fiable dentro del overlay del Navigator.
class NeonDialog extends StatelessWidget {
  const NeonDialog({
    super.key,
    required this.child,
    this.glow,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.radius = AppRadii.panel,
  });

  final Widget child;
  final Color? glow;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      constraints: const BoxConstraints(maxWidth: 520),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF21A2742), Color(0xF20F172A)],
        ),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 32,
            spreadRadius: 2,
          ),
          if (glow != null)
            BoxShadow(
              color: glow!.withValues(alpha: 0.18),
              blurRadius: 28,
              spreadRadius: 0,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.edgeLight, width: 1)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Muestra un diálogo de cristal con entrada animada (scale + fade).
/// Usa `showDialog` + `Dialog` estándar: en Flutter web, el `Dialog` de
/// Material expone el árbol de semántica completo (campo + botones), mientras
/// `showGeneralDialog` con transitionBuilder custom lo rompe (solo el título
/// queda accesible — rompía el E2E Playwright y la accesibilidad real).
Future<T?> showNeonDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? glow,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: NeonDialog(glow: glow, child: builder(ctx)),
    ),
  );
}
