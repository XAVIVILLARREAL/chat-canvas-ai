/// Sync CRDT del canva (Etapa 8.1): adaptador `CanvaState ↔ MapCrdt` con HLC.
/// Cada nodo/edge es un registro `node:<id>`/`edge:<id>`; el borrado se
/// representa con `isDeleted` (HLC decide delete-vs-edit). Dos dispositivos que
/// editan en paralelo convergen sin pérdida.
library;

import 'package:crdt/map_crdt.dart';
import 'package:canva_core/canva.dart';

class CanvaCrdt {
  final MapCrdt _crdt;
  final String actor;

  static const _table = 'canva';

  /// Crea un documento vacío. Las operaciones (put/merge) son async (la
  /// librería `crdt` aplica en microtask) → hay que `await`arlas.
  CanvaCrdt.empty({required this.actor}) : _crdt = MapCrdt([_table]);

  /// Siembra el estado inicial (await antes de leer).
  Future<void> seed(CanvaState state) async {
    for (final n in state.nodes) {
      await _crdt.put(_table, 'node:${n.id}', n.toJson());
    }
    for (final e in state.edges) {
      await _crdt.put(_table, 'edge:${e.id}', e.toJson());
    }
  }

  Future<void> putNode(CanvaNode n) =>
      _crdt.put(_table, 'node:${n.id}', n.toJson());

  Future<void> putEdge(CanvaEdge e) =>
      _crdt.put(_table, 'edge:${e.id}', e.toJson());

  Future<void> deleteNode(String id) =>
      _crdt.put(_table, 'node:$id', null, true);

  Future<void> deleteEdge(String id) =>
      _crdt.put(_table, 'edge:$id', null, true);

  /// Mergea los cambios de [other] en este documento (convergencia).
  Future<void> merge(CanvaCrdt other) async {
    await _crdt.merge(other._crdt.getChangeset());
  }

  /// Devuelve el estado actual (los registros borrados se excluyen).
  CanvaState toState() {
    final map = _crdt.getMap(_table);
    final nodes = <CanvaNode>[];
    final edges = <CanvaEdge>[];
    map.forEach((key, value) {
      if (value is! Map) return;
      final j = value.cast<String, dynamic>();
      if (key.startsWith('node:')) {
        nodes.add(CanvaNode.fromJson(j));
      } else if (key.startsWith('edge:')) {
        edges.add(CanvaEdge.fromJson(j));
      }
    });
    return CanvaState(nodes: nodes, edges: edges);
  }
}
