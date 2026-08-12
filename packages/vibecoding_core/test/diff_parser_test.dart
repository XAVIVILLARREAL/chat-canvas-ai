import 'package:test/test.dart';
import 'package:vibecoding_core/vibecoding_core.dart';

void main() {
  group('DiffParser.parsePatch', () {
    test('diff unificado de 2 archivos -> 2 FilePatch con hunks correctos', () {
      const patch = '''
diff --git a/lib/foo.dart b/lib/foo.dart
index 1111111..2222222 100644
--- a/lib/foo.dart
+++ b/lib/foo.dart
@@ -1,3 +1,5 @@
 int foo() => 1;
+
+// nuevo comentario
 void main() {}
 int bar() => 2;
diff --git a/lib/extra.dart b/lib/extra.dart
index 5555555..6666666 100644
--- a/lib/extra.dart
+++ b/lib/extra.dart
@@ -1,1 +1,2 @@
-version: '1'
+version: '2'
+revisado: true
''';

      final result = DiffParser.parsePatch(patch);
      expect(result.files, hasLength(2));
      expect(result.files[0].path, 'lib/foo.dart');
      expect(result.files[1].path, 'lib/extra.dart');

      final h0 = result.files[0].hunks.single;
      expect(h0.oldStart, 1);
      expect(h0.oldCount, 3);
      expect(h0.newStart, 1);
      expect(h0.newCount, 5);
      expect(h0.before, [
        'int foo() => 1;',
        'void main() {}',
        'int bar() => 2;',
      ]);
      expect(h0.after, [
        'int foo() => 1;',
        '',
        '// nuevo comentario',
        'void main() {}',
        'int bar() => 2;',
      ]);

      final h1 = result.files[1].hunks.single;
      expect(h1.before, ["version: '1'"]);
      expect(h1.after, ["version: '2'", 'revisado: true']);
    });

    test('archivo nuevo (dev/null) -> isNew, before vacio', () {
      const patch = '''
diff --git a/notes/index.md b/notes/index.md
new file mode 100644
index 0000000..3333333
--- /dev/null
+++ b/notes/index.md
@@ -0,0 +1,2 @@
+# Inicio
+ver [[guia]]
''';

      final file = DiffParser.parsePatch(patch).files.single;
      expect(file.path, 'notes/index.md');
      expect(file.isNew, isTrue);
      expect(file.isDeleted, isFalse);
      expect(file.hunks.single.oldStart, 0);
      expect(file.hunks.single.oldCount, 0);
      expect(file.hunks.single.newCount, 2);
      expect(file.hunks.single.before, isEmpty);
      expect(file.hunks.single.after, ['# Inicio', 'ver [[guia]]']);
    });

    test('archivo borrado -> isDeleted, after vacio', () {
      const patch = '''
diff --git a/viejo.txt b/viejo.txt
deleted file mode 100644
index 4444444..0000000
--- a/viejo.txt
+++ /dev/null
@@ -1,2 +0,0 @@
-linea uno
-linea dos
''';

      final file = DiffParser.parsePatch(patch).files.single;
      expect(file.path, 'viejo.txt');
      expect(file.isDeleted, isTrue);
      expect(file.hunks.single.before, ['linea uno', 'linea dos']);
      expect(file.hunks.single.after, isEmpty);
    });

    test('varios hunks por archivo se conservan en orden', () {
      const patch = '''
diff --git a/grande.md b/grande.md
index aaaaaaa..bbbbbbb 100644
--- a/grande.md
+++ b/grande.md
@@ -1,2 +1,3 @@
 # Cap 1
+
+introduccion
@@ -10,2 +11,3 @@
 # Cap 2
+
+detalle
''';

      final file = DiffParser.parsePatch(patch).files.single;
      expect(file.hunks, hasLength(2));
      expect(file.hunks[0].newStart, 1);
      expect(file.hunks[1].newStart, 11);
      expect(file.hunks[1].after, ['# Cap 2', '', 'detalle']);
    });

    test('patch vacio -> sin archivos', () {
      final result = DiffParser.parsePatch('');
      expect(result.files, isEmpty);
    });

    test('sintaxis rota -> error tipado (DiffFormatException)', () {
      expect(
        () => DiffParser.parsePatch('@@ -1,1 +1,1 @@\nesto no tiene header'),
        throwsA(isA<DiffFormatException>()),
      );
    });
  });
}