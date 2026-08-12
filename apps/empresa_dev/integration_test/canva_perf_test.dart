import 'dart:io';
import 'dart:ui' show FrameTiming;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:canva_core/canva.dart';
import 'package:empresa_dev/screens/canva_screen.dart';
import 'package:empresa_dev/services/canva_store.dart';
import 'package:empresa_dev/services/ssh_service.dart';

/// Benchmark de UI del canva LOD (Etapa 8.6, SDD-121): 10.000 nodos,
/// culling por viewport + clusters por zoom, ≥ 30fps en zoom-out total.
///
/// Ejecutar (Windows real, igual que graph_flow_test):
///
/// ```
/// flutter test integration_test/canva_perf_test.dart -d windows
/// ```
///
/// Escribe la evidencia en `data/evidence/etapa86-benchmark.md`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const goalMs = 33.3; // 30fps

  Future<List<FrameTiming>> measureFor(WidgetTester tester, Duration duration,
      Future<void> Function(WidgetTester tester) keepDirty) async {
    final timings = <FrameTiming>[];
    void onTimings(List<FrameTiming> ts) => timings.addAll(ts);
    binding.addTimingsCallback(onTimings);
    try {
      final stopwatch = Stopwatch()..start();
      while (stopwatch.elapsed < duration) {
        await keepDirty(tester);
        await tester.pump(const Duration(milliseconds: 16));
      }
    } finally {
      binding.removeTimingsCallback(onTimings);
    }
    return timings;
  }

  testWidgets('canva LOD: 10.000 nodos zoom-out total ≥ 30fps', (tester) async {
    // Grid 100x100 = 10.000 nodos en el dominio 3000x2000 del canva.
    final nodes = <CanvaNode>[
      for (var i = 0; i < 100; i++)
        for (var j = 0; j < 100; j++)
          CanvaNode(
            id: 'n${i * 100 + j}',
            type: CanvaNodeType.note,
            x: i * 30.0 + 15,
            y: j * 20.0 + 10,
            label: 'n${i * 100 + j}',
            colorHex: '#F59E0B',
          ),
    ];

    await tester.pumpWidget(MaterialApp(
      home: CanvaScreen(hosts: [], sshService: SshService(), store: _BenchStore(nodes)),
    ));
    await tester.pumpAndSettle();

    int countOf(String type) => tester
        .widgetList(
            find.byWidgetPredicate((w) => w.runtimeType.toString() == type))
        .length;

    int lodCanvasNodes() {
      for (final w in tester.widgetList(find.byType(CustomPaint))) {
        final p = (w as CustomPaint).painter;
        if (p != null && p.runtimeType.toString() == '_LodCanvasPainter') {
          return (p as dynamic).nodes.length as int;
        }
      }
      return -1;
    }

    Future<void> jiggle(Offset delta) async {
      final center = tester.getCenter(find.byType(InteractiveViewer));
      final g = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 16));
      await g.moveBy(delta);
      await tester.pump(const Duration(milliseconds: 16));
      await g.up();
    }

    Future<void> pinchToZoomOut() async {
      final center = tester.getCenter(find.byType(InteractiveViewer));
      final g1 = await tester.startGesture(center - const Offset(400, 0));
      final g2 = await tester.startGesture(center + const Offset(400, 0));
      await tester.pump();
      for (var i = 0; i < 30; i++) {
        await g1.moveBy(const Offset(10, 0));
        await g2.moveBy(const Offset(-10, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g1.up();
      await g2.up();
      await tester.pumpAndSettle();
    }

    // Fase 1: zoom 1.0, culling por viewport.
    final t1 = await measureFor(tester, const Duration(seconds: 2),
        (t) => jiggle(const Offset(20, 10)));
    final drawnZoom1 = lodCanvasNodes();
    final clustersZoom1 = countOf('_ClusterChip');

    // Fase 2: zoom-out total → clusters.
    await pinchToZoomOut();
    final t2 = await measureFor(tester, const Duration(seconds: 3),
        (t) => jiggle(const Offset(4, 3)));
    final drawnZoomOut = lodCanvasNodes();
    final clustersZoomOut = countOf('_ClusterChip');

    String stats(String label, List<FrameTiming> ts) {
      if (ts.isEmpty) return '$label: sin frames';
      final work = ts
          .map((f) => f.buildDuration.inMicroseconds / 1000.0 +
              f.rasterDuration.inMicroseconds / 1000.0)
          .toList();
      final avg = work.reduce((a, b) => a + b) / work.length;
      final late = work.where((ms) => ms > goalMs).length;
      return '$label: media ${avg.toStringAsFixed(2)} ms/frame · '
          'tardíos(>$goalMs ms) $late/${ts.length} '
          '(${(late * 100 / ts.length).toStringAsFixed(1)}%)';
    }

    final report = <String>[
      '# Evidencia Etapa 8.6 — benchmark canva LOD (10.000 nodos)',
      '',
      '> Generado por `integration_test/canva_perf_test.dart` (Windows real, `-d windows`).',
      '',
      '- Nodos totales: ${nodes.length}',
      '- Zoom 1.0 → nodos dibujados en el canvas: $drawnZoom1 / ${nodes.length} · clusters: $clustersZoom1',
      '- Zoom-out total → nodos sueltos en el canvas: $drawnZoomOut · clusters: $clustersZoomOut',
      '- ${stats('Zoom 1.0 (culling)', t1)}',
      '- ${stats('Zoom-out total (clusters)', t2)}',
    ];
    for (final l in report) {
      debugPrint('BENCH: $l');
    }

    // Gate SDD-121/8.6: culling activo y clusters en zoom-out.
    expect(clustersZoom1, 0, reason: 'escala 1.0 no debe agrupar');
    expect(drawnZoom1, greaterThan(0));
    expect(drawnZoom1, lessThan(nodes.length),
        reason: 'el viewport no dibuja los 10.000 (culling activo)');
    expect(clustersZoomOut, greaterThan(0), reason: 'zoom-out debe agrupar en clusters');
    expect(drawnZoomOut, lessThan(clustersZoomOut * 2 + 50),
        reason: 'tras el cluster quedan pocos nodos sueltos');

    // Gate de rendimiento: media ≤ 33.3ms y < 10% de frames tardíos.
    double avgOf(List<FrameTiming> ts) => ts.isEmpty
        ? double.infinity
        : ts
                .map((f) => f.buildDuration.inMicroseconds / 1000.0 +
                    f.rasterDuration.inMicroseconds / 1000.0)
                .reduce((a, b) => a + b) /
            ts.length;
    bool lateUnder10Pct(List<FrameTiming> ts) {
      if (ts.isEmpty) return false;
      final late = ts
          .where((f) =>
              f.buildDuration.inMicroseconds / 1000.0 +
                  f.rasterDuration.inMicroseconds / 1000.0 >
              goalMs)
          .length;
      return late * 100 / ts.length < 10;
    }

    final okZoom1 = avgOf(t1) <= goalMs && lateUnder10Pct(t1);
    final okZoomOut = avgOf(t2) <= goalMs && lateUnder10Pct(t2);
    expect(okZoomOut, isTrue,
        reason: 'zoom-out: media/frame debajo de 33.3ms y <10% tardíos');

    // Evidencia en disco (misma convención que etapa5-benchmark.md).
    final evidenceDir = Directory('data/evidence');
    evidenceDir.createSync(recursive: true);
    File('${evidenceDir.path}/etapa86-benchmark.md').writeAsStringSync(
        '${report.join('\n')}'
        '\n- Resultado fase zoom-out: ${okZoomOut ? "OK ≥30fps" : "FALLO"}'
        '\n- Resultado fase zoom 1.0: ${okZoom1 ? "OK ≥30fps" : "FALLO"}'
        '\n');
  });
}

class _BenchStore extends CanvaStore {
  final List<CanvaNode> nodes;
  _BenchStore(this.nodes);

  @override
  Future<CanvaState> load() async => CanvaState(nodes: nodes, edges: []);
}