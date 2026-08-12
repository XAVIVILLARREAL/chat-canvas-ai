// Verificación del fixture vibecoding SIN dependencias externas ni
// package_config (corre con `dart run test/todo_check.dart`):
// imprime TODO_TEST_OK si `duplicate` quedó implementada.
// Nota: no se llama *_test.dart a propósito — flutter test descubriría este
// archivo como parte de la suite de la app (rompería CI).
// El import relativo a lib/ es intencional (fixture sin pubspec ni
// package_config): ignore del lint que asume estructura de package.
import 'dart:io';

// ignore: avoid_relative_lib_imports
import '../lib/todo.dart';

void main() {
  if (duplicate(2) != 4) {
    throw StateError('duplicate(2) debería ser 4, era ${duplicate(2)}');
  }
  stdout.writeln('TODO_TEST_OK');
}
