# SDD-001 · Roadmap Maestro — Empresa Dev

> Fecha: 2026-08-24 · Estado: Activo · v3.10 MEGA-PLAN (16 etapas base + P + 4 intermedio, ~137 fases: 114 base + 23 intermedio intercalado)
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
| 2 | Sidepanels Lovable | [plan-b](./plan-b-sidepanels-lovable.md) | B.1–B.9 | Ves construirse en vivo |
| 3 | Runtime Reasonix+DeepSeek+Ollama+**API universal** | [plan-c](./plan-c-reasonix-deepseek.md) | C.0–C.7 | 3 motores (local-ready), costos, cancelación |
| 4 | Memoria V3Code | [plan-d](./plan-d-memoria-v3code.md) | D.0–D.8 | Recuerda entre sesiones + gobernanza + grafo dual |
| 5 | Cierre Base | [plan-e](./plan-e-integracion-total.md) | E.1–E.3 | Tag `plan-base-v0.1` |
| 6 | Canva ReactFlow + Oficina | [plan-f](./plan-f-canva-oficina.md) | F.0–F.7 | Nodos-agentes animados arrastrables |
| 7 | Skills Lab | [plan-g](./plan-g-skills-lab.md) | G.1–G.7 | Crear/probar/exportar skills sin YAML |
| 8 | Motor de pruebas y resultados | [plan-h](./plan-h-motor-pruebas.md) | H.1–H.9 | Agentes demuestran con tests, no promesas |
| 9 | Revisión auto + Superposiciones | [plan-i](./plan-i-revision-superposiciones.md) | I.1–I.6 | El sistema detecta y corrige solo |
| 10 | Grafo 3D Repo-Map | [plan-j](./plan-j-grafo3d-repomap.md) | J.1–J.2 | Repo entero en <1000 tokens para el contexto (J.3 visor 3D → intermedio 3D) |
| 11 | Voz | [plan-k](./plan-k-voz.md) | K.3 | Política de interrupción (transversal; K.1/K.2 TTS/STT → intermedio CR) |
| 12 | Sync multi-device + Co-Work | [plan-l](./plan-l-sync-cowork.md) | L.1–L.4 | Continúas donde dejaste, en cualquier dispositivo |
| 13 | GitHub nativo | [plan-m](./plan-m-github.md) | M.1–M.3 | Push/pull/PRs sin terminal |
| 14 | Empresas autónomas | [plan-n](./plan-n-empresas-autonomas.md) | N.1–N.7 | Empresa completa operada por agentes |
| 15 | Marketplace + MCP público + v1.0 | [plan-o](./plan-o-marketplace-v1.md) | O.1–O.3 | Empresas empaquetables, release 1.0 |
| 16 | Canvas Planeación + **Consejo de Expertos** + **Discovery Hub** | [plan-intermedio](../SDD-005-plan-intermedio.md) | VI.1–VI.8 | **INTERCALADO**: VI.1–VI.4 tras Gate F · VI.5–VI.8 (Consejo + Discovery) tras Gate G — DOGFOOD + exploración repos |
| 17 | Kanban de Resultados | [plan-intermedio](../SDD-005-plan-intermedio.md) | KR.1–KR.5 | **INTERCALADO tras Gate H** (KR.3 tras N.3/N.6): tablero evidencia-first con bloques animados de tests |
| 18 | Control Room | [plan-intermedio](../SDD-005-plan-intermedio.md) | CR.1–CR.5 | **AL FINAL** (paralelo a N/O): mapa global + cards de sesión vivas + órdenes por voz |
| 19 | Preparación espacial + Visor 3D | [plan-intermedio](../SDD-005-plan-intermedio.md) | 3D.1 + J.3 + 3D.2 | **tras Gate J**: SpatialMeta → visores 3D unificados (puente a gafas/WebXR) |
| P | **Centro MCP transversal** | [plan-p](./plan-p-centro-mcp.md) | P.1–P.4 | Conectar herramientas externas sin tocar JSON (o pegándolo) |
| S | **Despliegue/Costos/Stack eficiente** | [plan-s](./plan-s-despliegue-costos.md) | S.1–S.4 | Hosting 3 etapas ($16→$600/mes), stack Rust fijado, patrones Tauri — datos ago-2026 |
| T | **Excelencia transversal** | [plan-t](./plan-t-excelencia.md) | T.SEC/T.A11Y/T.ONB/T.QA/T.BIZ | Seguridad profesional, i18n, onboarding <5min, calidad continua, comercial/legal |
| U | **Dopaminérgico v2 (juice+flow)** | [plan-u](./plan-u-motivacion.md) | U.1–U.8 | JUICE calibrado, hitos gated con cofres funcionales, rachas-perdonables, heatmap, inbox de resultados anti-spinner, flow-protection, widget 2-datos, unboxing emocional — cero dark patterns |
| V | **Visual GrokBot (transversal social)** | [plan-v](./plan-v-visual-grokbot.md) | V.0–V.4 | Chat-first estilo mensajería: desks, identidad por avatar geométrico (el color es QUIÉN, no estado), estados en 2 capas, actividad/aprobaciones inline en el hilo, group chat con handoffs visibles |
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

### De Grok Bot (VISUAL — la capa social, referencia de UI de mensajería)

| Patrón visual Grok Bot (verificado) | Adaptación | Fase |
|---|---|---|
| La app es mensajería, no dashboard: cada bot es un "desk" en la sidebar | AppShell chat-first: fila por bot/proyecto con última actividad; el chat es la superficie primaria | [V·V.0](./plan-v-visual-grokbot.md#v0) |
| Avatar geométrico de color = IDENTIDAD (triángulo/hexágono/círculo…); el estado es capa aparte | Avatares geométricos deterministas + estados 2 capas (puntos=working, needs-attention, badge no-leído) | [V·V.1](./plan-v-visual-grokbot.md#v1) |
| Actividad del bot INLINE en el hilo; aprobaciones como opciones numeradas (▸ 1. X · 2. Y) | Tools/archivos/diffs y aprobaciones viven en el hilo con un tap de respuesta | [V·V.2](./plan-v-visual-grokbot.md#v2) |
| Group chat 2–6 bots, @menciones, handoffs visibles en la conversación | Group chat de la empresa con identidad por mensaje y ownership visible | [V·V.3](./plan-v-visual-grokbot.md#v3) |
| Follow-along con indicador; notificaciones por bot que persisten como no-leído; digests como mensajes | Rutinas visibles + badges persistentes + digest del PM en el hilo | [V·V.4](./plan-v-visual-grokbot.md#v4) |

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

**Prerequisito de Etapa 1**: [ADR-005](../ADRs/ADR-005-modelo-despliegue-dual.md) + [SDD-008](../SDD-008-analisis-cliente-servidor-k8s.md) + [SDD-009 debate adversarial](../SDD-009-debate-decisiones.md) — refactor a workspace Cargo con binarios `server` (gateway axum stateless QUE SIRVE LA WEB APP), `worker` (agentes, patrón Everruns FOR UPDATE SKIP LOCKED) y clientes intercambiables: **WEB PRIMERO** (React servida directamente por el gateway — cero instalación), CLI ligero para repos locales, — mercado 2026 votó URL: Lovable/Replit/Bolt), CLI ligero después para repos locales, `tauri-shell` diferido hasta demanda demostrada; Postgres+RLS fail-closed (`tenaxum`); fan-out broadcast POR SESIÓN; K8s fuera de la base (camino Compose→k3s+agent-sandbox en SDD-008). ✅ **RATIFICADO POR EL USUARIO (2026-08-24): WEB-FIRST** — el gateway sirve la aplicación web; `tauri-shell` se construye DESPUÉS solo si hay demanda demostrada (envoltorio de la misma web + superpoderes nativos), para que "local o nube" sea propiedad del build y no una promesa. Habilita Etapa 12 (sync) y agentes always-on del servidor. ✅ **Ejecutado 2026-08-23**: workspace con `crates/core` (dominio compartido) + `crates/server` (axum, prueba viva: sirve el mismo dominio por HTTP) + `src-tauri` (shell fino).

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
│ NAVEGADOR (v1) │    │ CELULAR / tablet    │    │ SERVIDOR (nube)  │
│ (web servida   │    │ (UI adaptada del    │    │ binario axum     │
│  por el gateway│    │  mismo web)         │    │ 24/7 · agentes   │
└───────┬────────┘    └──────────┬──────────┘    └────────┬─────────┘
        │ HTTP/WS               │ HTTP/WS                │ local
        │ (siempre)             │ (siempre)              │ (siempre)
        └────────────────────────┼────────────────────────┘
                                 ▼
                    ┌──────────────────────────┐
                    │  SYNC HUB (Etapa 12)     │
                    │  CRDT Yrs + event log    │
                    │  = la sala donde todo    │
                    │    converge              │
                    └──────────────────────────┘
```

- **Navegador (v1 — WEB-FIRST):** el cerebro lo sirve el gateway axum — cero instalación, abre y trabajas; los agentes corren en el servidor (o en modo local).
- **Celular/tablet:** misma web con UI adaptada (ADR-001) — participa, aprueba, chatea; el trabajo pesado delega al servidor.
- **Servidor:** el cerebro corriendo 24/7 sin pantalla — aquí trabajan los agentes cuando TÚ no estás conectado.
- **Tauri shell (DIFERIDO):** envuelve la misma web con superpoderes nativos (IPC local, offline real) — se construye SOLO si hay demanda demostrada ([ADR-005](../ADRs/ADR-005-modelo-despliegue-dual.md)). "local o nube" es propiedad del build, no una promesa.

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
| **Navegador (v1 — WEB-FIRST)** | ✅ completa | ✅ (modo servidor) | ✅ (repos bare del servidor) | parcial (cola cambios) |
| Celular/tablet | ✅ adaptada | ❌ delega | ❌ lee/escribe via hub | ✅ (cola cambios) |
| Servidor | ❌ headless | ✅ **siempre (24/7)** | ✅ fuente canónica | n/a |
| Tauri shell (diferido, solo con demanda) | ✅ completa | ✅ (modo local) | ✅ (modo local) | ✅ |

**Regla de oro:** el dispositivo más pobre del mundo debe poder PARTICIPAR (ver, aprobar, chatear); el trabajo pesado nunca depende de que un dispositivo esté encendido.



Reglas transversales intocables: **CÓMPUTO CLIENT-FIRST** (todo lo que pueda correr en el cliente va al cliente — ver ARQUITECTURA.md) · **CADA PROYECTO ES UN TENANT** — todo dato lleva `project_id` desde el día 1 ([A·A.0](./plan-a-chat-codex.md#a0): cards + tabs + historial aislado; skills/MCP/agentes GLOBAL o COPIA LOCAL a decisión del usuario) · secretos SOLO en Rust · un trait por capacidad (provider/store/embeddings/router) · SQLite append-only para auditoría · fail-open en extras, fail-safe en datos · cada capa expone su contraparte MCP (visión V3Code).

## Estimación global honesta (vibecoding dedicado)

| Bloque | Etapas | Duración |
|---|---|---|
| Base funcional | 1–5 | 4.5–6 sem |
| Visual + Skills + Pruebas | 6–8 | 5–7 sem |
| Inteligencia (revisión, 3D, voz, sync, git) | 9–13 | 5–7 sem |
| Empresas autónomas + marketplace | 14–15 | 4–6 sem |
| **Total** | 15 etapas | **~24–32 semanas** (+GrokBot fases G.6/I.6/N.6)

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

### Revisión v3.10 (2026-08-24) — análisis profundo final: unificación y orden

- **VI.8 (Discovery Hub) absorbida** (sesión concurrente): explorador GitHub + Repo Scout tras Gate G; matriz y totales unificados — **137 fases (114 base + 23 intermedio: VI 8 + KR 5 + CR 5 + 3D 3 + K.1/K.2 2)**
- **Header/tabla/ORDEN alineados**: v3.10, filas de Etapas 16–19 en la tabla maestra (KR tras H, CR al final, 3D tras J), ORDEN con VI.8, secciones de revisión reordenadas cronológicamente (v3.10→v3.9→v3.8→v3.6→v3.5→v3.4)
- **A.4 ↔ V.2 aclarado**: las cards inline + aprobaciones de opciones numeradas se implementan NATIVAMENTE en A.4 (Etapa 1, es el corazón UX Codex); V.2 (con F.0) unifica la primitiva con el Consejo (VI.6) y aplica el pulido SDD-013 — sin dependencia hacia adelante falsa
- **ESTADO.md actualizado**: "Donde estamos" a v3.10/137; el siguiente paso concreto es **schema maestro (mini-SDD) → mini-SDD PLAN A → A.1** (los prerequisitos de arranque del §PRE-ARRANQUE ya están fijados y el crate `worker` ya existe)
- **Blindaje de PRUEBAS (reglas 14–16 + SDD-002)**: cada fase manejable por prompt (slices `X.1a/X.1b` con mini-gate si excede ~1 sesión IA; fases grandes conocidas SIEMPRE se parten) · contrato de pruebas 1:1 con criterios de negocio (4 capas + humana en GUI + chaos en I/O) · **E2E transversal por etapa en cada gate** (las pruebas E2E crecen por fase Y por etapa) · **gate de deuda por fase** (knip/clippy/biome limpios, 0 TODOs nuevos, cobertura ≥ umbral, suites históricas verdes, evidencia) — nada se quitó, todo es aditivo

### Revisión v3.9 (2026-08-24) — Spec visual "Obsidian Glass" integrada

- **[SDD-013](../SDD-013-gui-visual-spec.md) es la FUENTE CANÓNICA VISUAL** de todo el plan (no solo F): tokens oklch (fondos void→overlay, vidrio translúcido, acentos neón sofisticados), tipografía/espaciado/radios, motion neuro-psicológico (física de resortes, solo transform+opacity, catálogo de 10 animaciones), Liquid Glass 4 capas con fallback, componentes (GlassCard/AgentNode/AnimatedBeam/Toast/⌘K), tabla de sonidos por teoría musical y checklist de calidad auditado en F.5
- **Fusión con el plan**: F.0 (implementación del §1–§4) · PLAN U (mapeo token/animación/sonido por primitiva) · PLAN V (avatares/estados usan la paleta de identidad §1.1) · K.3 (sonidos §5.3 canónicos) · T.A11Y (contraste §1.1 + checklist §7) · A.4 (superficie chat con GlassCard) · matriz: regla "toda UI usa tokens SDD-013; CSS improvisado prohibido"
- Tokens ya implementados en `src/styles.css` (Obsidian Glass) — la IA lee SDD-013 antes de tocar cualquier UI

### Revisión v3.8 (2026-08-24) — Plan Intermedio INTERCALADO (ratificado por el usuario)

- **El intermedio deja de ser "el plan después de la base"**: pasa a ser un **carril de vistas** intercalado — cada ventana se construye justo tras su fase base habilitadora (VI tras F/G, KR tras H, 3D tras J, CR al final paralelo a N/O)
- **J.3 (visor 3D) se movió de la base al intermedio** (J.1/J.2 quedan: el repo-map alimenta el contexto del agente)
- **K.1/K.2 (voz TTS/STT) se movieron al intermedio** (las consume CR); **K.3 (política de interrupción) se queda en base** por ser transversal (U.5/V.4/I)
- **Consejo de Expertos ADELANTADO como DOGFOOD**: en cuanto existan G.1/G.2 (Etapa 7), VI.5–VI.8 se construyen y se usan para **auditar los gates de la propia base** (Consejo + Discovery Hub)
- Base: **114 fases** · Intermedio: **23** (VI 8 + KR 5 + CR 5 + 3D 3 + K.1/K.2 2) · **Total 137**

### Revisión v3.6 (2026-08-24) — Visual GrokBot como referencia de la capa social

- **Nuevo [PLAN V](./plan-v-visual-grokbot.md) (transversal, 5 fases)**: lo visual de Grok Bot (xAI/Cursor, verificado con docs oficiales + reviews) — la app se SIENTE mensajería, no dashboard
- **Chat-first "desks"**: sidebar = una fila por bot/proyecto con su última actividad (V.0 con A.1/A.4)
- **Identidad por avatar geométrico**: el color del avatar es QUIÉN, no estado — estados en 2 capas separadas: puntos animados = trabajando, needs-attention, badge no-leído, desk activo (V.1 con F.0/G.7)
- **Actividad inline en el hilo**: tools/archivos/diffs y **aprobaciones como opciones numeradas** (▸ 1. X · 2. Y) con un tap (V.2 con A.4/B.4)
- **Group chat de bots visual**: 2–6 bots, @menciones/@everyone, handoffs visibles en la conversación (V.3 con N.6)
- **Rutinas visibles + notificaciones persistentes**: follow-along con indicador, badge no-leído que persiste, digests como mensajes del PM (V.4 con G.6/K.3/U.5)
- **Complementa, no quita**: Codex sigue siendo la referencia de paneles/diffs; GrokBot es la referencia de la capa social

### Revisión de arquitectura v3.5 (2026-08-24) — escalabilidad + stack validado por investigación

- **CÓMPUTO CLIENT-FIRST elevado a regla transversal #12**: todo cómputo que pueda correr en el cliente va al cliente (búsqueda local wa-sqlite/OPFS + sqlite-vec WASM en D.5, indexación AST web-tree-sitter en J.1, canva Three.js WebGPU en F.6, LLM local Ollama en C.6) — el servidor escala con los DATOS, no con la CPU de cada usuario; solo queda server-only lo central (agentes 24/7, sync, repos, secretos, RLS)
- **ARQUITECTURA.md reescrita (v3.5)**: eliminado el backend Python fantasma (FastAPI/CrewAI — no existía `services/python/`) y el modelo Tauri-first; alineada a ADR-005 (web-first) + SDD-008 (workers Everruns, Postgres SKIP LOCKED) + Plan Base v3.4; **INFRA.md corregido** y ADR-002 marcado como superado en parte
- **Stack validado por investigación (2026-08-24)**: Rust axum 0.8.9 + tokio 1.53 + sqlx 0.9 + rustls 0.23 es la combinación vigente (3.475 sesiones WS/vCPU, benchmark streaming — el más barato por conexión; patrón Everruns); **sin BFF Node/Hono** (un solo stack para un dev); Go (chi/pgx) como plan B pragmático (70% rendimiento, ~1/4 fricción); Hono solo si mañana se necesita ecosistema npm/edge (nunca Express)

### Revisión profunda v3.4 (2026-08-24) — decisiones del usuario aplicadas

- **A.5 (medidor/debug contexto) y D.7 (blame-rung) reintegradas** como fases reales con pruebas — estaban prometidas en ORDEN/torneo pero no existían
- **H.9 partida**: H.9a (aislamiento contenedor mínimo) se ejecuta tras C.3 y cumple la condición NO negociable de seguridad de PLAN C; H.9b (computadora persistente) al final de H
- **P (Centro MCP)** pasa a ejecutarse tras el Gate B, en paralelo con C/D (antes en paralelo con F)
- **M (GitHub) antes que K/L** ahora está DENTRO del ORDEN (antes era una recomendación que contradecía el propio bloque); voz (K) al final del bloque
- **Multiplataforma alineada a WEB-FIRST**: navegador = v1 servido por el gateway; Tauri diferido hasta demanda (sección "cómo funciona la plataforma" corregida)
- **A.7/A.8**: v1 mínima en Etapa 1 (tarea simple / resume sin rungs) que H.1/D.1 formalizan después
- **C.7 y D.8**: alcance v1 acotado en la base; lo pesado (OAuth/small_model · memoria relacional/reflexión) marcado post-base (C.7b / D.8b)
- **Matriz regenerada**: 112 fases, orden = ejecución, regla "fase GUI ⇒ [E]+[H]", presupuesto **máx $20/gate** con APIs reales

### Recomendaciones de orden APROBADAS (aplican al ejecutar)

- ✅ **M (GitHub) antes que K/L** ya está EN el ORDEN (bloque de ejecución arriba) — los agentes necesitan committir para el Gate N, y PRs automáticos dan demo de valor antes que voz/sync
- **L.3 Co-Work CRDT** queda detrás de feature-flag y puede moverse a post-v1 sin romper L.1–L.2 (Yjs es la dependencia más compleja de menor valor inmediato)
- **B.5 Fast Apply** se activa tras feature-flag hasta pasar su chaos-test
- ✅ **P (Centro MCP)** se ejecuta tras el Gate B, en paralelo con C/D (antes esperaba a F)
- ✅ **H.9 partida**: H.9a (contenedor mínimo) tras C.3; H.9b (computadora persistente) al final de H
- ✅ **Voz (K)** al final del bloque de inteligencia (J → M → L → K)

### Carga de pruebas proyectada (matemática de viabilidad)

| Punto | Funcionales | Humanas core | Humanas full | Tiempo CI |
|---|---|---|---|---|
| Hoy | 4+12=16 | 6 (~22s) | 12 (~80s) | ~2 min |
| Gate E | ~70 | ~10 (~35s) | ~45 (~6 min) | ~9 min |
| Gate N | ~300 | ~20 (~70s) | ~140 (~22 min) | ~28 min |

Dentro de rango sano para CI en cada push (core) + gates (full).

## Plan Intermedio — INTERCALADO (no "después de la base") — [SDD-005](../SDD-005-plan-intermedio.md)

**Modelo v3.8 (ratificado 2026-08-24)**: el intermedio NO va después de la base — es un **carril de vistas** que se construye justo tras su fase base habilitadora, en paralelo con el resto de la base:
- **VI.1–VI.4** (Canvas Planeación) ⟶ tras Gate F (necesita D.2 + F.1)
- **VI.5–VI.8** (Consejo de Expertos + Discovery Hub) ⟶ tras Gate G — **ADELANTADO como DOGFOOD**: audita los gates de la propia base + exploración de repos
- **KR.1–KR.5** (Kanban Resultados) ⟶ tras Gate H (KR.3 tras N.3/N.6)
- **3D** (3D.1 + J.3 + 3D.2) ⟶ tras Gate J (motor Three.js); **J.3 se movió de la base al intermedio**
- **K.1/K.2** (voz TTS/STT) ⟶ intermedio (las consume CR); **K.3** (política de interrupción) SE QUEDA en base (transversal: U.5/V.4/I)
- **CR.1–CR.5** (Control Room) ⟶ al final (paralelo a N/O; consume K.1/K.2 + todo)

Ganchos que la base ya deja (sin tablas nuevas): `event_stream` TEST_RESULT → KR · `documents/knowledge` + índice dual → VI · sesiones/rungs → CR · `SpatialMeta` (F.0/F.4) → terreno 3D. Regla: cada ventana es una VISTA sobre estos datos; prohibido duplicar.

## ORDEN DE EJECUCIÓN MAESTRO (los números de fase son IDs estables; esta es la secuencia de construcción)

```
ETAPA 1  A.0→A.1→A.2(+settings cifrada)→A.3→A.4→A.5→A.6→A.7→A.8→A.9 ── Gate A
PARALELO TRAS GATE A:
  Track BETA   B.1→B.2→B.3→B.4→B.5→B.6→B.7→B.8→B.9 ── Gate B
  Track GAMMA  C.0→C.1→C.2→C.3→H.9a→C.5→C.6→C.7 ─────── Gate C  ← H.9a (contenedor mínimo) tras C.3: condición NO negociable de seguridad
PARALELO TRAS GATE B (con C/D):
  P.1→P.2→P.3→P.4 ── Gate P (Centro MCP — alimenta G y N)
ETAPA 4  D.0→D.1→D.2→D.3→D.4→D.5→D.6→D.7→D.8 ── Gate D
ETAPA 5  E.1→E.2→E.3 ── 🏷️ plan-base-v0.1
POST-BASE (base funcional) ⟷ INTERMEDIO (carril de vistas — INTERCALADO, no después):
  F.0→F.1→F.2→F.3→F.4→F.7→F.5→F.6 (Gate F)
    ⟶ INTERMEDIO VI.1→VI.4 (Canvas Planeación — tras F, necesita D.2+F.1)
  G.1→G.2→G.3→G.4→G.6→G.7→G.5 (Gate G)  ← G.7 identidad viva; su voz se completa en el intermedio (K.1)
    ⟶ INTERMEDIO VI.5→VI.8 (Consejo de Expertos + Discovery Hub — ADELANTADO: DOGFOOD, audita los gates de la base)
  H.1→H.2→H.5→H.6→H.3→H.4→H.7→H.8→H.9b (Gate H)  ← desviación: Shadow primero; H.9a ya corrió en Etapa 3
    ⟶ INTERMEDIO KR.1→KR.2→KR.4→KR.5 (Kanban Resultados — tras H; KR.3 tras N.3/N.6)
  I.1→I.6→I.2→I.3→I.4→I.5 (Gate I)
  J.1→J.2 (Gate J) ← J.3 (visor 3D) MOVIDO al intermedio (3D)
  M.1→M.2→M.3 (Gate M) ← ANTES que L: los agentes necesitan git para el Gate N y los PRs dan valor visible temprano
  L.1→L.2→L.4→L.3-flag (Gate L)
  K.3 (Gate K parcial) ← política de interrupción transversal (la usan U.5/V.4/I); K.1/K.2 voz → intermedio (CR)
  N.1→N.2→N.3→N.4→N.5→N.6→N.7 (Gate N) · O.1→O.2→O.3 (v1.0)
INTERMEDIO AL FINAL (paralelo a N/O):
  3D: 3D.1→J.3→3D.2 (visores 3D unificados — tras J) · Voz: K.1→K.2 (las consume CR) · CR.1→CR.5 (Control Room — la vista que unifica todo)
TRANSVERSALES: U.1 con F.0 · subconjunto flow-protection/inbox de U.5 desde A.4 ·
  resto U tras cada ventana · S.1+S.2 prerequisito de Etapa 1 · S.3 solo con demanda Tauri · S.4 continuo ·
  T.SEC/T.QA desde Etapa 1 · T.BIZ antes v1.0 ·
  V.0 con A.1/A.4 (chat-first) · V.1–V.2 con F.0/G.7 (identidad + actividad inline) · V.3 con N.6 (group chat) · V.4 con G.6/K.3/U.5 (rutinas + notif)
```

**Matriz completa de TODAS las fases con sus pruebas**: [MATRIZ-FASES-PRUEBAS.md](./MATRIZ-FASES-PRUEBAS.md) — generada automáticamente, regenerar al cambiar fases.

## Optimización visual/UX aplicada

| Patrón | Fuente | Fase |
|---|---|---|
| Design System core: tokens oklch, primitivas, Toast+UNDO, Skeletons, **Status bar global** | Zed/Vim/Linear | [F·F.0](./plan-f-canva-oficina.md#f0) |
| Artefactos versionados side-by-side | Claude artifacts | [B·B.9](./plan-b-sidepanels-lovable.md#b9) |
| Ramas visuales ‹2/3› al editar mensajes | ChatGPT | [A·A.9](./plan-a-chat-codex.md#a9) |
| Identidad viva: avatar IA por agente, presencia, "está escribiendo…" | Grok Bot/Slack/Discord | [N·N.6](./plan-n-empresas-autonomas.md#n6) |
| Chat-first "desks": la app es mensajería, no dashboard | Grok Bot | [V·V.0](./plan-v-visual-grokbot.md#v0) |
| Identidad por avatar geométrico + estados en 2 capas | Grok Bot | [V·V.1](./plan-v-visual-grokbot.md#v1) |
| Aprobaciones como opciones numeradas inline en el hilo | Grok Bot | [V·V.2](./plan-v-visual-grokbot.md#v2) |

copia.md queda COMPLETAMENTE minado. Backlog del torneo conserva lo no-promovido.

## 🔧 PRE-ARRANQUE — checklist antes de tocar Etapa 1 (v3.8, ratificado 2026-08-24)

Decisiones que cuestan caro cambiarlas después — fijadas ANTES de codificar:

1. **Refactor Cargo con `crates/worker` (patrón Everruns)** — ✅ EJECUTADO (2026-08-24): worker stateless SIN credenciales de DB, heartbeat 30s; el claim `FOR UPDATE SKIP LOCKED` y el sandbox Docker llegan con C.3/H.9a
2. **Auth MVP en A.0 (modo servidor)**: el gateway es público (web-first) → A.0 incluye sesión/token simple + **RLS fail-closed desde el día 1**; passkeys/QR-pairing ([SDD-008](../SDD-008-analisis-cliente-servidor-k8s.md)) quedan post-base
3. **Postgres en Compose desde el día 1** (dev web-first = servidor): RLS se prueba REAL desde Etapa 1; SQLite solo para el shell Tauri offline futuro ([ADR-005 D2](../ADRs/ADR-005-modelo-despliegue-dual.md))
4. **Schema maestro unificado (mini-SDD ANTES de A.2)**: TODAS las tablas con `tenant_id` + **contrato de `event_stream`/rung** (event_type canónico + payload) definidos UNA vez, implementados por fases — evita migraciones dolorosas entre D.1/F.4/H.3/KR/CR/VI
5. **Tipos compartidos web-first**: fuente de verdad `crates/core` (specta) → JSON schema → cliente TS generado de la **OpenAPI del gateway axum** (openapi-typescript/orval); `shared-types` deja de ser manual
6. **KEK de settings cifradas (A.2)**: env var / keyring con fallback cifrado (patrón [T.SEC](./plan-t-excelencia.md#tsec)) — decidido, no improvisado en A.2
7. **Sandbox dev**: docker socket del host montado en el worker (C.3/H.9a); red denegada por defecto
8. **Recursos**: cuenta DeepSeek + Ollama (servidor 32GB) listas antes de Etapa 1 · cuenta GitHub de prueba (Gates M/N) · presupuesto dev LLM ~$50–100/mes (gates reales: E.1/N.5/C.6/I.1/M.1)
9. **Proceso**: UNA sesión a la vez sobre docs/plan (las sesiones concurrentes ya causaron roces de commits); los commits de docs se pushean al cerrar cada decisión

## Reglas de ejecución (no negociables)

1. Mini-SDD técnico por ETAPA antes de codificarla (ampliar su archivo)
2. Sistema spec-driven [SDD-002](../SDD-002-testing-spec-driven.md): 4 capas + suite humana ampliada en cada gate
3. Gates con evidencia REAL: video + suites verdes — "compila" NO es gate
4. Máx 3 intentos por error antes de escalar
5. Docs auto-gestionadas cada sesión (ESTADO/CHANGELOG/INDEX)
6. Fase >50% sobre estimación ⇒ recortar alcance documentado
7. Anti-scope-creep: features nuevas ⇒ nuevo mini-SDD antes de tocar código
8. **Toda fase GUI tiene [E]2E humano explícito** ([H] obligatoria) — "compila" no es gate; "lo operé como persona" sí
9. Presupuesto de pruebas con APIs reales (DeepSeek/GitHub/Ollama): **máx $20/gate**; el resto de la suite corre mock-first (~$0)
10. **La matriz se regenera en CADA cambio de fases**; una fase sin fila en la matriz no se construye
14. **CADA FASE ES MANEJABLE POR PROMPT**: si una fase excede ~1 sesión IA (≈200–400 líneas o 2+ prompts), se subdivide en slices (`X.1a/X.1b…`) con mini-gate y commit propios — las fases grandes conocidas (A.4, C.7, D.8, F.0, H.9b, N.2, N.6, VI.6, CR.1–3) SIEMPRE se parten al implementar ([SDD-002 §slices](../SDD-002-testing-spec-driven.md))
15. **MÁXIMA COBERTURA DE PRUEBAS (regla de negocio)**: cada fase declara criterios de negocio observables y sus pruebas 4 capas los verifican 1:1; toda fase GUI tiene E2E humana; chaos en toda fase que toque I/O/externo; **cada Gate añade un journey E2E transversal de etapa** (SDD-002 §contrato)
16. **GATE DE DEUDA POR FASE**: knip/clippy/biome limpios, 0 TODOs nuevos sin responsable, cobertura ≥ umbral, suites históricas verdes, evidencia adjunta — una fase que cierra con deuda nueva NO está cerrada ([SDD-002 §deuda](../SDD-002-testing-spec-driven.md))
11. **RESPONSIVE TOTAL (transversal dura)**: TODAS las pantallas/secciones/ventanas son mobile-first y operables en celular — toda fase GUI se verifica en móvil 375 + desktop 1440 (suite humana `responsive-human.spec.ts` en cada gate); no existe pantalla "solo desktop"; un gate con mobile rojo NO cierra
12. **CÓMPUTO CLIENT-FIRST (transversal dura, escalabilidad)**: todo cómputo que PUEDA correr en el cliente corre en el cliente (render, búsqueda local FTS/vectorial, indexación AST WASM, canva WebGPU, LLM local Ollama) — el servidor solo ejecuta lo central (agentes 24/7, estado autoritativo, sync, repos, secretos); el servidor escala con los DATOS, no con la CPU de cada usuario (tabla en ARQUITECTURA.md)
13. **RENDERER AGNÓSTICO (transversal dura, preparación 3D/gafas)**: toda UI visual se construye con **primitivas del Design System** (F.0) y **tipos de dominio con `SpatialMeta`**, NO con componentes específicos de un renderer. El renderer (ReactFlow 2D → Three.js 3D → WebXR gafas) es un "executor" intercambiable — los componentes y datos NO cambian al cambiar de renderer. Cadena: `Design System primitives → ReactFlow (2D) → Three.js (3D) → WebXR (gafas)`
