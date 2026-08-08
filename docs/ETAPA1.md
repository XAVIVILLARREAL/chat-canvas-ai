# ETAPA 1 — Terminal SSH funcional en Flutter (construir primero)

> **Qué se construye primero:** el **terminal SSH/SFTP multiplataforma** hecho en Flutter con dartssh2 + xterm.dart. Sin esto no hay nada. Después se construye el canva y el hub.

## Por qué primero

- Es el **núcleo** del reemplazo de Termius: sin SSH funcional no hay producto.
- Valida el stack completo (Flutter + dartssh2 + xterm.dart) en un día.
- El canva y el hub de sync se construyen **alrededor** de esta base.

## Hito 1.1 — "Hola SSH" (slice vertical)

**Objetivo:** conectar por SSH a un servidor real (el pve, `192.168.100.200` o `100.101.69.79` vía Tailscale) desde una app Flutter y ver un shell funcional.

### Qué incluye

- Scaffold Flutter: Android + Windows (las 2 plataformas de prueba).
- Tema Material 3 dark, pantalla simple "agregar host" (host, puerto, usuario, password).
- Servicio `SshService` con dartssh2: conectar, autenticar, abrir shell.
- `xterm.dart` conectado al shell: escribir comandos, ver salida.
- Botón "conectar" → terminal en vivo.

### Qué NO incluye (siguientes slices)

- Llaves públicas, SFTP, túneles (Fase 1.2).
- Canva (Fase 1.3).
- Hub de sync (Fase 1.4).

## Cómo se conecta

```
Flutter app ── dartssh2 ──► SSH al servidor (pve / cualquier host)
                    ▲
   xterm.dart (input/output del shell)
```

## Criterios de aceptación

- [ ] La app Flutter compila en Android y Windows.
- [ ] Agrego el host `pve` (192.168.100.200, usuario root, password) y conecta.
- [ ] El terminal muestra el prompt y ejecuto `ls`, `pwd`, `whoami` correctamente.
- [ ] Resize de la ventana → el terminal se ajusta.
- [ ] Dark mode + look profesional.
- [ ] Desconectar/reconectar sin crash.

## Pruebas de la Etapa 1 (gate de calidad)

| Tipo | Qué se prueba | Cómo |
|---|---|---|
| Análisis estático | `flutter analyze` 0 issues | CI |
| Unitario | Modelo de host, parsing de puerto | `flutter test` |
| Manual SSH | Conexión real a pve (password) + comandos | La app en Windows/Android |
| Terminal | Escribir, scroll, resize, UTF-8 | xterm.dart en vivo |
| Reconexión | Desconectar y reconectar sin crash | Manual |
| Evidencia | Capturas del terminal funcionando | Screenshots por plataforma |

## Herramientas

- Flutter SDK (instalar local o en el servidor).
- dartssh2, xterm.dart.
- Servidor de prueba: `pve` (ya disponible, accesible por SSH).

## Después de la Etapa 1

- Fase 1.2: llaves + SFTP + túneles.
- Fase 1.3: canva visual.
- Fase 1.4: hub de sync (celular + Tailscale).
- Etapa 2: agentes IA (ver `docs/legacy/`).
