import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/services/md_link_parser.dart';

void main() {
  group('BacklinkIndex', () {
    test('A referencia a B y C → backlinks de B incluyen A', () {
      final index = BacklinkIndex.build({
        'A': 'Habla de [[B]] y [[C]]',
        'B': 'Contenido',
        'C': 'Más contenido',
      });
      expect(index['B'], ['A']);
      expect(index['C'], ['A']);
    });

    test('alias [[B|Ver B]] cuenta como backlink a B', () {
      final index = BacklinkIndex.build({
        'A': 'Ver [[B|Ver B]] aquí',
        'B': 'Destino',
      });
      expect(index['B'], ['A']);
    });

    test('nodos sin referencias → lista vacía', () {
      final index = BacklinkIndex.build({
        'A': 'Sin links',
        'B': 'Otro',
      });
      expect(index['A'], isEmpty);
      expect(index['B'], isEmpty);
    });

    test('self-reference se filtra', () {
      final index = BacklinkIndex.build({
        'A': 'Yo me cito [[A]]',
      });
      expect(index['A'], isEmpty);
    });

    test('backlinks ordenados por orden de aparición', () {
      final index = BacklinkIndex.build({
        'A': '[[Z]]',
        'B': '[[Z]] después',
        'Z': 'Destino',
      });
      expect(index['Z'], ['A', 'B']);
    });
  });
}
