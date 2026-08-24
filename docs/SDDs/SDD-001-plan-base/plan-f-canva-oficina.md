# PLAN F — Etapa 6: Canva ReactFlow + Oficina animada

> [← Maestro](./README.md) · [← PLAN E](./plan-e-integracion-total.md) · [PLAN G →](./plan-g-skills-lab.md)
> Depende de: base completa (Etapas 1-5). Referencias de diseño: `reference/` (magic-ui Animated Beams, react-bits, ui-ux-pro-max, liquid-glass-web, impeccable).

**Entregable:** la oficina visual del plan original — agentes como personajes-nodo en un canva animado, con estados vivos conectados a los datos reales de las etapas anteriores.

## Fases

<a id="f0"></a>
### F.0 — Design System core + capa de experiencia (prerrequisito de TODO lo visual)
- **Fuente canónica visual:** [`SDD-013-gui-visual-spec.md`](../SDD-013-gui-visual-spec.md) — paleta oklch "Obsidian Glass", tipografía, espaciado, motion, Liquid Glass, componentes, checklist de calidad. La IA lee SDD-013 ANTES de tocar cualquier UI.
- **Tokens de diseño** (`oklch()` + cascade layers): paleta completa "Obsidian Glass" (fondos void→deep→surface→elevated→overlay, vidrio translucido con refracción, acentos neón sofisticados, texto con jerarquía 3 niveles, estados semánticos, degradados solo en elementos activos) — ver SDD-013 §1.1-1.3
- **Primitivas base** (expandidas con SDD-013):
  - `GlassCard` — vidrio con `backdrop-filter: blur(20px) saturate(1.5)`, borde translúcido, highlight interior
  - `AgentNode` — avatar con glow ring pulsante, badge de estado, barra de progreso sutil
  - `AnimatedBeam` — partícula viajante con `offset-path` + glow trail
  - `Toast` neuro-gratificante — never spinner, progreso real, mini-confetti local
  - `ProgressRing`, `MilestonePop`, `CelebrationOverlay` (pulse/burst/festivo), `StreakFlame`, `LevelBadge`, `HeatmapAnual`
  - `Button`, `Input`, `Modal`, `Skeleton` (nunca spinners), `Avatar`, `StatusDot`, `Tabs`, `Tooltip`, `EmptyState`
- **Command Palette global ⌘K** (patrón Zed/Raycast): glass profundo con `backdrop-filter: blur(30px)`, fuzzy-match <50ms, hotkeys configurables
- **Motion spec** (SDD-013 §2): duraciones 50ms→1200ms, easings físicos (expo, back, spring, quart), reglas no negociables (solo transform+opacity, stagger máx 20, `prefers-reduced-motion`), catálogo de 10 animaciones con timing y sensación exactos
- **Sonido** (SDD-013 §5.3): teoría musical aplicada — cada evento tiene chime DISTINTO (commit≠test≠deploy), mute por defecto, `prefers-reduced-motion` = silencio
- **SpatialMeta (primitiva transversal 3D/gafas):** toda componente visual que se renderice en el canvas lleva un campo `spatial?: SpatialMeta` en su tipo:
```typescript
interface SpatialMeta {
  x: number;          // posición horizontal (ReactFlow la maneja en 2D)
  y: number;          // posición vertical
  z?: number | null;  // profundidad — null en 2D, populated en 3D (force-directed o manual)
  cluster?: string;   // agrupación semántica (ej: "agents", "docs", "tasks")
  camera?: {          // vista al enfocar este nodo
    position: [number, number, number];
    target: [number, number, number];
  };
}
```
En 2D: `z` es `null`, ReactFlow ignora `cluster` y `camera`. En 3D: se calcula `z` con force-directed y `camera` se define. **Sin refactor al cambiar de renderer.** Todas las ventanas (Oficina, Planeación, Kanban, Control Room) heredan esta primitiva — el tipo se define en F.0 y se reutiliza en Etapas 6-19.
- **Liquid Glass** (SDD-013 §4): composición de 4 capas (CSS blur + SVG feDisplacementMap + gradiente de borde + sombra interior). Prioridad: paneles laterales → modales → command palette → cards → status bar. Fallback Firefox/Safari.
- **Pruebas:** Vitest tokens/primitivas. E2E humano: contraste AA automatizado, toast deshace acción destructiva, status bar refleja modelo/coste reales. **Gate visual F.5** audita contra checklist SDD-013 §7.

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
- **Persistencia espacial (regla terreno 3D/gafas):** al arrastrar un nodo, su `SpatialMeta` (x, y, cluster) se guarda en `event_stream` o tabla `spatial_layout` — NO solo en el store de ReactFlow. Las posiciones SOBREVIVEN reinicios y están disponibles para el visor 3D (Etapa 10/19). El gate F.4 no cierra sin esto.
- **Pruebas:** E2E humano: drag tarea todo→doing→done; **arrastrar nodo → recargar app → posición conservada**; verificar que `event_stream` tiene el registro de la posición

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
