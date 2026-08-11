import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/services/project_service.dart';

void main() {
  late Directory tempDir;
  late ProjectService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('project_service_test');
    service = ProjectService(root: tempDir.path);

    // Árbol de prueba:
    //   lib/main.dart, lib/models/canva.dart
    //   docs/PLAN.md
    //   build/output.exe  (se ignora build/)
    //   .git/config       (se ignora .git/)
    Directory('${tempDir.path}/lib').createSync(recursive: true);
    Directory('${tempDir.path}/lib/models').createSync(recursive: true);
    Directory('${tempDir.path}/docs').createSync(recursive: true);
    Directory('${tempDir.path}/build').createSync(recursive: true);
    Directory('${tempDir.path}/.git').createSync(recursive: true);
    File('${tempDir.path}/lib/main.dart').writeAsStringSync('void main() {}');
    File('${tempDir.path}/lib/models/canva.dart').writeAsStringSync('class Canva {}');
    File('${tempDir.path}/docs/PLAN.md').writeAsStringSync('# Plan');
    File('${tempDir.path}/build/output.exe').writeAsBytesSync([1, 2, 3]);
    File('${tempDir.path}/.git/config').writeAsStringSync('[core]');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('ProjectService', () {
    test('list ignora .git y build/ y ordena directorios primero', () async {
      final root = await service.list(tempDir.path);
      final names = root.map((n) => n.name).toList();
      expect(names, ['docs', 'lib']);
    });

    test('list recursivo lazy por nivel', () async {
      final lib = await service.list('${tempDir.path}/lib');
      expect(lib.map((n) => n.name), ['models', 'main.dart']);

      final models = await service.list('${tempDir.path}/lib/models');
      expect(models.single.name, 'canva.dart');
      expect(models.single.size, greaterThan(0));
    });

    test('read decodifica UTF-8', () async {
      final content = await service.read('${tempDir.path}/docs/PLAN.md');
      expect(content, '# Plan');
    });

    test('read decodifica UTF-16 con BOM', () async {
      final path = '${tempDir.path}/utf16.txt';
      final bytes = [0xFF, 0xFE, 0x48, 0x00, 0x69, 0x00]; // BOM LE + "Hi"
      File(path).writeAsBytesSync(bytes);
      expect(await service.read(path), 'Hi');
    });

    test('write conserva BOM si existía', () async {
      final path = '${tempDir.path}/utf16bom.txt';
      File(path).writeAsBytesSync([0xFF, 0xFE, 0x48, 0x00, 0x69, 0x00]);
      await service.write(path, 'Hola mundo');
      final bytes = File(path).readAsBytesSync();
      expect(bytes.sublist(0, 2), [0xFF, 0xFE]);
      expect(await service.read(path), 'Hola mundo');
    });

    test('isBinary detecta bytes nulos', () async {
      final path = '${tempDir.path}/bin.dat';
      File(path).writeAsBytesSync([0, 1, 2, 255]);
      expect(service.isBinary(path), isTrue);
      expect(service.isBinary('${tempDir.path}/docs/PLAN.md'), isFalse);
    });
  });
}