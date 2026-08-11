import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:ssh_core/session.dart';

class SessionsStore {
  List<DevSession> _sessions = [];
  String _lastTab = 'hosts'; // 'hosts' | 'canva'

  List<DevSession> get sessions => List.unmodifiable(_sessions);
  String get lastTab => _lastTab;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/sessions_state.json');
  }

  Future<void> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return;
      final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      _sessions = (json['sessions'] as List? ?? [])
          .map((e) => DevSession.fromJson(e as Map<String, dynamic>))
          .toList();
      _lastTab = json['lastTab'] as String? ?? 'hosts';
    } catch (_) {
      _sessions = [];
    }
  }

  Future<void> save() async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode({
        'sessions': _sessions.map((s) => s.toJson()).toList(),
        'lastTab': _lastTab,
      }));
    } catch (_) {}
  }

  Future<void> addSession(String hostId, String title) async {
    _sessions.add(DevSession(
      id: 's${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      hostId: hostId,
      open: true,
    ));
    await save();
  }

  Future<void> removeSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
    await save();
  }

  Future<void> moveSession(int from, int to) async {
    if (from < 0 || from >= _sessions.length || to < 0 || to >= _sessions.length) return;
    final s = _sessions.removeAt(from);
    _sessions.insert(to, s);
    await save();
  }

  Future<void> setLastTab(String tab) async {
    _lastTab = tab;
    await save();
  }

  bool hasSessionForHost(String hostId) =>
      _sessions.any((s) => s.hostId == hostId && s.open);
}
