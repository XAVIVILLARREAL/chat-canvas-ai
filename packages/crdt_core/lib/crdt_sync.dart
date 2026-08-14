/// Merge del canva en la capa de sync (Etapa 8.1): el hub mantiene un
/// [CanvaCrdt] persistente y fusiona el canva entrante de cada snapshot.
///
/// Si el snapshot trae `canvaCrdt` (changeset con HLC) se mergea de verdad
/// (convergencia sin pérdida); si no (clientes legacy) se siembran los nodos
/// planos (LWW por nodo). Devuelve el estado convergido.
library;

import 'package:canva_core/canva.dart';
import 'package:ssh_core/sync_snapshot.dart';
import 'canva_crdt.dart';

class CrdtSyncCanva {
  final CanvaCrdt doc;

  CrdtSyncCanva({required this.doc});

  Future<CanvaState> mergeIncoming(SyncSnapshot incoming) async {
    final cs = incoming.canvaCrdt;
    if (cs != null && cs.isNotEmpty) {
      await doc.mergeChangesetJson(cs);
    } else {
      await doc.seed(
          CanvaState(nodes: incoming.nodes, edges: incoming.edges));
    }
    return doc.toState();
  }
}
