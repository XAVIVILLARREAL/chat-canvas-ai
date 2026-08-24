# SDD-009 — Debate adversarial de decisiones clave (4 sub-agentes abogados del diablo)

> Fecha: 2026-08-24 · Estado: Propuesto · Método: cada decisión arquitectónica mayor fue desafiada por un sub-agente investigador construyendo el caso EN CONTRA con datos 2026. Este documento registra el debate completo, ventajas/desventajas y los VEREDICTOS integrados al roadmap.

---

## DEBATE 1 — Cliente: Desktop Tauri-first vs Web-first 🔄 CAMBIO RECOMENDADO

### El caso contra desktop-first (verificado, demoledor)
| Hallazgo | Dato |
|---|---|
| El mercado de "IA que construye software" votó URL | Lovable ~$400-500M ARR en 18 meses · Replit $525M ARR · Bolt $40M en 6 meses — **ninguno exige instalación** |
| Cursor (desktop) ganó por razones que NO aplican aquí | Indexa filesystem local, corre debuggers/Docker local, protege código en la máquina — **con agentes en servidor central, nuestro cliente no ejecuta nada** |
| Costos ocultos Tauri ×3 OS | macOS: notarización obligatoria (Sequoia eliminó el bypass), cert $99/año, ~2 días setup · Windows: SmartScreen ya NO se bypassea con EV; sin reputación = **62% completación de instalación** (vs 88-94%) · Linux: WebKitGTK mantenedor: "no vemos futuro" |
| Updates = deuda estructural | 3 pipelines firma/update perpetuos vs deploy instantáneo web |

### El contra-punto honesto (steelman)
Si el diferenciador fuera *"tus agentes editan TU codebase local sin subir nada"* — competencia frontal de Cursor — desktop sí sería el producto. Pero eso contradice SDD-008 (agentes centralizados): el desktop sería un shell vacío con triple costo.

### ✅ VEREDICTO: WEB-FIRST, Tauri pasa a opcional post-tracción
- El crate `tauri-shell` del [ADR-005](../ADRs/ADR-005-modelo-despliegue-dual.md) **NO se elimina** — se re-prioriza: se construye **después**, solo si hay demanda demostrada de empaquetado
- El **gateway axum sirve la WEB APP directamente** (React compartido — cero desperdicio del trabajo hecho)
- La privacidad/Ollama se vende como **deploy on-prem del SERVIDOR** (Docker), no como app de escritorio — *local-first ≠ desktop-client*
- Salvaguardas baratas día 1: protocolo cliente↔agente agnóstico (WS/SSE portable) + roadmap de **CLI ligero** para repos locales del power-user (patrón Devin/Claude Code)
- ⚠️ **REQUIERE RATIFICACIÓN DEL USUARIO** (afecta identidad del producto)

---

## DEBATE 2 — Sync: implementación propia vs comprar (PowerOpen/ElectricSQL/Zero)

| Opción | Pros | Contras |
|---|---|---|
| **Propio (delta-sync+outbox)** | Encaja nuestro patrón simple (agentes centrales, dispositivos consumidores) · código mínimo · control total | Los bugs sutiles (duplicados/reorden/skew) ya están depurados en productos existentes · ventana cierra cuando DOS dispositivos editan la misma fila |
| **PowerSync Open Edition** | **$0 self-hosted**, Postgres→SQLite battle-tested, upload hacia NUESTRA API respetando RLS | Integración inicial, dependencia externa |
| ElectricSQL / Zero | Read-path reactivo bueno | Writes fuera de scope / React-centric sin móvil maduro |

### ✅ VEREDICTO: mantener PROPIO para v0.x (nuestro patrón es genuinamente simple) + **trigger definido para adoptar PowerSync Open Edition** si aparecen conflictos complejos multi-editor (>10% sesiones con edición concurrente de misma entidad o >2 dispositivos escribiendo activamente). Documentado en [PLAN L](./SDD-001-plan-base/plan-l-sync-cowork.md).

---

## DEBATE 3 — Runtime de agentes: Reasonix-core vs Loop-propio vs Híbrido progresivo

### Datos verificados que cambian el análisis
- Reasonix es **MIT open source** (`esengine/DeepSeek-Reasonix`) → **SÍ bundlable en SaaS comercial** (riesgo licencia BAJO)
- Pero está acoplado a DeepSeek **por diseño** (cache-first architecture) y en **reescritura TS→Go en vuelo**
- Su superpoder medido: **99.82% cache-hit sobre 435M tokens ⇒ $12 en vez de $61 (5×)** — replicarlo en loop propio requiere SU disciplina arquitectónica entera (no es un toggle)
- Loop propio: el `while` toma días; **el HARNESS productivo toma 2-6 meses** (aider midió 9× más errores de edición sin su pipeline de diffs)
- ⚠️ Seguridad: SymJack comprometió a TODOS los grandes CLIs en 2026 → sandbox kernel-level necesario SIN IMPORTAR el runtime

### ✅ VEREDICTO: HÍBRIDO PROGRESIVO por etapas (la decisión original estaba incompleta, no incorrecta)
| Etapa | Runtime | Condiciones no negociables desde el día 1 |
|---|---|---|
| MVP base | **Reasonix-core** | (1) Cada sesión en contenedor efímero ([H·H.9](./SDD-001-plan-base/plan-h-motor-pruebas.md#h9) ContainerDriver) — su sandbox NO es kernel-level y toda la categoría ha sido comprometida · (2) Pin estricto de versión + CI prueba upgrades antes de adoptar · (3) Transcripts JSONL persistidos desde el día 1 (= dataset de migración futuro + auditoría) |
| Crecimiento | Híbrido: piezas periféricas propias (explore/review sobre API directa con caching disciplinado — mayor volumen, menor riesgo) | Trait AgentProvider absorbe el "impuesto de traducción" temprano (~15-25%) |
| Escala | **OwnLoopProvider principal** (base OSS: mini-swe-agent + OpenHands SDK + estrategias aider) + Reasonix como fallback fail-open | Solo si se replica la disciplina de prefix-cache Y se opera sandbox por contenedor |

Disparadores de migración definidos: volumen tokens justifique 1 FTE en el loop · necesidades UX que sidecars no cubran · primer incidente de seguridad no contenido · señal de churn (breaking release/paid-tier).

---

## DEBATE 4 — (integrado de rondas anteriores) K8s, memorias, registro proveedores
Ya arbitrados en [SDD-006](./SDD-006-investigacion-cache-memoria.md)/[008](./SDD-008-analisis-cliente-servidor-k8s.md): Compose→k3s→K8s endurecido · tenaxum RLS · Everruns-pattern · models.dev registry. Sin cambios.

## Resumen de acciones tomadas en el plan base
1. README maestro: prereq Etapa 1 actualizado — **web-shell servida por el gateway primero; tauri-shell diferido** (pendiente ratificación usuario)
2. [PLAN L](./SDD-001-plan-base/plan-l-sync-cowork.md): trigger PowerSync Open Edition documentado
3. [PLAN C](./SDD-001-plan-base/plan-c-reasonix-deepseek.md): condiciones no-negociables del runtime + disparadores de migración OwnLoop
