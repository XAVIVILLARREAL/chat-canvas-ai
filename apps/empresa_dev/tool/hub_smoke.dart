// Smoke test del HubServer (protocolo snapshot/apply/auth) en Dart puro.
// Uso: dart run tool/hub_smoke.dart
// Devuelve exit 0 si todo pasa.
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:ssh_core/sync_snapshot.dart';
import 'package:empresa_dev/services/hub_server.dart';

Future<String> httpGet(String url, {String? auth}) async {
  final h = HttpClient()..findProxy = (u) => 'DIRECT';
  final req = await h.getUrl(Uri.parse(url));
  if (auth != null) req.headers.set('Authorization', 'Bearer $auth');
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  h.close();
  return '${res.statusCode}|$body';
}

Future<String> httpPost(String url, String body, {String? auth}) async {
  final h = HttpClient()..findProxy = (u) => 'DIRECT';
  final req = await h.postUrl(Uri.parse(url));
  if (auth != null) req.headers.set('Authorization', 'Bearer $auth');
  req.headers.contentType = ContentType.json;
  req.write(body);
  final res = await req.close();
  final respBody = await res.transform(utf8.decoder).join();
  h.close();
  return '${res.statusCode}|$respBody';
}

Future<void> main() async {
  final token = 'smoke-token-1234';
  var failures = 0;

  Future<void> check(String name, Future<bool> Function() fn) async {
    try {
      final ok = await fn().timeout(const Duration(seconds: 5));
      print('${ok ? "PASS" : "FAIL"}: $name');
      if (!ok) failures++;
    } catch (e) {
      print('FAIL: $name -> ERROR: $e');
      failures++;
    }
  }

  // 1. rechazo sin token
  await check('rechaza sin token (401)', () async {
    final hub = HubServer();
    await hub.start(token: token, bindIp: '127.0.0.1', port: 0);
    final base = 'http://127.0.0.1:${hub.port}';
    final res = await httpGet('$base/api/snapshot');
    await hub.stop();
    return res.startsWith('401');
  });

  // 2. snapshot + apply + ultima version gana
  await check('snapshot/apply/last-write-wins', () async {
    final hub = HubServer();
    await hub.start(token: token, bindIp: '127.0.0.1', port: 0);
    final base = 'http://127.0.0.1:${hub.port}';

    final initial = SyncSnapshot(
      version: 1,
      hosts: [HostRecord(id: 'h1', name: 'pve', host: '100.101.69.79', port: 22, username: 'root')],
      nodes: [],
      edges: [],
      sessions: [],
    );
    hub.updateSnapshot(initial);

    final snap = await httpGet('$base/api/snapshot', auth: token);
    final snapOk = snap.startsWith('200') && snap.contains('pve');

    final v2 = initial.copyWith(version: 2);
    v2.hosts.add(HostRecord(id: 'h2', name: 'backup', host: '10.0.0.5', port: 22, username: 'root'));
    final applyRes = await httpPost('$base/api/apply', jsonEncode(v2.toJson()), auth: token);
    final applyOk = applyRes.startsWith('200') && hub.snapshot.hosts.length == 2;

    final stale = initial.copyWith(version: 1);
    await httpPost('$base/api/apply', jsonEncode(stale.toJson()), auth: token);
    final lwwOk = hub.snapshot.hosts.length == 2;

    await hub.stop();
    return snapOk && applyOk && lwwOk;
  });

  print(failures == 0 ? '\nSMOKE OK' : '\nSMOKE FAIL ($failures)');
  exit(failures == 0 ? 0 : 1);
}
