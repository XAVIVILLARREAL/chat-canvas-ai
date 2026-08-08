# ADR-002 — El celular como hub de sincronización vía Tailscale

- **Estado:** Aceptado (2026-08)
- **Decisión:** El celular corre un **servidor embebido** (dart:io) dentro de la app Flutter; los demás dispositivos sincronizan contra él **vía Tailscale**.
- **Tags:** sync, hub, tailscale, privacidad

## Contexto

Queremos que canvas, hosts SSH, llaves y sesiones estén sincronizados entre todos los dispositivos del usuario, **sin servidor central ni nube de terceros**. El celular es el dispositivo que siempre está contigo.

## Decisión

- **Celular = hub**: la app Flutter corre un servidor HTTP + WebSocket embebido en un puerto local (ej. 8170).
- **Alcance global por Tailscale**: celular y dispositivos en el mismo tailnet → el celular es alcanzable en `http://100.x.y.z:<puerto>` desde cualquier parte (NAT-traversal, cifrado, sin abrir puertos).
- **Sync**: snapshot (GET) + apply (POST) + push en tiempo real (WebSocket). Last-write-wins por registro.
- **Auth**: token de emparejamiento; el hub escucha solo en la interfaz Tailscale.

## Consecuencias

**Positivas:**
- Sin servidor central, sin nube — privado por diseño.
- Tailscale ya lo usamos (pve en `100.101.69.79`) → infra conocida.
- La conexión SSH es directa del dispositivo al servidor; el hub solo sincroniza config/estado (eficiente).
- Dart soporta servidores embebidos nativamente (`dart:io`).

**Negativas / a vigilar:**
- iOS puede restringir servidores en background → hub desactivado en iOS si es necesario (Android/laptop como hub).
- El celular (hub) debe estar encendido y en el tailnet para que otros sincronicen.
- Conflictos: last-write-wins es suficiente para uso personal (datos pequeños).

## Alternativas descartadas

| Alternativa | Por qué |
|---|---|
| Servidor central (VPS) | Contradice el objetivo de privacidad y "celular como centro" |
| Cloudflare Tunnel desde el celular | No necesario; Tailscale es más simple y no expone a internet |
| mDNS local (solo Wi-Fi) | No funciona desde cualquier lugar |

## Referencias

- `docs/ARQUITECTURA.md` (capas hub/sync), `docs/PRODUCTO.md` (espacio 3).
- Tailscale: MagicDNS + NAT traversal.
