import 'dart:io';
import 'dart:math' as math;

import 'package:graph_core/force_simulation.dart';
import 'package:graph_core/models.dart';

/// Benchmark Etapa 5: 5.000 nodos a ~30fps (16ms/frame) en la simulación.
/// Escribe baseline en apps/empresa_dev/data/evidence/etapa5-benchmark.md.
/// Uso: dart run benchmark/graph_benchmark.dart
void main() {
  const nodeCount = 5000;
  final rand = math.Random(42);
  final nodes = <GraphNode>[
    for (var i = 0; i < nodeCount; i++)
      GraphNode(
        id: 'file$i.dart',
        label: 'file$i.dart',
        kind: GraphNodeKind.dart,
        package: 'pkg${i % 20}',
      ),
  ];
  final edges = <GraphEdge>[
    for (var i = 0; i < nodeCount; i++)
      GraphEdge(
        from: nodes[i].id,
        to: nodes[(i + 1) % nodeCount].id,
        kind: GraphEdgeKind.import,
      ),
    for (var i = 0; i < nodeCount ~/ 2; i++)
      GraphEdge(
        from: nodes[rand.nextInt(nodeCount)].id,
        to: nodes[rand.nextInt(nodeCount)].id,
        kind: GraphEdgeKind.import,
      ),
  ];

  final sim = ForceSimulation(nodes, edges);
  final sw = Stopwatch()..start();
  const frames = 60; // 60 frames = 1 s a 60fps / 0.5 s a 30fps
  var lateFrames = 0;
  const frameBudgetMs = 16.0;
  for (var i = 0; i < frames; i++) {
    final t = Stopwatch()..start();
    sim.step(0.5);
    final dt = t.elapsedMicroseconds / 1000;
    if (dt > frameBudgetMs) lateFrames++;
  }
  sw.stop();
  final avgMs = sw.elapsedMicroseconds / 1000 / frames;

  final report = StringBuffer('# Evidencia Etapa 5 — benchmark 5.000 nodos\n\n')
    ..writeln('> Generado por `dart run benchmark/graph_benchmark.dart` '
        '(packages/graph_core).')
    ..writeln()
    ..writeln('- Nodos: $nodeCount')
    ..writeln('- Aristas: ${edges.length}')
    ..writeln('- Frames simulados: $frames')
    ..writeln('- Tiempo total: ${sw.elapsedMilliseconds} ms')
    ..writeln('- Media por frame: ${avgMs.toStringAsFixed(2)} ms '
        '(objetivo 30fps ≥ 33.3 ms/frame)')
    ..writeln('- Frames sobre presupuesto (${frameBudgetMs.toStringAsFixed(1)} ms): '
        '$lateFrames / $frames')
    ..writeln()
    ..writeln(lateFrames < frames ~/ 2
        ? '- **Resultado: OK** — la mayoría de frames caben en presupuesto.'
        : '- **Resultado: LENTO** — optimizar (grid de repulsión O(n·k)).')
    ..writeln();
  File('../../apps/empresa_dev/data/evidence/etapa5-benchmark.md')
      .parent
      .createSync(recursive: true);
  File('../../apps/empresa_dev/data/evidence/etapa5-benchmark.md')
      .writeAsStringSync(report.toString());
  stdout.writeln('avg ${avgMs.toStringAsFixed(2)} ms/frame, '
      '$lateFrames late of $frames');
  exit(lateFrames < frames ~/ 2 ? 0 : 1);
}