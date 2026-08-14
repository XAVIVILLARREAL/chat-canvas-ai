import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:canva_core/canva.dart';
import 'package:crdt_core/canva_crdt.dart';
import 'package:ssh_core/sync_snapshot.dart';
import 'package:empresa_dev/services/hub_server.dart';

CanvaNode node(String id) =>
    CanvaNode(id: id, type: CanvaNodeType.note, x: 10, y: 20, label: id);

void main() {
  const hubToken = 'token-de-prueba-largo';

  Future<void> postApply(HubServer hub, CanvaCrdt doc) async {
    final state = doc.toState();
    final snap = SyncSnapshot(
      version: 1,
      hosts: const [],
      nodes: state.nodes,
      edges: state.edges,
      sessions: const [],
      canvaCrdt: doc.changesetJson(),
    );
    final client = HttpClient();
    final req = await client
        .postUrl(Uri.parse('http://127.0.0.1:${hub.port}/api/apply'));
    req.headers.set('Authorization', 'Bearer $hubToken');
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode(snap.toJson()));
    final res = await req.close();
    await res.transform(utf8.decoder).join();
    client.close();
    expect(res.statusCode, HttpStatus.ok);
  }

  Future<SyncSnapshot> getSnapshot(HubServer hub) async {
    final client = HttpClient();
    final req = await client
        .getUrl(Uri.parse('http://127.0.0.1:${hub.port}/api/snapshot'));
    req.headers.set('Authorization', 'Bearer $hubToken');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    client.close();
    return SyncSnapshot.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  test('hub CONVERGE ediciones concurrentes del canva (CRDT, no LWW snapshot)',
      () async {
    final hub = HubServer();
    await hub.start(token: hubToken, bindIp: '127.0.0.1', port: 0);
    addTearDown(hub.stop);

    final base = CanvaState(nodes: [node('a')], edges: const []);
    final devA = CanvaCrdt.empty(actor: 'devA');
    await devA.seed(base);
    await devA.putNode(node('x'));
    final devB = CanvaCrdt.empty(actor: 'devB');
    await devB.seed(base);
    await devB.putNode(node('y'));

    await postApply(hub, devA);
    await postApply(hub, devB);

    final snap = await getSnapshot(hub);
    expect(snap.nodes.map((n) => n.id).toSet(), {'a', 'x', 'y'},
        reason: 'la edición de A (x) no se pierde cuando B aplica (y)');
  });
}
