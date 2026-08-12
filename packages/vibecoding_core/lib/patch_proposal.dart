/// Modelos del nodo-diff de vibecoding (Dart puro, sin Flutter).
///
/// Una [PatchProposal] es la propuesta de cambio del agente IA sobre el repo:
/// lista de [FileEdit] (antes/después por archivo), estado de ciclo de vida y
/// trazabilidad (prompt, timestamps). Serializable para persistir historial.
library;

import 'dart:convert';

/// Estados del ciclo de vida de una propuesta.
enum ProposalState {
  pending, //  propuesta generada, esperando decisión
  applied, //  aceptada: cambios escritos en el árbol real
  rejected, // rechazada: nada se tocó
  reverted, // revertida: el árbol volvió al estado previo
  failed, //  conflicto o error: requiere intervención
}

/// Edición de un único archivo: contenido original -> propuesto.
class FileEdit {
  final String path; // ruta relativa al repo (separador '/')
  final String before; // contenido original
  final String after; // contenido propuesto

  const FileEdit({
    required this.path,
    required this.before,
    required this.after,
  });

  bool get isDeletion => before.isNotEmpty && after.isEmpty;
  bool get isCreation => before.isEmpty && after.isNotEmpty;

  Map<String, Object?> toJson() => {
        'path': path,
        'before': before,
        'after': after,
      };

  factory FileEdit.fromJson(Map<String, Object?> json) => FileEdit(
        path: json['path']! as String,
        before: json['before']! as String,
        after: json['after']! as String,
      );

  @override
  bool operator ==(Object other) =>
      other is FileEdit &&
      other.path == path &&
      other.before == before &&
      other.after == after;

  @override
  int get hashCode => Object.hash(path, before, after);

  @override
  String toString() => 'FileEdit($path)';
}

/// Propuesta de cambio del agente (el "nodo-diff" del canva).
class PatchProposal {
  /// ID opaco estable, patrón `v<sec>:<ms>:<seq>` (nunca reutilizado).
  final String id;
  final String prompt;
  final String? repoPath; // proyecto destino (null si vino de historial sin repo)
  final String? workdir; // copia aislada efímera (null tras dispose)
  final List<FileEdit> edits;
  ProposalState state;
  final DateTime createdAt;

  PatchProposal({
    required this.id,
    required this.prompt,
    this.repoPath,
    this.workdir,
    required this.edits,
    this.state = ProposalState.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  PatchProposal copyWith({
    ProposalState? state,
    String? workdir,
  }) =>
      PatchProposal(
        id: id,
        prompt: prompt,
        repoPath: repoPath,
        workdir: workdir ?? this.workdir,
        edits: edits,
        state: state ?? this.state,
        createdAt: createdAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'prompt': prompt,
        'repoPath': repoPath,
        'workdir': workdir,
        'edits': edits.map((e) => e.toJson()).toList(),
        'state': state.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PatchProposal.fromJson(Map<String, Object?> json) => PatchProposal(
        id: json['id']! as String,
        prompt: json['prompt']! as String,
        repoPath: json['repoPath'] as String?,
        workdir: json['workdir'] as String?,
        edits: [
          for (final e in json['edits']! as List)
            FileEdit.fromJson((e as Map).cast<String, Object?>()),
        ],
        state: ProposalState.values.byName(json['state']! as String),
        createdAt: DateTime.parse(json['createdAt']! as String),
      );

  /// Identificador estable para el nodo-diff en el canva: `v<sec>:<ms>:<seq>`.
  static String newId(int seq) {
    final now = DateTime.now();
    return 'v${now.second}:${now.millisecond % 1000}:$seq';
  }

  @override
  String toString() => 'PatchProposal($id, ${state.name}, ${edits.length} edits)';
}

/// Serialización de ida y vuelta (para el historial en SQLite, slice 6.3).
extension PatchProposalJson on PatchProposal {
  String encode() => jsonEncode(toJson());

  static PatchProposal decode(String source) =>
      PatchProposal.fromJson(jsonDecode(source) as Map<String, Object?>);
}
