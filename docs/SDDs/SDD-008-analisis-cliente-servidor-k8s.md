# SDD-008 — Análisis profundo: Cliente-Servidor autónomo + Escalado (Linux/Kubernetes)

> Fecha: 2026-08-23 · Estado: Propuesto · Método: 3 investigaciones paralelas con sub-agentes (K8s para agentes IA · sync multi-dispositivo · arquitectura servidor Rust)
> Evoluciona [ADR-005](../ADRs/ADR-005-modelo-despliegue-dual.md): el modo SERVIDOR pasa de opcional a **ciudadano de primera clase** — los clientes (desktop/móvil/web) son ventanas hacia el trabajo que vive en el servidor central.

## La decisión central

**El trabajo persiste en el SERVIDOR (Linux/docker/k8s); los dispositivos son ventanas + controles.**

```
 💻 Desktop    📱 Móvil    🌐 Web          ← ventanas + controles (delgados)
      └────────────┬───────────────┘
            API + SSE/WS (+push para despertar)
                   │
        ┌──────────▼───────────────────────┐
        │ GATEWAY axum (stateless, escala) │  auth · rate-limit · RLS
        ├──────────────────────────────────┤
        │ WORKERS de agentes (colas)       │  sesiones durables, reanudables
        ├──────────────────────────────────┤
        │ PostgreSQL (fuente de verdad)+RLS│  + MinIO artefactos · Valkey
        ├──────────────────────────────────┤
        │ SANDBOXES por agente             │  Docker hoy → gVisor/Kata mañana
        └──────────────────────────────────┘
```

Los dispositivos envían COMANDOS (optimistas, outbox duradero) y reciben STREAMS (fan-out por sesión). Si el dispositivo muere, nada se pierde: el agente sigue en el servidor.

## Arquitectura del servidor Rust (patrón Everruns, open source — copiar casi tal cual)

| Componente | Decisión | Crates |
|---|---|---|
| Gateway HTTP | axum + tower stack (Trace/CORS/Timeout/RequestId), WS+SSE simultáneos, graceful shutdown con CancellationToken para SSE | `axum`, `tower-http`, `tokio-util` |
| Workers de agentes | binario separado stateless SIN credenciales DB: reclama tareas con `FOR UPDATE SKIP LOCKED` + heartbeat (reclaim 30s) | comparte crate `core` |
| Cola durable + workflows largos | Postgres puro: `underway` o `tensorzero/durable` (`ctx.step()`, `await_event()` ideal para aprobaciones human-in-the-loop); jobs utilitarios con `apalis` | — |
| Multi-tenancy | **Postgres shared-schema + RLS** con crate `tenaxum`: setea `app.tenant_id` fail-closed por conexión, test CI de aislamiento por tabla; PgBouncer exige `SET LOCAL` en transacción | `tenaxum`, `sqlx` |
| Fan-out multi-dispositivo | `broadcast::channel` POR SESIÓN (lazy + GC): varios dispositivos ven la misma generación en vivo; deltas efímeros en el bus, eventos terminales persistentes; reconexión con `?since_id=N` repone desde PG | tokio |
| Streaming LLM | capa fina sobre OpenAI-compat: deltas tagged-enum + accumulator; dropear el stream aborta la request upstream (no quemar tokens) | diseño `rai-sdk` |
| Auth | passkeys `webauthn-rs` + sesión opaca por DISPOSITIVO (hash en DB, revocable individual estilo WhatsApp Web) + access token ES256 5min + refresh rotativo con detección de reuso | `webauthn-rs`, `jsonwebtoken` |
| Observabilidad | tracing→OTLP correlacionado (`.instrument()` en spawns); métricas SIN tenant_id como label (explotaría storage) — costos por tenant van a tablas de agregación | `tracing`, `metrics` |
| Auditoría | middleware append-only tras auth+tenant, sink plugable, REVOKE UPDATE/DELETE en tabla | ya existe modelo ERP |
| Transporte interno | PG LISTEN/NOTIFY como "nudge" sobre cola SKIP LOCKED (**conexión dedicada no-pooled** — gotcha crítico); NATS JetStream solo si se mide presión | `sqlx::PgListener` |

## Sync multi-dispositivo sin fricción (patrón Linear: "local-feeling, server-authoritative")

1. **Estado autoritativo en servidor** — NO réplica bidireccional ni CRDTs generales (innecesarios cuando los agentes corren centrales). El dispositivo = view + command sender
2. **Delta-sync con cursor**: cada dispositivo guarda su último `sync_id`; al reconectar pide SOLO el delta `/changes?since=` — nunca refetch completo ni polling
3. **Comandos optimistas con OUTBOX duradero**: acciones offline se persisten localmente con UUID; servidor idempotente por UUID (dedupe); ACK al procesar
4. **Sesión IA continua entre dispositivos**: prompt enviado desde A, agente corre en servidor, TODOS los dispositivos suscritos reciben el stream; abrir móvil a mitad = "replay history + attach live"
5. **Qué sincronizar**: mensajes/metadata/memoria/estado de tareas del agente ✓ — contexto cosmético del dispositivo (scroll, borradores) ✗ queda local (lección ChatGPT/Claude)
6. **Conflictos invisibles**: LWW por CAMPO silencioso; "keep both" + aviso específico solo cuando destruye trabajo authored; deletes = tombstones
7. **Push solo para DESPERTAR** (payload mínimo → delta-sync al abrir): dispatcher propio → APNs (iOS única vía) / FCM o ntfy-UnifiedPush (Android) / VAPID (web-PWA)

## Auth sin fricción

Passkeys sincronizadas como primaria (cubre 90% de nuevos dispositivos gratis vía iCloud/Google) · QR pairing para vincular dispositivos propios (token TTL<2min single-use + confirmación explícita en origen) · magic link/email OTP solo recovery · lista de dispositivos revocable en settings · frase contextual antes del QR ("Usa tu teléfono aquí") — reduce tickets a cero

## Escalado: camino por fases (consenso 2026: K8s NO desde día 1 — pero plataforma de agentes ES el caso excepcional parcial)

| Fase | Cuándo | Stack | Clave |
|---|---|---|---|
| **0. Hoy** | Desarrollo/PDF validation | Docker Compose + sandbox driver abstracto (LocalDriver) | Toda sesión de agente = unidad aislable con identidad/timeout/storage propios (el fallo de OpenHands V0 fue compartir procesos); imágenes de sandbox separadas del código del agente (inyección runtime estilo Cursor) |
| **1. Tracción** | >50 sesiones concurrentes o compliance BYOC | **k3s** (1-3 nodos) + CRD **`agent-sandbox`** (SIG-Apps Google: pod singleton stateful, warm pools, hibernación, scale-to-zero KEDA) + **gVisor RuntimeClass** + CloudNativePG + KEDA | Warm pools pre-calentados (asignación en ms); tiering: interactive→warm pool, background→suspend/resume, batch→oversubscription |
| **2. Multi-tenant serio** | >5-10 tenants externos / código no confiable en prod | namespaces endurecidos (ResourceQuota+LimitRange+NetworkPolicy default-deny+PSA restricted) → **Kata/Firecracker microVMs**, Karpenter, OpenCost chargeback por tenant (atribución pay-for-results) | Aislamiento de kernel garantizado; vCluster/clúster-por-tenant si hace falta |

**Anti-trampas documentadas**: no service mesh hasta 10+ servicios · no Prometheus self-managed al inicio · KEDA con `activationThreshold`+`cooldownPeriod` y workers-largos como ScaledJob (no matar trabajos a medio correr) · PVC individual por sandbox + objetos en S3/MinIO (evitar RWX salvo necesidad real) · SQLite distribuido vía Litestream→S3 si algún día aplica.

## Referencias open source para portar patrones

`moltis` (workspace 59 crates Rust, mejor modularización) · `Everruns` (control-plane/worker/PG/NATS/Valkey — plano casi exacto) · `ryvos` (ReAct loop + checkpoint/resume) · `octos` (UI Protocol JSON-RPC versionado desacoplando shell/server) · reverse-linear-sync-engine (endosado CTO Linear)

## Impacto en el roadmap base

- Prerequisito Etapa 1 (refactor Cargo) se amplía: crear también el binario **`worker`** junto a `server` desde el día 1 (patrón Everruns) — barato ahora, crítico después
- Etapa 12 (PLAN L) es la consumidora natural de todo esto (ya actualizada con L.4 push + delta-sync)
- Etapa 14 (N) usa sandboxes server-side ([ADR-005·D4](../ADRs/ADR-005-modelo-despliegue-dual.md)) — la escalera Fase 0→1→2 define cuándo
- Estimación global sin cambio significativo: el patrón Everruns es simple; K8s queda explícitamente FUERA de la base (Fase 1+)
