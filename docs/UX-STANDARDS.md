# UX-STANDARDS — Atajos, estados de UI y ayuda (estándar transversal)

> **Producto:** Canvas AI · **Estado:** v1.0 · 2026-08-25 · Complementa [SDD-013](./SDDs/SDD-013-gui-visual-spec.md) (visual) y [T.ONB](./SDDs/SDD-001-plan-base/plan-t-excelencia.md#tonb) (onboarding)

## 1 · Atajos de teclado (estándar)

| Atajo | Acción | Fase |
|---|---|---|
| `⌘/Ctrl+K` | Command Palette global | F.7 |
| `⌘/Ctrl+N` | Nueva sesión | A.1 |
| `⌘/Ctrl+S` | Guardar canvas | — |
| `⌘/Ctrl+E` | Enfocar editor | B.2 |
| `⌘/Ctrl+Shift+P` | Cambiar proyecto | A.0 |
| `⌘/Ctrl+/` | Cheatsheet de atajos | T.ONB |
| `/` | Slash commands (en el input del chat) | A.4 |
| `Esc` | Cerrar modal/panel | — |
| `⌘/Ctrl+Z / +Shift+Z` | Deshacer / rehacer | canvas |

Regla: todo atajo es **descubrible** (cheatsheet ⌘/), **documentado** y probado en la suite humana (teclado 100%).

## 2 · Estados de UI obligatorios (cada vista)

| Estado | Qué se muestra | Regla |
|---|---|---|
| **Carga** | skeleton (no spinner gigante) | <300ms → nada; >300ms → skeleton |
| **Vacío** | empty-state educativo que enseña qué hace la vista + acción principal | ninguna vista "en blanco" |
| **Error** | mensaje accionable + retry | nunca pantalla muerta; ErrorBoundary por ventana |
| **Offline** | banner global "sin conexión — cambios locales" + indicador de cola | local-first siempre operativo |
| **Streaming** | cursor/indicador + `aria-live="polite"` | accesibilidad |
| **Saving** | indicador sutil de persistencia | nunca bloquear la edición |

## 3 · Ayuda en la app

- **Tooltips progresivos** según uso (primeras 3 veces de cada vista).
- **Cheatsheet ⌘/** con atajos + búsqueda.
- **"¿Qué es esto?"** en cada panel (icono ⓘ → 1 línea + link a docs).
- **Diagnóstico exportable** para soporte (sin datos sensibles) en Ajustes → Soporte.
- **Guía in-app** (primeros pasos) reutiliza el onboarding de T.ONB.

## 4 · Anti-patrones (no hacer)

- Modales anidados · toasts por cada acción trivial · cambios sin feedback · botones deshabilitados sin explicación · spinners infinitos · strings hardcodeadas (i18n).

## 5 · Verificación

- Suite humana por gate: cada vista nueva se opera en vacío/error/offline/loading (truco: throttle de red en Playwright) + navegación 100% teclado + móvil 375/desktop 1440.
