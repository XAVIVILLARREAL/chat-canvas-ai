# PLAN G — Skills Lab

> [← PLAN F](./plan-f-canva-oficina.md) · [← Maestro](./README.md) · [PLAN H →](./plan-h-motor-pruebas.md)
> Referencia primaria: Hermes Agent (skill system, 3 tiers, progressive disclosure)
> Referencia: Codex (SKILL.md, tool-gating), Gemini Gems (identidad visual)

**Entregable:** Crear skills visualmente (sin YAML), probarlos en laboratorio, y usarlos como agentes con identidad propia — avatares, voces, personalidad.

---

## Qué es un skill

Un skill = **contrato estructurado + identidad visual**:
- **Contrato**: nombre, rol, triggers, instrucciones, herramientas permitidas, modelo preferido, criterios de éxito
- **Identidad**: avatar generado por IA, emoji-firma, mini-bio de personalidad, voz TTS
- **Comportamiento**: puede orquestar múltiples agentes (multi-agent loop)

Internamente se compila a lo que cada motor entienda (prompt markdown, reasonix subagent, AGENTS.md snippet).

---

## Fases

### G.1 — Modelo de datos + CRUD

Tabla `skills` en SQLite:
```
id, name, role, description, triggers (JSON), 
instructions (text), allowed_tools (JSON), preferred_model,
success_criteria (JSON), avatar_url, emoji, personality_bio,
voice_id, scope (global/local), project_id,
created_at, updated_at, metadata (JSON)
```

Store Zustand + React Query:
- `useSkillStore`: lista de skills, activos
- React Query: CRUD con optimistic updates
- UI: lista/grid con búsqueda FTS5

Alcance:
- **Global**: compartido entre todos los proyectos
- **Local**: solo visible en un proyecto (derivada de un global con linaje)

**Pruebas:** Cargo test repos. E2E: crear/editar/duplicar/eliminar skill.

---

### G.2 — Editor visual

Formulario por secciones (sin YAML visible):
- **Sección Identidad**: nombre, rol, emoji (selector), descripción
- **Sección Instrucciones**: textarea con markdown preview
- **Sección Herramientas**: toggles por tool (read, write, edit, test, build, etc.)
- **Sección Modelo**: selector de modelo (deepseek-v4-flash, reasoner, ollama)
- **Sección Triggers**: palabras/frases que activan el skill
- **Sección Criterios**: checklist de éxito

Validación Zod en vivo. Vista previa compilada a JSON.

Tool-gating estricto:
- El skill declara las ÚNICAS herramientas que puede usar
- El orquestador monta SOLO esas por sesión
- Presets por rol: dev (edit+build), QA (test+read), reviewer (read-only)

**Pruebas:** Unit validación + enforcement. E2E: crear skill completo solo con clicks.

---

### G.3 — Generador de avatar por IA

Al crear/editar un skill:
1. **Input**: nombre + rol del skill
2. **Generación**: llamar a API de generación de imágenes (DALL-E, Stable Diffusion, o fallback procedural)
3. **Variantes**: generar 3 opciones, el usuario elige
4. **Fallback**: si la IA no responde, avatar procedural basado en hash del nombre (colores consistentes)
5. **Consistencia**: mismo rol → misma familia visual (ej: "dev" = tonos azules, "QA" = tonos verdes)

**Formato**: PNG 512x512, fondo transparente, estilo flat/illustration
**Almacenamiento**: SQLite (blob) o filesystem con referencia

**Pruebas:** E2E: crear skill → generar 3 avatares → elegir uno → verificar que se muestra en la UI.

---

### G.4 — Identidad viva (estilo Gems de Gemini)

Cada skill tiene una **personalidad completa**:
- **Avatar**: imagen consistente (generada o procedural)
- **Emoji-firma**: emoji único que representa al skill (🎯 para PM, 🔍 para QA, etc.)
- **Mini-bio**: 1-2 frases con carácter, escrita por IA ("Soy el revisor de código. Me gusta la limpieza y odio los magic numbers.")
- **Voz TTS**: voz asignada para speak-back (opcional)

La identidad se muestra en:
- Lista de skills (avatar + emoji + nombre)
- Chat (cuando el skill responde, su avatar aparece)
- Control Room canvas (nodo del skill muestra avatar)
- Historial de ejecuciones (emoji por cada rung generado)

**Ceremonia de creación**: al guardar un skill nuevo, overlay festivo "Nace [nombre] — bienvenido al equipo" con avatar animado.

**Pruebas:** E2E: crear skill → ceremonia → personaje aparece en chat y canvas → editar bio → actualiza en todas partes.

---

### G.5 — Compilador a dialectos

`SkillCompiler`: skill → dialecto objetivo.

Dialectos v1:
- **Prompt markdown**: universal, funciona en cualquier LLM
- **Reasonix subagent**: formato `reasonix subagent create`
- **AGENTS.md snippet**: para proyectos que usan AGENTS.md
- **Hermes ACP**: para orquestación via ACP protocol

Arquitectura extensible por trait (nuevos dialectos sin tocar UI).

**Pruebas:** Cargo test compiler snapshot tests por dialecto. Roundtrip: compilar → ejecutar → respuesta esperada.

---

### G.6 — Laboratorio sandbox

Panel "Probar skill":
- Input de ejemplo (textarea)
- Ejecutar contra el provider activo
- Mostrar: salida + costo del ensayo + tiempo
- Historial de pruebas por skill
- Comparar pruebas (antes/después de editar)

**Pruebas:** E2E: probar skill con DeepSeek barato, costo visible, resultado persistido.

---

### G.7 — Multi-agent loops

Un skill puede orquestar **múltiples agentes** en secuencia o paralelo:

```
Skill "Code Review" 
  → Sub-agent 1: lint code (parallel)
  → Sub-agent 2: run tests (parallel)
  → Sub-agent 3: check security (parallel)
  → Agregador: combinar resultados
  → LLM: generar reporte final
```

Configuración visual:
- Drag de agentes al canvas del skill
- Conexiones entre agentes (data flow)
- Configuración por agente (modelo, tools, timeout)
- Modo secuencial vs paralelo
- Agregador (cómo combinar resultados)

**Pruebas:** E2E: crear skill con 3 sub-agentes paralelos → ejecutar → verificar resultado agregado.

---

### G.8 — Rutinas por demostración

Modo "Follow Along" (patrón GrokBot):
1. **Grabar**: humano hace el trabajo una vez mientras el sistema observa
2. **Detectar**: el sistema identifica pasos, herramientas, contexto
3. **Proponer**: generar skill editable con los pasos detectados
4. **Corregir**: humano ajusta, agrega, elimina pasos
5. **Ejecutar**: rutina re-ejecutada on-demand o programada
6. **Mejorar**: cada corrección se persiste, el skill mejora con uso

**Pruebas:** Integration: sesión grabada → skill propuesto → corrección → re-ejecución.

---

### G.9 — Skills globales y locales

- **Globales**: biblioteca compartida entre todos los proyectos del usuario
- **Locales**: copia editable de un global, solo visible en un proyecto
- **Linaje**: "derivada de X" — se muestra la origen
- **Sync**: opcional, sincronizar local → global (push mejoras)

**Pruebas:** E2E: crear global → derivar local → editar local → verificar que global no cambia.

---

## 🚪 GATE G (demo verificable)

Desde cero y sin YAML: creo skill "QA-Tester" → le doy nombre → genero 3 avatares → elijo uno → escribo mini-bio → le asigno tools (read+test) → lo compilo → lo pruebo en laboratorio contra un mini-proyecto → veo respuesta y costo → el skill aparece en el panel con su avatar → lo ejecuto en una sesión de chat → responde con su identidad. Suite humana verde.

---

[← PLAN F](./plan-f-canva-oficina.md) · [← Maestro](./README.md) · [PLAN H →](./plan-h-motor-pruebas.md)
