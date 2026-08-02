# PRODUCTO — Spec de la aplicación web

> Una app web **mobile-first, responsive, super eficiente y con apariencia increíble**, que es a la vez tu canva de sesiones, tu tablero de empresa de desarrollo, y la sala de control de tus agentes de IA.

## Visión de producto

Una sola aplicación con **tres espacios** que se conectan entre sí:

1. **Canva** — tu mente visual: **esquemas y diagramas libres** + **ventanitas de agente** que se abren como chat estilo terminal. Es la sección que se construye **primero** (ver [ETAPA1.md](./ETAPA1.md)).
2. **Kanban / Empresa** — el tablero de tu "empresa de IA": tickets, estados, qué agente trabaja en qué, CI, PRs, verificación.
3. **Sesión / IDE** — el espacio de trabajo: chat con el agente, editor de código, terminal, herramientas en vivo, y **el navegador real** donde el agente prueba la UI (Chrome DevTools MCP).

## Los tres espacios

### 1. Canva (inicio)

- Canva infinito, zoom/pan, arrastrar, responsive táctil.
- **Esquemas libres**: cajas, notas, flechas, colores y contenedores para diagramar arquitectura y flujos.
- **Ventanitas de agente**: cajas que al hacer click/touch abren un **chat de agentes estilo terminal** (streaming, logs de herramientas, código coloreado, voz). Ocórrer en el servidor (headless), la sesión sigue aunque cierres la ventanita.
- Las tarjetas/ventanitas muestran estado en vivo: en qué anda el agente, CI verde/rojo, capturas de la última verificación de UI.

> La Etapa 1 (canva + ventanitas) se detalla en [ETAPA1.md](./ETAPA1.md).

### 2. Kanban (la "empresa")

- Tablero por proyecto con columnas: `Backlog → Pendiente → En curso → PR → CI → Revisión → Listo`.
- Cada ticket: quién lo implementa, su SDD, estado del CI, enlace al PR, evidencia visual.
- El tablero es **la vista operativa de LangGraph**: cada ticket en "En curso" es un agente trabajando (visible en vivo).
- Comandos por voz/texto: "mueve el ticket X a revisión", "dime qué falló en CI", "aprueba el PR".
- Métricas: tickets completados, bugs capturados por CI, tiempo por ticket.

### 3. Sesión / IDE

Cada sesión es un agente trabajando en un directorio real de tu máquina (o del servidor):

- **Chat streaming** con el agente (texto o voz, como CanvaDev).
- **Log de herramientas en vivo**: ves qué hace (lee, edita, corre, navega, captura).
- **Explorador + editor** (Monaco).
- **Terminal**.
- **Panel "Browser"**: la vista en vivo de un **Chrome headless** que corre en segundo plano en el servidor (MCP Chrome DevTools) — el agente lo controla sin abrir ventana en tu dispositivo; ves su navegación y las capturas que toma como evidencia.

## Principios de UX

- **Mobile-first responsive**: todo funciona desde el celular; el canva se vuelve lista, el IDE usa pestañas.
- **Rápido**: sin fricción; las vistas pesadas (editor, browser) se cargan bajo demanda.
- **Bello pero funcional**: apariencia cuidada (dark mode, animaciones sutiles, tipografía moderna) sin sacrificar rendimiento.
- **Todo observable**: nunca un "está trabajando" sin detalles — ves exactamente qué hace el agente.

## Stack moderno propuesto

| Capa | Elección | Por qué |
|---|---|---|
| Frontend | **React 19 + Vite + TypeScript** | CanvaDev ya lo usa; ecosistema maduro |
| Estilos | **Tailwind CSS v4** | Moderno, rápido, consistente |
| UI components | **shadcn/ui** | Look profesional sin esfuerzo |
| Canva | **React Flow (xyflow)** | Ya probado en CanvaDev |
| Kanban | react-kanban / dnd-kit | Drag & drop táctil |
| Estado | **Zustand + TanStack Query** | Ya usado + cache/refetch |
| Realtime | **WebSocket** | Streaming de eventos del agente |
| Backend | **Node + TypeScript** (Express o Fastify) | Mismo idioma que frontend |
| Orquestación | **LangGraph (JS o Python)** | Estado, retry, human-in-the-loop |
| UI testing | **MCP Chrome DevTools** | El agente prueba como humano |
| DB | SQLite (local) → Postgres (multi-usuario) | Simple primero, robusto después |
| Mobile | **PWA** (instalable, offline básico) | "Añadir a pantalla de inicio" |

## Criterios de aceptación del producto

- [ ] Funciona en celular y desktop con la misma calidad.
- [ ] El canva permite ver y abrir cualquier sesión en ≤2 toques.
- [ ] El kanban refleja el estado real de los agentes en vivo.
- [ ] El panel Browser muestra al agente probando la UI (navegación, clics, capturas).
- [ ] Una feature completa se desarrolla y verifica sin salir de la app.
- [ ] La app se siente instantánea (carga de vistas bajo demanda, transiciones suaves).
