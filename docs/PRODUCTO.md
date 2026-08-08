# PRODUCTO — Spec del terminal SSH con supervitaminas

> Una app **Flutter multiplataforma** que reemplaza a Termius con un canva visual de tu infraestructura y el **celular como hub de sincronización global**.

## Visión de producto

Tres espacios conectados en una sola app:

1. **Terminal** — el corazón: SSH/SFTP completo, rápido y hermoso (xterm.dart).
2. **Canva** — el mapa visual: cada cuadrito es un **host SSH**, una **sesión de agente IA** (Etapa 2) o una **nota**. Conectas cajas para dibujar tu topología.
3. **Hub de sync** — el celular corre un servidor embebido; los demás dispositivos se sincronizan contra él vía Tailscale.

## Los tres espacios

### 1. Terminal (núcleo)

- **SSH completo** (dartssh2): password, llaves públicas (RSA/ECDSA/Ed25519), túneles local/remoto/dinámico (SOCKS5), jump servers.
- **SFTP**: navegar, subir, bajar, editar archivos remotos.
- **Terminal real** (xterm.dart): 60fps, soporte UTF-8/CJK/emoji, tema oscuro, redimensionable.
- **Sesiones persistentes**: se guardan y se pueden reabrir (incluso desde otro dispositivo).
- **Agrupación**: hosts organizables por carpeta/tag/color.

### 2. Canva (el diferenciador)

- Canva infinito con zoom/pan (responsive táctil y mouse).
- **Cuadritos SSH**: cada nodo es un host con su estado. Click/touch → abre el terminal.
- **Conexiones**: flechas entre hosts para dibujar topología y flujos de túneles.
- **Notas/colores/contenedores**: organizar proyectos, entornos, clusters.
- **Cuadritos de agente IA** (Etapa 2): sesiones de opencode como nodos.
- El canva **se sincroniza** entre dispositivos (posición, hosts, conexiones).

### 3. Hub de sync (la funcionalidad única)

- **El celular es el servidor**: la app Flutter corre un servidor HTTP + WebSocket embebido (`dart:io`) en un puerto local.
- **Alcance global por Tailscale**: el celular y tus dispositivos están en el mismo tailnet → el celular es alcanzable en `http://100.x.y.z:<puerto>` desde cualquier parte.
- **Sincronización**: canvas, hosts SSH, llaves, sesiones y notas viajan entre dispositivos.
- **Conflicto mínimo**: sync por versión/timestamp (datos pequeños). El celular es la autoridad.
- **Modo hub opcional**: cualquier dispositivo puede ser hub, pero por defecto el celular lo es.

## Principios de UX

- **Mobile-first**: todo usable con un pulgar; el terminal tiene teclado especial SSH.
- **Desktop completo**: atajos de teclado, multi-panel, mouse.
- **Dark mode por defecto** + tema claro opcional (Material 3).
- **Rápido**: conexiones nativas, sin webviews.
- **Bello pero funcional**: animaciones sutiles, tipografía mono para terminal.

## Stack (resumen)

| Capa | Elección |
|---|---|
| Framework | Flutter (Material 3) |
| SSH/SFTP | dartssh2 |
| Terminal | xterm.dart |
| Hub server | dart:io (HttpServer + WebSocket) |
| Sync | Tailscale (red privada) |
| DB local | SQLite (drift) |
| Canva | Flutter (InteractiveViewer + nodos custom) |
| Estado | Riverpod o Bloc |

## Criterios de aceptación del producto

- [ ] SSH funcional en Android, iOS, Windows y macOS (password + llaves).
- [ ] SFTP navegable (subir/bajar/editar).
- [ ] El canva muestra hosts como cuadritos y abre terminal al click.
- [ ] El celular corre el hub; la laptop se conecta por Tailscale y sincroniza canvas/hosts/llaves.
- [ ] Cambiar de dispositivo = el trabajo está (sincronizado), no se pierde nada.
- [ ] La app se siente nativa y rápida en cada plataforma.
