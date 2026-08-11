import 'dart:convert';

import 'package:canva_core/canva.dart';

class HostRecord {  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String authType; // password | key
  final String? folder;
  final String? color;

  HostRecord({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    this.authType = 'password',
    this.folder,
    this.color,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'port': port,
        'username': username,
        'authType': authType,
        if (folder != null) 'folder': folder,
        if (color != null) 'color': color,
      };

  factory HostRecord.fromJson(Map<String, dynamic> j) => HostRecord(
        id: j['id'] as String,
        name: j['name'] as String,
        host: j['host'] as String,
        port: (j['port'] as num?)?.toInt() ?? 22,
        username: j['username'] as String,
        authType: j['authType'] as String? ?? 'password',
        folder: j['folder'] as String?,
        color: j['color'] as String?,
      );
}

class SessionRecord {
  final String id;
  final String hostId;
  final String title;
  final int createdAt;

  SessionRecord({
    required this.id,
    required this.hostId,
    required this.title,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'hostId': hostId,
        'title': title,
        'createdAt': createdAt,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> j) => SessionRecord(
        id: j['id'] as String,
        hostId: j['hostId'] as String,
        title: j['title'] as String,
        createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
      );
}

class SyncSnapshot {
  int version;
  List<HostRecord> hosts;
  List<CanvaNode> nodes;
  List<CanvaEdge> edges;
  List<SessionRecord> sessions;

  SyncSnapshot({
    required this.version,
    required this.hosts,
    required this.nodes,
    required this.edges,
    required this.sessions,
  });

  factory SyncSnapshot.empty() => SyncSnapshot(
        version: 0,
        hosts: [],
        nodes: [],
        edges: [],
        sessions: [],
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'hosts': hosts.map((h) => h.toJson()).toList(),
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
      };

  factory SyncSnapshot.fromJson(Map<String, dynamic> j) => SyncSnapshot(
        version: (j['version'] as num?)?.toInt() ?? 0,
        hosts: (j['hosts'] as List? ?? [])
            .map((e) => HostRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        nodes: (j['nodes'] as List? ?? [])
            .map((e) => CanvaNode.fromJson(e as Map<String, dynamic>))
            .toList(),
        edges: (j['edges'] as List? ?? [])
            .map((e) => CanvaEdge.fromJson(e as Map<String, dynamic>))
            .toList(),
        sessions: (j['sessions'] as List? ?? [])
            .map((e) => SessionRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String encode() => jsonEncode(toJson());

  static SyncSnapshot decode(String raw) =>
      SyncSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  SyncSnapshot copyWith({int? version}) => SyncSnapshot(
        version: version ?? this.version,
        hosts: hosts,
        nodes: nodes,
        edges: edges,
        sessions: sessions,
      );
}
