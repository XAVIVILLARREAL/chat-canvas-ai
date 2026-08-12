import 'package:flutter/material.dart';

/// Tokens de color del lenguaje visual "Glassmorphism Neón" (SDD-114).
/// Paleta de luz semilla — todo color de la UI debe salir de aquí o
/// combinarse con alphas de estos valores.
abstract final class AppColors {
  static const bgBase = Color(0xFF0F172A);
  static const bgDeep = Color(0xFF0B1220);
  static const bgElevated = Color(0xFF111C33);
  static const bgPanel = Color(0x0FFFFFFF); // white 6%
  static const bgPanelHi = Color(0x1AFFFFFF); // white 10%
  static const neonCyan = Color(0xFF22D3EE);
  static const neonViolet = Color(0xFFA855F7);
  static const neonGreen = Color(0xFF4ADE80);
  static const neonAmber = Color(0xFFFBBF24);
  static const neonPink = Color(0xFFF472B6);
  static const edgeLight = Color(0xD9FFFFFF); // white 85%
  static const grid = Color(0x0FFFFFFF); // white 6%
  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white70;
  static const textTertiary = Colors.white54;
  static const textFaint = Colors.white38;
  static const border = Color(0x2BFFFFFF); // white 17%
  static const borderStrong = Color(0x3DFFFFFF); // white 24%
}

/// Gradientes reutilizables del sistema.
abstract final class AppGradients {
  static const glass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1FFFFFFF), // white 12% arriba
      Color(0x0FFFFFFF), // white 6%
      Color(0x0AFFFFFF), // white 4% abajo
    ],
  );

  static const neon = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.neonCyan, AppColors.neonViolet],
  );

  static const neonGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.neonCyan, AppColors.neonGreen],
  );

  static const hostAvatar = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5E9), AppColors.neonViolet],
  );
}

/// Sombras de luz (glow) del sistema — siempre BoxShadow baratos.
abstract final class AppGlow {
  static List<BoxShadow> cyan({double strength = 0.35, double blur = 24}) => [
        BoxShadow(
          color: AppColors.neonCyan.withValues(alpha: strength),
          blurRadius: blur,
          spreadRadius: 1,
        ),
      ];

  static List<BoxShadow> violet({double strength = 0.35, double blur = 24}) => [
        BoxShadow(
          color: AppColors.neonViolet.withValues(alpha: strength),
          blurRadius: blur,
          spreadRadius: 1,
        ),
      ];

  static List<BoxShadow> green({double strength = 0.35, double blur = 18}) => [
        BoxShadow(
          color: AppColors.neonGreen.withValues(alpha: strength),
          blurRadius: blur,
          spreadRadius: 0,
        ),
      ];
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
  static const easeOutBack = Curves.easeOutBack;
  static const elasticOut = Curves.elasticOut;
}

/// Borde "luz por arriba" para cristales (1px, blanco alto alpha).
BoxDecoration neonBorder({double radius = AppRadii.card}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: AppGradients.glass,
    border: Border.all(color: AppColors.border, width: 1),
  );
}

/// Tema oscuro futurista. Sustituye el `fromSeed` por defecto y aplica el
/// lenguaje visual Glassmorphism Neón de forma global a todos los widgets.
ThemeData buildFuturisticTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.neonCyan,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.neonCyan,
    secondary: AppColors.neonViolet,
    surface: AppColors.bgBase,
    error: Colors.redAccent,
    onPrimary: const Color(0xFF062A33),
    onSecondary: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bgBase,
    canvasColor: AppColors.bgBase,
    splashFactory: InkRipple.splashFactory,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.neonCyan,
      selectionColor: Color(0x5522D3EE),
      selectionHandleColor: AppColors.neonCyan,
    ),

    // Tipografía base
    textTheme: const TextTheme(
      titleLarge: TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(
          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
      bodySmall: TextStyle(color: Colors.white70, fontSize: 12),
      labelLarge: TextStyle(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
    ),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgPanel,
      hintStyle: const TextStyle(color: Colors.white38),
      labelStyle: const TextStyle(color: Colors.white54),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    ),

    // Botones
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return AppColors.bgElevated;
          return AppColors.neonCyan;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return Colors.white24;
          return const Color(0xFF062A33);
        }),
        elevation: WidgetStateProperty.all(0),
        shadowColor:
            WidgetStateProperty.all(AppColors.neonCyan.withValues(alpha: 0.5)),
        textStyle: WidgetStatePropertyAll(
            const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.input))),
        padding: WidgetStatePropertyAll(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(AppColors.neonCyan),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(color: Colors.white12);
          }
          return BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.6));
        }),
        textStyle: WidgetStatePropertyAll(
            const TextStyle(fontWeight: FontWeight.w600)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.input))),
        padding: WidgetStatePropertyAll(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(AppColors.neonCyan),
        textStyle: WidgetStatePropertyAll(
            const TextStyle(fontWeight: FontWeight.w600)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor:
            const WidgetStatePropertyAll(AppColors.textSecondary),
        iconSize: const WidgetStatePropertyAll(20),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.bgElevated,
      foregroundColor: AppColors.neonCyan,
      elevation: 0,
      shape: CircleBorder(),
    ),

    // AppBar translúcida (el fondo corre por detrás)
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Colors.white,
      titleTextStyle:
          TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      iconTheme: IconThemeData(color: AppColors.textSecondary),
    ),

    // Tarjetas
    cardTheme: CardThemeData(
      color: AppColors.bgPanel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: const BorderSide(color: AppColors.border),
      ),
    ),

    // Diálogos y sheets de cristal (transparentes → wrapper glass)
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.panel),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      modalBackgroundColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: Colors.white38,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.panel)),
      ),
    ),

    // SnackBars flotantes de cristal
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.bgElevated,
      elevation: 0,
      contentTextStyle: const TextStyle(color: Colors.white),
      actionTextColor: AppColors.neonCyan,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: const BorderSide(color: AppColors.border),
      ),
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.bgPanel,
      disabledColor: AppColors.bgPanel,
      selectedColor: AppColors.neonCyan.withValues(alpha: 0.18),
      side: const BorderSide(color: AppColors.border),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
      secondaryLabelStyle: const TextStyle(color: Colors.white70),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.chip)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    ),

    // Control segmentado
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.bgElevated;
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.neonCyan;
          return AppColors.textTertiary;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.5));
          }
          return const BorderSide(color: AppColors.border);
        }),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.input))),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        textStyle: WidgetStatePropertyAll(
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    ),

    // Listas, expansiones, dropdowns
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.textSecondary,
      textColor: Colors.white,
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      iconColor: AppColors.textTertiary,
      collapsedIconColor: AppColors.textFaint,
      textColor: Colors.white,
      collapsedTextColor: Colors.white,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: const TextStyle(color: Colors.white),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.bgElevated),
        side: const WidgetStatePropertyAll(BorderSide(color: AppColors.border)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card))),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: Color(0x14FFFFFF),
      thickness: 1,
      space: 1,
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.neonCyan,
      linearTrackColor: Color(0x1FFFFFFF),
      circularTrackColor: Color(0x1FFFFFFF),
    ),

    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 350),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: AppColors.border),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.neonCyan;
        return Colors.white38;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.neonCyan.withValues(alpha: 0.3);
        }
        return Colors.white12;
      }),
    ),
  );
}
