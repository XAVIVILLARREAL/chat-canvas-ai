# PLAN — Terminal SSH multiplataforma con supervitaminas

> **Decisión central (2026-08):** Este es el **plan principal**. El plan anterior (empresa web con agentes IA) pasa a ser la **Etapa 2** (archivado en `docs/legacy/`).

## La idea en una frase

> **Reemplazo de Termius open source con supervitaminas: un canva donde cada nodo es un servidor SSH o un agente IA, con el celular como hub de sincronización global vía Tailscale.**

## Visión

Una app **Flutter multiplataforma** (Android, iOS, Windows, macOS, Linux) que reemplaza a Termius pero con un concepto visual único:

- **Terminal SSH/SFTP** completo (password, claves, túneles, SOCKS5, jump servers).
- **Canva visual**: cada cuadrito del canva es una **conexión SSH**, una **sesión de agente IA**, o una **nota**. Es el mapa de tu infraestructura.
- **Celular como hub**: el celular corre un **servidor embebido** (HTTP + WebSocket) dentro de la app. Todos los demás dispositivos sincronizan contra él vía **Tailscale** — sin servidores centrales, sin nube.
- **Sincronización global**: canvas, hosts SSH, llaves, sesiones y notas, siempre al día en todos tus dispositivos.

## Principios

1. **Privado por diseño**: tus llaves y hosts viven en tus dispositivos, sincronizados punto a punto. Sin nube de terceros.
2. **Multiplataforma real**: un solo codebase Flutter para móvil + desktop.
3. **El canva ES el producto**: la vista de topología de tus servidores, no una lista aburrida.
4. **El celular es el centro**: es el hub que siempre tienes contigo. La laptop sincroniza contra él.
5. **Agentes IA incluidos (Etapa 2)**: los cuadritos de agente (opencode) que ya construimos se integran como ciudadanos de primera clase.
6. **Rápido y eficiente**: dartssh2 + xterm.dart son nativos y ligeros.

## Decisiones tomadas

| Decisión | Opción | Por qué |
|---|---|---|
| Framework | **Flutter** (no React Native) | dartssh2 + xterm.dart en Dart puro; ServerBox/NaviTerm lo prueban |
| SSH/SFTP | **dartssh2** | Completo: password, claves, forwards, SOCKS5, jump, SFTP |
| Terminal | **xterm.dart** | 60fps, móvil+desktop, frontend independiente |
| Sync hub | **Celular con servidor embebido** (dart:io) | Sin servidor central; privado |
| Alcance global | **Tailscale** | NAT-traversal, cifrado, sin abrir puertos (ya lo usas) |
| Almacenamiento | SQLite (drift) en cada dispositivo | Fuente de verdad local + réplicas |
| UI | Material 3, dark mode, tema cuidado | Look profesional |

## Qué NO es este plan (Etapa 2, archivado)

- La empresa web de agentes IA (React + Hono + opencode) **no se descarta**: sus agentes, voz y evidencia se integran en la **Etapa 2** como cuadritos de agente en el canva.
- No hay backend centralizado. Todo vive en tus dispositivos, con el celular como hub.

## Alcance por fases

1. **Etapa 1 (este plan):** terminal SSH/SFTP multiplataforma + canva de hosts + celular como hub de sync (Tailscale).
2. **Etapa 2 (después):** agentes IA (opencode) como cuadritos + voz + evidencia + verificación — reutilizando lo construido (ver `docs/legacy/`).
