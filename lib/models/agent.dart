import 'dart:convert';

enum AgentRole { user, assistant, error }

class AgentMessage {
  final AgentRole role;
  final String text;
  final DateTime at;

  const AgentMessage({
    required this.role,
    required this.text,
    required this.at,
  });

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'text': text,
        'at': at.toIso8601String(),
      };

  factory AgentMessage.fromJson(Map<String, dynamic> j) => AgentMessage(
        role: AgentRole.values.firstWhere(
          (r) => r.name == j['role'],
          orElse: () => AgentRole.user,
        ),
        text: j['text'] as String? ?? '',
        at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class AgentSession {
  final String id;
  final String agentName;
  final List<AgentMessage> messages;

  const AgentSession({
    required this.id,
    required this.agentName,
    this.messages = const [],
  });

  AgentSession copyWith({List<AgentMessage>? messages}) => AgentSession(
        id: id,
        agentName: agentName,
        messages: messages ?? this.messages,
      );

  static final Map<String, AgentSession> _cache = {};

  static AgentSession orCreate(String agentName) {
    final cached = _cache[agentName];
    if (cached != null) return cached;
    final s = AgentSession(
      id: 'a${DateTime.now().microsecondsSinceEpoch}',
      agentName: agentName,
    );
    _cache[agentName] = s;
    return s;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'agentName': agentName,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory AgentSession.fromJson(Map<String, dynamic> j) => AgentSession(
        id: j['id'] as String,
        agentName: j['agentName'] as String? ?? 'dev',
        messages: (j['messages'] as List? ?? [])
            .map((e) => AgentMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String encode() => jsonEncode(toJson());
}