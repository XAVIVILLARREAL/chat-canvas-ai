import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:canva_core/canva.dart';
import 'package:empresa_dev/widgets/canva_view.dart';

/// Nodo draggable mínimo para el test de aislamiento (replica del contrato:
/// el motor entrega gestos/posición vía CanvaNodeCallbacks).
class _TestDraggable extends StatefulWidget {
  final CanvaNode node;
  final CanvaNodeCallbacks cb;

  const _TestDraggable({required this.node, required this.cb});

  @override
  State<_TestDraggable> createState() => _TestDraggableState();
}

class _TestDraggableState extends State<_TestDraggable> {
  Offset _start = Offset.zero;
  double _bx = 0;
  double _by = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.cb.onTap,
      onPanStart: (d) {
        _start = d.localPosition;
        _bx = widget.node.x;
        _by = widget.node.y;
      },
      onPanUpdate: (d) => widget.cb.onMoved(
        _bx + d.localPosition.dx - _start.dx,
        _by + d.localPosition.dy - _start.dy,
      ),
      child: Container(
        width: 150,
        height: 44,
        color: Colors.blue,
        child: Text(widget.node.label,
            style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  /// Expone el callback de posición sin depender del arena de pan (los widget
  /// tests pierden el pan contra el InteractiveViewer).
  void simulateDragEnd(double x, double y) => widget.cb.onMoved(x, y);
}

List<CanvaNode> grid({int cols = 100, int rows = 10}) => [
      for (var i = 0; i < cols; i++)
        for (var j = 0; j < rows; j++)
          CanvaNode(
            id: 'n${i * rows + j}',
            type: CanvaNodeType.note,
            x: i * 30.0 + 15,
            y: j * 200.0 + 10,
            label: 'n${i * rows + j}',
          ),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('modo simple: nodeBuilder construye y tap/callbacks llegan',
      (tester) async {
    final tapped = <String>[];
    final moved = <String>[];
    await tester.pumpWidget(wrap(CanvaView(
      nodes: [CanvaNode(id: 'a', type: CanvaNodeType.note, x: 50, y: 60, label: 'a')],
      edges: const [],
      onNodeTap: (n) => tapped.add(n.id),
      onNodeMoved: (n, x, y) => moved.add('${n.id}:${x.toStringAsFixed(0)},${y.toStringAsFixed(0)}'),
      nodeBuilder: (node, cb) => _TestDraggable(node: node, cb: cb),
    )));

    await tester.tap(find.text('a'));
    expect(tapped, ['a'], reason: 'tap → onNodeTap');

    // onMoved se dispara con la posición final (el pan sintetizado lo gana el
    // InteractiveViewer en widget tests, igual que el E2E de graph_flow).
    final draggable = tester.state<_TestDraggableState>(find.byType(_TestDraggable));
    draggable.simulateDragEnd(91, 92);
    await tester.pump();
    expect(moved, ['a:91,92'], reason: 'cb.onMoved → onNodeMoved');
  });

  testWidgets('modo LOD: canvas único + hit-test de tap y long-press',
      (tester) async {
    final tapped = <String>[];
    final longPressed = <String>[];
    await tester.pumpWidget(wrap(CanvaView(
      nodes: grid(),
      edges: const [],
      onNodeTap: (n) => tapped.add(n.id),
      onNodeLongPress: (n) => longPressed.add(n.id),
      onNodeMoved: (_, __, ___) {},
      nodeBuilder: (node, cb) => const SizedBox.shrink(),
    )));

    final ivTopLeft = tester.getTopLeft(find.byType(InteractiveViewer));
    // Centro del box de n0 (canva 15,10 → 165,54): (90, 32).
    await tester.tapAt(ivTopLeft + const Offset(90, 32));
    await tester.pump();
    expect(tapped, ['n0'], reason: 'el hit-test del canvas llega al nodo');

    await tester.longPressAt(ivTopLeft + const Offset(90, 32));
    await tester.pump();
    expect(longPressed, ['n0'], reason: 'long-press del canvas llega al nodo');
  });

  testWidgets('modo LOD zoom-out: clusters con contador en vez de nodos',
      (tester) async {
    await tester.pumpWidget(wrap(CanvaView(
      nodes: grid(),
      edges: const [],
      onNodeTap: (_) {},
      onNodeMoved: (_, __, ___) {},
      nodeBuilder: (node, cb) => const SizedBox.shrink(),
    )));

    int countOf(String type) => tester
        .widgetList(
            find.byWidgetPredicate((w) => w.runtimeType.toString() == type))
        .length;

    // Pinza hacia adentro = zoom-out en Flutter.
    final center = tester.getCenter(find.byType(InteractiveViewer));
    final g1 = await tester.startGesture(center - const Offset(200, 0));
    final g2 = await tester.startGesture(center + const Offset(200, 0));
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      await g1.moveBy(const Offset(6, 0));
      await g2.moveBy(const Offset(-6, 0));
      await tester.pump();
    }
    await g1.up();
    await g2.up();
    await tester.pumpAndSettle();

    final chips = countOf('_ClusterChip');
    expect(chips, greaterThan(0), reason: 'zoom-out agrupa en clusters');
    expect(countOf('_TestDraggable'), 0, reason: 'LOD no usa widgets por nodo');
  });
}
