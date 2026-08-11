class MdLink {
  final String target;
  final String? alias;
  final int start;
  final int end;

  const MdLink({
    required this.target,
    required this.start,
    required this.end,
    this.alias,
  });
}

/// Parser de `[[links]]` estilo Obsidian. Simple: no distingue code spans;
/// el primer `]]` cierra el link.
class MdLinkParser {
  static List<MdLink> parse(String text) {
    final links = <MdLink>[];
    final open = RegExp(r'\[\[');
    var pos = 0;
    while (true) {
      final match = open.firstMatch(text.substring(pos));
      if (match == null) break;
      final start = pos + match.start;
      final contentStart = start + 2;
      final close = text.indexOf(']]', contentStart);
      if (close == -1) break;
      final raw = text.substring(contentStart, close);
      final parts = raw.split('|');
      links.add(MdLink(
        target: parts.first.trim(),
        alias: parts.length > 1 ? parts.sublist(1).join('|').trim() : null,
        start: start,
        end: close + 2,
      ));
      pos = close + 2;
    }
    return links;
  }
}

/// Convierte `[[target]]` / `[[target|alias]]` a markdown estándar con
/// href interno `md://target`, para que el renderer los haga clickables.
String wikiToMarkdown(String text) {
  var out = text;
  final links = MdLinkParser.parse(text);
  for (final link in links.reversed) {
    final visible = link.alias ?? link.target;
    out = out.replaceRange(
      link.start,
      link.end,
      '[${visible.replaceAll('[', '\\[').replaceAll(']', '\\]')}]'
      '(md://${Uri.encodeComponent(link.target)})',
    );
  }
  return out;
}

/// Índice de backlinks: id → ids cuyos contenidos referencian el id.
class BacklinkIndex {
  static Map<String, List<String>> build(Map<String, String> nodes) {
    final index = <String, List<String>>{
      for (final id in nodes.keys) id: [],
    };
    nodes.forEach((id, content) {
      for (final link in MdLinkParser.parse(content)) {
        if (link.target == id) continue; // self-reference filtrada
        index.putIfAbsent(link.target, () => []).add(id);
      }
    });
    return index;
  }
}
