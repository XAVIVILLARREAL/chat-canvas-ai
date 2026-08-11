# Plan de Copia — Inspirarse en buzz, herdr y Zed

> **Objetivo:** copiar/adaptar todo lo que sirva de los repos de referencia
> `buzz/` (Block Inc.), `herdr/` (herdrdev) y `reference/zed/` (Zed) hacia
> nuestro proyecto Flutter **Empresa Dev** (terminal SSH + canva + agentes IA + hub).
>
> Los repos están clonados en `buzz/`, `herdr/` y `reference/zed/` (con su
> propio `.git`; los dos primeros ignorados por git, Zed como submodulo).
> Fuente primaria:
> `herdr/skills/herdr/SKILL.md`, `herdr/src/detect/manifests/`,
> `buzz/crates/buzz-persona/PERSONA_PACK_SPEC.md`,
> `buzz/crates/buzz-acp/`, `buzz/mobile/lib/`,
> `reference/zed/crates/agent_skills/README.md`,
> `reference/zed/docs/src/ai/*.md`, `reference/zed/crates/rope/`.

---

## 0. Reglas de oro al copiar

1. **Copiar conceptos y patrones, no archivos crudos.** Adaptar a nuestro stack
   (Flutter/Dart, no Rust/TS) y a nuestra arquitectura (SSH directa + canva + hub).
2. **TDD por pieza:** primero el test que falla, después el código.
3. **Licencias:** buzz y herdr son Apache-2.0; **Zed es GPL-3.0-or-later** (con
   componentes Apache-2.0 marcados) — atribuir la fuente en cada archivo copiado
   (`// inspirado en buzz (Apache-2.0)` o doc `.md`) y **no copiar código crudo de
   Zed** salvo piezas Apache-2.0 explícitas; de Zed copiamos conceptos/decisiones.
4. **No arrastrar dependencias muertas:** copiar solo lo que usamos.
5. **Una pieza por fase**, con su gate (ver `docs/ROADMAP.md`).

---

## 1. Inmediato (puede copiarse hoy, bajo esfuerzo)

### 1.1. Formato de detección de agentes — de herdr
- **Fuente:** `herdr/src/detect/manifests/` (opencode.toml, claude.toml, codex.toml,
  cursor.toml, cline.toml, grok.toml, gemini.toml, …)
- **Qué copiar:** el esquema TOML de detección por "reglas" con estados
  `blocked/working/idle/unknown`, prioridades y matchers (`contains`, `regex`,
  `line_regex`, gates `any/all`).
- **En nuestro proyecto:** `lib/services/agent_detector/` — detector que lee la
  salida del terminal y clasifica el estado del agente que corre en el pane.
- **Para qué:** mostrar en el canva el estado del nodo-agente
  ("trabajando/bloqueado/esperando").
- **Entregable:** `AgentState` enum + manifiestos TOML portados + widget test.
- **Gate:** un host que ejecuta `opencode` se clasifica como `working` cuando su
  salida contiene "esc to interrupt".

### 1.2. Estructura Flutter profesional — de buzz
- **Fuente:** `buzz/mobile/lib/` (features/ + shared/) y su `pubspec.yaml`.
- **Qué copiar:**
  - Organización `lib/features/<feature>/` + `lib/shared/` (tema, widgets, util).
  - Riverpod + `flutter_hooks` (`HookConsumerWidget`), sin `StatefulWidget` en
    código nuevo (regla de buzz).
  - Testeo con `ProviderScope(overrides:)` + fakes que extienden el notifier real.
- **En nuestro proyecto:** refactor incremental de `lib/` manteniendo lo que ya
  funciona (terminal, canva, hub) — empezar por los módulos nuevos.
- **Entregable:** guía de convenciones propia + 1 feature refactorizada como
  ejemplo (p. ej. el `AgentChatScreen` con Riverpod).

### 1.3. Skill de agente estilo herdr — para nuestro canva
- **Fuente:** `herdr/skills/herdr/SKILL.md`
- **Qué copiar:** el patrón del skill:
  - frontmatter `name:` + `description:` con condición de activación explícita
    ("use only when…; requires ENV") — es el formato de skill de opencode.
  - Sección de descubrimiento del CLI: `--help` primero, grupos, no mutar sin args.
  - Reglas de seguridad: no cerrar sesiones ajenas, no matar el proceso principal.
- **En nuestro proyecto:** crear `skills/dev/` con el skill de la app (conectar
  por SSH, abrir canva, gestionar nodos-agente) usando este formato.
- **Entregable:** 1 skill propio + validación en CI de frontmatter.

### 1.4. Contratos "output JSON + exit codes" — de herdr/buzz-cli
- **Fuente:** `herdr/skills/herdr/SKILL.md` (JSON en stdout, errores en stderr,
  exit codes 1/2), `buzz/crates/buzz-cli/`.
- **Qué copiar:** la convención de que **todo comando de agente emite JSON en
  stdout, errores en stderr y exit codes semánticos** (0 ok, 1 input, 2 red/relay,
  3 auth, 4 otro, 5 conflicto). Hace el control remoto parseable desde Flutter.
- **Entregable:** contrato documentado + wrapper Dart que parsea ese JSON.

---

## 2. Corto plazo (semanas)

### 2.1. Formato de "Persona Pack" — de buzz → nuestro formato de skills
- **Fuente:** `buzz/crates/buzz-persona/PERSONA_PACK_SPEC.md`
- **Qué copiar (adaptado):** un bundle portable que agrupa:
  - `personas/` (identidad + system prompt, `.persona.md` con frontmatter YAML)
  - `skills/<name>/SKILL.md` (reutilizable entre agentes)
  - `mcp_config` (servidores de herramientas)
  - `instructions.md` (reglas de equipo)
  - `plugin.json` como manifiesto (superset del Open Plugin Spec)
- **En nuestro proyecto:** definimos nuestro `empresa-pack/` con skills propios
  + reglas de composición (skill compartido vs. por-agente) y colisión
  (no-overwrite con warning).
- **Entregable:** spec propio `docs/SDDs/SDD-2xx-skills-pack.md` + `buzz pack validate`
  equivalente (validador en Dart).
- **Gate:** un pack se carga/valida/serializa sin pérdida.

### 2.2. Motor de workflows YAML-as-code — de buzz
- **Fuente:** `buzz/crates/buzz-workflow/` (definición + ejecución + condiciones evalexpr)
- **Qué copiar (conceptos):**
  - Trigger tipos: `message_posted`, `reaction_added`, `schedule`, `webhook`.
  - Acciones: `send_message`, `send_dm`, `request_approval`, `delay`, `call_webhook`.
  - Condiciones con variables `{{trigger.text}}` y funciones (`str_contains`, …).
  - Approval gates (estado `WaitingApproval`).
- **En nuestro proyecto:** motor Dart `lib/services/workflow/` que escucha eventos
  del canva/hub (nodo agregado, conexión SSH, comando ejecutado) y dispara
  acciones (notificar, ejecutar comando, pedir aprobación).
- **Entregable:** motor + 3 ejemplos YAML + tests de triggers/acciones.

### 2.3. Detección y coordinación de agentes (colas) — de buzz-acp
- **Fuente:** `buzz/crates/buzz-acp/` (pool, queue, batching, claim/return)
- **Qué copiar (conceptos):**
  - Cola por canal/nodo con **máx 1 prompt en vuelo** por canal; el resto se
    encola y se batea en un solo prompt.
  - Pool de agentes (1–32) con ciclo claim/return y respawn en crash.
  - Estados: `Pending/Running/WaitingApproval/Completed/Failed`.
- **En nuestro proyecto:** `lib/services/agent_orchestrator/` — coordina los
  nodos-agente del canva (no lanzamos subprocesos goose/codex; orquestamos
  nuestras propias sesiones de agente).
- **Entregable:** orquestador + tests de cola/batch/claim.

### 2.4. Estados de pane e IDs estables — de herdr
- **Fuente:** `herdr/src/app/ids.rs`, `herdr/src/app/state.rs`, `herdr/skills/herdr/SKILL.md`
- **Qué copiar (conceptos):**
  - IDs opacos estables (`w1`, `w1:t1`, `w1:p1`), nunca reutilizados.
  - Estado separado del runtime (`AppState` puro vs. `PaneRuntime`).
  - Semántica de estados: `idle` vs `done` (mismo idle, distinto origen).
- **En nuestro proyecto:** aplicar a los nodos del canva (host/agente/nota) y a
  las sesiones de terminal (tabs) — IDs estables + estados explícitos.

---

## 3. Medio plazo (meses) — decisiones de arquitectura

### 3.1. Hub de sync con modelo de eventos firmados — inspirado en buzz
- **Fuente:** `buzz/ARCHITECTURE.md` (Nostr NIP-01: eventos `kind` firmados,
  relay = fuente de verdad, fan-out por suscripción).
- **Qué copiar (conceptos, no Nostr):** la idea de que **toda mutación sea un
  evento versionado con autor** en el hub (celular + Tailscale) en vez de
  mutar estado a ciegas:
  - Un evento por acción (nodo creado, conexión, comando, aprobación).
  - Replay/rebase para conflictos entre dispositivos.
  - Suscripciones por tipo de evento para el canva.
- **Decisión a tomar:** ¿eventos propios (JSON con id+kind+autor) o adoptar
  Nostr de verdad (buzz/mobile usa el paquete `nostr`)? Ponderar en un ADR.
- **Entregable:** ADR + prototipo de log de eventos en el hub.

### 3.2. Remote agents — inspirado en buzz/herdr
- **Fuente:** `buzz/VISION_REMOTE_AGENTS.md`, `herdr/src/remote.rs`, `herdr/src/handoff_runtime.rs`
- **Qué copiar (conceptos):** la identidad/historial/presencia del agente viven
  en el hub, no en la máquina; el agente puede reanudarse (handoff) en otro
  dispositivo. Aplicable a "agente como nodo que vive en el servidor pve".
- **Entregable:** diseño + POC de reanudar una sesión de agente.

### 3.3. Marketplace de skills/plugins — inspirado en herdr + buzz
- **Fuente:** `herdr/workers/plugin-marketplace/`, `buzz` (Phase 3 registry)
- **Qué copiar (conceptos):** un registro de packs (skills+personas) con
  instalación por URL/git, verificación de checksum y `pack.lock`.
- **Entregable:** servidor-lite (en el hub o Cloudflare Worker) + cliente en la app.

---

## 4. Mapa de correspondencia (lo que NO copiamos y por qué)

| Pieza de buzz/herdr | ¿Copiar? | Motivo |
|---|---|---|
| Relay Nostr completo (Rust) | No | Nosotros usamos hub + Tailscale; no necesitamos relay federado |
| Client desktop Tauri/React | No | Nuestro stack es Flutter multiplataforma |
| Detección de agente por manifiestos TOML | Sí | Directamente portable al modelo Dart |
| Motor de workflow YAML (buzz) | Sí (conceptos) | Triggers/acciones/approvals encajan con nuestro canva |
| Persona Pack spec | Sí (adaptado) | Base para nuestro formato de skills portable |
| Colas de agente (buzz-acp) | Sí (conceptos) | Coordinar nodos-agente del canva |
| Modelo de eventos firmados | Sí (conceptos) | Mejorar el hub de sync (requiere ADR) |
| Marketplace (herdr/buzz) | Sí (fase 3) | Registro de packs de skills |
| Huddle audio (buzz) | No | Fuera de alcance por ahora |
| Buzz Mesh / compute compartido | No | Visión lejana, no urgente |
| Hermit/nix/just toolchains | No | Depende de su infra |
| GPUI (framework UI Rust de Zed) | No | Es un framework completo; nosotros usamos Flutter |
| Rope + sum_tree + streaming_diff (Zed) | Sí (conceptos) | Base del editor (Etapa 3) y del nodo-diff en vivo (Etapa 6) |
| Sistema de skills de Zed (8.3) | Sí (conceptos/decisiones) | Define la Etapa 4b: catálogo + presupuesto + overrides + trust |
| Modelo de seguridad del agente (8.4) | Sí (conceptos) | Permisos por tool + sandbox antes de agentes en pve |
| ACP / External Agents (8.5) | Sí (concepto) | Controlar opencode/Claude/Codex desde el canva |
| Worktree isolation (8.6) | Sí (concepto) | Nodos-agente aislados del canva |
| Multiplayer RPC/collab (8.10) | Sí (referencia) | Candidato al ADR 3.1 junto al modelo de eventos de buzz |

---

## 5. Orden de ejecución sugerido

| # | Pieza | Esfuerzo | Gate |
|---|-------|----------|------|
| 1 | Detector de agentes (1.1) | S | Un host con opencode → estado `working` |
| 2 | Estructura Flutter Riverpod (1.2) | S-M | 1 feature refactorizada + tests verdes |
| 3 | Skill de agente propio (1.3) | S | `flutter analyze` 0 + skill validada |
| 4 | Contratos JSON/exit codes (1.4) | S | Wrapper parsea JSON del agente |
| 5 | Formato de skills pack (2.1) | M | Validador + roundtrip sin pérdida |
| 6 | Motor de workflows (2.2) | M-L | 3 ejemplos + tests de triggers |
| 7 | Orquestador de agentes (2.3) | M-L | Tests de cola/batch/claim |
| 8 | IDs/estados estables en canva (2.4) | M | Tests de identidad en canva |
| 9 | Hub con eventos firmados (3.1) | L | ADR aprobado + POC replay |
| 10 | Remote agents (3.2) | L | POC de reanudar sesión |
| 11 | Marketplace (3.3) | L | Instalar pack por URL |

### Piezas de Zed alineadas a etapas

| # | Pieza de Zed | Etapa destino | Gate |
|---|--------------|---------------|------|
| Z1 | Rope + índices incrementales (8.1) | Etapa 3 (editor) | Abrir/buscar `.md` de 10MB sin lag |
| Z2 | LSP + diagnostics (8.8) | Etapa 3 | Diagnóstico en vivo en un archivo Dart |
| Z3 | Worktree remoto vía `remote/` (8.9) | Etapa 4 + hub | Árbol del pve navegable como local |
| Z4 | Sistema de skills (8.3) | **Etapa 4b** | Laboratorio responde "qué skill se activaría" |
| Z5 | Streaming diff en vivo (8.2) | Etapa 6 | Nodo-diff muestra el cambio fluyendo |
| Z6 | Permisos por tool + sandbox (8.4) | Etapa 6 | Comando fuera del proyecto se bloquea |
| Z7 | ACP / agentes externos (8.5) | Etapa 6 | Sesión de opencode hosteada en la app |
| Z8 | Worktree isolation por nodo (8.6) | Etapa 6 | 2 agentes no pisan el mismo archivo |
| Z9 | Edit prediction (8.7) | Etapa 6 | `tab` acepta sugerencia multi-línea |
| Z10 | RPC/presencia `collab/` (8.10) | ADR 3.1 | ADR comparado con modelo de eventos |

> **S**=días, **M**=semanas, **L**=meses.

---

## 6. Documentos de referencia (fuentes primarias)

- `herdr/skills/herdr/SKILL.md` — skill de agente + convenciones CLI/JSON/estados
- `herdr/src/detect/manifests/*.toml` — detección de agentes (incl. opencode.toml)
- `herdr/src/app/ids.rs`, `herdr/src/app/state.rs` — IDs estables + estado puro
- `buzz/crates/buzz-persona/PERSONA_PACK_SPEC.md` — formato de persona/skill packs
- `buzz/crates/buzz-acp/src/*.rs` — pool/queue/batching de agentes
- `buzz/crates/buzz-workflow/` — motor de workflows
- `buzz/mobile/lib/` — arquitectura Flutter (features/shared + Riverpod)
- `buzz/ARCHITECTURE.md` — modelo de eventos firmados + relay
- `buzz/VISION_REMOTE_AGENTS.md` — agentes remotos
- `reference/zed/crates/agent_skills/README.md` — sistema de skills (decisiones)
- `reference/zed/docs/src/ai/skills.md`, `sandboxing.md`, `tool-permissions.md`,
  `parallel-agents.md`, `external-agents.md`, `edit-prediction.md` — doc de producto del agente
- `reference/zed/crates/streaming_diff/src/streaming_diff.rs` — diff incremental en vivo
- `reference/zed/crates/rope/`, `crates/sum_tree/`, `crates/multi_buffer/` — buffer grande
- `reference/zed/crates/lsp/`, `crates/remote/`, `crates/collab/`, `crates/ui/` — piezas por etapa

---

## 7. Estado del plan

> **2026-08:** aprobado el mapeo con el SUPER_PLAN. Las piezas 1.1, 2.4 y 1.4 pasan como **prefase Etapa 4** (inyección en `docs/SUPER_PLAN.md`); 1.3 y 2.1 se fusionan en **Etapa 4b**; 2.3 → Etapa 6; 2.2/3.x → post-Etapa 7; 1.2 → solo convención en código nuevo.
>
> **2026-08 (Zed):** añadida la Parte II como referencia para Etapas 3–7. La pieza
> Z4 (sistema de skills de Zed) se integra en **Etapa 4b** junto a 1.3/2.1; Z1–Z2
> → Etapa 3; Z5–Z9 → Etapa 6; Z10 alimenta el **ADR 3.1**. Cero código crudo (GPL).

- [ ] 1.1 Detector de agentes — **prefase Etapa 4**
- [ ] 1.2 Estructura Flutter Riverpod — post-Etapa 7 (convención en código nuevo)
- [ ] 1.3 Skill de agente propio — fusionado en Etapa 4b
- [ ] 1.4 Contratos JSON/exit codes — **prefase Etapa 4**
- [ ] 2.1 Formato de skills pack — fusionado en Etapa 4b
- [ ] 2.2 Motor de workflows — post-Etapa 7
- [ ] 2.3 Orquestador de agentes — Etapa 6
- [ ] 2.4 IDs/estados estables en canva — **prefase Etapa 4**
- [ ] 3.1 Hub con eventos firmados (ADR) — post-Etapa 7
- [ ] 3.2 Remote agents (POC) — post-Etapa 7
- [ ] 3.3 Marketplace — post-Etapa 7

---

## 8. Zed — el editor de referencia (GPUI + agente integrado)

> **Fuente:** `reference/zed/` (submodulo, rama main). Editor nativo de alto
> rendimiento (Rust) con agente IA de primera clase, hecho por los autores de
> Atom y Tree-sitter. Es la referencia canónica para **Etapas 3–7** (editor +
> canva + vibecoding + skills).
>
> ⚠️ **Licencia:** Zed es **GPL-3.0-or-later** (componentes Apache-2.0 marcados).
> A diferencia de buzz/herdr, **NO copiar código crudo** salvo piezas Apache-2.0
> explícitas — copiamos conceptos, arquitecturas y decisiones de diseño, que es
> justo lo que necesitamos.

### 8.1. `rope` + `sum_tree` + `text` + `language` + `multi_buffer` — el buffer que no se rompe
- **Fuente:** `crates/rope/`, `crates/sum_tree/`, `crates/text/`, `crates/language/`, `crates/multi_buffer/`
- **Qué copiar (conceptos):** edición sobre **rope con índices incrementalmente
  actualizados** (sum trees) — buscar/colorear/multicursor en O(log n) aunque el
  archivo pese 100MB; **multi-buffer** para trabajar varios archivos a la vez.
- **Para qué:** la base del editor de la Etapa 3. En Dart: una `Rope` + índices
  incrementales (nunca re-difundir el buffer completo por edit).
- **Gate:** abrir y buscar en un `.md` de 10MB sin lag.

### 8.2. `streaming_diff` — el diff en vivo mientras el agente edita
- **Fuente:** `crates/streaming_diff/src/streaming_diff.rs`
- **Qué copiar (concepto):** diffs **parciales e incrementales** del buffer
  mientras un proceso externo (el agente) escribe en él, sin recalcular todo.
- **Para qué:** es literalmente el **"nodo-diff del canva con preview y
  aceptar/rechazar"** de la Etapa 6 — el canva muestra el diff fluyendo en vivo.
- **Entregable:** `streaming_diff` en Dart (port del algoritmo Myers/LCS incremental).

### 8.3. `agent_skills` — el sistema de skills más pensado del ecosistema
- **Fuente:** `crates/agent_skills/README.md` (oro en decisiones de diseño),
  `docs/src/ai/skills.md`
- **Qué copiar (decisiones, no código):**
  - **Catálogo + progressive disclosure:** el modelo ve solo name+description; el
    cuerpo se carga on-demand (tool `skill` o slash command).
  - **Presupuesto fijo de 50KB** para el catálogo (decisión permanente, no
    proporcional al contexto) → obliga a descripciones cortas con keywords al frente.
  - **Validación estricta permanente:** `name` `[a-z0-9-]{1,64}`, desc 1–1024 chars;
    si falla, rechazar con error claro en UI. "Si piensas en aflojar la validación,
    la respuesta es no."
  - **Envelope `<skill_content>` con escape XML** y catálogo `<available_skills>`
    escapado — defensa real contra prompt injection desde descripciones hostiles.
  - **Override project-local > global** (con warning), scan plano sin recursión,
    **live reload** (editar el cuerpo no invalida el cache de prompt), y ediciones
    a `SKILL.md` como **ruta sensible que exige autorización** (el agente no puede
    auto-reescribirse — cierra el loop de auto-persistencia de un prompt hostil).
  - **`disable-model-invocation`** (el modelo no la ve; el usuario sí por slash).
  - **Worktree trust gate:** skills de un proyecto no confiable no cargan.
- **En nuestro proyecto:** directamente la **Etapa 4b** (gestor visual de skills +
  laboratorio). Nuestro laboratorio debe simular catálogo + presupuesto + overrides
  para responder "¿qué skill se activaría y por qué?".
- **Gate:** un skill con `name` inválido se rechaza en UI; un skill local overridea
  al global; editar el cuerpo de un skill activo no rompe la sesión.

### 8.4. `agent` + tool permissions + sandboxing — el modelo de seguridad del agente
- **Fuente:** `crates/agent/`, `docs/src/ai/tool-permissions.md`, `docs/src/ai/sandboxing.md`
- **Qué copiar (conceptos):**
  - **Permisos por herramienta y por acción** (Allow Once / Always Allow / Reject),
    configurables por settings y con scope por tool (el nombre del skill es el input).
  - **Sandbox a nivel OS** (bubblewrap Linux, WSL Windows, nativo macOS) para los
    tools `terminal` y `fetch`: sin red ni escrituras fuera del proyecto salvo
    permiso explícito con `reason` mostrada al usuario.
  - Clasificación de **rutas sensibles** (`SKILL.md`, `.git`, credenciales).
  - Modelo de amenazas documentado (side-channels: proc-macros, Makefiles, hooks
    de git que corren fuera del sandbox).
- **En nuestro proyecto:** el hub + canva gestionan agentes remotos — antes de que
  un agente ejecute en el servidor pve necesitamos este modelo de permisos y, al
  menos, sandbox de comandos en desktop (bubblewrap/WSL o contenedor).
- **Gate:** un comando del agente que intenta escribir fuera del proyecto se
  bloquea sin permiso.

### 8.5. ACP + External Agents (¡con opencode de primera clase!) — más allá de la detección
- **Fuente:** `crates/acp_thread/`, `crates/acp_tools/`, `crates/opencode/`,
  `docs/src/ai/external-agents.md`
- **Qué copiar (concepto):** Zed hostea el *thread* y la UI, pero el agente externo
  (Claude, Codex, **opencode**, Copilot, Cursor, Gemini CLI) es dueño de su
  runtime/auth/modelo vía el **Agent Client Protocol (ACP)**. Cada thread puede usar
  un agente distinto.
- **En nuestro proyecto:** nuestro `packages/agent_core` ya detecta agentes; esto le
  añade el **protocolo de control ACP** — hostear la sesión en la app mientras
  opencode corre por su cuenta. Conecta directo con Etapa 6 (vibecoding).

### 8.6. Parallel agents + Threads Sidebar + worktree isolation — el "canva de agentes"
- **Fuente:** `docs/src/ai/parallel-agents.md`
- **Qué copiar (conceptos):** múltiples hilos de agente en paralelo, cada uno con su
  contexto/historial propio, **aislados en Git worktrees** (dos threads no pisan los
  mismos archivos), thread history (archivar/restaurar, con el worktree recreado),
  multi-proyecto y multi-root.
- **En nuestro proyecto:** es el modelo para los **nodos-agente del canva** — cada
  nodo = thread con su sesión/worktree aislado; el canva es la "Threads Sidebar" en 2D.

### 8.7. Edit Prediction (Zeta) — autocompletado inline multi-línea
- **Fuente:** `docs/src/ai/edit-prediction.md`, `crates/edit_prediction*/`
- **Qué copiar (conceptos):** predicción **multi-línea** aceptable con `tab`
  (o `alt-tab`), modos `eager`/`subtle`, aceptar palabra a palabra o línea a línea.
  Se apoya en `streaming_diff` para aplicar la predicción sin tirones.
- **Para qué:** el "editor de vibecoding" de la Etapa 6.

### 8.8. `lsp` + `language` + `diagnostics` — Language Servers integrados
- **Fuente:** `crates/lsp/`, `crates/language/`, `crates/language_tools/`,
  `crates/project_symbols/`
- **Qué copiar (conceptos):** integración LSP (diagnósticos en vivo, símbolos del
  proyecto, go-to-definition) y el tool `diagnostics` del agente (resumen por
  archivo o de todo el proyecto) que alimenta el loop de edición del agente.
- **Para qué:** diagnóstico en vivo en nuestro editor de Etapa 3 y que el agente
  "mire el árbol de errores" como Zed antes de terminar una tarea.

### 8.9. `remote`/`remote_server`/`dev_container` — desarrollo remoto (hub + pve)
- **Fuente:** `crates/remote/`, `crates/remote_server/`, `crates/dev_container/`,
  `crates/worktree/`, `crates/fs/`
- **Qué copiar (conceptos):** editar archivos de una máquina remota como si fueran
  locales, con adaptadores (SSH, SSH2, container); el árbol remoto se vuelve un
  **worktree** más para el editor, la búsqueda y el agente.
- **En nuestro proyecto:** conecta nuestro **hub (celular + Tailscale)** con el
  **canva remoto** — el árbol del servidor pve (`remote_project_service`) como
  worktree remoto de primera clase.

### 8.10. `collab` — multiplayer de verdad (cursors, calls, RPC)
- **Fuente:** `crates/collab/`, `crates/rpc/`, `crates/channel/`, `crates/call/`, `crates/proto/`
- **Qué copiar (conceptos):** el modelo de **RPC + presencia** de Zed (cursors de
  otros usuarios en vivo, canales, llamadas) y su UX (`collab_ui/`).
- ⚠️ **Para nuestro ADR 3.1 (hub con eventos firmados):** Zed usa su propio
  `proto/` + websocket, no Nostr — nos da un **segundo candidato** de arquitectura
  para comparar con el modelo de eventos de buzz antes de decidir.

### 8.11. `ui` + `theme` — un UI kit interno consistente
- **Fuente:** `crates/ui/`, `crates/ui_input/`, `crates/theme/`, `crates/file_icons/`
- **Qué copiar (concepto):** una **librería de componentes** (botones, inputs,
  popovers, pickers, tooltips) con tema único — el equivalente en Flutter a lo que
  buzz hace con `shared/`. No copiamos GPUI (framework Rust completo), pero sí la
  disciplina de "una UI kit interna + sistema de temas".

### 8.12. El resto, con crédito corto
- `fuzzy`/`fuzzy_nucleo` — matching fuzzy ultrarápido (command palette, file
  finder, búsqueda de threads). En Dart: port del algoritmo.
- `task` — sistema de tareas (run test, hooks `create_worktree`/`on_open`).
- `dap` + `debugger_ui` — Debug Adapter Protocol para un debugger futuro.
- `markdown` + `mermaid_render` + `html_to_markdown` — render de `.md` con
  diagramas → nodos `.md` del canva (Etapa 4).
- `search` — búsqueda en proyecto con ripgrep.
- `extensions` + `extension_host` — sistema de extensiones → marketplace (3.3).
- `command_palette`, `outline`, `breadcrumbs`, `snippet`, `file_finder` — paleta,
  outline de símbolos, breadcrumbs, snippets, ir-a-archivo.
- `opencode/` crate — cómo integrar opencode como agente de primera clase.
- `journal` — diario de trabajo (bitácora por día).
- `docs/src/ai/*.md` — toda la doc de producto del agente; excelente referencia de
  UX para nuestro AgentChatScreen y el canva de nodos-agente.
