# SDD — Estilo Visual Futurista (Glassmorphism Neón + IA Autónoma)

> **Objetivo:** llevar toda la UI a un lenguaje **glassmorphism de cristal con
> contornos de luz, efectos neón sutiles, tech-grid de píxeles y animaciones
> fluidas**, que comunique *sistema de IA autónoma de la siguiente era*.
>
> Directiva obligatoria en `AGENTS.md` (§ Identidad visual). Este SDD define el
> **cómo** y las **fases** con sus gates.

---

## 1. Concepto

La app es un "cristal que flota sobre una cuadrícula de holograma". Cada panel,
tarjeta y diálogo es un **cristal translúcido** con luz entrando por el borde
superior, y **glow neón** solo en lo que está activo/importante (conexiones,
agentes, nodos del canva). El resultado debe sentirse como operar una
**consola de IA autónoma**, no como una app de gestión.

## 2. Sistema de diseño

### 2.1 Tokens (semilla)

| Token | Valor | Uso |
|---|---|---|
| `bg-base` | `#0F172A` | Fondo base |
| `bg-panel` | `white 6%` | Cristal base |
| `bg-panel-hi` | `white 10%` | Cristal elevado (diálogos) |
| `neon-cyan` | `#22D3EE` | Contornos, focus, acentos |
| `neon-violet` | `#A855F7` | Agentes IA |
| `neon-green` | `#4ADE80` | Conectado / éxito |
| `edge-light` | `white 0.85 → 0` | Borde superior de cristal |
| `grid` | `white 3%` | Tech-grid de fondo |

### 2.2 Widgets reutilizables (nuevos en `lib/widgets/`)

| Widget | Descripción |
|---|---|
| `GlassPanel` | Contenedor translúcido + blur + borde de luz superior + radius 20 |
| `NeonCard` | Tarjeta con glow cian/violeta opcional + estado activo |
| `NeonBackdrop` | Fondo con tech-grid + halos de luz (una sola vez por screen) |
| `GlassDialog` | Reemplazo de `AlertDialog` (cristal + borde de luz) |
| `GlassTextField` | Input con borde luminoso en focus |
| `StatusDot` | Punto de estado con glow (idle/working/blocked/done) |
| `NeonDivider` | Línea divisoria con gradiente de luz |

## 3. Fases (cada una con gate)

### Fase 0 — Base del tema (FUNDACIÓN)
- Crear `lib/theme/` con tokens (`AppColors`, `AppRadii`, `AppSpacing`).
- Definir `ThemeData` oscuro custom (no `fromSeed` por defecto) con
  `scaffoldBackgroundColor: bg-base`, botones/inputs con esquinas grandes.
- Aplicar `NeonBackdrop` en `HostsScreen` (root).
- **Gate:** `melos analyze` 0 issues + widget test que renderiza la raíz sin error.

### Fase 1 — Cristales (paneles, tarjetas, diálogos)
- Crear `GlassPanel`, `NeonCard`, `GlassDialog`.
- Migrar: tarjetas de host (`TabsScreen`), diálogo "Agregar host",
  SnackBars, y los paneles del hub.
- **Gate:** screenshots + tests de widgets existentes siguen pasando.

### Fase 2 — Canva futurista
- Nodos de host/agente/nota con cristal + glow al conectar.
- Estados de agente con `StatusDot` (glow cyan=working, violet=blocked).
- Grid de fondo en el canva (tech-grid).
- **Gate:** test de `canva_screen` sigue pasando + evidencia visual.

### Fase 3 — Terminal + SFTP
- Barra de título del terminal con cristal; el terminal mismo sin blur
  (performance), solo borde de luz superior.
- Panel de teclas SSH y SFTP con `GlassPanel`.
- **Gate:** `ssh_terminal_test` (whoami→root) sigue PASS.

### Fase 4 — Pule animaciones
- Transiciones de pantalla con `fade + slide` (300ms, `easeOutCubic`).
- Entradas destacadas (diálogos, tarjetas nuevas) con `elasticOut`.
- Micro-interacciones: hover glow, foco de input.
- **Gate:** `melos analyze` + tests verdes.

### Fase 5 — Auditoría anti-patterns
- Barrido: no quedan `AlertDialog`/`Card` planos, ni fondos grises sordos.
- Performance: `BackdropFilter` solo en paneles estáticos.
- **Gate:** checklist de anti-patterns vacío.

## 4. Performance (reglas duras)

1. **`BackdropFilter` cuesta.** Solo en paneles que cambian poco (header,
   diálogos, tarjetas fijas). NUNCA en listas virtualizadas (terminal scroll,
   lista de hosts larga) — ahí usar color translúcido simple + borde de luz.
2. Glow = `BoxShadow`, nunca `BackdropFilter`.
3. Animaciones ≤350ms. Sin `infinite` en elementos de la lista.

## 5. Evidencia

- Screenshots por fase en `data/evidence/` (`ui-faseN-*.png`).
- Un bug visual solo está "arreglado" si el test + screenshot lo demuestran.

## 6. Checklist por tarea visual

- [ ] Usé `GlassPanel`/`NeonCard` en vez de paneles planos.
- [ ] Borde superior de luz presente en cada cristal.
- [ ] Glow solo en elementos activos/importantes.
- [ ] Fondo con tech-grid sutil (una vez por screen).
- [ ] Animación ≤350ms, curva fluida.
- [ ] `melos analyze` + tests verdes.

## 7. Estado de ejecución

- ✅ **Fase 0 (base del tema)** — `lib/theme/app_theme.dart` (tokens + tema
  futurista), `lib/widgets/neon_backdrop.dart` (tech-grid + halos),
  `lib/widgets/glass_panel.dart` (cristal + borde de luz),
  `lib/widgets/neon_card.dart` (glow). Aplicado en `main.dart` (NeonBackdrop)
  y en las tarjetas de host (`TabsScreen`) con glow verde al conectar.
  Evidencia: `data/evidence/ui-fase0-glassmorphism.png`.
- ⬜ **Fase 1 (cristales en paneles/diálogos)** — pendiente.
- ⬜ **Fase 2 (canva futurista)** — pendiente.
- ⬜ **Fase 3 (terminal + SFTP)** — pendiente.
- ⬜ **Fase 4 (animaciones)** — pendiente.
- ⬜ **Fase 5 (auditoría anti-patterns)** — pendiente.
