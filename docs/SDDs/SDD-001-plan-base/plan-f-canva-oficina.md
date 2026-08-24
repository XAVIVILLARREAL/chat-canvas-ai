# PLAN F — Etapa 6: Canva ReactFlow + Oficina animada

> [← Maestro](./README.md) · [← PLAN E](./plan-e-integracion-total.md) · [PLAN G →](./plan-g-skills-lab.md)
> Depende de: base completa (Etapas 1-5). Referencias de diseño: `reference/` (magic-ui Animated Beams, react-bits, ui-ux-pro-max, liquid-glass-web, impeccable).

**Entregable:** la oficina visual del plan original — agentes como personajes-nodo en un canva animado, con estados vivos conectados a los datos reales de las etapas anteriores.

## Fases

<a id="f0"></a>
### F.0 — Design System core + capa de experiencia (prerrequisito de TODO lo visual)
- **Tokens de diseño** (`oklch()` + cascade layers): color/espacio/tipografía/radio/sombra/motion en un solo archivo consumido por todas las etapas — modo oscuro/claro/alto-contraste desde el mismo token
- **Primitivas base**: Button, Input, Card, Modal, **Toast + UNDO 5s** en acciones destructivas (patrón Linear), Skeleton loaders (nunca spinners), Avatar, StatusDot, Tabs, Tooltip, EmptyState ilustrado
- **Status bar global inferior** (patrón Zed/Vim): modelo activo · contexto usado% · coste sesión · rama git · estado sync · agentes corriendo — información mirable de reojo, cero clicks
- Motion spec único: duraciones/easing globales, respeta `prefers-reduced-motion`
- La IA aplica los skills de `reference/` SOBRE estos tokens (nunca CSS improvisado)
- **Pruebas:** Vitest tokens/primitivas. E2E humano: contraste AA automatizado, toast deshace acción destructiva, status bar refleja modelo/coste reales

### F.1 — Fundaciones ReactFlow
- ReactFlow instalado y montado en WorkArea como pestaña "Oficina" (el chat/sidepanels NO se tocan)
- Nodos estáticos arrastrables, edges, viewport con zoom/pan (rueda + pinch), minimap desktop
- Config adaptativa de ADR-001 (mobile: sin minimap, controls flotantes)
- **Pruebas:** E2E humano: arrastrar nodo, conectar dos nodos, zoom con rueda y pinch

<a id="f2"></a>
### F.2 — Nodos-agente vivos (datos reales)
- Nodo custom por agente del store real ([A·A.2](./plan-a-chat-codex.md#a2)): avatar, nombre, rol, badge de estado (`idle/working/blocked/error`)
- Estado sincronizado con eventos del provider ([C·C.1](./plan-c-reasonix-deepseek.md#c1)): cuando el agente ejecuta tool-call → estado "working" en vivo
- Click en nodo → abre su detalle en panel (reutiliza [B·B.4](./plan-b-sidepanels-lovable.md#b4))
- **Pruebas:** E2E: crear agente en chat → nodo aparece; mock provider working → badge cambia

<a id="f3"></a>
### F.3 — Edges semánticos + Animated Beams
- Aristas iluminadas animadas (magic-ui Animated Beam / SVG feTurbulence) para el flujo de trabajo
- Tipos de edge por relación: tarea-asignada, artefacto-entregado, bloquea-a
- Partículas viajando cuando hay actividad real en esa arista
- **Pruebas:** unit mapping evento→edge. Visual gate con screenshots/video

### F.4 — Tareas y Kanban sobre el canva
- Nodos-tarea vinculados al event_stream ([D·D.1](./plan-d-memoria-v3code.md#d1))
- Vista tablero Kanban (todo/doing/review/done) sincronizada bidireccionalmente con el canva (mismo store, dos vistas)
- Drag de tarea entre columnas actualiza estado real
- **Pruebas:** E2E humano: drag tarea todo→doing→done; verificar persistencia tras reinicio

### F.5 — Identidad visual dirigida por IA
- La IA (usando skills de `reference/`) elige estilo por pantalla: paleta ui-ux-pro-max + pulido impeccable + vidrio liquid-glass donde aporte
- Criterios duros: jerarquía clara, contraste WCAG AA, motion con propósito, coherencia entre pantallas
- Auditoría final documentada en docs (qué skill eligió qué y por qué)
- **Pruebas:** suite humana completa re-corrida + checklist RESPONSIVE.md + contraste automatizado básico

<a id="f7"></a>
### F.7 — Command Palette global ⌘K (ganadora torneo #173, patrón Zed/Raycast)
- Paleta accesible desde cualquier ventana: buscar/ejecutar acciones, saltar a proyecto/archivo/agente/sesión, despachar encargos rápidos ([A·A.7](./plan-a-chat-codex.md#a7))
- Respuesta <50ms percibida; fuzzy-match con ranking por uso reciente; hotkeys para las 5 acciones top configurables
- **Pruebas GUI:** E2E humano: ⌘K→escribir 3 letras→Enter ejecuta acción correcta; paleta lista proyectos/agentes/comandos; hotkey personalizada persiste
### F.6 — Performance del canva
- Virtualización de nodos (>50), solo transform/opacity en animaciones, will-change selectivo, prefers-reduced-motion
- **Renderer Three.js WebGPU** (2026: estándar; WebGL queda como fallback) — el canva 3D corre 100% en el CLIENTE, cero carga de servidor
- Benchmark: 100 nodos + 150 edges a 60fps en desktop dev
- **Pruebas:** test de rendimiento programático + suite humana sin jank percibido

## 🚪 GATE F (demo verificable)

Demo grabada: chateas "crea 3 agentes y asígnales tareas" → aparecen nodos animados en la oficina, edges se encienden con actividad real, mueves una tarea en Kanban y el canva refleja el cambio, en mobile funciona con touch. Suite humana ampliada verde.

---
[← Maestro](./README.md) · [← PLAN E](./plan-e-integracion-total.md) · [PLAN G →](./plan-g-skills-lab.md)
