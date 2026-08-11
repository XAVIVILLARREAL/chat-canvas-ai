# SDD-113 — Etapa 4b: Gestor visual de skills + laboratorio

> **Proyecto:** empresa_dev — Etapa 4b del SUPER_PLAN.
> **Fecha:** 2026-08. **Estado:** En implementación.

## Objetivo

Crear skills de agente **visualmente** (form + bloques drag&drop + preview), **probarlas en vivo** en un laboratorio sandbox (input → ranking con confianza y por qué), **exportarlas a cualquier dialecto** (opencode, Cursor, Claude Code, Continue, Codex), y representarlas como **nodos del canva**. CI de dogfood con `flutter test --tags skills`.

## Slices

### 4b.1 — Modelo Skill + frontmatter (unit)

- `Skill {name, description, triggers (List<String>), tags (List<String>), permissions (List<String>), body (String)}` puro.
- Serialize → markdown con frontmatter YAML estilo opencode (`name`, `description` con `Trigger: ...` inline, tags como comentario) — compatible con el formato real de `.opencode/skills/dev/SKILL.md`.
- Parse del mismo formato (frontmatter → modelo), tolerante.
- Mini-parser YAML de frontmatter propio (sin dependencias): solo claves escalares y listas inline.

### 4b.2 — Laboratorio headless: scoring de triggers (unit, tags skills)

- `SkillLab.evaluate(String input, List<Skill> skills)` → ranking con `{skill, score, confidence (0..1), reasons (triggers matcheados)}`.
- Scoring: cada trigger del skill pesa (palabra completa en el input → más; substring → menos); confianza normalizada por cantidad de triggers del skill y de matches.
- Modo headless para CI: `flutter test --tags skills` valida fixtures (regression tests embebidos en la skill como bloque `## Tests` del body).

### 4b.3 — Export multi-dialecto (unit)

- `DialectExporter.render(skill, dialect)` → texto por dialecto:
  - **opencode**: SKILL.md frontmatter name/description (+ triggers en description).
  - **cursor**: `.cursor/rules/*.mdc` (frontmatter description + globs).
  - **claude**: SKILL.md frontmatter name/description (+ allowed-tools opcional).
  - **continue**: bloque YAML de reglas.
  - **codex**: AGENTS.md frontmatter name/description.
- `dialects()` → lista de dialectos con nombre y extensión.

### 4b.4 — Constructor visual + sandbox UI (widget)

- `SkillBuilderScreen`: form (name, description, triggers chips, tags chips, permissions), cuerpo Markdown con bloques arrastrables (Instrucciones, Ejemplos, Restricciones, Anti-patrones → secciones `## X` del body), preview live.
- `SkillLabScreen`: input → ranking en vivo (barras de confianza + por qué).
- Entrada desde el canva (menú "Skills") y como pantalla standalone.

### 4b.5 — Skills como nodos del canva

- Nodo `agent` con `content = skill serializado`; doble-click abre el builder. Relaciones (depende/excluye) como edges con etiqueta.

## Contratos

```dart
class Skill {
  String name; String description;
  List<String> triggers; List<String> tags; List<String> permissions;
  String body; // markdown
  String toMarkdown();       // frontmatter opencode + body
  static Skill? fromMarkdown(String text);
}

enum Dialect { opencode, cursor, claude, continue_, codex }

class SkillLabResult { Skill skill; double score; double confidence; List<String> reasons; }

class SkillLab { static List<SkillLabResult> evaluate(String input, List<Skill> skills); }

class DialectExporter { static String render(Skill s, Dialect d); }
```

## Tests (TDD)

- `test/skill_model_test.dart`: round-trip toMarkdown/fromMarkdown (frontmatter con description "Trigger: ...", tags); parse de un SKILL.md real (copiar del `dev`).
- `test/skill_lab_test.dart` (tags skills): trigger exacto en input → score alto y confidence > 0.5; sin matches → score 0 y vacío de razones; ranking ordenado; triggers múltiples suman; case-insensitive.
- `test/dialect_exporter_test.dart`: render por dialecto produce frontmatter correcto (cursor → `---\ndescription: ...\nglobs: ...\n---`; opencode → name; codex → AGENTS-style).
- `test/skill_builder_widget_test.dart`: el form crea un Skill con body con las secciones de los bloques; chips de triggers se agregan/quitan; preview muestra el markdown.
- `test/skill_lab_widget_test.dart`: sandbox muestra ranking (top skill + confidence) al evaluar input.

## Dogfood duro (gate)

3 skills de este repo **creadas desde la app** (evidencia en `data/evidence/`): por ejemplo `dev-4b` (resumen), `terminal-sos`, `commit-es`. Cada una pasa su test en el laboratorio (fixture en `test/skills_*/` con tags skills). El builder se usa vía `dart run tool/skill_evidence.dart` (headless, crea las skills con el modelo, las evalúa en el lab y escribe evidencia) + manual en la app.

## Gate (SUPER_PLAN)

- [ ] Unit: parser frontmatter; simulador con scoring; export por dialecto.
- [ ] Widget: form crea SKILL.md válido; drag&drop de bloques; sandbox muestra ranking.
- [ ] **Dogfood duro:** 3 skills creadas y aprobadas en el laboratorio (evidencia).
- [ ] CI: `flutter test --tags skills` verde; `flutter analyze` 0; build Windows.
- [ ] Manual (usuario): crear → probar → exportar a `.opencode/skills/` → reiniciar opencode → trigger real.
