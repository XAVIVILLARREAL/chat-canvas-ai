# Empresa Dev — Terminal SSH multiplataforma con supervitaminas

Un **reemplazo de Termius con supervitaminas**: cliente **SSH/SFTP multiplataforma** (Android, iOS, Windows, macOS, Linux) hecho en **Flutter**, con un **canva visual** donde cada cuadrito es una conexión SSH, una sesión de agente IA, o una nota. 

**La funcionalidad única:** el **celular actúa como servidor de sincronización** — desde donde te conectes (laptop, tablet, otro celular), todo se sincroniza con tu teléfono vía **Tailscale**, sin servidores centrales.

## La idea en una frase

> **Termius open source + supervitaminas: un canva donde cada nodo es un servidor o un agente IA, con el celular como hub de sincronización global.**

## Qué lo hace único

1. **Canva = mapa de tu infraestructura**: cada cuadrito es un host SSH, un agente IA, o una nota. Conectas cajas con flechas (topología), y un clic abre el terminal.
2. **El celular es el hub**: un servidor embebido en la app Flutter sincroniza canvas, hosts, llaves y sesiones entre todos tus dispositivos.
3. **Agentes IA como ciudadanos de primera clase**: cada cuadrito puede ser una sesión de agente (opencode) que desarrolla, ejecuta y verifica — la "empresa" que ya construimos como **Etapa 2**.
4. **Multiplataforma real**: Flutter + dartssh2 + xterm.dart → SSH/SFTP nativo en móvil y desktop.

## Documentación

| Documento | Contenido |
|---|---|
| [PLAN.md](docs/PLAN.md) | Visión, decisiones y alcance |
| [PRODUCTO.md](docs/PRODUCTO.md) | El producto: terminal + canva + hub de sync, UX, stack |
| [ARQUITECTURA.md](docs/ARQUITECTURA.md) | Flutter + dartssh2 + xterm.dart + hub Tailscale |
| [ROADMAP.md](docs/ROADMAP.md) | Fases de construcción |
| [ETAPA1.md](docs/ETAPA1.md) | **Lo primero a construir:** SSH funcional en Flutter |
| [FUNDACION.md](docs/FUNDACION.md) | Decisiones base y stack final |
| [ADRs/](docs/ADRs/) | Decisiones de arquitectura |
| [legacy/](docs/legacy/) | **Etapa 2:** plan anterior (empresa web con agentes IA) |

## Estado

**En diseño.** Investigación hecha (2026-08): Flutter + dartssh2 + xterm.dart validados. Ver `docs/ETAPA1.md` para el primer hito.
