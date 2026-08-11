import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:agent_core/agent.dart';
import 'package:empresa_dev/services/evidence_store.dart';

void main() {
  late Directory tempDir;
  late EvidenceStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('evidence_test');
    store = EvidenceStore(baseDir: tempDir);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('EvidenceStore', () {
    test('formatName genera nombre con timestamp y agente', () {
      final name = store.formatName(DateTime(2026, 8, 10, 21, 30, 0), 'dev');
      expect(name, '2026-08-10_213000_dev.md');
    });

    test('save escribe el .md con prompt y respuesta', () async {
      final session = AgentSession(
        id: 'a1',
        agentName: 'dev',
        messages: [
          AgentMessage(role: AgentRole.user, text: 'hola', at: DateTime(2026, 8, 10, 21, 30)),
          AgentMessage(role: AgentRole.assistant, text: 'respuesta del agente', at: DateTime(2026, 8, 10, 21, 31)),
        ],
      );
      final path = await store.save(session, prompt: 'hola');
      expect(path, isNotNull);
      final content = await File(path!).readAsString();
      expect(content, contains('# Agente dev'));
      expect(content, contains('hola'));
      expect(content, contains('respuesta del agente'));
    });

    test('save con respuesta vacía no escribe', () async {
      final session = AgentSession(
        id: 'a2',
        agentName: 'dev',
        messages: [
          AgentMessage(role: AgentRole.user, text: 'x', at: DateTime(2026)),
        ],
      );
      final path = await store.save(session, prompt: 'x');
      expect(path, isNull);
    });

    test('list devuelve registros descendentes', () async {
      final s = AgentSession(
        id: 'a3',
        agentName: 'dev',
        messages: [
          AgentMessage(role: AgentRole.user, text: 'p1', at: DateTime(2026, 8, 10, 10)),
          AgentMessage(role: AgentRole.assistant, text: 'r1', at: DateTime(2026, 8, 10, 10, 1)),
        ],
      );
      await store.save(s, prompt: 'p1');
      await store.save(s, prompt: 'p2');

      final list = await store.list();
      expect(list.length, 2);
      expect(list.first.prompt, 'p2');
      expect(list.last.prompt, 'p1');
    });
  });
}