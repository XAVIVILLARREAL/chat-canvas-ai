import 'package:test/test.dart';
import 'package:canva_core/canva.dart';

List<CanvaNode> grid({int cols = 100, int rows = 100}) => [
      for (var i = 0; i < cols; i++)
        for (var j = 0; j < rows; j++)
          CanvaNode(
            id: 'n${i * rows + j}',
            type: CanvaNodeType.note,
            x: i * 30.0 + 15,
            y: j * 20.0 + 10,
            label: 'n${i * rows + j}',
          ),
    ];

void main() {
  group('CanvaRect', () {
    test('containsPoint con bordes inclusivos', () {
      final r = CanvaRect(x: 10, y: 20, width: 100, height: 50);
      expect(r.containsPoint(10, 20), isTrue);
      expect(r.containsPoint(110, 70), isTrue);
      expect(r.containsPoint(111, 70), isFalse);
      expect(r.containsPoint(10, 71), isFalse);
    });

    test('expand agranda en las 4 direcciones', () {
      final r = CanvaRect(x: 10, y: 20, width: 100, height: 50).expand(200);
      expect(r.left, -190);
      expect(r.top, -180);
      expect(r.right, 310);
      expect(r.bottom, 270);
    });
  });

  group('CanvaCuller', () {
    final nodes = grid();

    test('nodeCount es la cantidad de nodos', () {
      expect(CanvaCuller(nodes).nodeCount, 10000);
    });

    test('visibleIn con margen 0 devuelve exactamente los del viewport', () {
      final culler = CanvaCuller(nodes, margin: 0);
      const vx = 1000.0, vy = 500.0, w = 300.0, h = 200.0;
      final brute = nodes
          .where((n) => n.x >= vx && n.x <= vx + w && n.y >= vy && n.y <= vy + h)
          .map((n) => n.id)
          .toSet();
      final hits = culler.visibleIn(CanvaRect(x: vx, y: vy, width: w, height: h));
      expect(hits.map((n) => n.id).toSet(), brute);
    });

    test('el margen 200 incluye nodos a medio render fuera del viewport', () {
      final culler = CanvaCuller(nodes);
      final hits = culler.visibleIn(CanvaRect(x: 0, y: 0, width: 100, height: 100));
      expect(hits.length, greaterThan(0));
      final justOutside = nodes
          .where((n) => n.x > 100 && n.x <= 300 && n.y > 100 && n.y <= 300)
          .every((n) => hits.any((h) => h.id == n.id));
      expect(justOutside, isTrue);
    });

    test('move reubica el índice espacial', () {
      final culler = CanvaCuller(nodes, margin: 0);
      final soloN0 = CanvaRect(x: 0, y: 0, width: 20, height: 20);
      expect(culler.visibleIn(soloN0).map((n) => n.id), ['n0']);
      culler.move('n0', 2900, 1900);
      expect(
        culler.visibleIn(soloN0),
        isEmpty,
      );
      expect(
        culler.visibleIn(CanvaRect(x: 2900, y: 1900, width: 10, height: 10)),
        hasLength(1),
      );
    });

    test('query total (canva entero) devuelve los 10.000 nodos', () {
      final culler = CanvaCuller(nodes, margin: 0);
      final all = culler.visibleIn(CanvaRect(x: -1e9, y: -1e9, width: 2e9, height: 2e9));
      expect(all.length, 10000);
    });
  });

  group('CanvaClusterer', () {
    final nodes = grid();

    test('zoom-out extremo (0.3) agrupa el grid en pocos clusters con counts correctos', () {
      final clusterer = CanvaClusterer(nodes, cellSize: 160);
      final clusters = clusterer.clustersFor(0.3);
      expect(clusters.length, lessThan(50));
      expect(clusters.length, greaterThan(0));
      final total = clusters.fold<int>(0, (s, c) => s + c.count);
      expect(total, 10000);

      // Comparar contra agrupación por fuerza bruta con la misma celda.
      final cell = 160 / 0.3;
      final expected = <String, List<String>>{};
      for (final n in nodes) {
        final key = '${(n.x / cell).floor()},${(n.y / cell).floor()}';
        (expected[key] ??= []).add(n.id);
      }
      final perCell = {
        for (final e in expected.entries) e.key: e.value,
      };
      for (final c in clusters) {
        final key = '${(c.x / cell).floor()},${(c.y / cell).floor()}';
        final cellNodes = perCell.remove(key);
        expect(cellNodes, isNotNull, reason: 'cluster ${c.x},${c.y} sin celda');
        expect(cellNodes!.length, c.count);
      }
      expect(perCell, isEmpty, reason: 'cada celda con nodos produjo un cluster');
    });

    test('centroide ponderado correcto', () {
      final clusterer = CanvaClusterer(nodes, cellSize: 160);
      final clusters = clusterer.clustersFor(1.0);
      expect(clusters, isNotEmpty);
      final first = clusters.first;
      final cellNodes = nodes
          .where((n) =>
              (n.x / (160 / 1.0)).floor() == (first.x / (160 / 1.0)).floor() &&
              (n.y / (160 / 1.0)).floor() == (first.y / (160 / 1.0)).floor())
          .toList();
      final cx = cellNodes.fold<double>(0, (s, n) => s + n.x) / cellNodes.length;
      final cy = cellNodes.fold<double>(0, (s, n) => s + n.y) / cellNodes.length;
      expect(first.x, closeTo(cx, 1e-6));
      expect(first.y, closeTo(cy, 1e-6));
    });

    test('nodos sueltos salen en standaloneFor', () {
      final sparse = [
        CanvaNode(id: 'a', type: CanvaNodeType.note, x: 0, y: 0, label: 'a'),
        CanvaNode(id: 'b', type: CanvaNodeType.note, x: 1500, y: 1200, label: 'b'),
        CanvaNode(id: 'c', type: CanvaNodeType.note, x: 2900, y: 1900, label: 'c'),
      ];
      final clusterer = CanvaClusterer(sparse, cellSize: 160);
      expect(clusterer.clustersFor(0.3), isEmpty);
      expect(clusterer.standaloneFor(0.3).map((n) => n.id).toSet(), {'a', 'b', 'c'});
    });

    test('con escala alta (1.0) los nodos no se agrupan (nadie comparte celda)', () {
      final sparse = [
        CanvaNode(id: 'a', type: CanvaNodeType.note, x: 0, y: 0, label: 'a'),
        CanvaNode(id: 'b', type: CanvaNodeType.note, x: 500, y: 500, label: 'b'),
      ];
      final clusterer = CanvaClusterer(sparse, cellSize: 160);
      expect(clusterer.clustersFor(1.0), isEmpty);
      expect(clusterer.standaloneFor(1.0), hasLength(2));
    });
  });
}
