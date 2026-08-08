# FUNDACION — Decisiones base del proyecto (terminal SSH Flutter)

> Decisiones que se definen **antes** de escribir código. Este es el nuevo plan principal (2026-08). El plan anterior (empresa web) está archivado en `docs/legacy/`.

## Stack final

| Capa | Elección |
|---|---|
| Framework | **Flutter** (Material 3) |
| SSH/SFTP | **dartssh2** |
| Terminal | **xterm.dart** |
| Canva | Flutter (InteractiveViewer + nodos custom) |
| Hub server | dart:io (HttpServer + WebSocket) embebido en el celular |
| Sync | **Tailscale** (red privada p2p, NAT-traversal) |
| DB local | SQLite (drift) |
| Estado | Riverpod |
| Secretos | flutter_secure_storage (llaves SSH cifradas) |
| Mobile | Android + iOS |
| Desktop | Windows + macOS (+ Linux opcional) |

## Decisiones clave

1. **Flutter** (no React Native): dartssh2 + xterm.dart son el stack SSH probado (ServerBox, NaviTerm).
2. **Celular como hub**: servidor embebido; laptop sincroniza contra él.
3. **Tailscale para alcance global**: sin abrir puertos, cifrado, ya lo usas.
4. **La conexión SSH es directa** del dispositivo al servidor; el hub sincroniza config/estado, no tráfico.
5. **El canva es el producto**: hosts como cuadritos, topología, click = terminal.
6. **Etapa 2**: agentes IA (opencode) como nodos del canva (archivado en `docs/legacy/`).

## Reglas de trabajo

- SDD por feature antes de implementar (ver `docs/AGENTS.md`).
- TDD: primero el test que falla.
- CI: `flutter analyze` + `flutter test` + build multiplataforma.
- Commits en español, cortos y con contexto.

## Referencias

- `docs/PLAN.md`, `docs/PRODUCTO.md`, `docs/ARQUITECTURA.md`, `docs/ROADMAP.md`, `docs/ETAPA1.md`.
- `docs/ADRs/` — decisiones de arquitectura.
- `docs/legacy/` — Etapa 2 (empresa web con agentes IA).
