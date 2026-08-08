# ROADMAP — Fases del terminal SSH con supervitaminas

> **Prioridad:** Etapa 1 — terminal SSH/SFTP multiplataforma + canva + celular como hub (Tailscale). La Etapa 2 (agentes IA) está archivada en `docs/legacy/` y se retoma después.

## ✅ Hito 0 — Investigación y decisiones (HECHO)

- [x] Evaluado Flutter vs React Native → **Flutter** (dartssh2 + xterm.dart).
- [x] Validado celular como hub: servidor embebido Dart + Tailscale.
- [x] Referencias: ServerBox, NaviTerm (apps SSH en Flutter) como validación.
- Decisiones registradas en `docs/PLAN.md` y `docs/ADRs/`.

## 🚀 Etapa 1 — Terminal SSH multiplataforma + canva + hub (PLAN PRINCIPAL)

### Fase 1.1 — Fundación Flutter (primero)
**Features**
- [ ] Scaffold Flutter multiplataforma (Android, iOS, Windows, macOS).
- [ ] Tema Material 3 dark, navegación base, pantalla de hosts.
- [ ] Integrar dartssh2 + xterm.dart: **terminal SSH funcional** (password) en un host de prueba.
- [ ] CI día 1: `flutter analyze` + `flutter test` + build.

**Verificación de la Fase 1.1 (gate)**
- [ ] `flutter analyze` → 0 issues.
- [ ] `flutter test` → suite verde (test unitario del modelo de host).
- [ ] Build Windows + Android sin errores.
- [ ] **Prueba manual SSH**: conectar a `pve` (192.168.100.200, root) por password y ejecutar `ls`/`pwd` en el terminal xterm.
- [ ] Captura de pantalla del terminal funcionando como evidencia.

### Fase 1.2 — SSH completo + SFTP
**Features**
- [ ] Autenticación con **llaves públicas** (importar/generar, cifradas).
- [ ] Túneles: local, remoto, dinámico (SOCKS5).
- [ ] Jump servers.
- [ ] **SFTP**: navegación, subir/bajar/editar archivos.
- [ ] Sesiones persistentes (reabrir, incluso de otro dispositivo).
- [ ] Agrupación por carpetas/tags/colores.

**Verificación de la Fase 1.2 (gate)**
- [ ] Test unitario: `SshService.connectShell` con password (mock o servidor de test).
- [ ] Test unitario: autenticación con llave pública (generar ed25519, conectar a pve).
- [ ] Test SFTP: listar `/root`, subir un archivo, bajarlo, verificar hash.
- [ ] Prueba manual túnel: `ssh -L` local a un puerto del pve → funciona vía la app.
- [ ] Prueba manual jump: conectar a un host detrás de pve.
- [ ] Capturas/evidencia de cada flujo.

### Fase 1.3 — Canva visual
**Features**
- [ ] Canva infinito (zoom/pan) con nodos: **host SSH**, nota, contenedor.
- [ ] Click en nodo host → abre terminal.
- [ ] Conexiones/flechas entre hosts (topología).
- [ ] Persistencia del canva en SQLite.

**Verificación de la Fase 1.3 (gate)**
- [ ] Widget test: render del canva, agregar nodo host, arrastrar.
- [ ] Prueba manual: crear nodos, conectarlos, click en host → abre terminal y conecta.
- [ ] Prueba de persistencia: cerrar/reabrir app → el canva conserva nodos y posición.
- [ ] Capturas del canva con topología de varios hosts.

### Fase 1.4 — Hub de sincronización (celular)
**Features**
- [ ] Servidor embebido (dart:io) en el celular: snapshot + apply + WebSocket.
- [ ] Token de emparejamiento + auth.
- [ ] Cliente sync en laptop/otros: replica y suscribe.
- [ ] Tailscale: alcanzable desde cualquier parte.
- [ ] Sync de canvas, hosts, llaves y sesiones.

**Verificación de la Fase 1.4 (gate)**
- [ ] Test de integración: hub responde `GET /api/snapshot` y `POST /api/apply`.
- [ ] Test de auth: cliente sin token → rechazado; con token → aceptado.
- [ ] Prueba real 2 dispositivos: celular (hub) + laptop en el tailnet → sincronizan canvas y hosts.
- [ ] Prueba de conflictos: editar en 2 dispositivos a la vez → last-write-wins sin pérdida.
- [ ] Capturas/evidencia del sync en vivo.

### Fase 1.5 — Pulido
**Features**
- [x] Terminal con teclado SSH en móvil, atajos en desktop (Ctrl+R reconectar, Ctrl+L limpiar).
- [x] Resolución de conflictos (last-write-wins en el hub).
- [x] Testing multiplataforma (analyze + tests unitarios + smoke hub).
- [ ] Publicar (Play Store / App Store / releases desktop).

**Verificación de la Fase 1.5 (gate)**
- [x] `flutter analyze` 0 issues.
- [x] Tests unitarios verdes (7) + smoke del hub OK.
- [x] Build release Windows OK (`empresa_dev.exe`).
- [x] Teclado SSH móvil funcional (Esc, Tab, Ctrl, flechas, Ctrl-C/D).
- [ ] Prueba E2E en Android/iOS/macOS (requiere dispositivo).
- [ ] Test de batería: hub en celular no agota batería en 24h.
- [ ] Publicado y descargable (Play Store / App Store / releases).

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
