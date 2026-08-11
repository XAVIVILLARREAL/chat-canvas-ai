import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/xterm.dart';

/// Aisla el camino de input del terminal: tecla -> TerminalView -> onOutput.
/// Si el teclado del escritorio no envia las letras a onOutput, el shell
/// nunca recibe lo que el usuario escribe (bug: "no puedo escribir en la
/// terminal").
void main() {
  testWidgets('TerminalView: el teclado envia letras a onOutput', (tester) async {
    final out = StringBuffer();
    final term = Terminal(maxLines: 100, onOutput: out.write);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: TerminalView(term, autofocus: true, hardwareKeyboardOnly: true)),
    ));
    await tester.pump();

    for (final ch in 'whoami'.split('')) {
      await tester.sendKeyEvent(_keyForChar(ch), character: ch);
      await tester.pump();
    }

    expect(out.toString(), contains('whoami'),
        reason: 'teclear letras debe producir output hacia el shell');
  });
}

LogicalKeyboardKey _keyForChar(String ch) {
  switch (ch) {
    case 'w':
      return LogicalKeyboardKey.keyW;
    case 'h':
      return LogicalKeyboardKey.keyH;
    case 'o':
      return LogicalKeyboardKey.keyO;
    case 'a':
      return LogicalKeyboardKey.keyA;
    case 'm':
      return LogicalKeyboardKey.keyM;
    case 'i':
      return LogicalKeyboardKey.keyI;
  }
  return LogicalKeyboardKey.keyW;
}
