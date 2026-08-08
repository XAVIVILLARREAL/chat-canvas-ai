# AGENTS.md — Empresa Dev (terminal SSH Flutter con supervitaminas)

Guía de trabajo para los agentes (incluido este) en este proyecto. Léela antes de tocar código.

## Qué es este proyecto

Un **reemplazo de Termius multiplataforma** hecho en **Flutter**: terminal SSH/SFTP real (dartssh2 + xterm.dart), un **canva visual** donde cada cuadrito es un host SSH / nota / (agente IA en Etapa 2), y el **celular como hub de sincronización global vía Tailscale**.

- **Idea rectora:** *Termius open source + supervitaminas: un canva donde cada nodo es un servidor o un agente IA, con el celular como hub de sincronización.*
- **Documentación:** `docs/PLAN.md`, `PRODUCTO.md`, `ARQUITECTURA.md`, `ROADMAP.md`, `ETAPA1.md`, `FUNDACION.md`, `ADRs/`.
- **Etapa 2 (plan anterior):** archivada en `docs/legacy/` — agentes IA (opencode), voz, evidencia. No se toca hasta terminar la Etapa 1.

## Reglas obligatorias de trabajo

1. **SDD por feature — antes de implementar.** Escribe el diseño (objetivo, flujo, contratos, tests) antes de tocar código.
2. **TDD:** primero el test que falla, después el código que lo pasa.
3. **CI día 1:** `flutter analyze` + `flutter test --exclude-tags integration` + build multiplataforma.
4. **Gate por fase:** cada fase del ROADMAP tiene su verificación (ver `docs/ROADMAP.md`). Una fase no se cierra sin pasar su gate.
5. **Tests de integración SSH:** en `test/ssh_integration_test.dart`, tag `integration`, requieren red + llave (`test/fixtures/app_test_key`), no corren en CI.
6. **Definition of Done:** CI verde + probado en al menos 2 plataformas (Android + desktop) + gate de la fase cumplido.
7. Máx 3 intentos por error antes de escalar al humano.

## Decisiones de arquitectura (ADRs)

- **Framework: Flutter** (no React Native). SSH/SFTP con **dartssh2**; terminal con **xterm.dart**. → `ADR-001`.
- **Celular como hub**: servidor embebido (dart:io) + **Tailscale** para sync global. → `ADR-002`.
- **DB local:** SQLite (drift) en cada dispositivo; el hub es la autoridad.
- **La conexión SSH es directa** del dispositivo al servidor; el hub sincroniza config/estado.

## Stack

| Capa | Elección |
|---|---|
| Framework | Flutter (Material 3) |
| SSH/SFTP | dartssh2 |
| Terminal | xterm.dart |
| Canva | Flutter (InteractiveViewer + nodos custom) |
| Hub server | dart:io (HttpServer + WebSocket) |
| Sync | Tailscale |
| DB | SQLite (drift) |
| Estado | Riverpod |
| Secretos | flutter_secure_storage |

## Etapa 1 (lo primero)

Terminal SSH funcional en Flutter: conectar a `pve` (192.168.100.200 o 100.101.69.79 Tailscale), ver un shell en xterm.dart. Detalle en `docs/ETAPA1.md`.

## Convenios

- Commits en español, cortos y con contexto ("feat:", "fix:", "docs:", "chore:").
- El código Flutter vive en el monorepo (apps/ para la app Flutter).
- El repo se mantiene en `/opt/empresa-desarrollo-autonoma` en el servidor pve.
