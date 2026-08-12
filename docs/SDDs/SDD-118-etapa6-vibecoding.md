# SDD-118 — Etapa 6: Vibecoding (agente IA trabaja en el canva, nodo-diff)

> Fuentes de inspiración (copia.md): 2.3 orquestador (buzz-acp) → slice 6.3;
> Z5 `streaming_diff` (Zed, concepto) → slice 6.2; Z6 permisos por tool
> (Zed, concepto) → slice 6.4; Z7 ACP (concepto) → post-Etapa 6. Cero código
> crudo (zed es GPL-3.0; buzz Apache-2.0, atribuir origen).

## Objetivo

La Etapa 6 del SUPER_PLAN: el agente IA (opencode CLI vía `AgentCommandRunner`,
ya existente — copia 1.4) trabaja **dentro del canva**. Cada propuesta de cambio
se materializa como un **nodo-diff** con preview, aceptar/rechazar/revertir y
**historial navegable**. Al cerrar: dogfood = una feature real de este repo
implementada 100% vía vibecoding desde la app.

## Flujo

```
Canva (nodo agente o menú) → "Vibecoding"
  → VibecodingScreen (chat + historial de propuestas)
      usuario escribe prompt → VibecodingPipeline
        → clona worktree aislado del proyecto (o copia sandbox)
        → opencode run "prompt" (AgentCommandRunner, contrato JSON)
        → git diff del worktree → PatchProposal (nodo-diff)
      → NodoVisor: preview antes/después + botones
          Aceptar → aplica hunks al árbol real → estado applied
          Rechazar → descarta → estado rejected
          Revertir → undo del aplicado (via stash de hunks o git checkout de los archivos)
      → historial persistido (SQLite via store existente) navegable desde el canva
```

Aislamiento por propuesta: el agente **nunca toca el árbol de trabajo real**
mientras se decide — solo un worktree/clon efímero bajo `.opencode/.vibe/<id>/`
(concepto Zed 8.6 worktree isolation).

## Contratos

```dart
// packages/vibecoding_core/ (Dart puro, nuevo package monorepo)  — slice 6.1 ✅ (17 tests)

enum ProposalState { pending, applied, rejected, reverted, failed }
// NOTA: 'approved' del diseño previo se fusionó con apply (pending -> applied directo).

class FileEdit {
  final String path;        // ruta relativa al repo
  final String before;      // contenido original (para revert)
  final String after;       // contenido propuesto
}

class PatchProposal {
  final String id;          // 'v<sec>:<ms>:<seq>' (patrón canvas_node ID)
  final String prompt;
  final String? repoPath;   // proyecto destino (imprescindible para aplicar/revertir)
  final String? workdir;    // copia aislada efímera (null tras dispose)
  final List<FileEdit> edits;
  ProposalState state;
  final DateTime createdAt;
  PatchProposal copyWith({ProposalState? state, ...});
  Map<String, Object?> toJson(); factory PatchProposal.fromJson(...); // + encode()/decode()
}

// diff_parser.dart (puro, sin disco: solo sintaxis de unified diff)
class Hunk { oldStart, oldCount, newStart, newCount, List<String> before, after }
class FilePatch { path, bool isNew, bool isDeleted, List<Hunk> hunks }
class DiffResult { List<FilePatch> files; bool get isEmpty }
class DiffParser { static DiffResult parsePatch(String patch); } // DiffFormatException tipada

// vibecoding_pipeline.dart (puro, dart:io)
abstract interface class AgentRunner {  // el AgentCommandRunner de la app se adapta
  Future<RunResult> run(String command, {String? cwd});
}
class RunResult { int exitCode; String stdout; String stderr; }
class AgentRunException implements Exception { message, exitCode }   // runner falla
class ProposalConflict implements Exception { path, reason }         // conflicto/traversal

class VibecodingPipeline {
  Future<PatchProposal> propose({required String prompt, required String repoPath,
                                 required AgentRunner runner});
  // 1. copia aislada (ignora .git/build/.dart_tool/node_modules/.venv/.idea/...)
  // 2. runner.run('opencode run <json>', cwd: aislado); exit != 0 -> AgentRunException
  // 3. contraste byte a byte (UTF-8) -> FileEdit por archivo -> PatchProposal(pending)
  //    El árbol real NUNCA se toca durante propose (aislamiento).
  Future<void> applyProposal(PatchProposal p);   // before == actual? escribe after -> applied
  Future<void> rejectProposal(PatchProposal p);  // solo estado -> rejected
  Future<void> revertProposal(PatchProposal p);  // after == actual? restaura before -> reverted
  Future<void> dispose();                        // borra copias efímeras (idempotente)
}
// transiciones ilegales -> StateError; conflicto (contenido real cambió / '..' traversal
// / ruta absoluta) -> ProposalConflict y la propuesta pasa a failed.

// apps/empresa_dev/lib/screens/vibecoding_screen.dart (UI glassmorphism neón)  — slice 6.2
class VibecodingScreen extends StatefulWidget { final String? projectPath; }
// widget DiffPreview: antes/después con resaltado de +/-, Aceptar/Rechazar/Revertir
```

**Regla monorepo:** `vibecoding_core` es Dart puro (sin Flutter); la persistencia
de propuestas vive en `apps/empresa_dev` (store con path_provider, patrón
`canva_store`).

## Tests (TDD)

1. `packages/vibecoding_core/test/diff_parser_test.dart` (unit):
   - parsea un unified diff real de 2 archivos → `FileEdit` correctos (before/after).
   - diff vacío → `edits` vacío; sintaxis rota → error tipado, no excepción cruda.
2. `packages/vibecoding_core/test/pipeline_test.dart` (unit, runner **falso**):
   - `propose` con runner fake que "edita" el worktree → PatchProposal con edits y
     estado `pending`; el árbol real queda intacto (aislamiento).
   - `applyProposal` → archivos modificados + estado `applied`; `revertProposal` →
     contenido original restaurado exacto (byte a byte) + estado `reverted`;
     `rejectProposal` → nada tocado.
   - transiciones ilegales lanzan `StateError` (apply sobre applied, revert sobre rejected).
3. `apps/empresa_dev/test/vibecoding_widget_test.dart` (widget):
   - chat: prompt → (runner mock) → propuesta aparece como nodo-diff con preview.
   - Aceptar → SnackBar verde + historial actualizado; Rechazar → sin cambios;
     Revertir → contenido vuelve (widget con store fake).
4. `apps/empresa_dev/test/vibecoding_store_test.dart` (unit store):
   - propuestas persisten, historial navegable, estados reconstructibles desde JSON.
5. `integration_test/vibecoding_flow_test.dart` (E2E, `--tags integration`, opencode real):
   - fixture `test/fixtures/vibe_demo/` (un .dart con un TODO + test): prompt real
     "implementa el TODO" → propuesta → aplicar → `flutter test` del fixture pasa.
   - Se marca `@Tags(['integration'])`: no corre en CI sin opencode/red.

## Gate (SUPER_PLAN Etapa 6)

- [x] Unit ✅ (slice 6.1): `diff_parser_test.dart` (6 tests) + `pipeline_test.dart`
      (11 tests) — transiciones aceptar/rechazar/revertir, conflictos, traversal.
- [x] Widget ✅ (slice 6.2): `vibecoding_widget_test.dart` (8 tests) — chat +
      nodo-diff (DiffPreview) con Aceptar/Rechazar/Revertir sin estado residual,
      spinner de carga y error tipado. Suites: app 132 tests, monorepo analyze 0.
- [x] Widget ✅ (slice 6.3): `vibecoding_store_test.dart` (4) + historial en
      `vibecoding_widget_test.dart` (3) + nodo `proposal` en `canva_widget_test.dart`
      (4) — persistencia JSON, carga al abrir, mutaciones guardadas, tile en menú
      Añadir, nodo en canva con color por estado, tap → nodo-diff con acciones.
      Suites: app 143 tests, analyze 0, melos analyze/test OK. *(2026-08-11)*
- [x] Integration ✅ (slice 6.4): `vibecoding_integration_test.dart` (`@Tags
      (['integration'])`) — opencode real sobre fixture `test/fixtures/vibe_demo/`
      (lib/todo.dart con TODO + `test/todo_check.dart` sin dependencias) →
      propuesta con edit de lib/todo.dart → aplicar → `dart run test/todo_check.dart`
      pasa (TODO_TEST_OK). Fix hallado: `AgentCommandRunner` no cerraba stdin →
      opencode (node) moría con EUNKNOWN; cierre tras Process.start (mismo fix
      que OpenCodeAgentRunner). E2E verde en ~8s. *(2026-08-11)*
- [x] **Dogfood:** una feature real de **este repo** implementada 100% vía
      vibecoding desde la app. *(2026-08-11: `relativeTimeDetailed` en
      `vibecoding_core` — el agente opencode real (deepseek-v4-flash) generó la
      función + 4 tests exactos al contrato, aplicados con `--apply` y suite en
      verde (31 unit + analyze 0). El dogfood destapó y arregló 3 bugs reales
      del pipeline: (1) `pubspec_overrides.yaml` del monorepo entraba a la
      copia aislada; (2) `.dart_tool/`/`build/` generados por el agente
      entraban como edits; (3) prompts con `"`, `->` o `&` se manglaban — argv
      de `dart.bat` + escaping JSON no compatible con cmd; fix: prompt por
      archivo (`--prompt-file`) y `AgentCommandRunnerAdapter` por argv-list al
      `opencode.exe` nativo (sin cmd), patrón `/s /c ""...""` solo para el
      shim `.cmd`.)*
- [x] CI: `flutter analyze` 0 + suite unit/widget verde + melos.
- [ ] SUPER_PLAN: marcar Etapa 6 + definir SDD-119 (Etapa 7) al cerrar.

## Slices de implementación (TDD por slice)

- **6.1** package `vibecoding_core`: `DiffParser` + `PatchProposal` + `VibecodingPipeline`
  con runner inyectado (aísla del runtime real; unit con fakes).
- **6.2** **Widgets**: `DiffPreview` + `VibecodingScreen` + integración
  en canva (menú "Vibecoding" abre con el proyecto del nodo/nodo `.md` abierto).
- **6.3** Store + historial + nodo-diff en el canva (nodo tipo `proposal` con
  estado visible: `Aceptar/Rechazar/Revertir` también desde el canva).
- **6.4** ✅ **Integración real** (`test/vibecoding_integration_test.dart`,
  `@Tags(['integration'])`): opencode real sobre fixture `vibe_demo` → propuesta
  → aplicar → `dart run test/todo_check.dart` pasa. Z6 (permisos por tool):
  cubierto arquitectónicamente — el agente corre en copia aislada (ignora
  `.opencode` del proyecto real), solo se aplican los FileEdits dentro del repo
  (anti-traversal de `applyProposal`, tests en 6.1); escrituras fuera del repo
  en el sandbox se descartan por el contraste byte a byte. ACP/Z9 quedan como
  referencia para SDD-120+.

## Notas de implementación

- **Aislamiento**: `git worktree add --detach <tmp>` cuando el repo tiene git
  (rápido y barato); si no, copia del árbol ignorando `build/`, `.dart_tool/`,
  `.git/`, `node_modules/`. El agente corre con `cwd` = worktree.
- **opencode por contrato**: `opencode run "<prompt>"` (CLI estable); el stdout
  JSON se parsea con el `AgentCommandRunner` existente (BOM saneado, exit
  semánticos, timeout→kill). Si falta el binario (exit 9009/notFound) →
  estado `failed` con mensaje claro en UI (no crash).
- **Diff**: `git -C <worktree> diff --no-ext-diff --binary`; `DiffParser` maneja
  diffs de 2 y 3 líneas de contexto, archivos nuevos (dev/null) y borrados.
  `before` se obtiene del diff (líneas `-`/originales), no de re-lectura (evita
  carreras si el usuario edita el archivo abierto mientras decide).
- **Revert seguro**: `revertProposal` reescribe `before` de cada FileEdit; si el
  archivo cambió tras el apply (mtime/content hash distinto), marcar `failed`
  con warning — el usuario decide. Nunca `git checkout` ciego.
- **UI**: glassmorphism neón (GlassPanel + NeonCard existentes); el nodo-diff
  usa glow violeta al estar `pending`, verde al `applied`, rojo al `failed`.
- **Historias**: cada propuesta guarda prompt + edits + estados + timestamps
  (auditoría del vibecoding, misma filosofía que evidence_store).