# SDD-125 — Etapa 8.4: SSH proxy desde el hub (la llave nunca sale del hub)

> **Proyecto:** empresa_dev — Etapa 8.4 del SUPER_PLAN (cola de innovación).
> **Fecha:** 2026-08-12. **Estado: ✅ 8.4.1–8.4.3 completados** (10 unit + 3 relay localhost). Indicador canva (directo vs proxy) y gate Tailscale real pendientes.

## Objetivo

Si una laptop se compromete, las llaves guardadas en ella se roban. Con el
**SSH proxy**, las llaves viven SOLO en el hub (celular/pve); la laptop pide al
hub abrir la conexión con **tokens efímeros** y solo ve el flujo del terminal,
nunca la llave. Modo por defecto sigue siendo conexión directa (Etapa 1).

Gate SUPER_PLAN 8.4: *"laptop sin llaves conecta a un host vía proxy; la llave
jamás aparece en la laptop"*.

## Arquitectura

- **`lib/services/ssh_proxy.dart`** (app):
  - `ProxyTokenStore`: emite/valida tokens efímeros por host (`Random.secure`,
    TTL corto, no reutilizables).
  - `SshForward`: canal bidireccional de texto sobre una `SSHSession` (output =
    stdout+stderr; `write` → stdin; `close`). NO transporta la llave.
  - `SshProxyService`: `openForward(hostId, token)` → valida token + abre la
    shell del host (el `SshHost` con `keyPem` vive AQUÍ, en el hub).
- **`lib/services/hub_server.dart`**: relay WS `ssh` (open/data/write/close) con
  `SshProxyService` inyectado; por cliente mantiene los forwards abiertos.
- **`lib/services/ssh_proxy_client.dart`**: cliente que conecta al hub (auth con
  el token del hub), pide `open(hostId, proxyToken)` y relaya texto.

## Slices (TDD)

### 8.4.1 — `ssh_proxy.dart` (unit, fake SSHSession)

- Token: `issue(hostId)` → valor aleatorio + expiración; `validate` ok para el
  host correcto; falla para otro host; falla tras expirar (TTL corto/negativo);
  token no emitido falla.
- `SshForward`: relays I/O (escribo en el fake session → output emite; `write`
  llega al fake session); `close` cierra.
- `openForward`: token válido → forward; token inválido/expirado o host
  desconocido → lanza. La llave nunca está en el forward (solo texto).

### 8.4.2 — Relay WS en `hub_server.dart` (test localhost real, `test()` plano)

- Mensajes: `{type:'ssh', action:'open|write|close|data}`.
- Hub con `SshProxyService` fake → cliente WS real (localhost) abre con token →
  recibe `opened` y datos; `write` llega al fake; token inválido → `error`.
- Cerrar el WS cierra los forwards del cliente.

### 8.4.3 — `ssh_proxy_client.dart` (test localhost contra el hub)

- `connect` (auth hub) → `open(hostId, proxyToken)` → `output` emite lo que el
  forward recibe; `write` lo envía; `close`.

## Gate

- [x] Token efímero válido abre el forward; inválido/expirado → rechazado.
- [x] El forward solo transporta texto (la llave nunca viaja) — garantizado por
  diseño y verificado por test.
- [x] `flutter analyze` 0 + suite completa verde (181 app).
- [ ] Manual (gate real): laptop sin llaves conecta vía hub + Tailscale.

## Notas de cierre

- `SshForward.forSession` (público) para construir sobre una sesión ya abierta
  (tests) o desde el servicio.
- El relay usa mensajes `{type:'ssh', action: open|write|close|data}` sobre el
  WS del hub ya existente; la auth del hub (Bearer) es independiente del token
  efímero del proxy (dos niveles).
- `hub._server` no se accede desde fuera; los tests usan `hub.port`.
