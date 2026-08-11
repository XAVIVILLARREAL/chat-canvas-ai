# Evidencia Etapa 4b — Gestor visual de skills + laboratorio

> Generado por `dart run tool/skill_evidence.dart` (dogfood headless con el modelo `Skill` + `SkillLab`).

## dev-4b

- Trigger de prueba: `4b`
- Score: 2.0 — Confidence: 0.67
- Por qué: 4b
- Resultado: APROBADA

### Export opencode → `.opencode/skills/dev-4b/SKILL.md`

```markdown
---
name: dev-4b
description: Resumen de estado de la Etapa 4b y cómo continuarla. Trigger: "4b", "etapa 4b", "skills"
---

# Skill dev-4b

## Instrucciones

Resumir el SDD-113, los slices completos, el CI y el gate pendiente de la Etapa 4b.

```

## terminal-sos

- Trigger de prueba: `terminal`
- Score: 2.0 — Confidence: 0.67
- Por qué: terminal
- Resultado: APROBADA

### Export opencode → `.opencode/skills/terminal-sos/SKILL.md`

```markdown
---
name: terminal-sos
description: Ayuda rápida con problemas de terminal SSH/SFTP. Trigger: "terminal", "ssh", "sftp"
---

# Skill terminal-sos

## Instrucciones

Diagnosticar conectividad y errores comunes de dartssh2.

```

## commit-es

- Trigger de prueba: `commit`
- Score: 2.0 — Confidence: 1.00
- Por qué: commit
- Resultado: APROBADA

### Export opencode → `.opencode/skills/commit-es/SKILL.md`

```markdown
---
name: commit-es
description: Redacta commits cortos en español con contexto. Trigger: "commit", "mensaje de commit"
---

# Skill commit-es

## Restricciones

- Prefijos: feat:, fix:, docs:, chore:.
- Máximo 72 caracteres.

```

## Exports multi-dialecto (commit-es)

### opencode (.md)

```
---
name: commit-es
description: Redacta commits cortos en español con contexto. Trigger: "commit", "mensaje de commit"
---

# Skill commit-es

## Restricciones

- Prefijos: feat:, fix:, docs:, chore:.
- Máximo 72 caracteres.

```

### Cursor (.mdc)

```
---
description: Redacta commits cortos en español con contexto. Trigger: "commit", "mensaje de commit"
globs: **/*
---

# Skill commit-es

## Restricciones

- Prefijos: feat:, fix:, docs:, chore:.
- Máximo 72 caracteres.

```

### Claude Code (.md)

```
---
name: commit-es
description: Redacta commits cortos en español con contexto. Trigger: "commit", "mensaje de commit"
---

# Skill commit-es

## Restricciones

- Prefijos: feat:, fix:, docs:, chore:.
- Máximo 72 caracteres.

```

### Continue (.yaml)

```
rules:
  - name: commit-es
    description: Redacta commits cortos en español con contexto
    match: commit, mensaje de commit

# Skill commit-es

## Restricciones

- Prefijos: feat:, fix:, docs:, chore:.
- Máximo 72 caracteres.

```

### Codex (.md)

```
---
name: commit-es
description: Redacta commits cortos en español con contexto. Trigger: "commit", "mensaje de commit"
---

# Skill commit-es

## Restricciones

- Prefijos: feat:, fix:, docs:, chore:.
- Máximo 72 caracteres.

```

## Resultado global

- **3/3 skills aprobadas en el laboratorio.**

