import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vibecoding_core/vibecoding_core.dart';
import 'package:empresa_dev/services/vibecoding_store.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vibe_store_');
  });

  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  test('roundtrip: save -> load devuelve las propuestas tal cual', () async {
    final store = VibecodingStore(directory: dir.path);
    final p = PatchProposal(
      id: 'v1:2:3',
      prompt: 'arregla el lint',
      repoPath: '/repo',
      edits: [
        const FileEdit(path: 'lib/a.dart', before: 'int x;', after: 'final x;'),
        const FileEdit(path: 'lib/b.dart', before: '', after: 'void f() {}\n'),
      ],
      state: ProposalState.applied,
    );

    await store.save([p]);
    final loaded = await store.load();

    expect(loaded, hasLength(1));
    expect(loaded.first.id, 'v1:2:3');
    expect(loaded.first.prompt, 'arregla el lint');
    expect(loaded.first.state, ProposalState.applied);
    expect(loaded.first.edits, hasLength(2));
    expect(loaded.first.edits.first.path, 'lib/a.dart');
    expect(loaded.first.edits.last.after, 'void f() {}\n');
    expect(loaded.first.createdAt, p.createdAt);
  });

  test('archivo ausente -> lista vacía', () async {
    expect(await VibecodingStore(directory: dir.path).load(), isEmpty);
  });

  test('JSON corrupto -> lista vacía (no rompe la app)', () async {
    File('${dir.path}/vibecoding_proposals.json').writeAsStringSync('{no es json');
    expect(await VibecodingStore(directory: dir.path).load(), isEmpty);
  });

  test('save no rompe con lista vacía', () async {
    final store = VibecodingStore(directory: dir.path);
    await store.save([]);
    expect(await store.load(), isEmpty);
  });
}
