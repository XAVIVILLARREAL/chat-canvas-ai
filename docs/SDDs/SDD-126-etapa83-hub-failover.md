# SDD-126 — Etapa 8.3: Hub failover — elección con heartbeat + prioridad

> **Proyecto:** empresa_dev — Etapa 8.3 del SUPER_PLAN (cola de innovación).
> **Fecha:** 2026-08-12. **Estado: ✅ 8.3.1–8.3.2 completados** (9 unit/widget). Transporte Tailscale real + panel de estado pendientes.

## Objetivo

El sync depende de que el celular (hub) aguante; si está bajo de batería o en
reposo, el sync muere. **Hub elegible**: cuando el hub actual deja de latir
(timeout) o declara batería baja, otro nodo (el pve, siempre encendido, mayor
prioridad) toma el rol automáticamente; el celular vuelve a ser hub al cargar.
Privado (Tailscale), sin nube.

Gate SUPER_PLAN 8.3: *"bajar la batería del celular a <20% → el sync continúa
vía pve sin tocar la app"*.

## Arquitectura

- **`lib/services/hub_election.dart`** (app, lógica pura testeable):
  - `HubRole { idle, hub, standby, candidate }`.
  - `HubElection`: nodo con `nodeId` + `priority` (mayor = preferido). Recibe
    `now()` inyectado (reloj), `heartbeatInterval`, `hubTimeout`, umbral de
    batería. API:
    - `onHeartbeat(fromId, priority, lowBattery)` — actualiza `_lastHubBeat`;
      si el que late es de mayor prioridad estando sano, puede hacerse hub.
    - `tick()` — si soy `standby` y pasó el timeout sin heartbeat del hub →
      `candidate` → (ventana corta) → `hub`. Si soy `hub` y mi batería es baja →
      cedo (`standby`) para que el pve tome el rol.
    - `role`, `onRoleChange`.
  - **Lógica: batería baja → ceder; timeout → takeover; prioridad desempata.**
- **Transporte (seguimiento):** heartbeats por el hub/WS existente + Tailscale;
  política de batería desde el sistema. Aquí solo el contrato (métodos del
  election) + un `HubElectionService` que lo cablea con un temporizador.

## Slices (TDD)

### 8.3.1 — `HubElection` (unit, reloj fake)

- Heartbeat del hub mantiene `standby` (no hace takeover aunque pasen ticks).
- Timeout sin heartbeat → `candidate` → tras la ventana → `hub` (takeover).
- Prioridad: con 2 nodos standby y ambos timeouts, gana el de mayor prioridad.
- Batería baja en el hub → cede (`hub` → `standby`) y otro toma.
- Heartbeats viejos/desordenados se ignoran (monotónico).
- `onRoleChange` notifica cada transición.

### 8.3.2 — `HubElectionService` (unit)

- Temporizador real `Timer.periodic` que llama `tick()` y propaga heartbeats por
  un transport inyectable (contrato `ElectionTransport`); tests con fake clock +
  fake transport.

## Gate

- [x] Timeout → takeover; prioridad desempata; batería baja → cede (unit).
- [x] `flutter analyze` 0 + suite completa verde (190 app).
- [ ] Manual (gate real): celular <20% → pve toma el hub sin tocar la app (Tailscale).

## Notas de cierre

- `onHeartbeat` convierte `idle → standby` (recibir un latido te hace observador)
  y hace que un `candidate` de menor prioridad se aparte al oír a uno mayor.
- Un nodo `hub` que oye latir a otro (distinto nodeId) asume que perdió el rol.
- El `tick()` del `hub` se auto-latea (`_lastHubBeat = now`), así el takeover no
  se dispara a sí mismo tras promoverse.
