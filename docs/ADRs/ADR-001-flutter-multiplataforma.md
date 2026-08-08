# ADR-001 — Flutter como framework multiplataforma (en vez de React Native)

- **Estado:** Aceptado (2026-08)
- **Decisión:** La app se construye en **Flutter** (Dart) con dartssh2 + xterm.dart, no en React Native.
- **Tags:** framework, multiplataforma, ssh

## Contexto

Queremos un reemplazo de Termius multiplataforma (Android, iOS, Windows, macOS) con SSH/SFTP real. Se evaluaron Flutter y React Native.

## Decisión

- **Flutter** como framework.
- **dartssh2** (SSH/SFTP en Dart puro) y **xterm.dart** (emulador de terminal 60fps) como base.
- Un solo codebase Dart para móvil + desktop.

## Consecuencias

**Positivas:**
- Ecosistema SSH maduro y probado: dartssh2 es el motor de ServerBox y NaviTerm.
- Terminal real multiplataforma con xterm.dart (sin webviews).
- Un solo lenguaje, un solo codebase.
- Performance nativa (sin puente JS).

**Negativas / a vigilar:**
- React Native reutilizaría el React ya conocido, pero su stack SSH (ssh2 JS) requiere polyfills de Node — fricción alta.
- dartssh2 no soporta aún `chacha20-poly1305` (configurable; la mayoría usa aes-ctr).

## Alternativas descartadas

| Alternativa | Por qué |
|---|---|
| React Native | ssh2 JS necesita polyfills de Node; sin xterm equivalente maduro |
| Electron/Web (Termius así) | Pesado, no móvil nativo |
| Cliente web (webssh) | Sólo navegador; el producto es multiplataforma nativo |

## Referencias

- `docs/FUNDACION.md`, `docs/ETAPA1.md`.
- Investigación: pub.dev/packages/dartssh2, pub.dev/packages/xterm.
