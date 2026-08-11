import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Fondo futurista con tech-grid de puntos + halos de luz cian/violeta.
/// Poner UNA VEZ por screen (es costoso; nunca en listas).
class NeonBackdrop extends StatelessWidget {
  const NeonBackdrop({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF0B1220)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _TechGrid(),
          const _Halo(top: -180, left: -120, color: AppColors.neonCyan),
          const _Halo(bottom: -220, right: -160, color: AppColors.neonViolet),
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// Rejilla de puntos sutil (holograma).
class _TechGrid extends StatelessWidget {
  const _TechGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x14FFFFFF) // white 8%
      ..strokeWidth = 1;
    const spacing = 42.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawCircle(Offset(x, 0), 0.8, paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Halo de luz difusa de color.
class _Halo extends StatelessWidget {
  const _Halo({this.top, this.left, this.bottom, this.right, required this.color});

  final double? top;
  final double? left;
  final double? bottom;
  final double? right;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      bottom: bottom,
      right: right,
      child: Container(
        width: 320,
        height: 320,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
