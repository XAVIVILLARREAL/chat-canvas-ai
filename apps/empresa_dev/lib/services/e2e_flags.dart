import 'package:flutter/rendering.dart';

/// Flag de compilación para el build E2E web (`--dart-define=E2E_WEB=true`).
/// Activa el árbol de semántica de Flutter: sin él, Flutter web renderiza en
/// canvas y el DOM no expone botones accesibles para Playwright.
const bool e2eWebEnabled = bool.fromEnvironment('E2E_WEB');

/// Habilita la semántica solo cuando el build E2E web lo pide. `enabled`
/// inyectable para tests (el flag es const de compilación).
void ensureE2ESemantics({bool? enabled}) {
  final on = enabled ?? e2eWebEnabled;
  if (on) {
    SemanticsBinding.instance.ensureSemantics();
  }
}
