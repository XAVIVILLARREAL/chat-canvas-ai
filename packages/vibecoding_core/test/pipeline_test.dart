import 'dart:io';

import 'package:test/test.dart';
import 'package:vibecoding_core/vibecoding_core.dart';

/// Runner falso: ejecuta un cierre con cwd (el worktree aislado) para simular
/// que el agente de IA "edita archivos" sin tocar el arbol real.
class FakeAgentRunner implements AgentRunner {
  final void Function(String cwd) onRun;

  FakeAgentRunner(this.onRun);

  @override
  Future<RunResult> run(String command, {String? cwd}) async {
    onRun(cwd ?? '');
    return const RunResult(exitCode: 0, stdout: '{}', stderr: '');
  }
}

void main() {
  late Directory repo;
  late Directory copy;

  setUp(() async {
    repo = await Directory.systemTemp.createTemp('vibe_repo_');
    copy = await Directory.systemTemp.createTemp('vibe_copy_');
    File('${repo.path}/a.txt').writeAsStringSync('linea uno\nlinea dos\n');
    File('${repo.path}/b.txt').writeAsStringSync('B viejo\n');
  });

  tearDown(() async {
    if (repo.existsSync()) await repo.delete(recursive: true);
    if (copy.existsSync()) await copy.delete(recursive: true);
  });

  group('VibecodingPipeline.propose', () {
    test('propuesta con edits, estado pending y arbol real intacto', () async {
      final runner = FakeAgentRunner((cwd) {
        File('$cwd/a.txt').writeAsStringSync('linea uno\nlinea dos\n// nuevo\n');
      });

      final pipeline = VibecodingPipeline();
      final proposal = await pipeline.propose(
        prompt: 'anade un comentario',
        repoPath: repo.path,
        runner: runner,
      );

      expect(proposal.state, ProposalState.pending);
      expect(proposal.prompt, 'anade un comentario');
      expect(proposal.edits, hasLength(1));
      final edit = proposal.edits.single;
      expect(edit.path, 'a.txt');
      expect(edit.before, 'linea uno\nlinea dos\n');
      expect(edit.after, 'linea uno\nlinea dos\n// nuevo\n');

      // el arbol real NO se toco (aislamiento por copia)
      expect(
        File('${repo.path}/a.txt').readAsStringSync(),
        'linea uno\nlinea dos\n',
      );

      await pipeline.dispose();
    });

    test(
        'archivos generados (.dart_tool, build) creados por el agente en el '
        'sandbox no entran como edits', () async {
      final runner = FakeAgentRunner((cwd) {
        File('$cwd/lib/nuevo.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('void x() {}\n');
        File('$cwd/.dart_tool/version')
          ..createSync(recursive: true)
          ..writeAsStringSync('3.32.2');
        File('$cwd/build/generated')
          ..createSync(recursive: true)
          ..writeAsStringSync('junk');
      });

      final pipeline = VibecodingPipeline();
      final proposal = await pipeline.propose(
        prompt: 'anade un archivo',
        repoPath: repo.path,
        runner: runner,
      );

      expect(
        proposal.edits.map((e) => e.path),
        containsAll(['lib/nuevo.dart']),
      );
      expect(
        proposal.edits.map((e) => e.path),
        isNot(contains('.dart_tool/version')),
      );
      expect(
        proposal.edits.map((e) => e.path),
        isNot(contains('build/generated')),
      );

      await pipeline.dispose();
    });

    test('copia aislada se borra con dispose', () async {
      final pipeline = VibecodingPipeline();
      final proposal = await pipeline.propose(
        prompt: 'x',
        repoPath: repo.path,
        runner: FakeAgentRunner((_) {}),
      );
      final workdir = proposal.workdir!;
      expect(Directory(workdir).existsSync(), isTrue);
      await pipeline.dispose();
      expect(Directory(workdir).existsSync(), isFalse);
    });

    test('la copia aislada ignora pubspec_overrides.yaml del monorepo',
        () async {
      // melos genera rutas relativas al árbol REAL (../../packages/...): si
      // llegan a la copia, opencode intenta leer paquetes externos y el
      // sandbox los rechaza (dogfood Etapa 6 halló este fallo).
      File('${repo.path}/pubspec_overrides.yaml').writeAsStringSync(
        'dependency_overrides:\n  vibecoding_core:\n    path: ../../packages/vibecoding_core\n',
      );

      final pipeline = VibecodingPipeline();
      final proposal = await pipeline.propose(
        prompt: 'x',
        repoPath: repo.path,
        runner: FakeAgentRunner((_) {}),
      );

      expect(
        File('${proposal.workdir}/pubspec_overrides.yaml').existsSync(),
        isFalse,
      );
      await pipeline.dispose();
    });
  });

  group('transiciones de estado (aceptar/rechazar/revertir)', () {
    test('apply escribe el cambio y pasa a applied', () async {
      final pipeline = VibecodingPipeline();
      final proposal = await pipeline.propose(
        prompt: 'editar b',
        repoPath: repo.path,
        runner: FakeAgentRunner((cwd) {
          File('$cwd/b.txt').writeAsStringSync('B nuevo\n');
        }),
      );

      await pipeline.applyProposal(proposal);
      expect(proposal.state, ProposalState.applied);
      expect(
        File('${repo.path}/b.txt').readAsStringSync(),
        'B nuevo\n',
      );
      await pipeline.dispose();
    });

    test('reject no toca nada y pasa a rejected', () async {
      final pipeline = VibecodingPipeline();
      final proposal = await pipeline.propose(
        prompt: 'x',
        repoPath: repo.path,
        runner: FakeAgentRunner((_) {}),
      );

      await pipeline.rejectProposal(proposal);
      expect(proposal.state, ProposalState.rejected);
      expect(File('${repo.path}/a.txt').readAsStringSync(), 'linea uno\nlinea dos\n');
      await pipeline.dispose();
    });

    test('revert restaura el contenido original byte a byte', () async {
      final pipeline = VibecodingPipeline();
      final proposal = await pipeline.propose(
        prompt: 'editar a',
        repoPath: repo.path,
        runner: FakeAgentRunner((cwd) {
          File('$cwd/a.txt').writeAsStringSync('linea uno\nlinea dos\n// nuevo\n');
        }),
      );

      await pipeline.applyProposal(proposal);
      await pipeline.revertProposal(proposal);
      expect(proposal.state, ProposalState.reverted);
      expect(
        File('${repo.path}/a.txt').readAsStringSync(),
        'linea uno\nlinea dos\n',
      );
      await pipeline.dispose();
    });

    test('transiciones ilegales lanzan StateError', () async {
      final pipeline = VibecodingPipeline();
      final proposal = await pipeline.propose(
        prompt: 'x',
        repoPath: repo.path,
        runner: FakeAgentRunner((cwd) {
          File('$cwd/b.txt').writeAsStringSync('B nuevo\n');
        }),
      );

      await pipeline.applyProposal(proposal);
      expect(() => pipeline.applyProposal(proposal), throwsStateError);
      await pipeline.dispose();

      final proposal2 = await pipeline.propose(
        prompt: 'x',
        repoPath: repo.path,
        runner: FakeAgentRunner((_) {}),
      );
      await pipeline.rejectProposal(proposal2);
      expect(() => pipeline.revertProposal(proposal2), throwsStateError);
      await pipeline.dispose();
    });

    test('conflicto al aplicar si el archivo real cambio -> failed', () async {
      final pipeline = VibecodingPipeline();
      final proposal = await pipeline.propose(
        prompt: 'editar a',
        repoPath: repo.path,
        runner: FakeAgentRunner((cwd) {
          File('$cwd/a.txt').writeAsStringSync('linea uno\nlinea dos\n// nuevo\n');
        }),
      );

      // el usuario edita el archivo real mientras decide
      File('${repo.path}/a.txt').writeAsStringSync('mano humana\n');

      await expectLater(
        pipeline.applyProposal(proposal),
        throwsA(isA<ProposalConflict>()),
      );
      expect(proposal.state, ProposalState.failed);
      expect(File('${repo.path}/a.txt').readAsStringSync(), 'mano humana\n');
      await pipeline.dispose();
    });

    test('conflicto al revertir si el archivo cambio tras aplicar -> failed',
        () async {
      final pipeline = VibecodingPipeline();
      final proposal = await pipeline.propose(
        prompt: 'editar b',
        repoPath: repo.path,
        runner: FakeAgentRunner((cwd) {
          File('$cwd/b.txt').writeAsStringSync('B nuevo\n');
        }),
      );
      await pipeline.applyProposal(proposal);

      File('${repo.path}/b.txt').writeAsStringSync('otra edicion\n');

      await expectLater(
        pipeline.revertProposal(proposal),
        throwsA(isA<ProposalConflict>()),
      );
      expect(proposal.state, ProposalState.failed);
      await pipeline.dispose();
    });

    test('runner falla (exit != 0) -> AgentRunException y arbol intacto',
        () async {
      final pipeline = VibecodingPipeline();
      await expectLater(
        pipeline.propose(
          prompt: 'x',
          repoPath: repo.path,
          runner: FakeAgentRunner((_) {
            throw const AgentRunException('el agente estallo', 3);
          }),
        ),
        throwsA(isA<AgentRunException>()),
      );
      expect(File('${repo.path}/a.txt').readAsStringSync(), 'linea uno\nlinea dos\n');
      await pipeline.dispose();
    });

    test('path traversal se bloquea al aplicar', () async {
      final pipeline = VibecodingPipeline();
      final proposal = await pipeline.propose(
        prompt: 'x',
        repoPath: repo.path,
        runner: FakeAgentRunner((_) {}),
      );

      final maligna = PatchProposal(
        id: 'v1:1:1',
        prompt: 'maligno',
        repoPath: repo.path,
        workdir: proposal.workdir,
        edits: [
          FileEdit(
            path: '../${repo.uri.pathSegments.last}/escapado.txt',
            before: '',
            after: 'pwned',
          ),
        ],
      );

      await expectLater(
        pipeline.applyProposal(maligna),
        throwsA(isA<ProposalConflict>()),
      );
      await pipeline.dispose();
    });
  });

  group('PatchProposal serializable', () {
    test('toJson/fromJson roundtrip sin perdida', () {
      final p = PatchProposal(
        id: 'v1:2:3',
        prompt: 'un prompt',
        workdir: null,
        edits: [
          FileEdit(path: 'lib/a.dart', before: 'a', after: 'b'),
          FileEdit(path: 'lib/c.dart', before: '', after: 'nuevo'),
        ],
        state: ProposalState.applied,
      );
      final back = PatchProposal.fromJson(p.toJson());
      expect(back.id, p.id);
      expect(back.prompt, p.prompt);
      expect(back.state, ProposalState.applied);
      expect(back.edits, hasLength(2));
      expect(back.edits[0].path, 'lib/a.dart');
      expect(back.edits[0].before, 'a');
      expect(back.edits[0].after, 'b');
      expect(back.edits[1].before, '');
      expect(back.createdAt, p.createdAt);
    });
  });
}