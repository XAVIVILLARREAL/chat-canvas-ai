import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Cliente de proxy SSH (Etapa 8.4): habla con el hub, pide abrir un forward
/// con un token efímero y relaya texto. La llave nunca llega aquí.
class SshProxyClient {
  WebSocket? _ws;
  final StreamController<String> _output = StreamController<String>();
  String? _hostId;
  bool _opened = false;

  bool get opened => _opened;

  Stream<String> get output => _output.stream;

  /// Conecta al hub y se autentica con el token del hub.
  Future<bool> connect(String url, String token) async {
    final wsUrl = url.replaceFirst('http', 'ws');
    try {
      final ws = await WebSocket.connect('$wsUrl/ws', headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 8));
      _ws = ws;
      ws.listen(
        _onMessage,
        onDone: () {
          _ws = null;
          _opened = false;
        },
        onError: (_) {
          _ws = null;
          _opened = false;
        },
      );
      return true;
    } catch (_) {
      _ws = null;
      return false;
    }
  }

  void _onMessage(dynamic data) {
    try {
      final msg = jsonDecode(data as String) as Map<String, dynamic>;
      if (msg['type'] != 'ssh') return;
      switch (msg['action']) {
        case 'opened':
          _opened = true;
          break;
        case 'data':
          _output.add(msg['data'] as String? ?? '');
          break;
        case 'error':
          _opened = false;
          _output.addError(StateError(msg['message'] as String? ?? 'error'));
          break;
      }
    } catch (_) {
      // ignorar
    }
  }

  /// Pide abrir un forward con un token efímero del proxy. Devuelve true si el
  /// hub confirmó; los datos llegan por [output].
  Future<bool> open(String hostId, String proxyToken) async {
    final ws = _ws;
    if (ws == null) return false;
    _hostId = hostId;
    _opened = false;
    ws.add(jsonEncode({
      'type': 'ssh',
      'action': 'open',
      'hostId': hostId,
      'token': proxyToken,
    }));
    final deadline = DateTime.now().add(const Duration(seconds: 8));
    while (!_opened && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    return _opened;
  }

  void write(String data) {
    _ws?.add(jsonEncode({
      'type': 'ssh',
      'action': 'write',
      'hostId': _hostId ?? '',
      'data': data,
    }));
  }

  Future<void> close() async {
    _ws?.add(jsonEncode(
        {'type': 'ssh', 'action': 'close', 'hostId': _hostId ?? ''}));
    try {
      await _ws?.close();
    } catch (_) {}
    _ws = null;
    _opened = false;
  }
}
