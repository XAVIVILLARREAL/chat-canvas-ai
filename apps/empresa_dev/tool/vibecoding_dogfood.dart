// Dogfood Etapa 6: una feature real de ESTE repo implementada 100% vía el
// pipeline de vibecoding (el mismo que usa la app: copia aislada -> opencode
// real -> nodo-diff -> aceptar/rechazar).
//
// Uso (desde apps/empresa_dev):
//   dart run tool/vibecoding_dogfood.dart <repoPath> "<prompt>" [--apply]
//
// Sin --apply solo genera y muestra la propuesta (revisar antes de aceptar).

import 'dart:io';

import 'package:vibecoding_core/vibecoding_core.dart';
import 'package:empresa_dev/services/vibecoding_service.dart';

Future<void> main(List<String> args) async {
  final apply = args.contains('--apply');
  final fileIdx = args.indexOf('--prompt-file');
  final promptFile = fileIdx >= 0 && fileIdx + 1 < args.length
      ? args[fileIdx + 1]
      : null;
  if (args.length < 2 || promptFile == null) {
    stderr.writeln('uso: dart run tool/vibecoding_dogfood.dart '
        '<repoPath> --prompt-file <archivo.txt> [--apply]');
    stderr.writeln('  El prompt va en un archivo UTF-8: el argv de dart.bat '
        'en Windows mangla comillas dobles (hallado por el dogfood).');
    exit(2);
  }
  final repoPath = args[0];
  final prompt = File(promptFile).readAsStringSync();

  final pipeline = VibecodingPipeline();
  try {
    final proposal = await pipeline.propose(
      prompt: prompt,
      repoPath: repoPath,
      runner: AgentCommandRunnerAdapter(),
    );
    stdout.writeln('=== PROPUESTA ${proposal.id} ===');
    stdout.writeln('prompt: ${proposal.prompt.substring(0, prompt.length.clamp(0, 120))}...');
    stdout.writeln('edits: ${proposal.edits.length} archivo(s)');
    for (final e in proposal.edits) {
      stdout.writeln('\n--- ${e.path} '
          '(nuevo: ${e.isCreation}, borrado: ${e.isDeletion}) ---');
      if (e.before.isNotEmpty) {
        stdout.writeln('ANTES:\n${e.before}');
      }
      if (e.after.isNotEmpty) {
        stdout.writeln('DESPUES:\n${e.after}');
      }
    }
    if (apply) {
      await pipeline.applyProposal(proposal);
      stdout.writeln('\n=== APLICADA: ${proposal.state.name} ===');
    } else {
      stdout.writeln('\n(sin --apply: revisa y corre con --apply para aceptar)');
    }
  } catch (e) {
    stderr.writeln('fallo del agente: $e');
    exit(1);
  } finally {
    await pipeline.dispose();
  }
}
