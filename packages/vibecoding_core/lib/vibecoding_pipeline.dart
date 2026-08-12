/// Pipeline de vibecoding: aísla el proyecto en una copia, corre el agente
/// (runner inyectado), extrae los cambios como [PatchProposal] y aplica/
/// rechaza/revierte contra el árbol real (Dart puro, sin Flutter).
///
/// Aislamiento por copia: el agente NUNCA toca el árbol real mientras se
/// decide. `git worktree` puede sustituir la copia en slice posterior (el
/// contraste se hace byte a byte, independiente del método de aislamiento).
library;

import 'dart:convert';
import 'dart:io';

import 'patch_proposal.dart';

/// Contrato de ejecución de comandos de agente (el `AgentCommandRunner` de la
/// app se adapta a esta interfaz; los tests inyectan fakes).
abstract interface class AgentRunner {
  Future<RunResult> run(String command, {String? cwd});
}

/// Resultado tipado de un comando (contrato JSON en stdout / errores en
/// stderr / exit semántico — copia 1.4).
class RunResult {
  final int exitCode;
  final String stdout;
  final String stderr;
  const RunResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });
}

/// El agente (runner) falló al ejecutar.
class AgentRunException implements Exception {
  final String message;
  final int exitCode;
  const AgentRunException(this.message, [this.exitCode = 1]);

  @override
  String toString() => 'AgentRunException($exitCode): $message';
}

/// Conflicto al aplicar/revertir (el árbol real cambió o la ruta es inválida).
class ProposalConflict implements Exception {
  final String path;
  final String reason;
  const ProposalConflict(this.path, this.reason);

  @override
  String toString() => 'ProposalConflict($path): $reason';
}

/// Directorios que nunca se copian al aislar el proyecto.
const _ignoredNames = <String>{
  '.git',
  '.dart_tool',
  'build',
  'node_modules',
  '.venv',
  '.idea',
  '.pytest_cache',
  '__pycache__',
  '.pub-cache',
  '.opencode',
  // melos: rutas relativas al árbol REAL (../../packages/...) → opencode
  // intentaría leer paquetes fuera del sandbox (permiso rechazado → fallo).
  'pubspec_overrides.yaml',
};

class VibecodingPipeline {
  Directory? _root;
  var _seq = 0;

  /// Genera una propuesta: copia aislada -> runner -> contraste de árboles.
  Future<PatchProposal> propose({
    required String prompt,
    required String repoPath,
    required AgentRunner runner,
  }) async {
    final workdir = await _isolate(repoPath);
    final id = PatchProposal.newId(++_seq);
    try {
      final result = await runner.run(
        'opencode run ${jsonEncode(prompt)}',
        cwd: workdir,
      );
      if (result.exitCode != 0) {
        throw AgentRunException(
          result.stderr.isEmpty ? 'exit ${result.exitCode}' : result.stderr,
          result.exitCode,
        );
      }
      final edits = _diffTrees(repoPath, workdir);
      return PatchProposal(
        id: id,
        prompt: prompt,
        repoPath: repoPath,
        workdir: workdir,
        edits: edits,
      );
    } catch (_) {
      final dir = Directory(workdir);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      rethrow;
    }
  }

  /// Acepta la propuesta: escribe [after] en el árbol real.
  Future<void> applyProposal(PatchProposal p) async {
    _require(p, ProposalState.pending, 'aplicar');
    final repo = _repoOf(p);
    try {
      for (final edit in p.edits) {
        _guardPath(repo, edit.path);
        final current = _readOrNull(repo, edit.path);
        if (current != edit.before) {
          throw ProposalConflict(
            edit.path,
            'el archivo real cambió tras la propuesta '
            '(¿edición manual mientras decidías?)',
          );
        }
        _writeText(repo, edit.path, edit.after);
      }
      p.state = ProposalState.applied;
    } on ProposalConflict {
      p.state = ProposalState.failed;
      rethrow;
    }
  }

  /// Revierte una propuesta aplicada: restaura [before] byte a byte.
  Future<void> revertProposal(PatchProposal p) async {
    _require(p, ProposalState.applied, 'revertir');
    final repo = _repoOf(p);
    try {
      for (final edit in p.edits) {
        _guardPath(repo, edit.path);
        final current = _readOrNull(repo, edit.path);
        if (current != edit.after) {
          throw ProposalConflict(
            edit.path,
            'el archivo real cambió tras aplicar (¿edición manual?)',
          );
        }
        _writeText(repo, edit.path, edit.before);
      }
      p.state = ProposalState.reverted;
    } on ProposalConflict {
      p.state = ProposalState.failed;
      rethrow;
    }
  }

  /// Rechaza la propuesta: no toca nada, solo estado.
  Future<void> rejectProposal(PatchProposal p) async {
    _require(p, ProposalState.pending, 'rechazar');
    p.state = ProposalState.rejected;
  }

  /// Elimina todas las copias aisladas. Idempotente.
  Future<void> dispose() async {
    final root = _root;
    _root = null;
    if (root != null && root.existsSync()) {
      await root.delete(recursive: true);
    }
  }

  // --- privado ---

  void _require(PatchProposal p, ProposalState expected, String accion) {
    if (p.repoPath == null) {
      throw StateError('propuesta sin repoPath: no se puede $accion');
    }
    if (p.state != expected) {
      throw StateError(
        'no se puede $accion una propuesta en estado ${p.state.name} '
        '(se esperaba ${expected.name})',
      );
    }
  }

  String _repoOf(PatchProposal p) => p.repoPath!;

  Future<String> _isolate(String repoPath) async {
    _root ??= await Directory.systemTemp.createTemp('vibecoding_');
    final workdir = '${_root!.path}${Platform.pathSeparator}p$_seq';
    final target = Directory(workdir);
    target.createSync(recursive: true);

    final source = Directory(repoPath);
    for (final entry in source.listSync(recursive: true)) {
      final rel = entry.path.substring(source.path.length + 1)
          .split(Platform.pathSeparator)
          .join('/');
      if (rel.split('/').any(_ignoredNames.contains)) continue;
      if (entry is File) {
        final dest = File('${target.path}${Platform.pathSeparator}'
            '${rel.split('/').join(Platform.pathSeparator)}');
        dest.parent.createSync(recursive: true);
        entry.copySync(dest.path);
      }
    }
    return target.path;
  }

  /// Contraste byte a byte entre árbol real y copia aislada (solo UTF-8).
  List<FileEdit> _diffTrees(String repoPath, String workdir) {
    final edits = <FileEdit>[];

    void add(FileEdit edit) => edits.add(edit);

    for (final entry in Directory(repoPath).listSync(recursive: true)) {
      if (entry is! File) continue;
      final rel = entry.path.substring(repoPath.length + 1)
          .split(Platform.pathSeparator)
          .join('/');
      if (rel.split('/').any(_ignoredNames.contains)) continue;

      final copyFile = File('$workdir${Platform.pathSeparator}'
          '${rel.split('/').join(Platform.pathSeparator)}');
      final before = _tryReadText(entry);
      final after = copyFile.existsSync() ? _tryReadText(copyFile) : null;

      if (after == null && before == null) continue; // binario: fuera de alcance
      if (after == before) continue;
      add(FileEdit(
        path: rel,
        before: before ?? '',
        after: after ?? '',
      ));
    }

    // archivos creados por el agente que no existían en el original
    for (final entry in Directory(workdir).listSync(recursive: true)) {
      if (entry is! File) continue;
      final rel = entry.path.substring(workdir.length + 1)
          .split(Platform.pathSeparator)
          .join('/');
      if (rel.split('/').any(_ignoredNames.contains)) continue;
      final original = File('$repoPath${Platform.pathSeparator}'
          '${rel.split('/').join(Platform.pathSeparator)}');
      if (!original.existsSync()) {
        add(FileEdit(
          path: rel,
          before: '',
          after: _tryReadText(entry) ?? '',
        ));
      }
    }
    return edits;
  }

  static String? _tryReadText(File file) {
    try {
      return utf8.decode(file.readAsBytesSync());
    } on FormatException {
      return null; // binario
    } on FileSystemException {
      return null;
    }
  }

  static String? _readOrNull(String repo, String relPath) {
    final file = File('$repo${Platform.pathSeparator}'
        '${relPath.split('/').join(Platform.pathSeparator)}');
    if (!file.existsSync()) return null;
    return _tryReadText(file);
  }

  static void _writeText(String repo, String relPath, String content) {
    final file = File('$repo${Platform.pathSeparator}'
        '${relPath.split('/').join(Platform.pathSeparator)}');
    if (content.isEmpty && file.existsSync()) {
      file.deleteSync();
      return;
    }
    if (content.isEmpty) return;
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  /// Anti path traversal: rutas absolutas o con '..' fuera del repo se bloquean.
  static void _guardPath(String repo, String relPath) {
    final segments = relPath.split('/');
    if (relPath.startsWith('/') ||
        relPath.contains(r'\') ||
        segments.any((s) => s == '..' || s.isEmpty)) {
      throw ProposalConflict(relPath, 'ruta inválida (traversal bloqueado)');
    }
    final normalizedRepo = repo.replaceAll('\\', '/');
    final candidate = '$normalizedRepo/$relPath';
    if (!candidate.startsWith('$normalizedRepo/')) {
      throw ProposalConflict(relPath, 'ruta fuera del proyecto');
    }
  }
}
