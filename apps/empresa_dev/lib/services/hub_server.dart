import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/sync_snapshot.dart';

class HubServer {
  HttpServer? _server;
  final List<WebSocket> _clients = [];
  String _token = '';
  SyncSnapshot _snapshot = SyncSnapshot.empty();
  int _port = 0;
  String _ip = '0.0.0.0';

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
          onDone: () => _clients.remove(ws),
          onError: (_) => _clients.remove(ws),
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
      }
    } catch (_) {
      // ignorar
    }
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
