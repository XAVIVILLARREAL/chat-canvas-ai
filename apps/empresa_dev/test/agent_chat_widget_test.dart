import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agent_core/agent.dart';
import 'package:empresa_dev/screens/agent_chat_screen.dart';
import 'package:empresa_dev/services/agent_runner.dart';

class FakeAgentRunner implements AgentRunner {
  final List<String> prompts = [];
  final List<StreamController<AgentRunLine>> _controllers = [];

  @override
  Stream<AgentRunLine> run(String prompt, {String? cwd}) {
    prompts.add(prompt);
    final controller = StreamController<AgentRunLine>();
    _controllers.add(controller);
    return controller.stream;
  }

  void emitLine(AgentRunLine line) {
    final c = _controllers.lastOrNull;
    if (c != null) c.add(line);
  }

  void close() {
    for (final c in _controllers) {
      if (!c.isClosed) c.close();
    }
  }
}

void main() {
  late FakeAgentRunner runner;
  late AgentSession session;

  setUp(() {
    runner = FakeAgentRunner();
    session = AgentSession(id: 'a1', agentName: 'dev', messages: []);
  });

  tearDown(() => runner.close());

  Widget buildApp() => MaterialApp(
        home: AgentChatScreen(
          session: session,
          store: (_) async {},
          runner: runner,
        ),
      );

  testWidgets('envía el prompt y muestra la respuesta del asistente', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.enterText(find.byType(TextField), 'hola agente');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(runner.prompts, ['hola agente']);
    expect(find.text('hola agente'), findsOneWidget);

    runner.emitLine(const AgentRunLine(content: 'hola, soy el agente', isError: false));
    runner.close();
    await tester.pump();

    expect(find.text('hola, soy el agente'), findsOneWidget);
  });

  testWidgets('deshabilita el input mientras el agente corre', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.enterText(find.byType(TextField), 'pregunta');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.enabled, isFalse);

    runner.emitLine(const AgentRunLine(content: 'respuesta', isError: false));
    runner.close();
    await tester.pumpAndSettle();

    final inputAfter = tester.widget<TextField>(find.byType(TextField));
    expect(inputAfter.enabled, isTrue);
  });

  testWidgets('muestra error si el agente falla', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.enterText(find.byType(TextField), 'rompe');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    runner.emitLine(const AgentRunLine(content: 'opencode no encontrado', isError: true));
    runner.close();
    await tester.pumpAndSettle();

    expect(find.text('opencode no encontrado'), findsOneWidget);
  });
}