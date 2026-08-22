# Referencia de diseño

> Catálogo de los recursos de diseño visual instalados en `reference/`. Clonados el 2026-08-21 (shallow, depth 1). Estrellas verificadas esa fecha vía API de GitHub.
> Regla general: **la IA decide qué skill usar por tarea** buscando el resultado más impactante (ver AGENTS.md → Recursos de diseño visual).

## Resumen rápido

| # | Recurso | Origen | ★ | Ruta local | Rol |
|---|---|---|---|---|---|
| 1 | apple-design-skill (dickwu) | https://github.com/dickwu/apple-design-skill | 74 | `reference/apple-design-skill/` | Auditor UI/UX (HIG) |
| 2 | ui-ux-pro-max | https://github.com/nextlevelbuilder/ui-ux-pro-max-skill | 119.3k | `reference/ui-ux-pro-max/` | Catálogo de estilos y paletas |
| 3 | impeccable (pbakaus) | https://github.com/pbakaus/impeccable | 61.4k | `reference/impeccable/` | Pulido anti-"estética IA genérica" |
| 4 | liquid-glass-web (Zettersten) | https://github.com/Zettersten/skills | — | `reference/liquid-glass-web/` | Liquid Glass técnico en web |
| 5 | magic-ui | https://github.com/magicuidesign/magicui | 22k | `reference/magic-ui/` | Componentes animados "wow" |
| 6 | react-bits | https://github.com/DavidHDev/react-bits | 45.9k | `reference/react-bits/` | Componentes interactivos de alto impacto |

---

## 1. apple-design-skill (dickwu)

- **Link:** https://github.com/dickwu/apple-design-skill
- **Qué es:** Revisor y auditor de UI/UX basado estrictamente en las Apple Human Interface Guidelines (HIG), traducidas a reglas universales multiplataforma. Funciona con Flutter, Tauri, Electron, React Native y web.
- **Contenido local:**
  - `SKILL.md` — metodología de revisión, framework de auditoría, sistema de severidad
  - `references/hig/` — 53 guías: color, tipografía, accesibilidad, dark mode, gestos, liquid-glass, etc.
  - `references/hig-lookup.md` — tabla de ruteo tema→archivo
- **Cómo se usa:** Para auditar UI existente o validar antes de entregar. Ejemplo: *"Revisa esta pantalla contra las guías de accesibilidad y dark mode del HIG"*.
- **Actualizar:** `git -C reference/apple-design-skill pull`

## 2. ui-ux-pro-max (nextlevelbuilder)

- **Link:** https://github.com/nextlevelbuilder/ui-ux-pro-max-skill
- **Qué es:** El catálogo de diseño más grande del ecosistema (~119k★). Motor de recomendación que devuelve un sistema de diseño completo (estilo + paleta + tipografía + reglas) en una consulta.
- **Contenido local:**
  - `.claude/skills/ui-ux-pro-max/SKILL.md` — skill principal
  - `cli/assets/skills/` — skills derivados: `design`, `ui-styling`, `design-system`, `brand`, `banner-design`, `slides`
  - Base de datos: 84 estilos (glassmorphism, claymorphism, brutalismo…), 192 paletas, 74 pares tipográficos, 98 reglas UX
- **Cómo se usa:** Al iniciar una pantalla nueva, para elegir estilo + paleta + tipografía coherente. Soporta Tailwind y shadcn.
- **Actualizar:** `git -C reference/ui-ux-pro-max pull`

## 3. impeccable (pbakaus)

- **Link:** https://github.com/pbakaus/impeccable
- **Qué es:** Lenguaje de diseño compartido con la IA para evitar la "estética genérica de IA". De Paul Bakaus (creador de jQuery UI). ~61k★.
- **Contenido local:**
  - `plugin/skills/impeccable/SKILL.md` — entrada canónica
  - Referencias: tipografía, color, motion, spatial, interaction, responsive, UX writing + registro brand-vs-product
  - Comandos: `polish`, `audit`, `critique`, `animate`, `bolder`, `quieter`, `distill`
- **Cómo se usa:** Como capa de pulido sobre cualquier pantalla terminada. Ejecutar `audit` o `polish` antes de cerrar un gate visual.
- **Actualizar:** `git -C reference/impeccable pull`

## 4. liquid-glass-web (Zettersten)

- **Link:** https://github.com/Zettersten/skills (skill: `liquid-glass`)
- **Qué es:** Implementación técnica del Liquid Glass real de Apple (iOS/macOS 26) para web: CSS `backdrop-filter` + SVG `feDisplacementMap` (refracción de borde, no solo blur).
- **Contenido local (`skills/liquid-glass/`):**
  - `SKILL.md` — composición en 4 capas + triggers
  - `scripts/generate-displacement-map.py` — generador sin dependencias (SDF + ley de Snell)
  - `references/physics.md`, `references/filter-pipeline.md`
  - `assets/templates/` — botón, card, navbar pill y componente React `LiquidGlass.tsx`
- **Compatibilidad:** efecto completo solo en Chrome/Chromium; Firefox/Safari degradan a blur esmerilado.
- **Cómo se usa:** Cuando una superficie necesita vidrio creíble (paneles del canva, modales flotantes).
- **Actualizar:** `git -C reference/liquid-glass-web pull`

## 5. magic-ui

- **Link:** https://github.com/magicuidesign/magicui
- **Qué es:** Librería "para design engineers": 150+ componentes animados React + TypeScript + Tailwind + Motion (MIT), compañera de shadcn/ui. ~22k★. Incluye su propio skill de agente y servidor MCP oficial.
- **Contenido local:**
  - `skills/magic-ui/SKILL.md` — skill nativo para agentes
  - Componentes destacados para este proyecto:
    - `Border Beam` / `Shine Border` — bordes iluminados animados
    - `Animated Beam` — aristas de luz entre nodos (ideal para conexiones del canva)
    - Meteors, Particles, Dot/Grid patterns — fondos vivos
    - Aurora Text, Animated Shiny Text, Number Ticker — tipografía cinética
    - Shimmer/Rainbow Button, Neon Gradient Card, Bento Grid, Dock, Globe 3D
- **Cómo se usa:** Copiar componentes al proyecto cuando una pieza necesita impacto visual inmediato.
- **Actualizar:** `git -C reference/magic-ui pull`

## 6. react-bits

- **Link:** https://github.com/DavidHDev/react-bits
- **Qué es:** Colección open source de componentes React animados, interactivos y personalizables (~46k★), con variantes JS/TS y CSS/Tailwind.
- **Contenido local:**
  - `AGENTS/SKILLS/` — 4 skills propios para agentes:
    - `find-animation-opportunities` — detectar dónde animar
    - `improve-animations` / `review-animations` — mejorar y auditar motion
    - `apple-design` — versión condensada de principios Apple
  - Componentes: Spotlight Cards, Click Spark, fondos Silk/Aurora, Blur Text, Glare Hover, contadores animados
- **Cómo se usa:** Sus skills sirven como proceso para encontrar oportunidades de animación; los componentes se copian bajo demanda.
- **Actualizar:** `git -C reference/react-bits pull`

---

## Otros recursos en `reference/` (no son de diseño)

| Recurso | Origen | Uso |
|---|---|---|
| zed | https://github.com/zed-industries/zed (submodule) | Referencia de código Rust/editor |
| v3code | ver `reference/v3code/README.md` | Arquitectura de memoria en 3 capas, Memory Rail, auto model router |

## Evaluados pero NO instalados

| Recurso | Link | Motivo |
|---|---|---|
| s1gamale1/apple-design-skills | https://github.com/s1gamale1/apple-design-skills | Buen módulo de motion/scrollytelling, pero muy nuevo (7★, 1 commit) y orientado a páginas marketing |
| Ethelye/apple-like-ui-skill | https://github.com/Ethelye/apple-like-ui-skill | Se solapa con dickwu (0★); prescindible |
| Leonxlnx/taste-skill | https://github.com/Leonxlnx/taste-skill | Alternativa a impeccable (79k★); elegir uno solo anti-genérico |
| nexu-io/open-design | https://github.com/nexu-io/open-design | 19 skills + 71 sistemas, pero huella pesada |
| alchaincyf/huashu-design | https://github.com/alchaincyf/huashu-design | 20 escuelas de diseño nombradas; útil si queremos variedad filosófica |
| google-labs-code/stitch-skills | https://github.com/google-labs-code/stitch-skills | Requiere MCP de Stitch (Google Labs) |
| anthropics/skills | https://github.com/anthropics/skills | Oficial (170k★): candidatos futuros `canvas-design`, `theme-factory`, `frontend-design`, `webapp-testing` |

## Cómo elegir (decide la IA)

1. La IA elige skill y estilo según la tarea, buscando siempre el resultado más impresionante
2. Puede combinar: ui-ux-pro-max (elegir estilo) → magic-ui / react-bits (componentes) → liquid-glass-web (vidrio) → impeccable (pulir) → apple-design-skill (auditar)
3. No mezclar dos estilos prescriptivos contradictorios en la misma pantalla
4. Criterio final intransferible: jerarquía clara, contraste WCAG AA, motion con propósito, coherencia entre pantallas

## Instalación desde cero

```powershell
cd reference
git clone --depth 1 https://github.com/dickwu/apple-design-skill.git apple-design-skill
git clone --depth 1 https://github.com/nextlevelbuilder/ui-ux-pro-max-skill.git ui-ux-pro-max
git clone --depth 1 https://github.com/pbakaus/impeccable.git impeccable
git clone --depth 1 https://github.com/Zettersten/skills.git liquid-glass-web
git clone --depth 1 https://github.com/magicuidesign/magicui.git magic-ui
git clone --depth 1 https://github.com/DavidHDev/react-bits.git react-bits
```

Nota: `reference/` está en `.gitignore` — estos recursos son locales y no se versionan en el repo del proyecto.
