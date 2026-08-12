import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:empresa_dev/services/e2e_flags.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('e2eWebEnabled es bool (const de compilación, default false)', () {
    expect(e2eWebEnabled, isA<bool>());
    expect(e2eWebEnabled, isFalse); // sin --dart-define en tests
  });

  test('ensureE2ESemantics() sin flag usa el const (off en tests)', () {
    ensureE2ESemantics();
    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);
  });

  // NOTA: el estado de semántica es global y solo se enciende una vez por
  // proceso; los casos "off" van ANTES del caso "on".
  test('ensureE2ESemantics(enabled: false) no activa nada', () {
    ensureE2ESemantics(enabled: false);
    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);
  });

  test('ensureE2ESemantics(enabled: true) activa el árbol de semántica', () {
    ensureE2ESemantics(enabled: true);
    expect(SemanticsBinding.instance.semanticsEnabled, isTrue);
  });
}
