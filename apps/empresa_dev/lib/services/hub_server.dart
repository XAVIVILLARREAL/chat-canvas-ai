import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ssh_core/sync_snapshot.dart';
import 'ssh_proxy.dart';

class HubServer {
  HttpServer? _server;
  final List<WebSocket> _clients = [];
  final Map<WebSocket, Map<String, SshForward>> _forwards = {};
  String _token = '';
  SyncSnapshot _snapshot = SyncSnapshot.empty();
  int _port = 0;
  String _ip = '0.0.0.0';

  /// Proxy SSH (Etapa 8.4): si está inyectado, el hub puede abrir forwards con
  /// tokens efímeros — la llave nunca sale del hub.
  SshProxyService? proxy;

  SyncSnapshot get snapshot => _snapshot;
  int get port => _port;
  String get ip => _ip;
  bool get running => _server != null;

  StreamController<SyncSnapshot>? _onChange;

  Stream<SyncSnapshot> get onChange {
    _onChange ??= StreamController<SyncSnapshot>.broadcast();
    return _onChange!.stream;
  }

  Future<void> start({
    required String token,
    required String bindIp,
    required int port,
  }) async {
    _token = token;
    _ip = bindIp;
    _server = await HttpServer.bind(bindIp, port);
    _port = _server!.port;
    _server!.listen(_handleRequest);
  }

  void _handleRequest(HttpRequest req) {
    final auth = req.headers.value('Authorization');
    final tokenOk = auth != null && auth == 'Bearer $_token';
    if (req.uri.path == '/ws') {
      if (!tokenOk) {
        req.response
          ..statusCode = HttpStatus.unauthorized
          ..write('{"error":"token invalido"}');
        req.response.close();
        return;
      }
      WebSocketTransformer.upgrade(req).then((ws) {
        _clients.add(ws);
        ws.listen(
          (data) => _onMessage(ws, data),
          onDone: () => _onClientGone(ws),
          onError: (_) => _onClientGone(ws),
        );
      }).catchError((_) {});
      return;
    }
    _handleHttp(req);
  }

  void _handleHttp(HttpRequest req) {
    final auth = req.headers.value('Authorization');
    final tokenOk = auth != null && auth == 'Bearer $_token';
    if (!tokenOk) {
      req.response
        ..statusCode = HttpStatus.unauthorized
        ..write('{"error":"token invalido"}');
      req.response.close();
      return;
    }

    final path = req.uri.path;
    if (req.method == 'GET' && path == '/api/snapshot') {
      _respondJson(req, _snapshot.toJson());
      return;
    }
    if (req.method == 'POST' && path == '/api/apply') {
      req.listen((data) async {
        try {
          final json = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
          final incoming = SyncSnapshot.fromJson(json);
          // last-write-wins por version
          if (incoming.version > _snapshot.version) {
            _snapshot = incoming;
            _broadcast(_snapshot);
          }
          _respondJson(req, {'ok': true, 'version': _snapshot.version});
        } catch (e) {
          _respondJson(req, {'error': 'payload invalido: $e'}, status: 400);
        }
      });
      return;
    }
    _respondJson(req, {'error': 'not found'}, status: 404);
  }

  void _onMessage(WebSocket ws, dynamic data) {
    try {
      final msg = jsonDecode(data as String) as Map<String, dynamic>;
      if (msg['type'] == 'ping') {
        ws.add(jsonEncode({'type': 'pong'}));
        return;
      }
      if (msg['type'] == 'ssh') {
        _onSshMessage(ws, msg);
      }
    } catch (_) {
      // ignorar
    }
  }

  /// Relay de SSH proxy (Etapa 8.4): open / write / close. El hub abre la
  /// sesión con la llave local y relaya SOLO texto al cliente.
  Future<void> _onSshMessage(WebSocket ws, Map<String, dynamic> msg) async {
    final action = msg['action'] as String? ?? '';
    final hostId = msg['hostId'] as String? ?? '';
    final proxy = this.proxy;
    switch (action) {
      case 'open':
        if (proxy == null) {
          ws.add(jsonEncode(
              {'type': 'ssh', 'action': 'error', 'hostId': hostId, 'message': 'proxy no disponible'}));
          return;
        }
        try {
          final forward =
              await proxy.openForward(hostId, msg['token'] as String? ?? '');
          (_forwards[ws] ??= {})[hostId] = forward;
          forward.output.listen((text) {
            try {
              ws.add(jsonEncode(
                  {'type': 'ssh', 'action': 'data', 'hostId': hostId, 'data': text}));
            } catch (_) {}
          });
          ws.add(jsonEncode({'type': 'ssh', 'action': 'opened', 'hostId': hostId}));
        } catch (e) {
          ws.add(jsonEncode(
              {'type': 'ssh', 'action': 'error', 'hostId': hostId, 'message': '$e'}));
        }
        break;
      case 'write':
        _forwards[ws]?[hostId]?.write(msg['data'] as String? ?? '');
        break;
      case 'close':
        _forwards[ws]?.remove(hostId)?.close();
        break;
    }
  }

  void _onClientGone(WebSocket ws) {
    _clients.remove(ws);
    _forwards.remove(ws)?.forEach((_, f) => f.close());
  }

  /// El hub actualiza su snapshot y propaga a los clientes.
  void updateSnapshot(SyncSnapshot snap) {
    _snapshot = snap;
    _broadcast(_snapshot);
    _onChange?.add(_snapshot);
  }

  void _broadcast(SyncSnapshot snap) {
    final payload = jsonEncode({'type': 'sync', 'data': snap.toJson()});
    for (final ws in List<WebSocket>.from(_clients)) {
      try {
        ws.add(payload);
      } catch (_) {
        _clients.remove(ws);
      }
    }
  }

  void _respondJson(HttpRequest req, Map<String, dynamic> body, {int status = 200}) {
    req.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    req.response.close();
  }

  Future<void> stop() async {
    for (final ws in List<WebSocket>.from(_clients)) {
      try {
        await ws.close();
      } catch (_) {}
    }
    _clients.clear();
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
    _onChange?.close();
    _onChange = null;
  }
}
