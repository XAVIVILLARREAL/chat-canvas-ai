import 'package:test/test.dart';
import 'package:ssh_core/session.dart';
import 'package:ssh_core/sync_snapshot.dart';
import 'package:canva_core/canva.dart';

void main() {
  test('DevSession serializa round-trip', () {
    final s = DevSession(id: 's1', title: 'pve', hostId: 'pve');
    final back = DevSession.fromJson(s.toJson());
    expect(back.id, 's1');
    expect(back.title, 'pve');
  });

  test('SyncSnapshot round-trip preserva nodos y edges', () {
    final snap = SyncSnapshot(
      version: 1,
      hosts: [
        HostRecord(id: 'pve', name: 'pve', host: '100.101.69.79', port: 22, username: 'root', authType: 'key'),
      ],
      nodes: [
        CanvaNode(id: 'a', type: CanvaNodeType.host, x: 10, y: 20, label: 'pve', hostId: 'pve'),
      ],
      edges: const [],
      sessions: const [],
    );
    final back = SyncSnapshot.fromJson(snap.toJson());
    expect(back.hosts.length, 1);
    expect(back.nodes.length, 1);
    expect(back.nodes.first.label, 'pve');
  });
}
