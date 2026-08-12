import 'dart:math';

import 'package:test/test.dart';
import 'package:spatial_core/spatial_core.dart';

void main() {
  group('QuadTree básico', () {
    test('insert + queryRect con bounds vacíos devuelve vacío', () {
      final qt = QuadTree<String>();
      qt.insert(x: 10, y: 10, data: 'a', id: 'a');
      expect(qt.size, 1);
      expect(qt.queryRect(0, 0, 5, 5), isEmpty);
    });

    test('queryRect devuelve exactamente los puntos dentro del rect', () {
      final qt = QuadTree<String>();
      qt.insert(x: 10, y: 10, data: 'a', id: 'a');
      qt.insert(x: 30, y: 30, data: 'b', id: 'b');
      qt.insert(x: 50, y: 10, data: 'c', id: 'c');
      final hits = qt.queryRect(0, 0, 40, 40);
      expect(hits.toSet(), {'a', 'b'});
    });

    test('update reubica un punto (index espacial correcto)', () {
      final qt = QuadTree<String>();
      qt.insert(x: 10, y: 10, data: 'a', id: 'a');
      qt.update('a', 1000, 1000);
      expect(qt.queryRect(0, 0, 40, 40), isEmpty);
      expect(qt.queryRect(900, 900, 1100, 1100), ['a']);
    });

    test('remove elimina el punto', () {
      final qt = QuadTree<String>();
      qt.insert(x: 10, y: 10, data: 'a', id: 'a');
      qt.insert(x: 20, y: 20, data: 'b', id: 'b');
      qt.remove('a');
      expect(qt.size, 1);
      expect(qt.queryRect(0, 0, 40, 40), ['b']);
    });

    test('queryCircle devuelve puntos dentro del radio', () {
      final qt = QuadTree<String>();
      qt.insert(x: 0, y: 0, data: 'origen', id: 'o');
      qt.insert(x: 3, y: 4, data: 'a5', id: 'a');
      qt.insert(x: 10, y: 0, data: 'lejos', id: 'l');
      final hits = qt.queryCircle(0, 0, 5);
      expect(hits.toSet(), {'origen', 'a5'});
    });

    test('sin id los insert se autogeneran y el query funciona', () {
      final qt = QuadTree<int>();
      for (var i = 0; i < 100; i++) {
        qt.insert(x: i.toDouble(), y: 0, data: i);
      }
      expect(qt.size, 100);
      expect(qt.queryRect(0, -1, 9, 1).length, 10);
    });
  });

  group('QuadTree a escala (10k puntos, comparado con fuerza bruta)', () {
    final rng = Random(42);
    final qt = QuadTree<String>();
    final expected = <String, Point<double>>{};

    setUpAll(() {
      for (var i = 0; i < 10000; i++) {
        final x = rng.nextDouble() * 3000;
        final y = rng.nextDouble() * 2000;
        final id = 'n$i';
        qt.insert(x: x, y: y, data: id, id: id);
        expected[id] = Point(x, y);
      }
    });

    test('queryRect coincide con fuerza bruta en 5 viewports aleatorios', () {
      for (var v = 0; v < 5; v++) {
        final vx = rng.nextDouble() * 2500;
        final vy = rng.nextDouble() * 1500;
        final w = 200 + rng.nextDouble() * 400;
        final h = 150 + rng.nextDouble() * 300;
        final brute = expected.entries
            .where((e) =>
                e.value.x >= vx &&
                e.value.x <= vx + w &&
                e.value.y >= vy &&
                e.value.y <= vy + h)
            .map((e) => e.key)
            .toSet();
        final qtHits = qt.queryRect(vx, vy, vx + w, vy + h).toSet();
        expect(qtHits, brute,
            reason: 'viewport $v: ($vx,$vy,$w,$h) — ${qtHits.length} vs ${brute.length}');
      }
    });

    test('queryCircle coincide con fuerza bruta', () {
      final cx = 1500.0, cy = 1000.0, r = 300.0;
      final brute = expected.entries
          .where((e) =>
              (e.value.x - cx) * (e.value.x - cx) +
                  (e.value.y - cy) * (e.value.y - cy) <=
              r * r)
          .map((e) => e.key)
          .toSet();
      final qtHits = qt.queryCircle(cx, cy, r).toSet();
      expect(qtHits, brute);
    });

    test('update masivo de 1.000 puntos mantiene queries exactas', () {
      for (var i = 0; i < 1000; i++) {
        final id = 'n${i * 3}';
        final x = rng.nextDouble() * 3000;
        final y = rng.nextDouble() * 2000;
        qt.update(id, x, y);
        expected[id] = Point(x, y);
      }
      final vx = 500.0, vy = 500.0, w = 800.0, h = 600.0;
      final brute = expected.entries
          .where((e) =>
              e.value.x >= vx &&
              e.value.x <= vx + w &&
              e.value.y >= vy &&
              e.value.y <= vy + h)
          .map((e) => e.key)
          .toSet();
      expect(qt.queryRect(vx, vy, vx + w, vy + h).toSet(), brute);
    });
  });
}
