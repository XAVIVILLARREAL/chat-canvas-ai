import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibecoding_core/vibecoding_core.dart';
import 'package:empresa_dev/screens/vibecoding_screen.dart';
import 'package:empresa_dev/services/vibecoding_store.dart';
import 'package:empresa_dev/widgets/diff_preview.dart';

/// Runner falso (contrato vibecoding_core): edita archivos en la copia aislada.
class FakeVibeRunner implements AgentRunner {
  void Function(String cwd) onRun;
  FakeVibeRunner(this.onRun);

  @override
  Future<RunResult> run(String command, {String? cwd}) async {
    onRun(cwd ?? '');
    return const RunResult(exitCode: 0, stdout: '{}', stderr: '');
  }
}

/// Store falso en memoria: el historial completo (persistencia real a disco)
/// ya lo cubre vibecoding_store_test.dart; aquí solo se prueba la integración
/// de la pantalla con el store (cargar al abrir, persistir tras mutar).
class _FakeVibeStore extends VibecodingStore {
  final List<PatchProposal> saved = [];
  _FakeVibeStore() : super(directory: null);

  @override
  Future<List<PatchProposal>> load() async => List.of(saved);

  @override
  Future<void> save(List<PatchProposal> proposals) async {
    saved
      ..clear()
      ..addAll(proposals);
  }
}

PatchProposal proposalConEdits() => PatchProposal(
      id: 'v1:1:1',
      prompt: 'haz algo',
      repoPath: null,
      workdir: null,
      edits: [
        FileEdit(path: 'lib/nuevo.dart', before: '', after: 'void main() {}\n'),
        FileEdit(
          path: 'lib/viejo.dart',
          before: 'int a = 1;\n',
          after: 'int a = 2;\n',
        ),
      ],
    );

/// Expira los SnackBars visibles (auto-dismiss ~4s) para que el siguiente
/// pueda mostrarse sin quedar encolado.
Future<void> expireSnackBars(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  late Directory repo;

  setUp(() async {
    repo = await Directory.systemTemp.createTemp('vibe_widget_');
    Directory('${repo.path}/lib').createSync(recursive: true);
    File('${repo.path}/lib/main.dart').writeAsStringSync('void main() {}\n');
  });

  tearDown(() async {
    if (repo.existsSync()) await repo.delete(recursive: true);
  });

  group('DiffPreview', () {
    testWidgets('muestra path, badge nuevo y paneles antes/después',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DiffPreview(
            proposal: proposalConEdits(),
            onAccept: () {},
            onReject: () {},
          ),
        ),
      ));

      expect(find.text('lib/nuevo.dart'), findsOneWidget);
      expect(find.text('nuevo'), findsOneWidget);
      expect(
        find.textContaining('void main() {}', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('int a = 2;', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('int a = 1;', findRichText: true),
        findsOneWidget,
      );
      expect(find.byKey(const Key('diff-accept')), findsOneWidget);
      expect(find.byKey(const Key('diff-reject')), findsOneWidget);
      expect(find.byKey(const Key('diff-revert')), findsNothing);
    });

    testWidgets('en estado applied solo se ofrece Revertir', (tester) async {
      final p = proposalConEdits()..state = ProposalState.applied;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DiffPreview(proposal: p, onRevert: () {}),
        ),
      ));

      expect(find.byKey(const Key('diff-revert')), findsOneWidget);
      expect(find.byKey(const Key('diff-accept')), findsNothing);
      expect(find.byKey(const Key('diff-reject')), findsNothing);
    });
  });

  group('VibecodingScreen', () {
    testWidgets('proponer crea la propuesta sin tocar el arbol real',
        (tester) async {
      final runner = FakeVibeRunner((cwd) {
        File('$cwd/lib/nuevo.dart')
            .writeAsStringSync('int x = 1;\n');
      });

      await tester.pumpWidget(MaterialApp(
        home: VibecodingScreen(projectPath: repo.path, runner: runner),
      ));
      await tester.enterText(
          find.byKey(const Key('vibe-input')), 'crea un archivo');
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('vibe-propose')));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      expect(find.byType(DiffPreview), findsOneWidget);
      expect(find.text('lib/nuevo.dart'), findsOneWidget);
      expect(File('${repo.path}/lib/nuevo.dart').existsSync(), isFalse);
    });

    testWidgets('aceptar aplica en disco y muestra SnackBar', (tester) async {
      final runner = FakeVibeRunner((cwd) {
        File('$cwd/lib/main.dart').writeAsStringSync('void main() {}\n// nuevo\n');
      });

      await tester.pumpWidget(MaterialApp(
        home: VibecodingScreen(projectPath: repo.path, runner: runner),
      ));
      await tester.enterText(
          find.byKey(const Key('vibe-input')), 'anade comentario');
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('vibe-propose')));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();
      await expireSnackBars(tester);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('diff-accept')));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      expect(
        File('${repo.path}/lib/main.dart').readAsStringSync(),
        'void main() {}\n// nuevo\n',
      );
      expect(find.text('Cambios aplicados'), findsOneWidget);
      expect(find.text('aplicado'), findsOneWidget);
      expect(find.byKey(const Key('diff-revert')), findsOneWidget);
    });

    testWidgets('rechazar no toca nada y muestra SnackBar', (tester) async {
      final runner = FakeVibeRunner((cwd) {
        File('$cwd/lib/main.dart').writeAsStringSync('void main() {}\n// x\n');
      });

      await tester.pumpWidget(MaterialApp(
        home: VibecodingScreen(projectPath: repo.path, runner: runner),
      ));
      await tester.enterText(
          find.byKey(const Key('vibe-input')), 'cambia algo');
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('vibe-propose')));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();
      await expireSnackBars(tester);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('diff-reject')));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      expect(
        File('${repo.path}/lib/main.dart').readAsStringSync(),
        'void main() {}\n',
      );
      expect(find.text('Propuesta rechazada'), findsOneWidget);
      expect(find.text('rechazado'), findsOneWidget);
    });

    testWidgets('revertir restaura el contenido byte a byte', (tester) async {
      final runner = FakeVibeRunner((cwd) {
        File('$cwd/lib/main.dart').writeAsStringSync('void main() {}\n// x\n');
      });

      await tester.pumpWidget(MaterialApp(
        home: VibecodingScreen(projectPath: repo.path, runner: runner),
      ));
      await tester.enterText(
          find.byKey(const Key('vibe-input')), 'cambia algo');
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('vibe-propose')));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();
      await expireSnackBars(tester);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('diff-accept')));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();
      await expireSnackBars(tester);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('diff-revert')));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      expect(
        File('${repo.path}/lib/main.dart').readAsStringSync(),
        'void main() {}\n',
      );
      expect(find.text('Cambios revertidos'), findsOneWidget);
      expect(find.text('revertido'), findsOneWidget);
    });

    testWidgets('runner que falla muestra error sin propuestas',
        (tester) async {
      final runner = FakeVibeRunner((_) {})
        ..onRun = (cwd) {
          throw const AgentRunException('el agente estallo', 3);
        };

      await tester.pumpWidget(MaterialApp(
        home: VibecodingScreen(projectPath: repo.path, runner: runner),
      ));
      await tester.enterText(
          find.byKey(const Key('vibe-input')), 'algo imposible');
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('vibe-propose')));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      expect(find.textContaining('el agente estallo'), findsOneWidget);
      expect(find.byType(DiffPreview), findsNothing);
    });

    testWidgets('spinner de carga mientras el agente trabaja', (tester) async {
      final gate = Completer<RunResult>();
      final runner = _GatedRunner(gate.future);

      await tester.pumpWidget(MaterialApp(
        home: VibecodingScreen(projectPath: repo.path, runner: runner),
      ));
      await tester.enterText(
          find.byKey(const Key('vibe-input')), 'trabaja');
      await tester.tap(find.byKey(const Key('vibe-propose')));
      await tester.pump();

      expect(find.byKey(const Key('vibe-loading')), findsOneWidget);

      await tester.runAsync(() async {
        gate.complete(const RunResult(exitCode: 0, stdout: '{}', stderr: ''));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('vibe-loading')), findsNothing);
    });
  });

  group('historial persistente (slice 6.3)', () {
    testWidgets('abre cargando las propuestas guardadas', (tester) async {
      final store = _FakeVibeStore();
      final saved = proposalConEdits()
        ..state = ProposalState.applied;
      await store.save([saved]);

      await tester.pumpWidget(MaterialApp(
        home: VibecodingScreen(
          projectPath: repo.path,
          runner: FakeVibeRunner((_) {}),
          store: store,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(DiffPreview), findsOneWidget);
      expect(find.text('aplicado'), findsOneWidget);
      expect(find.textContaining('Sin propuestas aún'), findsNothing);
    });

    testWidgets('proponer persiste la propuesta en el historial',
        (tester) async {
      final store = _FakeVibeStore();
      final runner = FakeVibeRunner((cwd) {
        File('$cwd/lib/nuevo.dart').writeAsStringSync('int x = 1;\n');
      });

      await tester.pumpWidget(MaterialApp(
        home: VibecodingScreen(
          projectPath: repo.path,
          runner: runner,
          store: store,
        ),
      ));
      await tester.enterText(
          find.byKey(const Key('vibe-input')), 'crea un archivo');
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('vibe-propose')));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      expect(store.saved, hasLength(1));
      expect(store.saved.single.state, ProposalState.pending);
      final onDisk = await store.load();
      expect(onDisk, hasLength(1));
      expect(onDisk.single.prompt, 'crea un archivo');
    });

    testWidgets('aceptar actualiza el estado en el historial en disco',
        (tester) async {
      final store = _FakeVibeStore();
      final runner = FakeVibeRunner((cwd) {
        File('$cwd/lib/main.dart')
            .writeAsStringSync('void main() {}\n// nuevo\n');
      });

      await tester.pumpWidget(MaterialApp(
        home: VibecodingScreen(
          projectPath: repo.path,
          runner: runner,
          store: store,
        ),
      ));
      await tester.enterText(
          find.byKey(const Key('vibe-input')), 'anade comentario');
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('vibe-propose')));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();
      await expireSnackBars(tester);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('diff-accept')));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      expect(store.saved.single.state, ProposalState.applied);
      expect((await store.load()).single.state, ProposalState.applied);
    });
  });
}

class _GatedRunner implements AgentRunner {
  final Future<RunResult> result;
  _GatedRunner(this.result);

  @override
  Future<RunResult> run(String command, {String? cwd}) async => result;
}