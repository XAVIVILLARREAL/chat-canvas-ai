@Tags(['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vibecoding_core/vibecoding_core.dart';
import 'package:empresa_dev/services/vibecoding_service.dart';

/// E2E real de vibecoding (gate Etapa 6, slice 6.4):
/// opencode real sobre el fixture `vibe_demo` → propuesta → aplicar →
/// `dart run test/todo_check.dart` pasa (TODO implementado).
/// No corre en CI: requiere opencode instalado en el sistema.
///
/// El fixture se copia a un temporal: aplicar muta el repoPath y el fixture
/// del repo debe quedar intacto.
void main() {
  late Directory scratch;

  setUpAll(() async {
    scratch = await Directory.systemTemp.createTemp('vibe_e2e_');
    _copyTree(Directory('test/fixtures/vibe_demo'), scratch);
  });

  tearDownAll(() async {
    if (scratch.existsSync()) await scratch.delete(recursive: true);
  });

  test('agente real implementa el TODO y los cambios pasan la verificación',
      () async {
    final pipeline = VibecodingPipeline();
    try {
      final proposal = await pipeline.propose(
        prompt:
            'En el archivo lib/todo.dart hay una función duplicate(int x) con '
            'un TODO: impleméntala para que devuelva x * 2. NO modifiques '
            'ningún otro archivo y no ejecutes comandos.',
        repoPath: scratch.path,
        runner: AgentCommandRunnerAdapter(),
      );

      expect(proposal.edits, isNotEmpty,
          reason: 'el agente debió proponer al menos lib/todo.dart');
      final todoEdit = proposal.edits
          .where((e) => e.path == 'lib/todo.dart')
          .firstOrNull;
      expect(todoEdit, isNotNull, reason: 'falta el edit de lib/todo.dart');
      expect(todoEdit!.after, contains('x * 2'));
      for (final e in proposal.edits) {
        expect(e.path.startsWith('lib/'), isTrue,
            reason: 'el agente no debió tocar ${e.path}');
      }

      await pipeline.applyProposal(proposal);
      expect(proposal.state, ProposalState.applied);
      final real = File('${scratch.path}/lib/todo.dart').readAsStringSync();
      expect(real, contains('x * 2'));

      final check = await Process.run(
          'cmd', ['/d', '/c', 'dart run test/todo_check.dart'],
          workingDirectory: scratch.path);
      expect(check.exitCode, 0,
          reason: 'la verificación del fixture falló: ${check.stdout}\n${check.stderr}');
      expect(check.stdout, contains('TODO_TEST_OK'));
    } finally {
      await pipeline.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}

void _copyTree(Directory from, Directory to) {
  to.createSync(recursive: true);
  for (final entry in from.listSync(recursive: true)) {
    final rel = entry.path.substring(from.path.length + 1);
    if (entry is File) {
      final dest = File('${to.path}${Platform.pathSeparator}'
          '${rel.split('/').join(Platform.pathSeparator)}');
      dest.parent.createSync(recursive: true);
      entry.copySync(dest.path);
    }
  }
}
