enum CanvaNodeType { host, note, container, agent }

class CanvaNode {
  String id;
  CanvaNodeType type;
  double x;
  double y;
  String label;
  String? hostId;
  String colorHex;

  CanvaNode({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.label,
    this.hostId,
    this.colorHex = '#334155',
  });

  /// ARGB como int (0xFFRRGGBB) — evita depender de dart:ui en modelos puros.
  int get colorValue {
    try {
      final hex = colorHex.replaceFirst('#', '');
      return int.parse('FF$hex', radix: 16);
    } catch (_) {
      return 0xFF334155;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'x': x,
        'y': y,
        'label': label,
        if (hostId != null) 'hostId': hostId,
        'color': colorHex,
      };

  factory CanvaNode.fromJson(Map<String, dynamic> j) => CanvaNode(
        id: j['id'] as String,
        type: CanvaNodeType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => CanvaNodeType.note,
        ),
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        label: j['label'] as String? ?? '',
        hostId: j['hostId'] as String?,
        colorHex: j['color'] as String? ?? '#334155',
      );
}

class CanvaEdge {
  String id;
  String fromNodeId;
  String toNodeId;

  CanvaEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'from': fromNodeId,
        'to': toNodeId,
      };

  factory CanvaEdge.fromJson(Map<String, dynamic> j) => CanvaEdge(
        id: j['id'] as String,
        fromNodeId: j['from'] as String,
        toNodeId: j['to'] as String,
      );
}

class CanvaState {
  List<CanvaNode> nodes;
  List<CanvaEdge> edges;

  CanvaState({required this.nodes, required this.edges});

  Map<String, dynamic> toJson() => {
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
      };

  factory CanvaState.fromJson(Map<String, dynamic> j) => CanvaState(
        nodes: (j['nodes'] as List? ?? [])
            .map((e) => CanvaNode.fromJson(e as Map<String, dynamic>))
            .toList(),
        edges: (j['edges'] as List? ?? [])
            .map((e) => CanvaEdge.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  factory CanvaState.empty() => CanvaState(nodes: [], edges: []);
}
