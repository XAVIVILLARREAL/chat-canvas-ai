@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:ssh_core/sync_snapshot.dart';
import 'package:empresa_dev/services/hub_server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // flutter_test bloquea red real por defecto; lo desactivamos para probar el hub.
  HttpOverrides.global = null;
  final token = 'test-token-secreto-1234';

  Future<String> httpGet(String url, {String? auth}) async {
    final h = HttpClient();
    final req = await h.getUrl(Uri.parse(url));
    if (auth != null) req.headers.set('Authorization', 'Bearer $auth');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    h.close();
    return '$res.statusCode|$body';
  }

  Future<String> httpPost(String url, String body, {String? auth}) async {
    final h = HttpClient();
    final req = await h.postUrl(Uri.parse(url));
    if (auth != null) req.headers.set('Authorization', 'Bearer $auth');
    req.headers.contentType = ContentType.json;
    req.write(body);
    final res = await req.close();
    final respBody = await res.transform(utf8.decoder).join();
    h.close();
    return '$res.statusCode|$respBody';
  }

  test('hub rechaza sin token', () async {
    final hub = HubServer();
    await hub.start(token: token, bindIp: '127.0.0.1', port: 0);
    final base = 'http://127.0.0.1:${hub.port}';

    final res = await httpGet('$base/api/snapshot');
    expect(res.startsWith('401'), isTrue);
    await hub.stop();
  });

  test('snapshot + apply + ultima version gana', () async {
    final hub = HubServer();
    await hub.start(token: token, bindIp: '127.0.0.1', port: 0);
    final base = 'http://127.0.0.1:${hub.port}';

    final initial = SyncSnapshot(
      version: 1,
      hosts: [
        HostRecord(id: 'h1', name: 'pve', host: '100.101.69.79', port: 22, username: 'root'),
      ],
      nodes: [],
      edges: [],
      sessions: [],
    );
    hub.updateSnapshot(initial);

    final snap = await httpGet('$base/api/snapshot', auth: token);
    expect(snap.startsWith('200'), isTrue);
    expect(snap, contains('pve'));

    final v2 = initial.copyWith(version: 2);
    v2.hosts.add(HostRecord(id: 'h2', name: 'backup', host: '10.0.0.5', port: 22, username: 'root'));
    final applyRes = await httpPost('$base/api/apply', jsonEncode(v2.toJson()), auth: token);
    expect(applyRes.startsWith('200'), isTrue);
    expect(hub.snapshot.hosts.length, 2);

    final stale = initial.copyWith(version: 1);
    await httpPost('$base/api/apply', jsonEncode(stale.toJson()), auth: token);
    expect(hub.snapshot.hosts.length, 2, reason: 'version vieja no debe sobreescribir');

    await hub.stop();
  });
}
