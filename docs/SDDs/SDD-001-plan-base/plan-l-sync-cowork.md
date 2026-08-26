# PLAN L — Etapa 12: Sync multi-device + Modo Co-Work

> [← Maestro](./README.md) · [← PLAN K](./plan-k-voz.md) · [PLAN M →](./plan-m-github.md)
> Depende de: base 1-5. ADR-003 (WebSocket, NO P2P) + concepto Co-Work con Yjs CRDT + **ADR-005 (Despliegue Dual)**: el modo servidor es lo que hace la continuidad real.

**Entregable:** continuar donde dejaste desde cualquier dispositivo sin fricción — y un segundo dispositivo puede VER (y luego editar con permiso) la sesión activa en vivo.

<a id="l1"></a>
### L.1 — SyncHub server (el puente)
- Hub WebSocket opcional self-hosted (binario Rust del crate `server` de [ADR-005](../../ADRs/ADR-005-modelo-despliegue-dual.md)): sincroniza sesiones, config y skills ([G](./plan-g-skills-lab.md)) por device-pairing con token QR efímero
- Conflictos: **LWW para config**, merge manual asistido para sesiones (ADR-003); todo cifrado en tránsito
- En modo servidor ([ADR-005·D4](../../ADRs/ADR-005-modelo-despliegue-dual.md)): los agentes corren EN el hub con sandboxes Docker y siguen trabajando aunque TODOS los dispositivos se desconecten
- **Pruebas:** Integration: 2 clientes mock → misma sesión converge; conflicto LWW resuelto documentado; agente sigue activo tras desconectar ambos clientes

<a id="l2"></a>
### L.2 — Cliente sync sin fricción
- Login al hub una sola vez por dispositivo; selección de QUÉ sincronizar (sesiones/config/skills); estado de última sync visible
- Resolución de conflictos con UI diff-and-choose; offline queue con flush automático al volver
- **Trigger de adopción PowerSync Open Edition ($0 self-hosted)**: si >10% sesiones con edición concurrente de misma entidad o >2 dispositivos escribiendo activamente — los bugs sutiles del sync propio ya están depurados ahí (debate SDD-009)
- Continuidad total combinada con lo que ya existe: tabs restauradas ([A·A.0](./plan-a-chat-codex.md#a0)), resume inteligente ([A·A.8](./plan-a-chat-codex.md#a8)), snapshots del entorno ([H·H.9](./plan-h-motor-pruebas.md#h9))
- **Delta-sync con cursor** (patrón Linear): cada dispositivo guarda su último `sync_id`; al reconectar pide SOLO `/changes?since=` — nunca refetch completo
- **Outbox duradero**: comandos offline persistidos localmente con UUID; servidor idempotente (dedupe); ACK al procesar
- **Pruebas:** E2E humano: crear en laptop → aparece en móvil → editar ambos → resolver eligiendo

<a id="l3"></a>
### L.3 — Co-Work en vivo *(tras feature-flag; puede moverse a post-v1)*
- Yjs CRDT sobre el mismo WS: dispositivo B ve el chat/canva de A en solo-lectura con indicador 👁️; v2: edición compartida con permisos por panel
- Latencia objetivo <100ms local
- **Pruebas:** Integration CRDT: dos docs convergen tras ediciones concurrentes. E2E: B refleja acciones de A

<a id="l4"></a>
### L.4 — Push dispatcher cross-platform (despertar sin drenar batería)
- Servicio propio que registra tokens por dispositivo/plataforma y enruta: **APNs** (iOS — única vía fiable) · FCM o ntfy-UnifiedPush (Android) · Web Push VAPID (web/PWA)
- Payload mínimo ("evento del agente") → al abrir dispara delta-sync; los DATOS viajan por el canal de sync, no por el push
- Respeta la política de interrupción [K·K.3](./plan-k-voz.md#k3)
- **Pruebas:** Integration dispatcher con mocks APNs/FCM/VAPID. E2E humano: agente termina en servidor → push llega al móvil → abrir muestra el delta correcto

## 🚪 GATE L (demo verificable)

Dos ventanas simulando dos dispositivos: sesión creada en "laptop" aparece en "celular" con historial completo; config editada en ambos → conflicto resuelto eligiendo; Co-Work: B ve en vivo mientras A chatea; desconecto AMBOS y el agente sigue trabajando en el servidor ([ADR-005](../../ADRs/ADR-005-modelo-despliegue-dual.md)). Video doble-pantalla + suites verdes.

---
[← Maestro](./README.md) · [← PLAN K](./plan-k-voz.md) · [PLAN M →](./plan-m-github.md)
