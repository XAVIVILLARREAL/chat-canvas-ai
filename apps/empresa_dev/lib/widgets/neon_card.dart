import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tarjeta con cristal + glow neón opcional (estado activo/conectado).
/// El glow usa BoxShadow (barato), NO BackdropFilter.
/// Hover en desktop intensifica el borde y el glow; el tap escala sutilmente.
/// El borde es uniforme (BoxDecoration) y la "luz de arriba" se pinta como
/// una línea de gradiente superpuesta (evita el assert de Border no uniforme).
class NeonCard extends StatefulWidget {
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
  State<NeonCard> createState() => _NeonCardState();
}

class _NeonCardState extends State<NeonCard> {
  bool _hovered = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.glow;
    final showGlow = glowColor != null;
    final edgeColor = showGlow
        ? glowColor.withValues(alpha: _hovered ? 0.5 : 0.35)
        : Colors.white.withValues(alpha: _hovered ? 0.22 : 0.09);

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.easeOutCubic,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: edgeColor, width: 1),
              boxShadow: showGlow
                  ? [
                      BoxShadow(
                        color: glowColor.withValues(
                            alpha: _hovered ? 0.35 : 0.22),
                        blurRadius: _hovered ? 26 : 18,
                        spreadRadius: _hovered ? 1 : 0,
                      ),
                    ]
                  : _hovered
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 18,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
            ),
            child: widget.child,
          ),
          // "Luz que entra por arriba": línea de gradiente en el borde superior.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: AppMotion.fast,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      (showGlow
                              ? glowColor
                              : Colors.white)
                          .withValues(alpha: _hovered ? 0.9 : 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.onTap == null) return content;

    content = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: content,
    );

    return Listener(
      onPointerDown: (_) => _down = true,
      onPointerUp: (_) => _down = false,
      onPointerCancel: (_) => _down = false,
      child: AnimatedScale(
        duration: AppMotion.fast,
        curve: AppMotion.easeOutCubic,
        scale: _down ? 0.985 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadii.card),
            splashColor:
                (glowColor ?? AppColors.neonCyan).withValues(alpha: 0.08),
            highlightColor: Colors.transparent,
            child: content,
          ),
        ),
      ),
    );
  }
}
