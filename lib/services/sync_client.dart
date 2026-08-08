import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/sync_snapshot.dart';

class SyncClient {
  String? _baseUrl;
  String? _token;
  WebSocket? _ws;
  SyncSnapshot? _snapshot;

  StreamController<SyncSnapshot>? _onRemote;

  SyncSnapshot? get snapshot => _snapshot;
  bool get connected => _ws != null;

  Stream<SyncSnapshot> get onRemote {
    _onRemote ??= StreamController<SyncSnapshot>.broadcast();
    return _onRemote!.stream;
  }

  Future<bool> connect(String url, String token) async {
    _baseUrl = url;
    _token = token;
    final wsUrl = url.replaceFirst('http', 'ws');
    try {
      final ws = await WebSocket.connect('$wsUrl/ws', headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 8));
      _ws = ws;
      ws.listen(
        (data) => _onWsMessage(data),
        onDone: () {
          _ws = null;
        },
        onError: (_) {
          _ws = null;
        },
      );
      final snap = await fetchSnapshot();
      if (snap == null) {
        try {
          await ws.close();
        } catch (_) {}
        _ws = null;
        return false;
      }
      _snapshot = snap;
      _onRemote?.add(snap);
      return true;
    } catch (_) {
      _ws = null;
      return false;
    }
  }

  void _onWsMessage(dynamic data) {
    try {
      final msg = jsonDecode(data as String) as Map<String, dynamic>;
      if (msg['type'] == 'sync') {
        final snap = SyncSnapshot.fromJson(msg['data'] as Map<String, dynamic>);
        _snapshot = snap;
        _onRemote?.add(snap);
      }
    } catch (_) {
      // ignorar
    }
  }

  Future<SyncSnapshot?> fetchSnapshot() async {
    final url = _baseUrl;
    final token = _token;
    if (url == null || token == null) return null;
    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse('$url/api/snapshot')).timeout(const Duration(seconds: 8));
      req.headers.set('Authorization', 'Bearer $token');
      final res = await req.close().timeout(const Duration(seconds: 8));
      if (res.statusCode != HttpStatus.ok) {
        client.close();
        return null;
      }
      final body = await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 8));
      client.close();
      return SyncSnapshot.fromJson(jsonDecode(body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> apply(SyncSnapshot snap) async {
    final url = _baseUrl;
    final token = _token;
    if (url == null || token == null) return false;
    try {
      final client = HttpClient();
      final req = await client.postUrl(Uri.parse('$url/api/apply')).timeout(const Duration(seconds: 8));
      req.headers.set('Authorization', 'Bearer $token');
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(snap.toJson()));
      final res = await req.close().timeout(const Duration(seconds: 8));
      await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 8));
      client.close();
      final ok = res.statusCode == HttpStatus.ok;
      if (ok) {
        _snapshot = snap;
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  void sendPing() {
    try {
      _ws?.add(jsonEncode({'type': 'ping'}));
    } catch (_) {}
  }

  Future<void> disconnect() async {
    try {
      await _ws?.close();
    } catch (_) {}
    _ws = null;
  }
}
