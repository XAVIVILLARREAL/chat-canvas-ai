# Plan de Copia — Inspirarse en buzz y herdr

> **Objetivo:** copiar/adaptar todo lo que sirva de los repos de referencia
> `buzz/` (Block Inc.) y `herdr/` (herdrdev) hacia nuestro proyecto Flutter
> **Empresa Dev** (terminal SSH + canva + agentes IA + hub).
>
> Los repos están clonados en `buzz/` y `herdr/` (con su propio `.git`,
> ignorados por git, excluidos del analyzer). Fuente primaria:
> `herdr/skills/herdr/SKILL.md`, `herdr/src/detect/manifests/`,
> `buzz/crates/buzz-persona/PERSONA_PACK_SPEC.md`,
> `buzz/crates/buzz-acp/`, `buzz/mobile/lib/`.

---

## 0. Reglas de oro al copiar

1. **Copiar conceptos y patrones, no archivos crudos.** Adaptar a nuestro stack
   (Flutter/Dart, no Rust/TS) y a nuestra arquitectura (SSH directa + canva + hub).
2. **TDD por pieza:** primero el test que falla, después el código.
3. **Licencias:** buzz y herdr son Apache-2.0 — atribuir la fuente en cada
   archivo copiado (`// inspirado en buzz (Apache-2.0)` o doc `.md`).
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

---

## 7. Estado del plan

- [ ] 1.1 Detector de agentes — pendiente
- [ ] 1.2 Estructura Flutter Riverpod — pendiente
- [ ] 1.3 Skill de agente propio — pendiente
- [ ] 1.4 Contratos JSON/exit codes — pendiente
- [ ] 2.1 Formato de skills pack — pendiente
- [ ] 2.2 Motor de workflows — pendiente
- [ ] 2.3 Orquestador de agentes — pendiente
- [ ] 2.4 IDs/estados estables en canva — pendiente
- [ ] 3.1 Hub con eventos firmados (ADR) — pendiente
- [ ] 3.2 Remote agents (POC) — pendiente
- [ ] 3.3 Marketplace — pendiente
