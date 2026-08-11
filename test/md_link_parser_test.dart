import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/services/md_link_parser.dart';

void main() {
  group('MdLinkParser', () {
    test('link simple [[docs]]', () {
      final links = MdLinkParser.parse('Ver [[docs]] ya.');
      expect(links.length, 1);
      expect(links.first.target, 'docs');
      expect(links.first.alias, isNull);
      expect('Ver [[docs]] ya.'.substring(links.first.start, links.first.end),
          '[[docs]]');
    });

    test('link con alias [[docs|Plan]]', () {
      final links = MdLinkParser.parse('[[docs|Plan]] es la guía');
      expect(links.first.target, 'docs');
      expect(links.first.alias, 'Plan');
    });

    test('múltiples links con texto alrededor', () {
      final links = MdLinkParser.parse('[[a]] y [[b|c]] y [[a]]');
      expect(links.length, 3);
      expect(links[1].target, 'b');
      expect(links[1].alias, 'c');
    });

    test('links con espacios en el destino', () {
      final links = MdLinkParser.parse('[[mi nota]] ok');
      expect(links.single.target, 'mi nota');
    });

    test('sin links devuelve lista vacía', () {
      expect(MdLinkParser.parse('hola mundo sin corchetes'), isEmpty);
    });

    test('offsets correctos con alias', () {
      const text = 'x [[a|A]] y';
      final link = MdLinkParser.parse(text).single;
      expect(text.substring(link.start, link.end), '[[a|A]]');
    });
  });

  group('wikiToMarkdown', () {
    test('[[target]] → [target](md://target)', () {
      expect(wikiToMarkdown('Ver [[docs]] ya'),
          'Ver [docs](md://docs) ya');
    });

    test('[[target|alias]] → [alias](md://target)', () {
      expect(wikiToMarkdown('[[docs|Plan]] mola'),
          '[Plan](md://docs) mola');
    });

    test('múltiples links se convierten todos', () {
      expect(wikiToMarkdown('[[a]] y [[b|c]]'),
          '[a](md://a) y [c](md://b)');
    });

    test('sin links → texto intacto', () {
      const t = 'hola mundo';
      expect(wikiToMarkdown(t), t);
    });
  });
}
