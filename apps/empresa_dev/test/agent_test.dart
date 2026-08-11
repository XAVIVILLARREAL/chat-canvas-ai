import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:agent_core/agent.dart';
import 'package:empresa_dev/services/agent_store.dart';

void main() {
  group('AgentMessage', () {
    test('serializa y deserializa todos los roles', () {
      for (final role in AgentRole.values) {
        final m = AgentMessage(role: role, text: 'hola', at: DateTime(2026, 8, 10));
        final back = AgentMessage.fromJson(m.toJson());
        expect(back.role, role);
        expect(back.text, 'hola');
        expect(back.at, DateTime(2026, 8, 10));
      }
    });

    test('deserializa JSON sin timestamp (tolerancia)', () {
      final m = AgentMessage.fromJson({'role': 'user', 'text': 'x'});
      expect(m.role, AgentRole.user);
      expect(m.text, 'x');
    });
  });

  group('AgentSession', () {
    test('roundtrip JSON preserva mensajes y agente', () {
      final s = AgentSession(
        id: 'a1',
        agentName: 'dev',
        messages: [
          AgentMessage(role: AgentRole.user, text: 'hola', at: DateTime(2026, 8, 10)),
          AgentMessage(role: AgentRole.assistant, text: 'respuesta', at: DateTime(2026, 8, 10, 0, 1)),
        ],
      );
      final json = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;
      final back = AgentSession.fromJson(json);
      expect(back.id, 'a1');
      expect(back.agentName, 'dev');
      expect(back.messages.length, 2);
      expect(back.messages.first.role, AgentRole.user);
      expect(back.messages.last.text, 'respuesta');
    });

    test('copyWith agrega mensaje preservando el resto', () {
      final s = AgentSession(id: 'a1', agentName: 'dev', messages: []);
      final m = AgentMessage(role: AgentRole.user, text: 'x', at: DateTime(2026));
      final next = s.copyWith(messages: [...s.messages, m]);
      expect(next.messages.length, 1);
      expect(next.id, 'a1');
    });
  });

  group('AgentStore', () {
    late Directory tempDir;
    late AgentStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('agent_store_test');
      store = AgentStore(baseDir: tempDir);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('load devuelve vacío cuando no existe archivo', () async {
      final sessions = await store.load();
      expect(sessions, isEmpty);
    });

    test('save/load roundtrip', () async {
      final s = AgentSession(
        id: 'a1',
        agentName: 'dev',
        messages: [AgentMessage(role: AgentRole.user, text: 'hola', at: DateTime(2026))],
      );
      await store.save([s]);
      final back = await store.load();
      expect(back.length, 1);
      expect(back.first.agentName, 'dev');
      expect(back.first.messages.first.text, 'hola');
    });

    test('getOrCreate reusa la sesión del mismo agente', () async {
      final first = await store.getOrCreate('dev');
      final second = await store.getOrCreate('dev');
      expect(first.id, second.id);
      final other = await store.getOrCreate('otro');
      expect(other.id, isNot(first.id));
    });

    test('append guarda el mensaje en disco', () async {
      final s = await store.getOrCreate('dev');
      await store.append(s, AgentMessage(role: AgentRole.user, text: 'pregunta', at: DateTime(2026)));
      final back = await store.load();
      expect(back.first.messages.length, 1);
      expect(back.first.messages.first.text, 'pregunta');
    });
  });
}
