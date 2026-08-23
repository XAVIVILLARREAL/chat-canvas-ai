# PLAN D — Memoria V3Code (3 capas funcionales)

> [← Maestro](./README.md) · [← PLAN C](./plan-c-reasonix-deepseek.md) · [PLAN E →](./plan-e-integracion-total.md)
> Depende de: [PLAN C](./plan-c-reasonix-deepseek.md#c1) (trajectory como fuente de eventos).

**Entregable:** el agente RECuerda decisiones y conocimiento entre sesiones, y la UI lo hace visible (Memory Rail estilo V3Code).

## Fases

<a id="d0"></a>
### D.0 — Restaurar artefactos de referencia (prerequisito)
- `reference/` está gitignoreada: los artefactos V3Code (memory-heatmap, model-router, visual-edit) NO están en este clone
- Copiarlos desde la máquina Windows del repo original o re-descargar según `docs/"referencia de diseno.md"`
- **Criterio:** archivos presentes en `reference/v3code/` local

<a id="d1"></a>
### D.1 — Capa 1: Decision Ledger
- Tabla `event_stream` **append-only** con `project_id` (el Ledger de cada tenant-proyecto es independiente): `session_id, event_type(PROMPT/DIFF/DECISION/TEST_RESULT), summary, payload JSON, lines_added/deleted`
- Fuente primaria: `--trajectory` de Reasonix ([C·C.1](./plan-c-reasonix-deepseek.md#c1)) mapeado a rungs
- Al cerrar sesión → rung-resumen autogenerado con LLM barato (`deepseek-v4-flash`)
- Export rollout JSONL compatible con formato de sesiones Codex
- **Pruebas:** Cargo test append-only (UPDATE/DELETE rechazados por trigger); integration rung al finalizar

<a id="d2"></a>
### D.2 — Capa 2: Workspace Knowledge + Human-Tweak Lock
- Tabla `workspace_knowledge`: ADRs/convenciones/hechos del proyecto con búsqueda **FTS5** (ranking verificado en tests) — knowledge SIEMPRE scoped al proyecto; lo compartido va en biblioteca global ([A·A.0](./plan-a-chat-codex.md#a0))
- Tabla `human_invariants` (Human-Tweak Lock V3Code): coordenadas protegidas por el humano → se inyectan al contexto del agente con regla "no tocar" — costo 0 tokens de negociación
- Embeddings vectoriales DETRÁS de un trait (`EmbeddingStore`) — implementación v1: no-op; spike sqlite-vec aislado documentado aparte (no bloquea)
- **Pruebas:** Cargo test FTS ranking + invariants presentes en contexto capturado

<a id="d3"></a>
### D.3 — Capa 3: Memory Rail UI + inyección automática
- Franja vertical junto al chat (gutter teñido por sesión — paleta V3Code), icono por tipo de rung
- Scrubber simple: arrastrar filtra el chat/knowledge por momento de la sesión (replay)
- **Inyección automática de contexto**: cada prompt nuevo incluye últimos N rungs + top-k knowledge relevante (FTS5) + invariantes activas
- `/compact` slash command: compacta historial viejo a un rung (completa el set de Codex de [A·A.4](./plan-a-chat-codex.md#a4))
- **Pruebas:** E2E componentes rail/scrubber. Integration: request capturado por mock contiene contexto esperado

<a id="d4"></a>
### D.4 — Gobernanza de decisiones (patrón varve)
- Las decisiones que el AGENTE propone quedan `proposed`: NO vinculan ni se inyectan hasta que el humano las acepta (el agente jamás auto-legisla)
- Ciclo de vida completo: `proposed → accepted → violated → superseded/reverted` con evidencia obligatoria para aceptar (commit, test, link) y registro append-only de transiciones
- Scopes por file-glob: una decisión gobierna `src/auth/**`, no el mundo — la relevancia se calcula contra el diff en curso
- UI: cola "Decisiones pendientes" con aceptar/rechazar/evidencia; violaciones detectadas al tocar archivos gobernados
- **Pruebas:** Cargo test ciclo estados + enforcement de scope. E2E humano: agente propone → acepto con evidencia → otra tarea toca archivo gobernado → aviso de decisión activa

<a id="d5"></a>
### D.5 — Índice semántico dual local (patrón V3Code: "dual semantic indexing + Beast search")
- Dos índices sobre el mismo store SQLite, 100% embebido y local — CERO servicios externos:
  - Nivel BAJO: símbolos y fragmentos de código ([J·J.1](./plan-j-grafo3d-repomap.md#j1) alimenta los nodos)
  - Nivel ALTO: conceptos arquitectónicos, ADRs y decisiones del workspace
- v1 práctica: FTS5 léxico con ranking BM25 para ambos niveles (ya probado en [D·D.2](./plan-d-memoria-v3code.md#d2))
- v2 opcional (spike aislado): búsqueda semántica KNN con `sqlite-vec` embebido y embeddings generados LOCALMENTE por el provider configurado — si no hay motor disponible, el sistema queda en v1 sin degradarse (fail-open)
- Búsqueda híbrida final: FTS5 ∪ KNN con fusión por ranking cuando la v2 exista
- **Pruebas:** Integration: consulta ("cómo manejamos auth") retorna la decisión correcta aunque no comparta palabras. Indexado incremental <100ms/archivo

<a id="d6"></a>
### D.6 — Memory Router + shards + checkpoints (patrones CLAUDE.md-router / V3Code)
- El conocimiento crece por SHARDS temáticos (`auth.md`, `deploy.md`, un tema por archivo) — el contexto SIEMPRE cargado es solo el ROUTER: índice fino de una línea por shard con cuándo cargarlo (cap duro de líneas; lo que no cabe, se gradúa a shard)
- Aging policy escrita: nota activa >14 días → a su shard; shard inactivo >30 días → archivo
- **Checkpoints V3Code**: cada turno genera snapshot git-backed (rama interna shadow) — saltar a cualquier checkpoint restaura código Y contexto de conversación intactos
- **Pruebas:** Unit aging policy. Integration router: prompt de auth carga SOLO shard auth (verificado en request capturado). E2E checkpoint: rebobinar a turno N restaura archivos exactos

## 🚪 GATE D (demo verificable)

1. Sesión 1: "decidimos usar Tailwind, prohibido CSS global" → decisión queda en Ledger
2. Cerrar la app completamente
3. Sesión 2: "estila un botón" → el agente usa Tailwind y cita la decisión previa; el contexto inyectado es visible en devtools
4. El Memory Rail muestra ambas sesiones conectadas con sus tintes
5. Línea/archivo bloqueado por el humano (lock) NO es modificado por el agente

Evidencia: video + suites verdes.

---
[← Maestro](./README.md) · [← PLAN C](./plan-c-reasonix-deepseek.md#c1) · [PLAN E →](./plan-e-integracion-total.md)
