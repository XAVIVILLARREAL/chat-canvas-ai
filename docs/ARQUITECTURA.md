# ARQUITECTURA — Flutter + dartssh2 + xterm.dart + hub Tailscale

> Arquitectura del terminal SSH multiplataforma con celular como hub de sincronización.

## Visión general

```
┌─────────────────────────── CELULAR (hub) ───────────────────────────┐
│ Flutter app                                                            │
│  ├─ UI (Material 3)                                                    │
│  ├─ Terminal: xterm.dart + dartssh2 → SSH/SFTP a servidores            │
│  ├─ Canva: nodos SSH + notas + (agentes IA Etapa 2)                    │
│  ├─ DB local: SQLite (drift) — fuente de verdad del hub                │
│  └─ Hub server: dart:io (HttpServer + WebSocket) en puerto local      │
│          │  Tailscale (100.x.y.z)                                      │
└──────────┼───────────────────────────────────────────────────────────┘
           │  WebSocket/HTTP (sync)
┌──────────┴─────────── LAPTOP / OTROS ────────────────────────────────┐
│ Flutter app (misma)                                                   │
│  ├─ UI + Terminal + Canva                                             │
│  ├─ DB local réplica (SQLite)                                         │
│  └─ Sync client: conecta al hub del celular, replica y suscribe       │
└───────────────────────────────────────────────────────────────────────┘
```

## Capas

### 1. Capa SSH (dartssh2)

- `SSHClient` por conexión: autenticación (password / llaves), sesiones de shell y ejecución.
- Soporte de **túneles** (local/remoto/dinámico/SOCKS5) y **jump servers**.
- `SFTPClient` para gestión de archivos remotos.
- Desacoplado en un servicio `SshService` (se inyecta en UI y en el hub).

### 2. Capa terminal (xterm.dart)

- `Terminal` + `TerminalView`: emulador 60fps.
- Puente: `dartssh2` shell `stdin/stdout/stderr` → `xterm.dart` (input/output).
- Soporte de resize (cambiar tamaño de ventana → resize remoto).

### 3. Capa canva

- `InteractiveViewer` (zoom/pan) + nodos custom (host SSH, nota, contenedor).
- Estado en un store (`Riverpod`): lista de nodos, posición, conexiones.
- Persistencia en SQLite.

### 4. Capa datos (SQLite / drift)

- Tablas: `hosts`, `llaves`, `canva_nodos`, `canva_edges`, `sesiones`, `notas`.
- Modelo con versionado (timestamp + versión por registro) para sync.

### 5. Capa hub (servidor embebido, celular)

- `dart:io HttpServer` + WebSocket en puerto local (ej. 8170).
- Endpoints:
  - `GET /api/snapshot` → estado completo (canvas, hosts, llaves, sesiones).
  - `POST /api/apply` → aplicar cambios recibidos.
  - `WS /ws` → push de cambios en tiempo real + suscripción.
- **Auth**: token de emparejamiento (código corto) + solo escucha en la interfaz Tailscale.
- El hub también puede **exponer SFTP/terminal remoto** si se quiere (futuro).

### 6. Capa sync (clientes)

- En cada dispositivo no-hub: `SyncClient` se conecta al hub (Tailscale IP), descarga snapshot, replica en SQLite local y suscribe a cambios.
- En el hub: cada cambio local se propaga a clientes conectados.
- Resolución de conflictos: **last-write-wins por registro** (versión + timestamp). Suficiente para datos pequeños de uso personal.

## Flujo de conexión SSH desde cualquier dispositivo

```
Laptop (Flutter) ──Terminal local──► servidor SSH remoto
        │
        └── Sync ──► Celular hub (guarda sesión/host, replica al resto)
```

La conexión SSH es **directa** del dispositivo al servidor; el hub solo sincroniza **config y estado**, no el tráfico SSH (eficiente y privado).

## Seguridad

- Sync solo sobre Tailscale (cifrado punto a punto, red privada).
- Token de emparejamiento en el hub; rechazo de clientes sin token.
- Llaves SSH almacenadas cifradas localmente (flutter_secure_storage).
- El hub escucha solo en la interfaz Tailscale (no en Wi-Fi público).

## Etapa 2 (agentes IA) — extensión

- Los nodos de agente (opencode) se conectan al mismo canva y DB.
- El hub puede lanzar/controlar agentes en el servidor (reutilizando lo de `docs/legacy/`).
- No cambia la arquitectura base: es un tipo de nodo + un servicio más.

## Tecnología clave verificada (2026-08)

| Librería | Versión | Estado |
|---|---|---|
| Flutter | 3.x | multiplataforma |
| dartssh2 | 2.22.5 | SSH/SFTP completo, MIT |
| xterm.dart | 4.0 | terminal 60fps, MIT |
| drift (SQLite) | 2.x | ORM tipado |
| Tailscale | SDK | red privada p2p |
