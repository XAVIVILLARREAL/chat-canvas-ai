import '../services/agent_detector.dart';

/// ID opaco de nodo del canva: `w<sec>:w<ms>` del momento de creación.
/// Nunca se reutiliza: aunque el nodo se borre, no se vuelve a emitir.
class CanvasNodeId {
  final String value;

  const CanvasNodeId(this.value);

  static int _seq = 0;

  factory CanvasNodeId.generate() {
    final now = DateTime.now();
    final seq = _seq++;
    return CanvasNodeId(
        'w${now.millisecondsSinceEpoch ~/ 1000}:${now.microsecondsSinceEpoch % 1000000}:$seq');
  }

  @override
  bool operator ==(Object other) => other is CanvasNodeId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

enum NodeKind { host, note, agent, md }

/// Modelo puro y serializable de un nodo del canva.
/// El estado de ejecución (buffers, streams) NO vive aquí — ver
/// [AgentNodeRuntime] en canvas_node.dart.
class CanvasNode {
  final CanvasNodeId id;
  final String label;
  final NodeKind kind;
  final double x;
  final double y;
  final int color;
  final String? content;

  const CanvasNode({
    required this.id,
    required this.label,
    required this.kind,
    this.x = 0,
    this.y = 0,
    this.color = 0xFF000000,
    this.content,
  });

  Map<String, Object?> toJson() => {
        'id': id.value,
        'label': label,
        'kind': kind.name,
        'x': x,
        'y': y,
        'color': color,
        if (content != null) 'content': content,
      };

  static CanvasNode fromJson(Map<String, Object?> json) => CanvasNode(
        id: CanvasNodeId(json['id'] as String),
        label: json['label'] as String,
        kind: NodeKind.values.byName(json['kind'] as String),
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        color: json['color'] as int,
        content: json['content'] as String?,
      );

  CanvasNode copyWith({
    String? label,
    NodeKind? kind,
    double? x,
    double? y,
    int? color,
    String? content,
  }) =>
      CanvasNode(
        id: id,
        label: label ?? this.label,
        kind: kind ?? this.kind,
        x: x ?? this.x,
        y: y ?? this.y,
        color: color ?? this.color,
        content: content ?? this.content,
      );
}

/// Estado de ejecución de un nodo agente — separado del modelo serializable.
class AgentNodeRuntime {
  bool running = false;
  final StringBuffer buffer = StringBuffer();
  AgentDetection detection = const AgentDetection(AgentState.idle, null);
}
