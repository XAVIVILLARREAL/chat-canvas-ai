# SDD-001 · Roadmap Maestro — Empresa Dev

> Fecha: 2026-08-22 · Estado: Propuesto · v3.2 MEGA-PLAN (15 etapas + P, ~88 fases)
> Investigación profunda: OpenAI Codex (docs oficiales), Reasonix v1.23 (verificado EN VIVO en este servidor), V3Code (sitio oficial + spec copia.md), **Grok Bot xAI/Cursor** ([SDD-004](../SDD-004-analisis-grokbot.md): group chat de agentes, rutinas por demostración, proactividad, pipeline de bugs) + patrones de varve/codevira.
> Pruebas: [SDD-002](../SDD-002-testing-spec-driven.md) — toda fase pasa las 4 capas; todo gate cierra con suite humana.

## Objetivo final

**Fábrica visual de empresas de desarrollo autónomas**: chateas (Codex-style), ves construirse en paneles (Lovable-style), sobre Reasonix+DeepSeek barato, con memoria V3Code que nunca olvida — y evoluciona hasta canva animado, skills, motor de pruebas, grafo 3D, voz, sync, GitHub nativo y EMPRESAS COMPLETAS operadas por agentes con jerarquía.

## EL PRODUCTO — el flujo estrella que todo sirve

```
1. HABLAS  →  "necesito una app de reservas con tests"
2. VES     →  oficina animada: PM planifica, devs escriben en worktrees paralelos,
             paquetes-artefacto viajando por edges iluminados
3. CONFÍAS →  Shadow Workspace garantiza que NUNCA ves código que no compila;
             review automático marca riesgos; tú solo apruebas hitos con evidencia
4. RECUERDA→  cada decisión queda gobernada; mañana el sistema sabe el porqué de todo
5. CONECTA →  tu cerebro empresarial expuesto por MCP a cualquier otro agente
```

Features ganadoras combinadas en un solo producto: chat Codex + paneles Lovable + motor barato DeepSeek + memoria V3Code + shadow workspace Cursor + fast apply Morph + gobernanza varve + revisión Reasonix + repo-map Aider + voz natural + sync CRDT + git nativo.

## Mapa de las 15 ETAPAS (~88 fases)

| Etapa | Nombre | Archivo | Fases | Gate resumen |
|---|---|---|---|---|
| 0 | Fundaciones | *(completada)* | — | Infra 100% verde + testing humano 12/12 ✅ |
| 1 | Chat núcleo Codex + **tenants** | [plan-a](./plan-a-chat-codex.md) | **A.0**–A.9 | Streaming real, 2 perillas, slash cmds |
| 2 | Sidepanels Lovable | [plan-b](./plan-b-sidepanels-lovable.md) | B.1–B.5 | Ves construirse en vivo |
| 3 | Runtime Reasonix+DeepSeek+Ollama+**API universal** | [plan-c](./plan-c-reasonix-deepseek.md) | C.0–C.6 | 3 motores (local-ready), costos, cancelación |
| 4 | Memoria V3Code | [plan-d](./plan-d-memoria-v3code.md) | D.0–D.6 | Recuerda entre sesiones + gobernanza + grafo dual |
| 5 | Cierre Base | [plan-e](./plan-e-integracion-total.md) | E.1–E.3 | Tag `plan-base-v0.1` |
| 6 | Canva ReactFlow + Oficina | [plan-f](./plan-f-canva-oficina.md) | F.1–F.6 | Nodos-agentes animados arrastrables |
| 7 | Skills Lab | [plan-g](./plan-g-skills-lab.md) | G.1–G.4 | Crear/probar/exportar skills sin YAML |
| 8 | Motor de pruebas y resultados | [plan-h](./plan-h-motor-pruebas.md) | H.1–H.6 | Agentes demuestran con tests, no promesas |
| 9 | Revisión auto + Superposiciones | [plan-i](./plan-i-revision-superposiciones.md) | I.1–I.6 | El sistema detecta y corrige solo |
| 10 | Grafo 3D Repo-Map | [plan-j](./plan-j-grafo3d-repomap.md) | J.1–J.3 | Repo entero en <1000 tokens + visual 3D |
| 11 | Voz | [plan-k](./plan-k-voz.md) | K.1–K.3 | Hablas, los agentes responden |
| 12 | Sync multi-device + Co-Work | [plan-l](./plan-l-sync-cowork.md) | L.1–L.3 | Continúas donde dejaste, en cualquier dispositivo |
| 13 | GitHub nativo | [plan-m](./plan-m-github.md) | M.1–M.3 | Push/pull/PRs sin terminal |
| 14 | Empresas autónomas | [plan-n](./plan-n-empresas-autonomas.md) | N.1–N.5 | Empresa completa operada por agentes |
| 15 | Marketplace + MCP público + v1.0 | [plan-o](./plan-o-marketplace-v1.md) | O.1–O.3 | Empresas empaquetables, release 1.0 |
| P | **Centro MCP transversal** | [plan-p](./plan-p-centro-mcp.md) | P.1–P.4 | Conectar herramientas externas sin tocar JSON (o pegándolo) |
| C.5+D.8+H.9+A.6 | **Motor Contexto/Memoria/Caché configurable** | [SDD-006 investigación](../SDD-006-investigacion-cache-memoria.md) → fases en plan-c/d/h/a | — | KV-caché, compresión, memorias multi-tipo y respaldos por rol en 5 scopes |

```
                    ┌──────────────────────────────────────┐
                    │   ETAPA 14 Empresas autónomas        │
                    │   (el gran objetivo)                 │
                    └───────────┬──────────────────────────┘
        ┌───────────┬───────────┼───────────┬──────────────┐
        ▼           ▼           ▼           ▼              ▼
   9 Revisión   8 Motor    7 Skills    10 Grafo3D    12 Sync
   (usa C)      (usa 6,7)  (usa C,D)   (usa 8)       (usa 1-5)
        └───────────┴─────┬─────┴───────────┴──────────────┘
                          ▼
        ┌─── 6 Canva+Oficina ◄── 11 Voz ──┐
        ▼                                 │
   1 Chat ► 2 Paneles ► 3 Reasonix ► 4 Memoria ► 5 Base ✓
                                    (paralelizables B∥C)
```

**Regla de orden estratégico:** cada etapa entrega valor USABLE por sí misma y desbloquea las siguientes. Nunca se construye algo que dependa de una etapa no cerrada.

## Qué copiamos de cada proyecto (síntesis — detalle en cada plan)

### De copia.md (el documento maestro original — TODO aprovechado ahora)

| Idea | Dónde aterrizó |
|---|---|
| Shadow Workspace (pre-ejecutar checks invisibles antes de mostrar código) | [H·H.5](./plan-h-motor-pruebas.md#h5) |
| Bucle auto-corrección silencioso + auto-purgado de logs | [H·H.6](./plan-h-motor-pruebas.md#h6) |
| Fast Apply / Speculative Diff (+1000 tok/s sin truncar) | [B·B.5](./plan-b-sidepanels-lovable.md#b5) |
| Índice semántico dual local + Beast search (cero servicios externos) | [D·D.5](./plan-d-memoria-v3code.md#d5) |
| Tool-Gating estricto por rol (Cline/RooCode) | [G·G.2](./plan-g-skills-lab.md#g2), [N·N.1](./plan-n-empresas-autonomas.md#n1) |
| SOP como artefactos tipados fluyendo (MetaGPT/ChatDev) | [N·N.2](./plan-n-empresas-autonomas.md#n2) |
| Taxonomía rungs completa (+SELF_FIX, REVIEW, ESCALATION) | [H](./plan-h-motor-pruebas.md#h3), [I](./plan-i-revision-superposiciones.md#i1) |
| DSPy optimizer de skills | [G·G.5](./plan-g-skills-lab.md#g5) |

### Robados a proyectos hermanos (encajan de perlas)

| Patrón | Origen | Dónde |
|---|---|---|
| Gobernanza de decisiones proposed→accepted→violated + evidencia obligatoria + scopes file-glob | varve | [D·D.4](./plan-d-memoria-v3code.md#d4) |
| Memory router fino + shards temáticos + aging policy | patrón CLAUDE.md-router | [D·D.6](./plan-d-memoria-v3code.md#d6) |
| Checkpoints git-backed por turno (código+contexto) | V3Code | [D·D.6](./plan-d-memoria-v3code.md#d6) |
| Approvals reviewer agéntico (auto_review) + reglas granulares por prefijo | Codex | [I·I.4](./plan-i-revision-superposiciones.md#i4) |
| Reflect: aprender lecciones de transcripciones pasadas (sin LLM para detectar) | codevira | [I·I.5](./plan-i-revision-superposiciones.md#i5) |
| Worktrees paralelos por agente | Codex/Cursor | [N·N.2](./plan-n-empresas-autonomas.md#n2) |
| MCP público del cerebro hacia otros agentes | Zed/V3Code | [O·O.2](./plan-o-marketplace-v1.md#o2) |

### De OpenAI Codex
2 perillas sandbox×aprobación ortogonales con presets · detección git→Auto · AGENTS.md en capas · diff clicable con feedback al turno · slash commands (/resume /fork /compact /status /permissions) · sesiones rollout JSONL · **skills como SKILL.md empaquetables** (Etapa 7) · **profiles en config** · granular approval policy · **approvals_reviewer auto_review** (un agente revisa aprobaciones — inspiración Etapa 9) · reglas allow/prompt/forbid por prefijo de comando.

### De Reasonix (verificado en vivo v1.23.0)
serve HTTP+SSE con auth token · eventos tipados reales capturados · --metrics (costo real por run) · --trajectory JSONL completo · modos permiso nativos · perfiles economy/balanced/delivery · compaction configurable (/compact) · task stop/cancel · sesiones --json · balance de cuenta · ⚠️ overhead ~31k tokens/run ⇒ enrutamiento · 🆕 **subagentes built-in: explore, research, review (veredicto+file:line), security-review (severidades)** → potencian Etapas 9 y 14 · 🆕 bot gateway multi-canal (qq/feishu/weixin — referencia futura).

### De V3Code (+ patrones robados a varve/codevira)
Memory Rail rungs teñidos clicables→trazan código · time scrubber rebobina archivos · V3 auto-router visible en vivo · checkpoints conversación+código · agentes en workspace propio paralelo · hand-edits locked leídos como memoria · todo expuesto sobre MCP · 12 herramientas LSP estructurales + Beast search · **de varve**: decisiones con gobernanza `proposed→accepted` (agente propone, humano acepta) + scopes por file-glob + `memory_pack` con presupuesto de tokens y ranking · **de codevira**: locks content-aware por símbolo (no archivo entero) + decisions.jsonl commiteado a git.

## Arquitectura central (evoluciona por etapas, nunca se rompe)

```
ETAPA 1-5 (base):  React+Zustand │ Rust: Provider trait {DeepSeekDirect, ReasonixProvider}, SQLite sqlx, EventBus
ETAPA 6+:          + CanvasLayer (ReactFlow) sobre EventBus · nodos=agentes/tareas/skills
ETAPA 7-8:         + SkillEngine (TS+Rust sandbox) · TestRunner (sandbox Docker opcional local)
ETAPA 9:           + ReviewOrchestrator (subagentes reasonix review/security-review)
ETAPA 10:          + RepoIndexer (tree-sitter + pagerank en Rust) · Three.js viewer
ETAPA 11-12:       + VoiceService (Web Speech/Edge TTS) · SyncHub (WS + Yjs CRDT)
ETAPA 13:          + GitService (gitoxide/Rust o CLI git)
ETAPA 14:          + CompanyOrchestrator (jerarquía líder→operativos sobre subagentes reasonix)
```

**Prerequisito de Etapa 1**: [ADR-005](../ADRs/ADR-005-modelo-despliegue-dual.md) + [SDD-008 análisis cliente-servidor/K8s](../SDD-008-analisis-cliente-servidor-k8s.md) — refactor a workspace Cargo creando DESDE EL DÍA 1 tres binarios: `server` (gateway axum stateless), `worker` (ejecuta agentes, patrón Everruns FOR UPDATE SKIP LOCKED) y `tauri-shell`; Postgres+RLS server-side (`tenaxum` fail-closed); fan-out broadcast POR SESIÓN para multi-dispositivo; K8s explícitamente fuera de la base (camino Compose→k3s+agent-sandbox→K8s endurecido en SDD-008), para que "local o nube" sea propiedad del build y no una promesa. Habilita Etapa 12 (sync) y agentes always-on del servidor. ✅ **Ejecutado 2026-08-23**: workspace con `crates/core` (dominio compartido) + `crates/server` (axum, prueba viva: sirve el mismo dominio por HTTP) + `src-tauri` (shell fino).

## 🔄 Cómo funciona la plataforma: multiplataforma + sync sin fricción (la explicación simple)

> Esta sección define EL modelo mental del producto. Todo feature nuevo debe caber aquí sin excepciones.

### La idea en una frase

**Tu trabajo vive en un lugar; tus pantallas solo lo muestran.** Como WhatsApp: los mensajes no viven en tu celular ni en tu laptop, viven en el servicio — por eso empiezas en el celular y terminas en la laptop sin pensarlo.

### Pieza 1 — Un solo cerebro, tres cuerpos

Todo el "cerebro" del sistema (tipos de dominio, reglas de negocio, agentes, tareas) vive en UN crate de Rust llamado `empresa-dev-core`. Ese mismo cerebro se monta en tres cuerpos distintos:

```
                    ┌──────────────────────────┐
                    │   crates/core            │
                    │   (EL CEREBRO — Rust)    │
                    │   Agentes · Tareas ·     │
                    │   Skills · Sesiones      │
                    └────────────┬─────────────┘
                                 │  el mismo código, tres montajes:
        ┌────────────────────────┼────────────────────────┐
        ▼                        ▼                        ▼
┌────────────────┐    ┌─────────────────────┐    ┌──────────────────┐
│ APP DESKTOP    │    │ APP CELULAR         │    │ SERVIDOR (nube)  │
│ (Tauri Win/Mac │    │ (Tauri iOS/Android) │    │ binario axum     │
│  /Linux)       │    │                     │    │                  │
└───────┬────────┘    └──────────┬──────────┘    └────────┬─────────┘
        │ IPC local              │ IPC local              │ HTTP/WebSocket
        │ (rápido, offline)      │ (rápido, offline)      │ (24/7, siempre)
        └────────────────────────┼────────────────────────┘
                                 ▼
                    ┌──────────────────────────┐
                    │  SYNC HUB (Etapa 12)     │
                    │  CRDT Yrs + event log    │
                    │  = la sala donde todo    │
                    │    converge              │
                    └──────────────────────────┘
```

- **Desktop/laptop:** cuerpo completo — puede trabajar SOLO (offline) porque lleva el cerebro adentro.
- **Celular:** mismo cerebro, cuerpo más pequeño (UI adaptada, ADR-001) — también puede trabajar solo.
- **Servidor:** el cerebro corriendo 24/7 sin pantalla — aquí trabajan los agentes cuando TÚ no estás conectado.

### Pieza 2 — Tu sesión es un documento vivo, no una máquina

Una sesión de trabajo NO es "la app abierta en tu laptop". Es un **documento sincronizado** (CRDT Yrs) + un **diario de eventos** (append-only):

```
SESIÓN = { doc vivo (canvas, chat, agentes, tareas) + diario de eventos }
```

Por eso da igual desde dónde abras: cualquier dispositivo descarga el documento y ya está DENTRO de tu sesión, con todo el historial. No hay "migrar" nada — solo leer el documento.

### Pieza 3 — El viaje de tu trabajo entre dispositivos (paso a paso)

1. **Lunes, laptop:** pides "arma una app de reservas". Los agentes planifican y escriben código.
2. **Martes, camino al gym (celular):** abres la app → ves el MISMO canvas, el chat completo, y una notificación: *"QA encontró 2 tests fallando"*. Respondes desde el celular: *"corrígelos"*. Son 30 segundos de tu vida.
3. **Martes noche, laptop otra vez:** todo lo que pasó sigue ahí — incluido lo que decidiste desde el celular. Los agentes NUNCA dejaron de trabajar: corren en el servidor.
4. **Sin internet:** la app local sigue funcionando (lleva el cerebro adentro); al volver la conexión, el CRDT reconcilia automáticamente lo hecho offline. Sin botón de "sincronizar": no existe.

### Pieza 4 — Git como memoria a largo plazo

El servidor guarda cada proyecto como un **repositorio git bare** (tu "GitHub propio", ADR-005 D3):

- Cada acción de un agente = commits en ramas → nada se pierde jamás, todo es revisable como diff
- Puente a GitHub real vía octocrab: push/mirror/PRs cuando quieras publicar
- Tu código propietario puede vivir SOLO en tu servidor self-hosted — nunca tiene que salir

### Resumen de qué-corre-dónde

| Dispositivo | UI | Ejecuta agentes | Guarda repos | Funciona offline |
|---|---|---|---|---|
| Laptop/desktop | ✅ completa | ✅ (modo local) | ✅ (modo local) | ✅ |
| Celular/tablet | ✅ adaptada | ❌ delega | ❌ lee/escribe via hub | ✅ (cola cambios) |
| Servidor | ❌ headless | ✅ **siempre (24/7)** | ✅ fuente canónica | n/a |
| Browser (v2) | ✅ ligera | ❌ delega | ❌ via hub | parcial |

**Regla de oro:** el dispositivo más pobre del mundo debe poder PARTICIPAR (ver, aprobar, chatear); el trabajo pesado nunca depende de que un dispositivo esté encendido.



Reglas transversales intocables: **CADA PROYECTO ES UN TENANT** — todo dato lleva `project_id` desde el día 1 ([A·A.0](./plan-a-chat-codex.md#a0): cards + tabs + historial aislado; skills/MCP/agentes GLOBAL o COPIA LOCAL a decisión del usuario) · secretos SOLO en Rust · un trait por capacidad (provider/store/embeddings/router) · SQLite append-only para auditoría · fail-open en extras, fail-safe en datos · cada capa expone su contraparte MCP (visión V3Code).

## Estimación global honesta (vibecoding dedicado)

| Bloque | Etapas | Duración |
|---|---|---|
| Base funcional | 1–5 | 4.5–6 sem |
| Visual + Skills + Pruebas | 6–8 | 5–7 sem |
| Inteligencia (revisión, 3D, voz, sync, git) | 9–13 | 5–7 sem |
| Empresas autónomas + marketplace | 14–15 | 4–6 sem |
| **Total** | 15 etapas | **~20–27 semanas** (+GrokBot fases G.6/I.6/N.6)

Valor usable continuo: chat desde semana 2, paneles semana 4, memoria semana 7, canva semana 10…

## Torneo de ideas (SDD-003)

Se generaron **500 ideas** de productos de mercado y se debatieron en torneo: solo **20 ganadoras** entran al roadmap (fases C.5 caché Reasonix, A.5 medidor/debug contexto, B.6-B.8 menciones/hunks/consola→agente, D.7 blame-rung, F.7 ⌘K, G.4 golden skills, H.7 best-of-N + H.8 cuarentena flaky, N.2 merge-train, I.4 risk-score). Detalle completo: [SDD-003-torneo-500-ideas](../SDD-003-torneo-500-ideas.md). Las 480 restantes son backlog vivo re-visible al cerrar cada etapa.

## Revisión de viabilidad y optimización (2026-08-23, post-commit d5be587)

**Veredicto: VIABLE.** Fortalezas comprobadas en runtime: infra 100% verde, trait Provider que aísla el riesgo del contrato Reasonix, estrategia mock-first que mantiene el coste de pruebas ≈$0 (gates con key real estimados <$2 c/u usando flash).

### Optimizaciones APLICADAS en esta revisión

1. **CI tenía un job roto** (`empresa-autonoma` apuntaba a carpeta eliminada en el reset Flutter→Tauri — fallaba cada push) → eliminado
2. **CI no ejecutaba ningún E2E** → job `e2e` nuevo: build + vite + chromium funcional + suite humana @core (21.8s medidas)
3. **Tiering de la suite humana**: `@core` (smoke ~22s, en cada push) vs completa (solo gates) — evita explosión de minutos de CI al crecer la suite
4. Knip añadido al CI (código muerto visible desde el principio)

### Recomendaciones de orden APROBADAS (aplican al ejecutar)

- Tras Etapa I: ejecutar **M (GitHub) antes que K/L** — los agentes necesitan committir para el Gate N, y PRs automáticos dan demo de valor antes que voz/sync
- **L.3 Co-Work CRDT** queda detrás de feature-flag y puede moverse a post-v1 sin romper L.1–L.2 (Yjs es la dependencia más compleja de menor valor inmediato)
- **B.5 Fast Apply** se activa tras feature-flag hasta pasar su chaos-test

### Carga de pruebas proyectada (matemática de viabilidad)

| Punto | Funcionales | Humanas core | Humanas full | Tiempo CI |
|---|---|---|---|---|
| Hoy | 4+12=16 | 6 (~22s) | 12 (~80s) | ~2 min |
| Gate E | ~70 | ~10 (~35s) | ~45 (~6 min) | ~9 min |

Dentro de rango sano para CI en cada push (core) + gates (full).

## Espacios reservados → [Plan Intermedio](../SDD-005-plan-intermedio.md) (no bloquea nada)

La base YA deja los ganchos que las 4 ventanas futuras necesitan — sin tablas nuevas ni deuda:
- `event_stream` con `TEST_RESULT` → alimentará el **Kanban de resultados animados** (Etapa 17)
- `documents/knowledge` ([D·D.2](./plan-d-memoria-v3code.md#d2)) + índice dual ([D·D.5](./plan-d-memoria-v3code.md#d5)) → alimentarán el **Grafo de documentos estilo Obsidian** (Etapa 16)
- Sesiones/rungs navegables ([D·D.3](./plan-d-memoria-v3code.md#d3)) → alimentarán el **Canvas de sesiones** (Etapa 18)
- Three.js + pagerank ([PLAN J](./plan-j-grafo3d-repomap.md)) + layouts persistidos desde F/VI → terreno listo para **3D/gafas** (Etapa 19)
Regla: cada ventana futura es una VISTA sobre estos datos; prohibido duplicar.

## Optimización visual/UX aplicada

| Patrón | Fuente | Fase |
|---|---|---|
| Design System core: tokens oklch, primitivas, Toast+UNDO, Skeletons, **Status bar global** | Zed/Vim/Linear | [F·F.0](./plan-f-canva-oficina.md#f0) |
| Artefactos versionados side-by-side | Claude artifacts | [B·B.9](./plan-b-sidepanels-lovable.md#b9) |
| Ramas visuales ‹2/3› al editar mensajes | ChatGPT | [A·A.9](./plan-a-chat-codex.md#a9) |
| Identidad viva: avatar IA por agente, presencia, "está escribiendo…" | Grok Bot/Slack/Discord | [N·N.6](./plan-n-empresas-autonomas.md#n6) |

copia.md queda COMPLETAMENTE minado. Backlog del torneo conserva lo no-promovido.

## Reglas de ejecución (no negociables)

1. Mini-SDD técnico por ETAPA antes de codificarla (ampliar su archivo)
2. Sistema spec-driven [SDD-002](../SDD-002-testing-spec-driven.md): 4 capas + suite humana ampliada en cada gate
3. Gates con evidencia REAL: video + suites verdes — "compila" NO es gate
4. Máx 3 intentos por error antes de escalar
5. Docs auto-gestionadas cada sesión (ESTADO/CHANGELOG/INDEX)
6. Fase >50% sobre estimación ⇒ recortar alcance documentado
7. Anti-scope-creep: features nuevas ⇒ nuevo mini-SDD antes de tocar código
