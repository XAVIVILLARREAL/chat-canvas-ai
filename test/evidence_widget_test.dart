import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/models/agent.dart';
import 'package:empresa_dev/screens/agent_chat_screen.dart';
import 'package:empresa_dev/services/agent_runner.dart';
import 'package:empresa_dev/services/evidence_store.dart';

class _FakeRunner extends AgentRunner {
  @override
  Stream<AgentRunLine> run(String prompt, {String? cwd}) async* {
    yield AgentRunLine('Hola ', isError: false);
    yield AgentRunLine('mundo', isError: false);
  }
}

void main() {
  late Directory tempDir;
  late EvidenceStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('evidence_widget');
    store = EvidenceStore(baseDir: tempDir);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  testWidgets('al terminar la respuesta se escribe evidencia .md', (tester) async {
    final session = AgentSession(
      id: 'w1',
      agentName: 'dev',
      messages: [
        AgentMessage(role: AgentRole.user, text: 'suma 2+2', at: DateTime(2026)),
      ],
    );

    await tester.pumpWidget(MaterialApp(
      home: AgentChatScreen(
        session: session,
        store: (_) async {},
        runner: _FakeRunner(),
        evidenceStore: store,
      ),
    ));

    await tester.enterText(find.byType(TextField), 'suma 2+2');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    final records = await store.list();
    expect(records.length, 1);
    expect(records.first.prompt, 'suma 2+2');
    expect(File(records.first.path).existsSync(), true);
  });

  testWidgets('el botón de evidencia abre la pantalla de lista', (tester) async {
    final session = AgentSession(
      id: 'w2',
      agentName: 'dev',
      messages: [
        AgentMessage(role: AgentRole.user, text: 'hola', at: DateTime(2026)),
      ],
    );

    await tester.pumpWidget(MaterialApp(
      home: AgentChatScreen(
        session: session,
        store: (_) async {},
        runner: _FakeRunner(),
        evidenceStore: store,
      ),
    ));

    await tester.tap(find.byIcon(Icons.description_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Evidencia'), findsOneWidget);
  });
}