/// Parser de diffs unificados (formato `git diff --no-ext-diff`) en Dart puro.
///
/// No toca disco: solo sintaxis. Las líneas `\ No newline at end of file` se
/// ignoran (la reconstrucción exacta de bytes es responsabilidad del pipeline).
library;

/// Error tipado de parseo (nunca excepciones crudas).
class DiffFormatException implements Exception {
  final String message;
  DiffFormatException(this.message);

  @override
  String toString() => 'DiffFormatException: $message';
}

/// Un hunk `@@ -a,b +c,d @@` con su cuerpo ya separado en antes/después.
class Hunk {
  final int oldStart;
  final int oldCount;
  final int newStart;
  final int newCount;
  final List<String> before; // líneas originales (contexto + '-')
  final List<String> after; //  líneas propuestas (contexto + '+')

  const Hunk({
    required this.oldStart,
    required this.oldCount,
    required this.newStart,
    required this.newCount,
    required this.before,
    required this.after,
  });
}

/// Cambios de un único archivo dentro del patch.
class FilePatch {
  final String path; // ruta relativa al repo
  final bool isNew;
  final bool isDeleted;
  final List<Hunk> hunks;

  const FilePatch({
    required this.path,
    required this.isNew,
    required this.isDeleted,
    required this.hunks,
  });
}

/// Resultado del parseo: lista ordenada de archivos modificados.
class DiffResult {
  final List<FilePatch> files;
  const DiffResult(this.files);

  bool get isEmpty => files.isEmpty;
}

final _hunkHeader = RegExp(
  r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@',
);

class DiffParser {
  static final _fileHeader = RegExp(r'^diff --git a/(\S+) b/(\S+)\s*$');

  /// Parsea un unified diff. [patch] vacío o sin encabezados -> resultado vacío.
  static DiffResult parsePatch(String patch) {
    final lines = patch.split('\n');
    final files = <FilePatch>[];

    String? currentPath;
    var currentNew = false;
    var currentDeleted = false;
    var hunks = <Hunk>[];
    Hunk? openHunk;

    void flushHunk() {
      if (openHunk != null) {
        hunks.add(openHunk!);
        openHunk = null;
      }
    }

    void flushFile() {
      flushHunk();
      if (currentPath != null) {
        files.add(FilePatch(
          path: currentPath!,
          isNew: currentNew,
          isDeleted: currentDeleted,
          hunks: List.unmodifiable(hunks),
        ));
      }
      currentPath = null;
      currentNew = false;
      currentDeleted = false;
      hunks = [];
    }

    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.isEmpty) continue;

      final fileMatch = _fileHeader.firstMatch(line);
      if (fileMatch != null) {
        flushFile();
        // para archivos nuevos el lado 'a/' es /dev/null; borrados el 'b/' lo es
        final a = fileMatch.group(1)!;
        final b = fileMatch.group(2)!;
        currentPath = b == '/dev/null' ? a : b;
        continue;
      }

      if (currentPath == null) {
        throw DiffFormatException(
          'contenido sin encabezado de archivo: "$line"',
        );
      }

      if (line == 'new file mode 100644' || line == 'new file mode 100755') {
        currentNew = true;
        continue;
      }
      if (line == 'deleted file mode 100644' || line == 'deleted file mode 100755') {
        currentDeleted = true;
        continue;
      }
      if (line.startsWith('index ') ||
          line.startsWith('--- ') ||
          line.startsWith('+++ ') ||
          line.startsWith('similarity index ') ||
          line.startsWith('rename from ') ||
          line.startsWith('rename to ')) {
        continue;
      }
      if (line.startsWith(r'\ ')) continue; // "\ No newline at end of file"

      final hunkMatch = _hunkHeader.firstMatch(line);
      if (hunkMatch != null) {
        flushHunk();
        openHunk = Hunk(
          oldStart: int.parse(hunkMatch.group(1)!),
          oldCount: int.parse(hunkMatch.group(2) ?? '1'),
          newStart: int.parse(hunkMatch.group(3)!),
          newCount: int.parse(hunkMatch.group(4) ?? '1'),
          before: [],
          after: [],
        );
        continue;
      }

      // cuerpo del hunk
      final hunk = openHunk;
      if (hunk == null) {
        throw DiffFormatException(
          'línea de cuerpo sin hunk abierto: "$line"',
        );
      }
      if (line.startsWith(' ')) {
        hunk.before.add(line.substring(1));
        hunk.after.add(line.substring(1));
      } else if (line.startsWith('-')) {
        hunk.before.add(line.substring(1));
      } else if (line.startsWith('+')) {
        hunk.after.add(line.substring(1));
      } else {
        throw DiffFormatException('línea de hunk inválida: "$line"');
      }
    }

    flushFile();
    return DiffResult(files);
  }
}
