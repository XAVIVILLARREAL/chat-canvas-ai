# SDD — Inyección copia.md, pieza 1.4: Contratos JSON y exit codes semánticos

> **Proyecto:** empresa_dev — prefase Etapa 4 (copia.md 1.4).
> **Fuente de concepto:** buzz/herdr — salida máquina en JSON (stdout), errores en stderr, exit codes semánticos.
> **Fecha:** 2026-08. **Estado:** En implementación.

## Objetivo

Todo comando que la app lanza contra un agente/servicio (opencode runner, y en Etapa 4+ el agente vía `run`) cumple un contrato máquina: **JSON en stdout, errores legibles en stderr, exit code semántico**. `AgentCommandRunner` encapsula el lanzamiento y mapea a un resultado tipado; en Etapa 6 el agente podrá emitir el mismo contrato.

## Alcance

- `AgentCommandRunner`: lanza `opencode run <prompt>` (reemplaza el uso directo de `AgentRunner` donde se necesite resultado estructurado), captura stdout/stderr y exit code.
- `AgentCommandResult`: `{exitCode, stdout, stderr, parsedJson?}`.
- `ExitCode` semántico (herdr/buzz style):
  - 0 = ok, 1 = error general (p.ej. `EUNKNOWN`), 2 = argumentos inválidos, 3 = no encontrado (binario/archivo), 4 = sin permiso, 5 = timeout/interrumpido.
- `tryParseJson(stdout)` → `Map<String, Object?>?` (null si stdout no es JSON).

## Fuera de alcance

- El agente emitiendo JSON estructurado en el chat (Etapa 6).
- Permisos/UI.

## Contratos

```dart
enum SemanticExit {
  ok(0), general(1), usage(2), notFound(3), permission(4), timeout(5);

  int get code;
  static SemanticExit from(int exitCode);
}

class AgentCommandResult {
  final int exitCode;
  final String stdout;
  final String stderr;
  final Map<String, Object?>? json;
}

class AgentCommandRunner {
  AgentCommandRunner({String? opencodePath, Map<String, String>? env});
  Future<AgentCommandResult> run(String prompt, {Duration? timeout});
}
```

## Tests (TDD) — `test/agent_command_runner_test.dart`

- `run` con proceso que imprime JSON válido → `json` parseado, exit 0 → `SemanticExit.ok`.
- `run` con proceso que muere con exit 1 y stderr → `SemanticExit.general`, stderr capturado.
- `run` con binario inexistente → `SemanticExit.notFound` (no lanza).
- `run` con stdout no-JSON → `json == null`.
- `SemanticExit.from` mapea 0..5 y desconocidos → general.
- Timeout → `SemanticExit.timeout`.

> Fixtures: scripts de prueba que emiten stdout/stderr y exit codes conocidos
> (`tool/fixtures/` o temp dirs por test).

## Gate (SUPER_PLAN)

- [ ] La app puede distinguir ok / error-general / binario-faltante / timeout por exit code sin excepciones.