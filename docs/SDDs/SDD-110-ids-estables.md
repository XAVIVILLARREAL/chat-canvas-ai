# SDD — Inyección copia.md, pieza 2.4: IDs estables y estado puro (canva)

> **Proyecto:** empresa_dev — prefase Etapa 4 (copia.md 2.4).
> **Fuente de concepto:** buzz (Block Inc.) — IDs opacos no reutilizados, estado serializable separado del runtime.
> **Fecha:** 2026-08. **Estado:** En implementación.

## Objetivo

Los nodos del canva dejan de identificar por índice/label volátil: cada nodo tiene un **ID opaco estable** (`w1:w2`, no reutilizado al borrar) y su **estado es puro** (serializable, sin referencias a runtime como streams/sockets), con runtime separado (lección copia 2.4).

## Alcance

- `CanvasNodeId`: tipo opaco con formato `w<sec>:w<ms>` (timestamp de creación) — nunca se reutiliza aunque el nodo se borre.
- `CanvasNode`: modelo puro `{id, label, kind (host|note|agent|md), x, y, color}` serializable a JSON; **sin** estado runtime.
- `AgentNodeRuntime` (estado de ejecución del agente: `running`, buffer, detección) en un mapa separado por ID, inyectado en el canva — no dentro del modelo.
- Migración: `CanvasNode` gana campo `id` requerido; call sites (canva_screen, tests) se actualizan.

## Contratos

```dart
class CanvasNodeId {
  final String value;             // "w<sec>:w<ms>"
  static CanvasNodeId generate(); // de DateTime.now()
  @override String toString() => value;
}

enum NodeKind { host, note, agent, md }

class CanvasNode {
  final CanvasNodeId id;
  final String label;
  final NodeKind kind;
  final double x, y;
  final int color;                // BIGINT estilo goals
  final String? content;          // nota / md body
  Map<String, Object?> toJson();
  static CanvasNode fromJson(...);
  CanvasNode copyWith(...);
}

class AgentNodeRuntime {
  bool running; StringBuffer buffer; AgentDetection detection;
}
```

## Tests (TDD) — `test/canvas_node_test.dart`

- `CanvasNodeId.generate()` produce IDs distintos consecutivos y con formato `^w\d+:\w+$`.
- Al borrar un nodo y crear otro, **ningún** nodo nuevo recibe el ID borrado (IDs únicos por generación — simular 1000 generaciones).
- `CanvasNode.toJson/fromJson` round-trip conserva todos los campos (id, label, kind, x, y, color, content).
- `copyWith` cambia solo el campo indicado y preserva el id.
- `AgentNodeRuntime` no vive dentro de `CanvasNode` (compilación: no existe el campo).

## Gate (SUPER_PLAN)

- [ ] Un nodo borrado no "hereda" su ID a nodos nuevos (único por generación).
- [ ] El estado de ejecución del agente es separable del modelo serializable.