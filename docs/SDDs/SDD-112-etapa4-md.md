# SDD-112 — Etapa 4: Canva de ideas + `.md`

> **Proyecto:** empresa_dev — Etapa 4 del SUPER_PLAN (canva de ideas, Obsidian-style).
> **Fecha:** 2026-08. **Estado:** En implementación.

## Objetivo

Los nodos del canva son **documentos Markdown enlazados** con `[[links]]`: se renderiza preview live, se navega por enlaces y backlinks, y el mapa de ideas del propio proyecto (`docs/`) se representa como canva navegable (dogfood).

## Slices

### Slice 4.1 — Parser `[[links]]` + índice de backlinks (puro, unit)

- `MdLinkParser.parse(String text)` → `List<MdLink>`, donde `MdLink{target, alias?}`.
  - Soporta `[[destino]]` y `[[destino|alias]]`; el alias se usa como texto visible.
  - Tolerancia: links con espacios en el destino; sin alias → el texto visible es el destino.
- `BacklinkIndex.build(Map<String, String> nodes)` (id → content) → `Map<String, List<String>>` (id → ids que lo referencian).
- Fuera de alcance: wiki-path de archivos físicos (slice 4.3 lo mapea a nodos).

### Slice 4.2 — Nodo `.md`: preview live + navegación (widget)

- `MdNodeEditor` (widget reutilizable dentro de una pantalla de edición): campo de texto del body + `MarkdownBody` (paquete `flutter_markdown`) con el preview en vivo.
- Los `[[links]]` visibles en el preview son **clickables**: click → si existe un nodo con ese título, navega (abre el editor del nodo destino); si no, ofrece crearlo (dialog "crear nota 'X' enlazada").
- Integración: doble-click en un nodo `md` del canva abre `MdNodeEditorScreen` (reusa estilo `CodeEditorScreen`); el nodo guarda el body en `CanvaNode.content`.

### Slice 4.3 — Auto-layout simple + mapa de `docs/` (dogfood)

- `DocsMapBuilder`: dado un directorio con `.md`, crea nodos (`kind=md`, título = nombre de archivo), detecta `[[links]]` entre ellos → edges, auto-layout en espiral/grid; los archivos que referencian nodos inexistentes crean nodos placeholder.
- Menú en el canva: **"Abrir docs (mapa)"** — importa `docs/` del repo (o carpeta elegida) como canva navegable.
- Persistencia: ya cubierta por `CanvaStore` (JSON en Documents; el plan mencionaba drift, el store existente cumple el gate manual "cerrar/reabrir → persiste").

## Contratos

```dart
class MdLink {
  final String target;   // sin corchetes, sin alias
  final String? alias;   // texto visible si existe
  final int start;       // offset del `[[` en el texto (para resaltar)
  final int end;         // offset tras `]]`
}

class MdLinkParser {
  static List<MdLink> parse(String text);
}

class BacklinkIndex {
  static Map<String, List<String>> build(Map<String, String> nodes);
  // value ordenado: ids cuyo content contiene `[[key]]` o `[[key|...]]`
}
```

## Tests (TDD)

**`test/md_link_parser_test.dart`** (unit):
- `[[docs]]` simple → target `docs`, alias null.
- `[[docs|Plan]]` → target `docs`, alias `Plan`.
- Múltiples links y con texto alrededor; `[[a]]` dentro de código inline (`` `[[a]]` ``) también se parsea (decisión: parser simple, sin aware de code spans).
- Round-trip de offsets: el substring del texto en `start..end` es `[[docs]]`.

**`test/backlink_index_test.dart`** (unit):
- A referencia a B y C → backlinks de B incluyen a A.
- Alias: `[[B|Ver B]]` cuenta como backlink a B.
- Nodos sin referencias → lista vacía.
- Self-reference se incluye o se filtra (decisión: se filtra).

**`test/md_node_editor_widget_test.dart`** (widget):
- Al escribir en el campo, el preview muestra el markdown renderizado (p. ej. `# Título` → heading) en vivo.
- Click en un link existente → callback `onOpenLink(target)`.
- Click en link inexistente → callback `onCreateLink(target)`.

**`test/docs_map_builder_test.dart`** (unit, temp dirs):
- 3 `.md` con `[[links]]` cruzados → nodos + edges correctos.
- Link a archivo inexistente → nodo placeholder.
- Layout: posiciones distintas para nodos distintos.

## Gate (SUPER_PLAN)

- [ ] Unit: parser de `[[links]]` + índice de backlinks (arriba).
- [ ] Widget: preview se actualiza en vivo; click en link navega al nodo.
- [ ] Manual: 5 notas enlazadas, navegar por backlinks, cerrar/reabrir → persiste (CanvaStore JSON).
- [ ] **Dogfood:** `docs/` del proyecto representado como canva navegable (evidencia: screenshot en `data/evidence/`).
- [ ] CI: `flutter analyze` 0 + suite verde + build Windows + `flutter_markdown` añadido al pubspec.
