# SDD-001 · Roadmap Maestro — Empresa Dev

> Fecha: 2026-08-22 · Estado: Propuesto · v3 MEGA-PLAN (15 etapas, ~70 fases)
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

## Mapa de las 15 ETAPAS (~70 fases)

| Etapa | Nombre | Archivo | Fases | Gate resumen |
|---|---|---|---|---|
| 0 | Fundaciones | *(completada)* | — | Infra 100% verde + testing humano 12/12 ✅ |
| 1 | Chat núcleo Codex | [plan-a](./plan-a-chat-codex.md) | A.1–A.4 | Streaming real, 2 perillas, slash cmds |
| 2 | Sidepanels Lovable | [plan-b](./plan-b-sidepanels-lovable.md) | B.1–B.5 | Ves construirse en vivo |
| 3 | Runtime Reasonix+DeepSeek | [plan-c](./plan-c-reasonix-deepseek.md) | C.0–C.3 | 2 motores, costos, cancelación |
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

Reglas transversales intocables: secretos SOLO en Rust · un trait por capacidad (provider/store/embeddings/router) · SQLite append-only para auditoría · fail-open en extras, fail-safe en datos · cada capa expone su contraparte MCP (visión V3Code).

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

## Reglas de ejecución (no negociables)

1. Mini-SDD técnico por ETAPA antes de codificarla (ampliar su archivo)
2. Sistema spec-driven [SDD-002](../SDD-002-testing-spec-driven.md): 4 capas + suite humana ampliada en cada gate
3. Gates con evidencia REAL: video + suites verdes — "compila" NO es gate
4. Máx 3 intentos por error antes de escalar
5. Docs auto-gestionadas cada sesión (ESTADO/CHANGELOG/INDEX)
6. Fase >50% sobre estimación ⇒ recortar alcance documentado
7. Anti-scope-creep: features nuevas ⇒ nuevo mini-SDD antes de tocar código
