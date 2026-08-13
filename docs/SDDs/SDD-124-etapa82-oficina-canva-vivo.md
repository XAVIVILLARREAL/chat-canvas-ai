# SDD-124 — Etapa 8.2: Oficina — el canva como vista viva del estado de los agentes

> **Proyecto:** empresa_dev — Etapa 8.2 del SUPER_PLAN (cola de innovación).
> **Fecha:** 2026-08-12. **Estado: ✅ 8.2.1 + 8.2.2 completados** (9 unit agent_core + 2 widget). 8.2.3 (bridge hub→Python) pendiente del server Fase 1.

## Objetivo

El canva pasa de mapa de infraestructura a **espejo de la oficina en tiempo
real** (visión empresa autónoma): cada agente-empleado es un nodo cuyo estado
(`working ⚡ / blocked 🚧 / waiting_approval ⏳ / done ✅`) se anima en vivo.
Según ADR-004, la oficina es **una instancia de `CanvaView`** (mismo motor), con
`nodeBuilder` que pinta el glow por estado.

Gate SUPER_PLAN 8.2: *"un nodo-agente cambia de estado en la empresa y el canva
lo anima en vivo"*.

## Arquitectura

- **`packages/agent_core`** (Dart puro): `OfficeState` (idle/working/blocked/
  waitingApproval/done/failed) + `AgentRuntimeStatus` (ChangeNotifier puro Dart:
  agentId, label/rol, estado, `update`) + `StatusNotifier<T>` (listenables
  mínimos sin Flutter) + `OfficeStatusSource` (abstracto: `statuses` notificable
  + `start/stop`).
- **App**: `services/office_service.dart` con `SimulatedOffice` (fuente de
  estados por temporizador con una secuencia guionada → demo/testeable sin el
  backend Python) y `screens/office_screen.dart` = `CanvaView` con nodos-agente
  cuyo card hace glow por estado (cyan=working, rojo=blocked, ámbar=
  waiting_approval, verde=done) + aristas de dependencia. Entrada desde el menú
  Añadir del canva.
- **Bridge real (seguimiento):** WebSocket hub → servicio Python
  (`empresa_autonoma`, Fase 1) cuando exista `server.py`; `OfficeStatusSource`
  es el punto de inyección.

## Slices (TDD)

### 8.2.1 — `agent_core`: modelo de estado de oficina (unit)

- `OfficeState` + `AgentRuntimeStatus` (cambios de estado, transición
  registrada) + `StatusNotifier<T>` (listeners, set ignora iguales, dispose).
- `OfficeStatusSource` abstracto (contrato para la fuente real/simulada).
- Tests: transiciones válidas, notificación a listeners, statuses por id.

### 8.2.2 — App: `SimulatedOffice` + `OfficeScreen` (widget)

- `SimulatedOffice`: temporizador que recorre una secuencia guionada de estados
  por agente (ej. dev → working → blocked → working → done); observable vía
  `StatusNotifier<Map<String, AgentRuntimeStatus>>`.
- `OfficeScreen`: `CanvaView(nodes: agentes, nodeBuilder: card con glow por
  estado + label de estado, edges: dependencias)`; escucha el notifier y
  re-renderiza.
- Tests widget: estado cambia (via `SimulatedOffice.step()`) → el nodo muestra
  el label/glow del estado nuevo; arista visible; 2 agentes en paralelo.

### 8.2.3 — Bridge real hub→Python (seguimiento, NO en este slice)

- `WebSocketOfficeSource` leyendo el estado del grafo por thread/empresa cuando
  exista `empresa_autonoma/server.py` (Fase 1). Aquí solo queda el contrato.

## Gate

- [x] Un agente pasa working→blocked→waiting_approval y el nodo del canva lo
  anima (verificado por widget test con la simulación).
- [x] `flutter analyze` 0 + suite completa verde (168 app + 9 agent_core).

## Notas de cierre

- `SimulatedOffice` vive en `agent_core` (Dart puro, `dart:async` Timer) →
  demo y tests sin el backend Python.
- `OfficeScreen` es una instancia de `CanvaView` (ADR-004): aporta solo el
  `nodeBuilder` (card con glow por estado) y las aristas de dependencia; el
  motor (LOD, clusters, hit-test) es el mismo que el canva.
- Los `AgentRuntimeStatus` se reconstruyen por build desde el notifier; las
  posiciones arrastradas persisten en un `Map` del estado.
