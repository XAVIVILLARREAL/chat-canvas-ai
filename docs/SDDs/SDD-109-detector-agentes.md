# SDD — Inyección copia.md, pieza 1.1: Detector de agentes (estado del nodo)

> **Proyecto:** empresa_dev — prefase Etapa 4 (copia.md 1.1).
> **Fuente:** portado de `herdr/src/detect/manifests/` (Apache-2.0) — conceptos y esquema TOML, código propio Dart.
> **Fecha:** 2026-08. **Estado:** En implementación.

## Objetivo

El canva muestra en vivo el **estado del agente** que corre en un nodo: `working` / `blocked` / `idle` / `unknown`. Se clasifica mirando la salida del proceso (terminal/sesión del agente) con reglas portables estilo herdr: matchers `contains` / `regex` / `line_regex`, gates `any`/`all`, prioridades.

## Alcance

- `AgentState` enum: `idle`, `working`, `blocked`, `unknown` (más `done` como estado terminal distinto de idle — lección 2.4).
- `AgentDetector`: dado el texto de salida (buffer de la sesión), aplica reglas ordenadas por prioridad y devuelve el estado con la regla que lo clasificó (para depurar).
- Manifiestos TOML portados de herdr (subset): `opencode.toml` con la regla "esc to interrupt" → `working`, "waiting for user input"/"password:" → `blocked`, etc.
- Widget: en `AgentChatScreen` y en el nodo del canva, un badge de estado (punto de color + texto corto) alimentado por el detector sobre el buffer acumulado.

## Fuera de alcance

- Colas/orquestador de agentes (copia 2.3 → Etapa 6).
- Detección automática de qué agente corre en un terminal arbitrario (solo opencode por ahora).
- UI del badge en el canva en vivo → el badge se pinta en el chat primero; canva se conecta en Etapa 4 con los IDs estables (2.4).

## Contratos

```dart
enum AgentState { idle, working, blocked, unknown }

class AgentDetection {
  final AgentState state;
  final String? matchedRule;   // nombre de la regla que clasificó
  const AgentDetection(this.state, this.matchedRule);
}

class AgentDetector {
  AgentDetector({List<AgentRule>? rules})  // defaults: manifiestos portados
  AgentDetection detect(String output);    // reglas por prioridad desc
}

class AgentRule {
  final String name;
  final AgentState state;
  final List<String> contains;     // any-of
  final List<String> regex;        // any-of
  final List<String> lineRegex;    // any-of, por línea
  final int priority;
}
```

- `AgentRule` se serializa a/desde el formato TOML de herdr (parser mínimo `RuleTomlParser`).

## Tests (TDD) — `test/agent_detector_test.dart`

- "esc to interrupt" en la salida → `working` (gate del SUPER_PLAN).
- `password:` / "waiting for input" → `blocked`.
- Salida vacía o sin match → `idle` (sin regla).
- Prioridad: si "esc to interrupt" y "password:" coexisten, gana la de mayor prioridad (blocked > working).
- `lineRegex` matchea solo si aparece en una línea completa (regex `^> .*` con ancla).
- Parser TOML: manifiesto fixture (subset de opencode.toml) → reglas correctas.
- Widget: `AgentStateBadge` pinta el color/icono por estado.

## Gate (SUPER_PLAN)

- [ ] Un host que corre `opencode` se clasifica `working` cuando su salida contiene "esc to interrupt" (fixture).
- [ ] `flutter analyze` 0 + suite unit/widget verde + build Windows OK.