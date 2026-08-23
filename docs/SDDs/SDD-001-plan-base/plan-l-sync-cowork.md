# PLAN L — Etapa 12: Sync multi-device + Modo Co-Work

> [← Maestro](./README.md) · [← PLAN K](./plan-k-voz.md) · [PLAN M →](./plan-m-github.md)
> Depende de: base 1-5. ADR-003 (WebSocket, NO P2P) + concepto Co-Work con Yjs CRDT.

**Entregable:** continúas donde dejaste desde otro dispositivo; y un segundo dispositivo puede VER (y luego editar con permiso) la sesión activa en vivo.

| Fase | Contenido | Pruebas |
|---|---|---|
| L.1 **SyncHub server** | Hub WebSocket opcional self-hosted (binario Rust o `reasonix serve` como transporte si aplica): sincroniza sesiones, config y skills ([G](./plan-g-skills-lab.md)) por device-pairing con token; conflictos: LWW para config, merge manual asistido para sesiones (ADR-003); todo cifrado en tránsito | Integration: 2 clientes mock → misma sesión converge; conflicto LWW resuelto documentado |
| L.2 **Cliente sync** | En la app: login al hub, selección de qué sincronizar (sesiones/config/skills), estado de última sync, resolución de conflictos con UI diff-and-choose | E2E humano con hub local: crear en A → aparece en B → editar ambas → resolver conflicto eligiendo |
| L.3 **Co-Work en vivo** | Yjs CRDT sobre el mismo WS: dispositivo B ve el chat/canva de A en modo solo-lectura con indicador 👁️; v2: edición compartida con permisos granulares por panel. Latencia objetivo <100ms local | Integration CRDT: dos docs convergen tras ediciones concurrentes. E2E: B refleja acciones de A |

## 🚪 GATE L

Demo con dos ventanas simulando dos dispositivos: sesión creada en "laptop" aparece en "celular" con historial completo; edito config en ambos → conflicto resuelto eligiendo; Co-Work: el segundo ve en vivo mientras el primero chatea. Video doble-pantalla + suites verdes.

---
[← Maestro](./README.md) · [← PLAN K](./plan-k-voz.md) · [PLAN M →](./plan-m-github.md)
