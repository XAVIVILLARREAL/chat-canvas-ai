# SDD — Fase 1.4: El celular como hub de sincronización (Tailscale)

> **Proyecto:** empresa_dev — Fase 1.4 del ROADMAP.
> **Fecha:** 2026-08. **Estado:** En implementación.

## Objetivo

La **funcionalidad única** del producto: el celular corre un **servidor embebido** dentro de la app Flutter; los demás dispositivos (laptop, tablet) se sincronizan contra él **vía Tailscale**. Canvas, hosts, llaves y sesiones viajan entre dispositivos sin servidor central ni nube.

## Alcance (este slice)

- **HubServer**: servidor `dart:io` embebido (HTTP + WebSocket) en el celular.
  - `GET /api/snapshot` → estado completo (hosts + canva + sesiones).
  - `POST /api/apply` → aplicar cambios recibidos.
  - `WS /ws` → push de cambios en tiempo real + suscripción.
  - **Auth por token**: rechazar clientes sin token válido.
  - Escucha solo en la interfaz Tailscale (bind a la IP 100.x.y.z).
- **SyncClient**: en cada dispositivo no-hub.
  - Conecta al hub (URL con IP Tailscale), descarga snapshot, replica local, suscribe a WS.
  - Envía `apply` de los cambios locales.
- **Modelo de datos sincronizable**: hosts + canva + sesiones en JSON con `version`.
- **Integración en la app**: pantalla de "Hub" donde eliges modo hub o cliente, token, y estado del sync.

## Fuera de alcance

- Resolución de conflictos avanzada (last-write-wins por registro basta para uso personal).
- Túneles SSH remotos a través del hub.
- Cifrado de llaves en reposo (flutter_secure_storage, se integra luego).

## Flujo (caso feliz)

1. En el celular, abres "Hub" → activas **modo hub**. Se genera un **token** y el servidor escucha en la IP Tailscale (`100.x.y.z:8170`).
2. En la laptop, abres "Hub" → **modo cliente**, pegas `100.x.y.z:8170` + token.
3. El cliente descarga el snapshot (hosts, canva, sesiones) y lo replica localmente.
4. Cuando el celular edita el canva → push por WS → la laptop se actualiza al instante.
5. Cuando la laptop agrega un host → `apply` → el celular (y otros clientes) lo reciben.
6. Sin internet, cada dispositivo sigue trabajando local (offline-first); al reconectar, se sincroniza.

### Casos límite

- Token inválido → el hub rechaza con 401.
- Hub apagado → el cliente muestra "sin conexión al hub" y trabaja local.
- Conflicto (mismo registro editado en 2 lados) → gana el de mayor `version`/timestamp.

## Contratos

### Datos sincronizables

```dart
class SyncSnapshot {
  int version;                 // incrementa en cada cambio
  List<HostRecord> hosts;      // hosts (sin secretos en claro en este slice)
  List<CanvaNodeRecord> nodes;
  List<CanvaEdgeRecord> edges;
  List<SessionRecord> sessions;
}
```

### HubServer (dart:io)

```dart
class HubServer {
  Future<void> start({required String token, required String bindIp, required int port});
  void updateSnapshot(SyncSnapshot snap);   // el hub propaga a clientes
  Stream<SyncSnapshot> get changes;          // cambios locales a propagar
}
```

### SyncClient

```dart
class SyncClient {
  Future<bool> connect(String url, String token);
  Future<SyncSnapshot?> fetchSnapshot();
  Future<void> apply(SyncSnapshot snap);
  Stream<SyncSnapshot> get remoteChanges;
}
```

## Datos

- Persistencia local del snapshot en cada dispositivo: JSON (`sync_state.json`), igual que el canva.
- El hub es la **autoridad**: los cambios del hub se propagan; los del cliente se envían con `apply` y versionan.

## Errores

| Error | Manejo |
|---|---|
| Token inválido (401) | UI "token incorrecto" |
| Hub no alcanzable | cliente en modo offline, badge "sin sync" |
| Version conflictiva | last-write-wins por registro (el hub decide) |

## Tests

- **Unit (serialización):** SyncSnapshot roundtrip JSON.
- **Integración local (sin Tailscale):** levantar HubServer en `127.0.0.1`, conectar SyncClient, verificar snapshot/apply/WS push.
  - `HubServer` en puerto efímero → `SyncClient.connect` con token OK.
  - `apply` de un host nuevo → el hub lo incluye en el próximo snapshot.
  - WS push: cambiar snapshot en el hub → el cliente recibe el cambio.

## Verificación de UI (gate Fase 1.4)

1. Celular: activar modo hub → muestra IP Tailscale + token.
2. Laptop: modo cliente → conectar con IP + token → descarga snapshot.
3. Editar canva en el celular → aparece en la laptop (WS push).
4. Agregar host en la laptop → aparece en el celular (apply).
5. Desconectar la laptop → funciona local; reconectar → sincroniza.
6. Capturas/evidencia de cada paso.

## Definition of Done

- [ ] `flutter analyze` 0 issues.
- [ ] Tests unitarios + integración hub/sync verdes.
- [ ] UI hub (modo hub/cliente, token, estado).
- [ ] Gate 1.4 documentado en ROADMAP.
