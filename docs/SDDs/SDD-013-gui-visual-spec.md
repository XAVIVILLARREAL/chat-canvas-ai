# SDD-013 · Especificación Visual — Identidad GUI "Obsidian Glass"

> Fecha: 2026-08-24 · Estado: Aprobado · v1.1 (integrada al Plan Base v3.9)
> Referencias: `reference/` (liquid-glass-web, impeccable, magic-ui, ui-ux-pro-max, apple-design-skill, react-bits)
> **Aplica a TODO el plan base** (no solo F): Design System (este SDD) · F.1–F.7 + KR (Canva + Kanban) · A.4 (chat-first) · V (Visual GrokBot: avatares/estados) · U (dopamina) · K.3 (sonido) · T.A11Y (contraste) · VI (Segundo Cerebro)

## Relación con el Plan Base (cómo se funde — v3.9)

| Dónde vive | Qué aporta SDD-013 | Referencia |
|---|---|---|
| **Este SDD (SDD-013)** | Tokens oklch "Obsidian Glass", primitivas (GlassCard/AgentNode/AnimatedBeam/Toast), motion, sonido, Liquid Glass — fuente canónica visual | §1-§4 |
| **[PLAN V](./SDD-001-plan-base/plan-v-visual-grokbot.md)** | Los avatares geométricos y estados 2 capas usan los tokens de identidad/estado de §1.1 (el color de QUIÉN sale de la paleta de identidad, no de estados semánticos) | V.1 |
| **[PLAN U](./SDD-001-plan-base/plan-u-motivacion.md)** | Cada primitiva dopaminérgica usa token + animación §2 + sonido §5.3 (tabla de mapeo en plan-u) | U.1–U.8 |
| **[K·K.3](./SDD-001-plan-base/plan-k-voz.md#k3)** | La tabla de sonidos §5.3 (teoría musical: arpegio/tritono/chime por evento) es canónica para la política de interrupción | K.3 |
| **[T.A11Y](./SDD-001-plan-base/plan-t-excelencia.md#ta11y)** | El checklist §7 (contraste AA, reduced-motion, touch targets, empty states) se audita en cada gate | T.A11Y |
| **A.4 (chat-first)** | La superficie de chat (desks/burbujas) usa GlassCard + tokens de texto §1 | A.4/V.0 |

## 1. Identidad visual: "Obsidian Glass"

**Concepto:** Un mundo de obsidiana oscura con capas de vidrio translúcido que revelan profundidad. Minimalista pero con vida — cada elemento tiene peso, cada animación comunica. No es "dark mode", es un **entorno espacial** donde los datos flotan en capas de vidrio sobre fondo profundo.

### 1.1 Paleta de color (oklch — perceptivamente uniforme)

```css
:root {
  /* === FONDO (capas de profundidad) === */
  --bg-void: oklch(0.08 0.01 260);        /* Vacío más profundo */
  --bg-deep: oklch(0.11 0.015 260);       /* Capa base */
  --bg-surface: oklch(0.14 0.02 260);     /* Superficies elevadas */
  --bg-elevated: oklch(0.18 0.025 260);   /* Cards, paneles */
  --bg-overlay: oklch(0.22 0.03 260);     /* Modales, overlays */

  /* === VIDRIO (translucidez con refracción) === */
  --glass-bg: oklch(0.16 0.02 260 / 0.6); /* Fondo del vidrio */
  --glass-border: oklch(0.3 0.01 260 / 0.15); /* Borde sutil */
  --glass-highlight: oklch(0.9 0.01 260 / 0.05); /* Reflejo superior */
  --glass-shadow: oklch(0.05 0.02 260 / 0.4);   /* Sombra profunda */

  /* === ACENTE (neón sofisticado, nunca chillón) === */
  --accent-primary: oklch(0.75 0.15 250);    /* Azul eléctrico */
  --accent-secondary: oklch(0.65 0.18 300);  /* Púrpura profundo */
  --accent-tertiary: oklch(0.72 0.12 170);   /* Turquesa */
  --accent-warm: oklch(0.7 0.14 50);         /* Ámbar cálido */

  /* === TEXTO (jerarquía clara) === */
  --text-primary: oklch(0.92 0.01 260);    /* Casi blanco */
  --text-secondary: oklch(0.65 0.02 260);  /* Gris legible */
  --text-tertiary: oklch(0.45 0.02 260);   /* Gris apagado */
  --text-accent: oklch(0.8 0.12 250);      /* Azul claro para links */

  /* === ESTADO (semántico, nunca decorativo) === */
  --state-success: oklch(0.72 0.18 145);   /* Verde vivo */
  --state-warning: oklch(0.78 0.16 85);    /* Ámbar */
  --state-error: oklch(0.65 0.2 25);       /* Rojo profundo */
  --state-info: oklch(0.72 0.14 250);      /* Azul info */

  /* === DEGRADADOS (solo en elementos activos) === */
  --gradient-brand: linear-gradient(135deg, var(--accent-primary), var(--accent-secondary));
  --gradient-glow: radial-gradient(circle at 50% 0%, oklch(0.75 0.15 250 / 0.15), transparent 70%);
  --gradient-depth: linear-gradient(180deg, var(--bg-surface), var(--bg-deep));
}
```

### 1.2 Tipografía

```css
:root {
  /* Display — títulos grandes, impacto */
  --font-display: "Inter", "SF Pro Display", system-ui;
  --font-display-weight: 700;
  --font-display-tracking: -0.02em;

  /* Body — lectura larga */
  --font-body: "Inter", "SF Pro Text", system-ui;
  --font-body-weight: 400;
  --font-body-tracking: 0;

  /* Mono — código, datos */
  --font-mono: "JetBrains Mono", "SF Mono", "Fira Code", monospace;
  --font-mono-weight: 400;

  /* Escala modular (1.250 — Major Third) */
  --text-xs: 0.64rem;    /* 10.24px */
  --text-sm: 0.8rem;     /* 12.8px */
  --text-base: 1rem;     /* 16px */
  --text-lg: 1.25rem;    /* 20px */
  --text-xl: 1.563rem;   /* 25px */
  --text-2xl: 1.953rem;  /* 31.25px */
  --text-3xl: 2.441rem;  /* 39px */
  --text-4xl: 3.052rem;  /* 48.8px */
}
```

### 1.3 Espaciado y radios

```css
:root {
  /* Espaciado base 4px */
  --space-1: 0.25rem;  /* 4px */
  --space-2: 0.5rem;   /* 8px */
  --space-3: 0.75rem;  /* 12px */
  --space-4: 1rem;     /* 16px */
  --space-5: 1.5rem;   /* 24px */
  --space-6: 2rem;     /* 32px */
  --space-8: 3rem;     /* 48px */
  --space-10: 4rem;    /* 64px */

  /* Radios — consistencia visual */
  --radius-sm: 6px;
  --radius-md: 10px;
  --radius-lg: 16px;
  --radius-xl: 24px;
  --radius-full: 9999px;

  /* Sombras — capas de profundidad */
  --shadow-sm: 0 1px 2px oklch(0.05 0.02 260 / 0.3);
  --shadow-md: 0 4px 12px oklch(0.05 0.02 260 / 0.25);
  --shadow-lg: 0 8px 32px oklch(0.05 0.02 260 / 0.2);
  --shadow-xl: 0 16px 64px oklch(0.05 0.02 260 / 0.15);
  --shadow-glow: 0 0 20px oklch(0.75 0.15 250 / 0.15);
}
```

## 2. Sistema de Motion (neuro-psicológico)

### 2.1 Timing functions (física real)

```css
:root {
  /* Duraciones (base 100ms) */
  --duration-instant: 50ms;     /* micro-feedback */
  --duration-fast: 150ms;       /* hover, focus */
  --duration-normal: 250ms;     /* transiciones UI */
  --duration-slow: 400ms;       /* modales, paneles */
  --duration-slower: 600ms;     /* celebraciones */
  --duration-ceremony: 1200ms;  /* celebraciones gated */

  /* Easings (física de resortes) */
  --ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);      /* Entradas suaves */
  --ease-out-back: cubic-bezier(0.34, 1.56, 0.64, 1);  /* Micro-overshoot */
  --ease-in-out-quart: cubic-bezier(0.76, 0, 0.24, 1); /* Transiciones complejas */
  --ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1);    /* Rebote sutil */

  /* Física de cards (Linear/Kanban) */
  --card-mass: 1;
  --card-tension: 180;
  --card-friction: 12;
}
```

### 2.2 Reglas de animación (no negociables)

| Regla | Por qué | Ejemplo |
|-------|---------|---------|
| **Solo transform + opacity** | GPU-accelerated, 60fps garantizado | Nunca animar width, height, top, left |
| **Stagger máximo 20 items** | Más de 20 = sobrecarga cognitiva | Listas largas: agrupar por página |
| **layout animations solo <50 items** | ReactFlow layout animation es O(n²) | Listas grandes: quitar `layout` |
| **will-change selectivo** | Memoria GPU limitada | Solo en elementos animados continuamente |
| **prefers-reduced-motion respetado** | Accesibilidad obligatoria | Desactivar partículas, reducir duración |
| **Recompensa variable** | Error de predicción Schultz = más dopamina | Nunca la misma celebración 2 veces seguidas |

### 2.3 Catálogo de animaciones

| Animación | Cuándo | Duración | Easing | Sensación |
|-----------|--------|----------|--------|-----------|
| **Micro-tick** | Test pasa, criterio cumple | 100ms | `ease-out-back` | Satisfacción inmediata |
| **Squash & stretch** | Card completada | 200ms | `spring` | Peso físico, logro tangible |
| **Glow pulse** | Agente trabajando | 2s loop | `ease-in-out` | Energía visible, vida |
| **Slide-in** | Panel/panel lateral | 300ms | `ease-out-expo` | Entrada elegante |
| **Fade-up** | Contenido nuevo | 250ms | `ease-out-expo` | Aparición suave |
| **Confetti burst** | Milestone gated | 1200ms | `ease-out` | Celebración memorable |
| **Particle trail** | Edge activo (activité) | loop | lineal | Flujo de datos vivo |
| **Shimmer** | Loading skeleton | 1.5s loop | lineal | Espera elegante, no spinner |
| **Parallax depth** | Scroll en paneles | scroll-linked | lineal | Profundidad espacial |

## 3. Componentes visuales (F.0 primitivas expandidas)

### 3.1 Card de vidrio (GlassCard)

```css
.glass-card {
  background: var(--glass-bg);
  border: 1px solid var(--glass-border);
  border-radius: var(--radius-lg);
  padding: var(--space-5);
  backdrop-filter: blur(20px) saturate(1.5);
  box-shadow:
    var(--shadow-lg),
    inset 0 1px 0 var(--glass-highlight);
  transition: all var(--duration-normal) var(--ease-out-expo);
}

.glass-card:hover {
  border-color: oklch(0.3 0.01 260 / 0.25);
  box-shadow:
    var(--shadow-xl),
    inset 0 1px 0 var(--glass-highlight),
    var(--shadow-glow);
  transform: translateY(-2px);
}
```

### 3.2 Agente vivo (AgentNode)

```
┌─────────────────────────────────┐
│  ◉ avatar (glow ring pulsante)  │
│                                 │
│  Nombre Agente                  │
│  ROLE · status dot              │
│                                 │
│  [barra de progreso sutil]      │
│  badges: ● ● ● (activos)       │
└─────────────────────────────────┘
```

- Avatar con **anillo de glow** que pulsa según estado
- Badge de estado = punto con color + glow (nunca texto)
- Barra de progreso sutil en la parte inferior (solo cuando working)
- Hover: elevación + glow azul + nombre se ilumina

### 3.3 Edge iluminado (AnimatedBeam)

```css
/* Partícula que viaja por el edge */
.beam-particle {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--accent-primary);
  box-shadow: 0 0 12px var(--accent-primary);
  offset-path: path("M..."); /* SVG path del edge */
  animation: travel 2s linear infinite;
}

@keyframes travel {
  to { offset-distance: 100%; }
}
```

### 3.4 Toast neuro-gratificante

```
┌──────────────────────────────────────┐
│  ✔ 14 tests pasaron                 │  ← éxito: verde + check
│  ████████████████░░░░ 80%           │  ← barra de progreso
│  "PR de auth listo para revisar"     │  ← outcome, no proceso
└──────────────────────────────────────┘
```

- Nunca spinner — siempre progreso o resultado
- Éxito = mini-confetti LOCAL dentro de la card (no overlay global)
- Error = borde rojo pulsante + "¿reintentar?" (nunca "fallo")

### 3.5 Command Palette (⌘K)

```
┌─────────────────────────────────────────┐
│ 🔍 Buscar...                            │
├─────────────────────────────────────────┤
│ ▸ Abrir proyecto "MiApp"               │
│ ▸ Crear agente QA                       │
│ ▸ Ver sesiones activas                  │
│ ▸ Ejecutar test suite                   │
│                                         │
│ ⌘+1 Abrir · ⌘+2 Crear · ⌘+3 Ver      │
└─────────────────────────────────────────┘
```

- Fondo: `--bg-overlay` con `backdrop-filter: blur(30px)`
- Resultados: fade-in stagger 50ms cada uno
- Seleccionado: glow sutil + badge de hotkey
- Respuesta <50ms percibida (fuzzy-match pre-cargado)

## 4. Liquid Glass (implementación web)

### 4.1 Composición de 4 capas (de liquid-glass-web)

```
Capa 1: CSS backdrop-filter: blur(20px) saturate(1.5)
Capa 2: SVG feDisplacementMap (refracción de Snell's law)
Capa 3: Gradiente de borde (reflejo specular)
Capa 4: Sombra interior (profundidad)
```

### 4.2 Dónde aplicar Liquid Glass

| Elemento | Aplicación | Prioridad |
|----------|------------|-----------|
| **Paneles laterales** | Refracción sutil del contenido detrás | Alta |
| **Modales** | Glass completo con borde iluminado | Alta |
| **Cards del canva** | Blur + refracción ligera | Media |
| **Status bar** | Glass sutil, siempre visible | Media |
| **Command Palette** | Glass profundo, focus total | Alta |
| **Toast/notifications** | Glass ligero, transient | Baja |

### 4.3 Fallback (Firefox/Safari)

```css
@supports not (backdrop-filter: url(#displacement)) {
  .glass-panel {
    backdrop-filter: blur(20px);
    /* Sin refracción, solo blur — degradado aceptable */
  }
}
```

## 5. Neuro-psicología aplicada (犬 de PLAN U)

### 5.1 Principios visuales

| Principio | Implementación visual | Fuente |
|-----------|----------------------|--------|
| **Error de predicción Schultz** | Celebraciones con variantes aleatorias (nunca idénticas) | Schultz 1997 |
| **Aversión a pérdida calibrada** | Rachas con escudo-perdón, nunca acumulativa | Kahneman |
| **SDT (autonomía+competencia+relación)** | Recompensas que expanden opciones, nunca restringen | Deci, 128 estudios |
| **Flow de Csikszentmihalyi** | Feedback inmediato, interrupciones agrupadas | Csikszentmihalyi |
| **Test ético de incertidumbre** | Drops cosméticos transparentes, loot-boxes jamás | Ética |

### 5.2 Sensaciones por momento

```
ANTICIPACIÓN (agente trabajando)
  → Glow pulsante en nodo · partículas viajando por edges
  → "Está ocurriendo algo" · energía visible

SATISFACCIÓN (pieza completada)
  → Micro-tick 100ms · squash&stretch de card
  → Check se dibuja DENTRO de la card · sonido consonante

ORGULLO (evidencia acumulada)
  → Antes/después visible · stats · rachas honestas
  → Heatmap · nivel de agente · recap semanal

PERTENENCIA (hacia los agentes)
  → Identidad única · voz propia · evolución visible
  → Son colegas, no herramientas

CALMA CONTROLADA (modo vigilancia)
  → Todo bajo control · excepciones visibles
  → Inbox de resultados · flow-protection
```

### 5.3 Sonido (teoría musical aplicada)

| Evento | Sonido | Teoría |
|--------|--------|--------|
| Test pasa | Tick percusivo corto | Micro-logro |
| Criterio cumple | Pop grave satisfecho | Golpe físico |
| Tarea completada | Arpegio ascendente Do mayor | Consonancia, resolución |
| Error/Fallo | Tritono descendente cuadrado | Tensión, atención |
| Warning | Segunda mayor chime | Alerta suave |
| Gate cerrado | Cascata ascendente + reverb | Celebración |
| Commit | Click seco grave | Acción confirmada |

**Reglas de sonido:**
- Mute cuando la app tiene foco + cooldown global anti-spam
- Cada tipo de evento tiene chime DISTINTO (commit ≠ test ≠ deploy)
- `prefers-reduced-motion` = silencio automático
- Volumen: micro-feedback 20%, celebraciones 50%, errores 70%

## 6. Responsive + Desktop

### 6.1 Breakpoints

| Breakpoint | Comportamiento |
|------------|---------------|
| < 640px (mobile) | BottomNav, BottomSheet, sin minimap, cards apiladas |
| 640-1024px (tablet) | Sidebar colapsable, cards grid 2 columnas |
| > 1024px (desktop) | Sidebar fija, panel derecho, minimap, grid 3+ columnas |

### 6.2 Touch targets

- Mobile: mínimo 44px × 44px
- Desktop: mínimo 24px × 24px
- Spacing entre targets: mínimo 8px

## 7. Checklist de calidad visual (F.5 gate)

- [ ] Tokens oklch aplicados (no hex hardcoded)
- [ ] Contraste WCAG AA verificado (4.5:1 texto, 3:1 UI)
- [ ] Liquid Glass en paneles principales
- [ ] Animaciones solo transform + opacity
- [ ] prefers-reduced-motion respetado
- [ ] Sonido mute por defecto, opt-in
- [ ] Celebraciones con variantes aleatorias
- [ ] Loading states: skeletons, nunca spinners
- [ ] Empty states ilustrados, nunca vacíos tristes
- [ ] Responsive en 375px + 1440px
- [ ] Touch targets ≥44px mobile, ≥24px desktop
- [ ] Texto legible sin zoom
- [ ] Modales a pantalla completa en mobile
- [ ] Status bar refleja estado real
- [ ] Command Palette <50ms percibida

---

## 8. Escalera visual: Liquid Glass → Espacial → VR (v4.1)

> Toda decisión visual debe funcionar HOY en 2D con Liquid Glass **y** escalar mañana a gafas VR sin refactor. La escalera define los 3 niveles y lo que cada nivel exige a los componentes.

### 8.1 Los 3 niveles

| Nivel | Cuándo | Render | Qué exige |
|---|---|---|---|
| **L1 · Glass 2D** (hoy, MVP-1/2/3) | web + desktop | CSS/SVG (4 capas §4.1) | tokens oklch · checklist §7 · responsive 375/1440 |
| **L2 · Espacial** (post-v1) | canvas con profundidad | Three.js/WebGPU sobre SpatialMeta | coordenadas 3D (1u=1m) · z calculada por layout · capas de profundidad |
| **L3 · VR/AR gafas** (futuro) | WebXR / nativo | renderer espacial | legibilidad AR (contraste AAA) · targets ≥44px equivalentes · confort visual (sin motion sickness: solo transform/opacity) |

### 8.2 Reglas de escalabilidad (por componente — no negociables desde L1)

1. **Posición SIEMPRE por SpatialMeta** (`x,y,z?` en unidades-metro) — jamás `position:absolute` en px dentro del canvas.
2. **Tamaños relativos** al sistema del canvas (proporciones/unidades), no píxeles absolutos.
3. **Colores SOLO por token oklch** — el hex hardcodeado rompe temas y calibración AR.
4. **Animaciones solo `transform` + `opacity`** (GPU-friendly en todos los niveles).
5. **Componentes agnósticos al renderer**: GlassCard/AgentNode/AnimatedBeam se definen una vez; el nivel decide cómo proyectarlos (DOM hoy, malla 3D mañana).
6. **Profundidad Z planificada**: `z: null` en 2D; capas semánticas definidas (fondo < nodos < edges < overlays).
7. **Contraste progresivo**: AA en L1 → AAA en L3 (legibilidad en AR); la paleta oklch ya lo soporta.

### 8.3 Gates automáticos (en CI)

- `scripts/check-visual.mjs`: falla si crece la deuda (`hex` hardcodeado o `absolute` en componentes de UI vs baseline) — la deuda actual queda registrada y solo puede BAJAR.
- Contraste AA automatizado contra paleta §1.1 ([F·F.0]).
- Checklist §7 auditado en F.5 y re-auditado antes de cada tag.

### 8.4 Camino a VR (qué se construye cuándo)

| Hito | Fase | Entregable |
|---|---|---|
| Tokens + Liquid Glass | F.0 (MVP-2) | design system Obsidian Glass completo |
| SpatialMeta transversal | 3D.1 (post-v1) | schema + persistencia + roundtrip |
| Visor 3D del repo-map | J.3 (post-v1) | rotar/zoom/click a archivo, 60fps @500 archivos |
| Visor unificado 3 capas | 3D.2 (post-v1) | grafo+kanban+sesiones como capas del mismo mundo |
| WebXR | exploratorio | prototipo de lectura de Control Room en gafas |

---

## 9. Catálogo de Juice neuro-graficado (v4.2 — implementado en `src/styles.css`)

> Clases CSS listas para usar. Reglas de oro: solo `transform`/`opacity`/`filter` (GPU), tokens oklch, `prefers-reduced-motion` apaga todo. El verificador `pnpm test:visual` bloquea hex hardcodeado y absolute en canvas.

### 9.1 Animaciones (keyframes)

| Clase/keyframe | Sensación | Cuándo usar |
|---|---|---|
| `.agent-alive` | **Respiración** (scale 1→1.03 + brillo, 3.2s) | Avatar/nodo de agente `working` — "está vivo" |
| `.agent-working` | Glow pulsante en borde | Nodo activo esperando resultado |
| `.juice-success` | Squash & stretch (pop 0.45s spring) | Al completar tarea/test/entrega — 600ms y quitar |
| `.stagger > *` | Entrada flotante escalonada (80ms por hijo) | Listas/cards que aparecen — nunca todas de golpe |
| `.skeleton` + `::after` | Barra de luz barriendo (1.6s) | Carga — NUNCA spinners |
| `.edge-flow` | Dash flow en edges SVG | Conexiones activas del canva |
| `.mesh-bg` | Fondo mesh animado (2 blobs oklch drifting 24s) | Canvas vacío / onboarding / hero |

### 9.2 Micro-interacciones

| Clase/regla | Comportamiento |
|---|---|
| `.juice-hover` | Hover: levita -2px + glow · Active: press scale(0.975) instantáneo |
| `button:active` global | Press scale(0.97) — todo botón responde al tacto |
| `.item-list .item:hover` | Levita -1px + ring de acento al 12% |
| `:focus-visible` | Ring oklch 2px con offset — accesible Y bello |
| `::selection` | Marca de marca (accent 35%) |
| Scrollbar | Premium: thumb redondeado translúcido, hover más claro |

### 9.3 Liquid Glass profundidades

| Clase | Uso |
|---|---|
| `.glass-panel` + `::before` | Panel con reflejo specular superior (capa 3) |
| `.glass-deep` | Modales/palettes: blur 40px saturate 1.8 brightness 1.05 |

### 9.4 Aplicado al scaffold

`.item-list .item` (hover juice) · `.agent-avatar` (alive si working) · `.sidebar-tab` (press) · `.canvas-section.mesh-bg` (fondo vivo) · `button:active` universal.

**Regla de adición:** cada micro-interacción nueva entra AQUÍ primero (clase + sensación + cuándo), luego a CSS. Prohibido animar sin documentar en este catálogo.

---

Este SDD es la **fuente canónica** de toda decisión visual. F.0 lo referencia, la IA lo lee antes de tocar UI, y F.5 lo audita contra este checklist. La escalera §8 garantiza que nada construido hoy bloquee las gafas VR de mañana; el catálogo §9 hace que TODO se sienta vivo.
