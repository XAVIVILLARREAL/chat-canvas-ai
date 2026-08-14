import 'package:test/test.dart';
import 'package:canva_core/canva.dart';
import 'package:ssh_core/sync_snapshot.dart';
import 'package:crdt_core/canva_crdt.dart';
import 'package:crdt_core/crdt_sync.dart';

CanvaNode node(String id, {String? label, double x = 10, double y = 20}) =>
    CanvaNode(id: id, type: CanvaNodeType.note, x: x, y: y, label: label ?? id);

Future<CanvaCrdt> seeded(CanvaState base, String actor) async {
  final c = CanvaCrdt.empty(actor: actor);
  await c.seed(base);
  return c;
}

void main() {
  group('CanvaCrdt', () {
    test('round-trip preserva nodos y edges', () async {
      final state = CanvaState(
        nodes: [node('a'), node('b')],
        edges: [CanvaEdge(id: 'e1', fromNodeId: 'a', toNodeId: 'b')],
      );
      final crdt = await seeded(state, 'dev1');
      final back = crdt.toState();
      expect(back.nodes.map((n) => n.id).toSet(), {'a', 'b'});
      expect(back.edges.single.id, 'e1');
      expect(back.nodes.first.label, 'a');
    });

    test('GATE 8.1: dos dispositivos editan en paralelo y convergen sin pérdida',
        () async {
      final base = CanvaState(nodes: [node('a')], edges: const []);
      final devA = await seeded(base, 'devA');
      final devB = await seeded(base, 'devB');

      // offline: A añade X, B añade Y
      await devA.putNode(node('x'));
      await devB.putNode(node('y'));

      await devA.merge(devB);
      await devB.merge(devA);

      expect(devA.toState().nodes.map((n) => n.id).toSet(),
          {'a', 'x', 'y'}, reason: 'ambas ediciones sobreviven');
      expect(devB.toState().nodes.map((n) => n.id).toSet(),
          {'a', 'x', 'y'});
    });

    test('conflicto al mismo registro converge a un solo valor (HLC)',
        () async {
      final base = CanvaState(nodes: [node('a', label: 'inicial')], edges: const []);
      final devA = await seeded(base, 'devA');
      final devB = await seeded(base, 'devB');

      await devA.putNode(node('a', label: 'desde-A'));
      await devB.putNode(node('a', label: 'desde-B'));

      await devA.merge(devB);
      await devB.merge(devA);

      final labelA = devA.toState().nodes.single.label;
      final labelB = devB.toState().nodes.single.label;
      expect(labelA, labelB, reason: 'ambos convergen al mismo valor');
      expect({'desde-A', 'desde-B'}, contains(labelA));
    });

    test('delete con timestamp más nuevo gana (no se revierte)', () async {
      final base = CanvaState(nodes: [node('a')], edges: const []);
      final devA = await seeded(base, 'devA');
      final devB = await seeded(base, 'devB');

      // A avanza su reloj (añade otro nodo) y LUEGO borra 'a' → el borrado de
      // A tiene timestamp estrictamente mayor que el edit de B.
      await devA.putNode(node('extra'));
      await devA.deleteNode('a');
      await devB.putNode(node('a', label: 'editado'));

      await devA.merge(devB);
      await devB.merge(devA);

      expect(devA.toState().nodes.map((n) => n.id), isNot(contains('a')),
          reason: 'el borrado (más nuevo) prevalece en A');
      expect(devB.toState().nodes.map((n) => n.id), isNot(contains('a')),
          reason: 'converge: B también ve el borrado');
      expect(devA.toState().nodes.any((n) => n.id == 'extra'), isTrue);
    });

    test('merge es idempotente y conmutativo', () async {
      final base = CanvaState(nodes: [node('a')], edges: const []);
      final devA = await seeded(base, 'devA');
      final devB = await seeded(base, 'devB');
      await devA.putNode(node('x'));
      await devB.putNode(node('y'));

      final r1 = await seeded(base, 'r1');
      await r1.merge(devA);
      await r1.merge(devB);
      final r2 = await seeded(base, 'r2');
      await r2.merge(devB);
      await r2.merge(devA);

      expect(r1.toState().nodes.map((n) => n.id).toSet(),
          r2.toState().nodes.map((n) => n.id).toSet());
      await r1.merge(devA); // idempotente
      expect(r1.toState().nodes.length, 3);
    });

    test('changesetJson → mergeChangesetJson round-trip conserva nodos', () async {
      final a = await seeded(
          CanvaState(nodes: [node('a')], edges: const []), 'devA');
      await a.putNode(node('x'));
      final json = a.changesetJson();

      final fresh = CanvaCrdt.empty(actor: 'hub');
      await fresh.mergeChangesetJson(json);
      expect(fresh.toState().nodes.map((n) => n.id).toSet(), {'a', 'x'});
    });
  });

  group('CrdtSyncCanva (merge en la capa de sync)', () {
    SyncSnapshot snapOf(CanvaCrdt doc, {int version = 2}) {
      final state = doc.toState();
      return SyncSnapshot(
        version: version,
        hosts: const [],
        nodes: state.nodes,
        edges: state.edges,
        sessions: const [],
        canvaCrdt: doc.changesetJson(),
      );
    }

    test('GATE: dos snapshots con changeset convergen en el hub sin pérdida',
        () async {
      final base = CanvaState(nodes: [node('a')], edges: const []);
      final devA = await seeded(base, 'devA');
      final devB = await seeded(base, 'devB');
      await devA.putNode(node('x'));
      await devB.putNode(node('y'));

      final sync = CrdtSyncCanva(doc: CanvaCrdt.empty(actor: 'hub'));
      await sync.mergeIncoming(snapOf(devA));
      final merged = await sync.mergeIncoming(snapOf(devB));

      expect(merged.nodes.map((n) => n.id).toSet(), {'a', 'x', 'y'},
          reason: 'ambas ediciones sobreviven vía CRDT en el hub');
    });

    test('fallback sin changeset: siembra nodos planos', () async {
      final legacy = SyncSnapshot(
        version: 1,
        hosts: const [],
        nodes: [node('pve')],
        edges: const [],
        sessions: const [],
      );
      final sync = CrdtSyncCanva(doc: CanvaCrdt.empty(actor: 'hub'));
      final merged = await sync.mergeIncoming(legacy);
      expect(merged.nodes.map((n) => n.id).toSet(), {'pve'});
    });
  });
}
