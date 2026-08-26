# CONTRATO-SKILL — El formato `.md` de los skills

> **Producto:** Canvas AI · **Estado:** v1.0 · 2026-08-25 · Base: [SCHEMA-MAESTRO](./SCHEMA-MAESTRO.md) y [PRD](./PRD.md) F7
> **Regla:** un skill **es un documento `.md`** (frontmatter + receta). El editor visual compila a este formato; el `.md` es la fuente de verdad canónica. Sin YAML a mano: el editor lo genera.

---

## 1 · Estructura

```markdown
---
name: "Revisor de Código"              # nombre visible
slug: code-reviewer                    # identificador único para /skill <slug>
version: 1                             # versión semántica del skill
description: "Revisa PRs por criterios de calidad y seguridad."   # 1 línea
role: reviewer                         # dev|qa|reviewer|planner|executor|expert|process|flow
model_tier: balanced                   # economy|balanced|delivery
budget: { max_usd: 2.0, max_runs: 10 } # límites por invocación (guardrail)
tools_allowlist:                       # tool-gating ESTRICTO (solo estos)
  - read_file
  - search_code
  - run_tests
tools_denylist: []                     # prohibidos aunque existan (seguridad)
personality:
  emoji: "🔍"
  avatar_prompt: "insecto detective con lupa, estilo flat, fondo azul"
  bio: "Soy meticuloso: prefiero romper el build que dejar pasar un bug."
  greeting: "¡Hola! Voy a revisar el código con lupa."
languages: [es, en]                    # idiomas en que responde
memory: { use_knowledge: true, remember_runs: true }
mcp: []                                # MCP servers permitidos (vacio = ninguno)
tags: [code-review, quality, security]
global: false                          # true = disponible en todos los proyectos
---

# Revisor de Código

## Rol
Revisas pull requests y código existente. Eres estricto pero constructivo.

## Proceso (SOP)
1. Lee el diff o el archivo señalado.
2. Busca: bugs, deuda, seguridad (secretos, inyección), claridad.
3. Corre los tests si están permitidos (`run_tests`).
4. Devuelve el resultado como lista priorizada: CRÍTICO / ALTO / MEDIO / BAJO.

## Salida (contrato de resultado)
```json
{
  "severity": "high",
  "findings": [{ "file": "...", "line": 12, "level": "critical", "message": "..." }],
  "tests": { "passed": 8, "failed": 1 }
}
```

## Restricciones
- NO modifiques archivos (solo `read_file`, `search_code`, `run_tests`).
- Si encuentras un secreto, no lo imprimas: repórtalo como `critical`.
```

---

## 2 · Schema del frontmatter (validación Zod en el editor)

| Campo | Tipo | Obligatorio | Regla |
|---|---|---|---|
| `name` | string | ✅ | ≤60 chars |
| `slug` | string | ✅ | `[a-z0-9-]`, único por proyecto |
| `version` | int | ✅ | ≥1, auto-incrementa al editar (→ `skill_versions`) |
| `description` | string | ✅ | 1 línea, para búsqueda/marketplace |
| `role` | enum | ✅ | dev/qa/reviewer/planner/executor/expert/process/flow |
| `model_tier` | enum | ✅ | economy/balanced/delivery |
| `budget` | object | ✅ | `{max_usd, max_runs}` — guardrail (plan-u / circuito) |
| `tools_allowlist` | string[] | ✅ | mínimo [] — gating estricto (G.2) |
| `tools_denylist` | string[] | ⬜ | prohibiciones explícitas |
| `personality` | object | ✅ | emoji + avatar_prompt + bio + greeting |
| `languages` | string[] | ⬜ | default [es, en] |
| `memory` | object | ⬜ | use_knowledge, remember_runs |
| `mcp` | string[] | ⬜ | servers MCP permitidos (default [] = ninguno) |
| `tags` | string[] | ⬜ | descubrimiento |
| `global` | bool | ⬜ | default false |

## 3 · Roles de skill (mapa a comportamiento)

| role | Comportamiento base | ¿Escribe? |
|---|---|---|
| `dev` | implementa código/diffs | ✅ con fast-apply |
| `qa` | ejecuta y escribe tests | ✅ (tests) |
| `reviewer` | audita, solo lee | ❌ read-only |
| `planner` | descompone tareas/PRD | ❌ (plan) |
| `executor` | ejecuta tareas puntuales | depende de tools |
| `supervisor` | **mayordomo de la cuenta**: ve TODOS los proyectos/sesiones del Control Room, atiende puentes de mensajería (N.9), crea/pausa sesiones por orden; destructivas con confirmación numerada | ✅ control (con guardrails propios) |
| `expert` | consejero (Consejo de Expertos, post-v1) | ❌ read-only |
| `process` | secuencia de pasos (rutina) | según tools |
| `flow` | flujo visual (se materializa en canvas) | — |

## 4 · Tipos de skill (materialización)

1. **Agente** — `role` + personalidad; se invoca en sesión (`/agent <slug>`).
2. **Experto** — consejero read-only (para Segundo Cerebro).
3. **Proceso** — receta de pasos (rutinas "follow-along").
4. **Flujo** — se compila a un canvas de automatización (nodos) en la Etapa 6.

## 5 · Verificación (Playwright humano — gate G)

Creo un skill desde cero **solo con clicks y tecleo** (sin abrir el .md) → nace con avatar/emoji/bio → lo pruebo en el laboratorio contra un input de ejemplo → el `.md` generado existe y es válido (frontmatter parseado por Zod) → lo invoco con `/skill <slug>` y responde con su personalidad. `tools_allowlist` bloquea herramientas no permitidas (agente QA no puede escribir). Suite humana verde (móvil+desktop).

## 6 · Marketplace (fase O)

El bundle `.canvas-ai-bundle` = `manifest.json` (firma hash) + uno o más `.md` de skills + assets. Validación al importar: frontmatter contra este schema + firma verificada + `tools_allowlist` saneado (nunca importar herramientas del host no declaradas).
