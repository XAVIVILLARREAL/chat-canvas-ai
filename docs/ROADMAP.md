# ROADMAP — Fases del terminal SSH con supervitaminas

> **Prioridad:** Etapa 1 — terminal SSH/SFTP multiplataforma + canva + celular como hub (Tailscale). La Etapa 2 (agentes IA) está archivada en `docs/legacy/` y se retoma después.

## ✅ Hito 0 — Investigación y decisiones (HECHO)

- [x] Evaluado Flutter vs React Native → **Flutter** (dartssh2 + xterm.dart).
- [x] Validado celular como hub: servidor embebido Dart + Tailscale.
- [x] Referencias: ServerBox, NaviTerm (apps SSH en Flutter) como validación.
- Decisiones registradas en `docs/PLAN.md` y `docs/ADRs/`.

## 🚀 Etapa 1 — Terminal SSH multiplataforma + canva + hub (PLAN PRINCIPAL)

### Fase 1.1 — Fundación Flutter (primero)
- [ ] Scaffold Flutter multiplataforma (Android, iOS, Windows, macOS).
- [ ] Tema Material 3 dark, navegación base, pantalla de hosts.
- [ ] Integrar dartssh2 + xterm.dart: **terminal SSH funcional** (password) en un host de prueba.
- [ ] CI día 1: `flutter analyze` + `flutter test` + build.

### Fase 1.2 — SSH completo + SFTP
- [ ] Autenticación con **llaves públicas** (importar/generar, cifradas).
- [ ] Túneles: local, remoto, dinámico (SOCKS5).
- [ ] Jump servers.
- [ ] **SFTP**: navegación, subir/bajar/editar archivos.
- [ ] Sesiones persistentes (reabrir, incluso de otro dispositivo).
- [ ] Agrupación por carpetas/tags/colores.

### Fase 1.3 — Canva visual
- [ ] Canva infinito (zoom/pan) con nodos: **host SSH**, nota, contenedor.
- [ ] Click en nodo host → abre terminal.
- [ ] Conexiones/flechas entre hosts (topología).
- [ ] Persistencia del canva en SQLite.

### Fase 1.4 — Hub de sincronización (celular)
- [ ] Servidor embebido (dart:io) en el celular: snapshot + apply + WebSocket.
- [ ] Token de emparejamiento + auth.
- [ ] Cliente sync en laptop/otros: replica y suscribe.
- [ ] Tailscale: alcanzable desde cualquier parte.
- [ ] Sync de canvas, hosts, llaves y sesiones.

### Fase 1.5 — Pulido
- [ ] Terminal con teclado SSH en móvil, atajos en desktop.
- [ ] Resolución de conflictos (last-write-wins).
- [ ] Testing en las 4 plataformas.
- [ ] Publicar (Play Store / App Store / releases desktop).

**Objetivo Etapa 1:** reemplazar Termius — terminal + SFTP + canva, con el celular como hub de sync.

## ⏭️ Etapa 2 — Agentes IA (después; archivado en docs/legacy/)

- [ ] Nodos de **agente IA** (opencode) en el canva, como ciudadanos de primera clase.
- [ ] Voz (Edge TTS + STT navegador), evidencia por prompt.
- [ ] Verificación de UI con Chrome headless (lo que ya construimos).
- [ ] Orquestación multi-agente (LangGraph) para la "empresa".

## Stack

| Necesidad | Elección | Estado |
|---|---|---|
| Framework | **Flutter** (Material 3) | Etapa 1 |
| SSH/SFTP | **dartssh2** | Etapa 1 |
| Terminal | **xterm.dart** | Etapa 1 |
| Canva | Flutter (InteractiveViewer + nodos custom) | Etapa 1 |
| Hub server | dart:io (HttpServer + WebSocket) | Etapa 1 |
| Sync | **Tailscale** (red privada p2p) | Etapa 1 |
| DB | SQLite (drift) | Etapa 1 |
| Estado | Riverpod | Etapa 1 |
| Agentes IA | opencode (Etapa 2) | Etapa 2 |

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| dartssh2 no soporta algún cipher nuevo (chacha20) | Cipher list configurable; la mayoría de servidores usan aes-ctr |
| Terminal móvil es incómoda sin teclado físico | Teclado SSH custom (Esc, Tab, Ctrl, flechas) |
| Sync conflictos entre dispositivos | last-write-wins + versionado; datos pequeños |
| Batería celular (hub siempre activo) | Hub solo responde a demanda; low-power en background |
| App Store iOS restringe servidores embebidos | Hub desactivado en iOS si es necesario; laptop/Android como hub |
