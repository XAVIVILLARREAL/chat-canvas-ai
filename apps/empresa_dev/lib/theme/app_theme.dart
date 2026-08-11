import 'package:flutter/material.dart';

/// Tokens de color del lenguaje visual "Glassmorphism Neón" (SDD-114).
/// Paleta de luz semilla — todo color de la UI debe salir de aquí o
/// combinarse con alphas de estos valores.
abstract final class AppColors {
  static const bgBase = Color(0xFF0F172A);
  static const bgPanel = Color(0x0FFFFFFF); // white 6%
  static const bgPanelHi = Color(0x1AFFFFFF); // white 10%
  static const neonCyan = Color(0xFF22D3EE);
  static const neonViolet = Color(0xFFA855F7);
  static const neonGreen = Color(0xFF4ADE80);
  static const edgeLight = Color(0xD9FFFFFF); // white 85%
  static const grid = Color(0x0FFFFFFF); // white 6%
  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white54;
}

/// Radii consistentes del sistema de cristal.
abstract final class AppRadii {
  static const panel = 20.0;
  static const card = 16.0;
  static const input = 12.0;
  static const chip = 8.0;
}

/// Espaciados base.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

/// Curvas de animación del sistema (≤350ms, fluido).
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 200);
  static const base = Duration(milliseconds: 300);
  static const easeOutCubic = Curves.easeOutCubic;
  static const elasticOut = Curves.elasticOut;
}

/// Tema oscuro futurista. Sustituye el `fromSeed` por defecto.
ThemeData buildFuturisticTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.neonCyan,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.neonCyan,
    secondary: AppColors.neonViolet,
    surface: AppColors.bgBase,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bgBase,
    splashFactory: InkRipple.splashFactory,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.neonCyan,
      selectionColor: Color(0x5522D3EE),
      selectionHandleColor: AppColors.neonCyan,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgPanel,
      hintStyle: const TextStyle(color: Colors.white38),
      labelStyle: const TextStyle(color: Colors.white54),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.2),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.bgPanel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.bgBase,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.panel),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.bgPanelHi,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
    ),
  );
}
