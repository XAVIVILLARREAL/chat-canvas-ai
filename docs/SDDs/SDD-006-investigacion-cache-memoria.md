# SDD-006 — Investigación profunda: Caché, Compresión y Memorias configurables (SOTA)

> Fecha: 2026-08-23 · Estado: Aprobado · Método: 3 investigaciones paralelas con sub-agentes (KV-cache/cuantización · jerarquías de config de productos líderes · arquitecturas de memoria)
> Esta investigación alimenta: [C·C.5](./SDD-001-plan-base/plan-c-reasonix-deepseek.md#c5) · [D·D.8](./SDD-001-plan-base/plan-d-memoria-v3code.md#d8) · [H·H.9](./SDD-001-plan-base/plan-h-motor-pruebas.md#h9) · [A·A.6](./SDD-001-plan-base/plan-a-chat-codex.md#a6)

## 1 · KV-cache y compresión — hallazgos que se vuelven KNOBS

| Hallazgo | Knob de configuración | Default |
|---|---|---|
| DeepSeek cachea prefijos idénticos desde token 0 (bloques de 64 tokens; hit fiable ≥1024 tokens); hit ≈ **1/50 del precio** del miss | `prefijo_estable` on/off + alerta si el hash del system prompt cambia | ON |
| TTL best-effort (horas–días sin garantía) | `warm_up` al abrir proyecto | ON |
| **KIVI**: keys per-channel + values per-token, ventana residual FP16 de ≤128 tokens crítica | Perfil cuantización KV: `fp16 / fp8-calibrado / int4 / int2-agresivo` + `ventana_residual=128` | fp8 |
| Cuantizar NO rompe prefix caching (vLLM hashea por token IDs); cambiar dtype enfría la caché | Aviso UI al cambiar perfil: "caché fría, medir tras warm-up" | — |
| **H2O**: retener ~20-25% presupuesto (heavy-hitters + recientes) | `eviccion`: `query-aware (Quest) / sinks+recientes (StreamingLLM sink=4) / H2O budget%` | query-aware |
| **LLMLingua-2**: 2×–5× compresión mantiene ~90% calidad; force_digits para dominios numéricos; chunk ≤512 tokens | Nivel compresión tramo medio: `ninguna / ligera(2×) / agresiva(5×)` + toggle reservar dígitos | ligera |
| Compresor consume latencia: solo paga si prompt >2K tokens | Umbral mínimo de aplicación | 2000 tokens |
| MemGPT: warning al **70%** de ventana, flush al 100% expulsando ~50% | Umbrales `aviso_pct=70`, `flush_pct=100`, `expulsar_pct=50` | tal cual |
| Claude: breakpoints de caché, TTL 5min/1h; OpenAI auto ≥1024; Gemini explícito $/hora | Estrategia por proveedor detectada automáticamente; knobs avanzados ocultos tras "modo experto" | auto |

## 2 · Jerarquía de configuración — patrones de productos líderes

| Producto | Mecanismo | Lección adoptada |
|---|---|---|
| Claude Code | Managed → CLI → Local → Project → User; arrays de permisos se FUSIONAN (union), escalares se reemplazan, claves deny bloquean | Merge declarado POR TIPO de campo en la UI |
| Codex | 6 capas; profiles = overlays de diferencias; ciertas claves PROHIBIDAS a nivel repo (warn) | Validación que marca "no configurable en este nivel" |
| Cursor | Team Rules *enforced* ganan siempre; activación condicional por globs | Políticas con candado 🔒 arriba que abajo no pueden tocar |
| Git | system→global→local→worktree; `--show-origin --show-scope` | **Vista de VALOR EFECTIVO con origen** ("definido en: Global") |
| VS Code | "Modified in Workspace" + Reset Setting por capa; objetos deep-merge, primitivos reemplazan | Indicador "modificado aquí/heredado" + reset que borra SOLO esa capa |
| Helm/Kustomize | defaults ricos en base, overrides mínimos; máx ~3 niveles debuggeables | Presupuesto: overrides mínimos por capa + vista diff renderizado |
| Devin/Replit/E2B | golden snapshot heredable; checkpoint=estado completo; sandbox es scratch | Respaldos versionados por rol; durable en BD, no en sandbox |

## 3 · Memorias — taxonomía y políticas (CoALA consolidado)

**Tipos** (configurables por separado): `working` (presupuesto tokens) · `episódica` (rungs/sesiones) · `semántica/largo-plazo` (hechos) · `relacional` (grafo entidades, bi-temporal estilo Zep: invalidar, nunca borrar) · `indexada` (FTS5/vector) · `procedimental` (skills/reglas versionadas)

**Operaciones completas obligatorias** (survey Du et al.): Consolidation · Indexing · Updating · Forgetting · Retrieval · Compression — si falta una, hay deuda.

**Políticas con knobs**:
- Escritura: `auto-extraída (async post-respuesta)` vs `explícita remember()` vs `cola pendiente con aprobación humana` (Cursor Memories pattern)
- Decay Ebbinghaus `S=S₀e^(−λΔt)` con λ POR TIPO (conversación 7-14d; hechos meses); refuerzo por acceso (spacing effect); **decay afecta RANKING, no borrado** (GC real solo <0.01, archivar originales)
- Scoring Generative Agents: `relevance×3 + importance×2 + recency×0.5` (pesos tuneables)
- Reflexión por UMBRAL de importancia acumulada (~150), no cron → insights de nivel superior escritos de vuelta como memorias scorable
- Consolidación: clustering → umbral 5-10 fragmentos → resumen archive-then-insert (idempotente)
- Scoping SIEMPRE namespaced: global/proyecto/agente/subagente — sin esto hay leakage cross-tenant

## 4 · Respaldos de agentes

- Snapshot frequency/retention POR ROL (estilo Claude Code: conserva últimos 5 automáticos)
- Checkpoint = estado COMPLETO (archivos+memoria), pero separar "estado ejecutable" de "memoria conversacional"
- ⚠️ Anti-patrón documentado (ACRFence): restaurar checkpoint puede RE-EJECUTAR acciones externas irreversibles → todo restore exige replay-or-fork explícito con registro de efectos ya ocurridos
