import 'dart:convert';

class DevSession {
  final String id;
  String title;
  final String hostId; // referencia al SshHost (por name)
  bool open;

  DevSession({
    required this.id,
    required this.title,
    required this.hostId,
    this.open = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'hostId': hostId,
        'open': open,
      };

  factory DevSession.fromJson(Map<String, dynamic> j) => DevSession(
        id: j['id'] as String,
        title: j['title'] as String,
        hostId: j['hostId'] as String,
        open: j['open'] as bool? ?? false,
      );

  String encode() => jsonEncode(toJson());
}
