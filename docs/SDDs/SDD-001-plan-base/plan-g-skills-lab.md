# PLAN G — Etapa 7: Skills Lab

> [← Maestro](./README.md) · [← PLAN F](./plan-f-canva-oficina.md) · [PLAN H →](./plan-h-motor-pruebas.md)
> Depende de: Etapas 3 (providers), 4 (memoria). Patrón de empaquetado: SKILL.md de Codex.

**Entregable:** crear skills visualmente (sin YAML), probarlos en laboratorio, y exportarlos a cualquier dialecto agéntico — el usuario arma la "planta" de su empresa.

## Qué es un skill aquí

Un skill = contrato estructurado: `{nombre, rol, triggers, instrucciones, herramientas permitidas, modelo preferido, criterios de éxito}`. Internamente se compila a lo que cada motor entienda.

<a id="g1"></a>
### G.1 — Modelo de datos + CRUD
- Tabla `skills` en SQLite; store Zustand + React Query; UI lista/grid con búsqueda FTS5 ([D·D.2](./plan-d-memoria-v3code.md#d2))
- **Alcance elegido por el usuario** ([A·A.0](./plan-a-chat-codex.md#a0)): skill GLOBAL (biblioteca compartida entre proyectos) o COPIA LOCAL editable sin afectar a otros — toggle visible y linaje "derivada de X" cuando es copia
- **Pruebas:** Cargo test repos. E2E humano: crear/editar/duplicar/eliminar skill desde cero

<a id="g2"></a>
### G.2 — Editor visual + Tool-Gating (copia.md §Cline/RooCode)
- Formulario por secciones (rol, triggers, herramientas con toggles, modelo), sin YAML visible; validación Zod en vivo; vista previa compilada a JSON
- **Tool-gating estricto**: el skill declara las ÚNICAS herramientas que su agente puede montar — el orquestador monta SOLO esas por sesión, evitando congestión de prompts y acciones fuera de rol
- Presets de gating por rol (dev: edit+build; QA: test+read; reviewer: read-only) editables
- **Pruebas:** Unit validación + enforcement de gating (agente QA no puede invocar write). E2E humano: crear skill completo solo con clicks y tecleo

<a id="g3"></a>
### G.3 — Compilador a dialectos
- `SkillCompiler`: skill → dialecto objetivo. v1: prompt-system markdown (universal), reasonix subagent profile (`reasonix subagent create` formato verificado en servidor), AGENTS.md snippet
- Arquitectura extensible por trait (nuevos dialectos sin tocar UI)
- **Pruebas:** Cargo test compiler snapshot tests por dialecto. Roundtrip: compilar→ejecutar en reasonix real→respuesta esperada

<a id="g4"></a>
### G.4 — Laboratorio sandbox
- Panel "Probar": ejecuta el skill contra un input de ejemplo usando el provider activo ([C·C.1](./plan-c-reasonix-deepseek.md#c1)), muestra salida + costo del ensayo (--metrics); historial de pruebas por skill
- **Pruebas:** E2E: probar skill real con DeepSeek barato; costo del ensayo visible; resultado persistido

<a id="g5"></a>
### G.5 — Optimizador DSPy-lite *(tardía, opcional)*
- Re-compilar instrucciones del skill comparando tasa de éxito de sus pruebas históricas (motor H); sugerir mejora aceptada por humano (gobernanza varve: propuesta→aceptación)
- **Pruebas:** Integration con corpus del motor de pruebas

<a id="g6"></a>
### G.6 — Rutinas por demostración "follow along" (patrón Grok Bot)
- Modo GRABAR: el humano hace el trabajo una vez (en la app o CLI) mientras el sistema observa acciones y contexto
- Al terminar → propone un skill editable con los pasos detectados; el humano corrige/ajusta y acepta (gobernanza [D·D.4](./plan-d-memoria-v3code.md#d4))
- La rutina aceptada se re-ejecuta on-demand o programada, y mejora con cada corrección
- **Pruebas:** Integration: sesión grabada de N pasos → skill propuesto con N pasos correctos; corrección humana se persiste. E2E humano: grabo "preparar release" → skill creado → lo ejecuto programado

## 🚪 GATE G (demo verificable)

Desde cero y sin YAML: creo skill "QA-Tester" (rol qa, triggers "revisar/tests", tools read+test, modelo flash) → lo compilo → lo pruebo en el laboratorio contra un mini-proyecto → veo respuesta y costo → lo exporto como subagent-profile de Reasonix y funciona en CLI. Suite humana ampliada verde.

---
[← Maestro](./README.md) · [← PLAN F](./plan-f-canva-oficina.md) · [PLAN H →](./plan-h-motor-pruebas.md)
