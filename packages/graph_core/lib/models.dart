/// Tipos de nodo del grafo.
enum GraphNodeKind { dart, python, markdown, other }

/// Tipos de arista del grafo.
enum GraphEdgeKind { import, link, ref }

class GraphNode {
  final String id;
  final String label;
  final GraphNodeKind kind;
  final String package;

  const GraphNode({
    required this.id,
    required this.label,
    required this.kind,
    this.package = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'kind': kind.name,
        'package': package,
      };

  @override
  bool operator ==(Object other) => other is GraphNode && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class GraphEdge {
  final String from;
  final String to;
  final GraphEdgeKind kind;

  const GraphEdge({required this.from, required this.to, required this.kind});

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'kind': kind.name,
      };

  @override
  bool operator ==(Object other) =>
      other is GraphEdge &&
      other.from == from &&
      other.to == to &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(from, to, kind);
}

class Graph {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  const Graph({required this.nodes, required this.edges});
}