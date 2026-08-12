import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Hoja inferior de cristal con borde de luz y glow neón opcional.
/// Sustituye los bottom sheets planos (directiva Glassmorphism Neón).
class NeonSheet extends StatelessWidget {
  const NeonSheet({
    super.key,
    required this.child,
    this.glow,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
  });

  final Widget child;
  final Color? glow;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadii.panel)),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF21A2742), Color(0xF50F172A)],
          ),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: glow != null
              ? [
                  BoxShadow(
                    color: glow!.withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: SingleChildScrollView(child: child),
      ),
    );
  }
}

/// Muestra un bottom sheet de cristal. Devuelve el resultado de la hoja.
Future<T?> showNeonSheet<T>({
  required BuildContext context,
  required Widget child,
  Color? glow,
  bool isScrollControlled = false,
  bool useSafeArea = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    showDragHandle: true,
    builder: (ctx) => NeonSheet(glow: glow, child: child),
  );
}

/// Fila de acción estándar dentro de una hoja/canva (icono + título + subtítulo).
class NeonSheetTile extends StatelessWidget {
  const NeonSheetTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadii.input),
          border: Border.all(color: iconColor.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
      onTap: onTap,
    );
  }
}
