import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:agent_core/agent.dart';

class AgentStore {
  final Directory? baseDir;

  AgentStore({this.baseDir});

  Future<File> _file() async {
    if (baseDir != null) return File('${baseDir!.path}/agent_sessions.json');
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/agent_sessions.json');
  }

  Future<List<AgentSession>> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return [];
      final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return (json['sessions'] as List? ?? [])
          .map((e) => AgentSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<AgentSession> sessions) async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode({
        'sessions': sessions.map((s) => s.toJson()).toList(),
      }));
    } catch (_) {}
  }

  Future<AgentSession> getOrCreate(String agentName) async {
    final sessions = await load();
    for (final s in sessions) {
      if (s.agentName == agentName) return s;
    }
    final s = AgentSession(
      id: 'a${DateTime.now().microsecondsSinceEpoch}',
      agentName: agentName,
    );
    await save([...sessions, s]);
    return s;
  }

  Future<void> append(AgentSession session, AgentMessage message) async {
    final sessions = await load();
    final updated = <AgentSession>[];
    var found = false;
    for (final s in sessions) {
      if (s.id == session.id) {
        updated.add(s.copyWith(messages: [...s.messages, message]));
        found = true;
      } else {
        updated.add(s);
      }
    }
    if (!found) {
      updated.add(session.copyWith(messages: [...session.messages, message]));
    }
    await save(updated);
  }
}