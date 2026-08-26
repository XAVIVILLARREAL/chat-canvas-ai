# PLAN I18N — Multilenguaje desde el día 1 (sencillo, muchos idiomas)

> **Producto:** Canvas AI · **Estado:** aprobado (Q3) · 2026-08-25
> **Decisión:** soporte **multilenguaje simple** desde el primer componente. No es solo es/en: el mecanismo hace trivial añadir cualquier idioma.
> **✅ IMPLEMENTADO (infra, 2026-08-25):** `src/i18n/` (hook `useI18n` + locales es/en JSON + fallback en + detección navigator) + selector en Header/Config. Fases I.1/I.2 restantes: cobertura completa de strings y script CI de claves.

---

## 1 · Enfoque (lo más simple que escala)

| Elección | Por qué |
|---|---|
| **Diccionarios JSON** por idioma (`locales/es.json`, `locales/en.json`, `locales/de.json`…) | Sin framework pesado; un archivo = un idioma |
| **Hook `useI18n()`** ligero (React Context) con `t('key', {vars})` | ~40 líneas, sin deps nuevas |
| **Detección automática** (navigator.language / preferencia del OS) + selector en Config | Primer arranque ya en tu idioma |
| **Fallback a `en`** para claves faltantes | Traducción parcial nunca rompe la UI |
| **Claves planas** con nombres semánticos (`session.new`, `agent.invoke`) | Fácil de auditar qué falta |
| RTL-ready (dirección `rtl` por locale) | Árabe/hebreo sin refactor futuro |
| Pluralización/inflexión con formato ICU minimal (`{n, plural, one{# item} other{# items}}`) | Correcto en todos los idiomas |

**Veredicto:** se descarta i18next/react-intl completo — un solo dev no necesita esa maquinaria en v1; el diccionario JSON + hook es mantenible y migrable si algún día se necesita.

## 2 · Reglas obligatorias

1. **NUNCA strings hardcodeadas** en JSX — todo pasa por `t()` o el diccionario.
2. **`locales/es.json` = idioma por defecto** y fuente canónica (los demás se copian de ahí y se traducen).
3. Script de CI: **falla si hay claves faltantes** entre idiomas (`scripts/i18n-check.mjs`).
4. Tiempo legible por idioma (fechas con `Intl.DateTimeFormat(locale)`), números con `Intl.NumberFormat`.
5. El **nombre del producto y los skills** no se traducen (marcas/personajes).
6. Móvil 375 + desktop 1440: strings largos nunca rompen layout (text-wrap balance, truncate con título).
7. Los **IDs de eventos y claves técnicas** van en inglés; solo la UI se traduce.

## 3 · Idiomas iniciales (lanzamiento MVP-1)

`es` (default) · `en` · `pt` · `de` · `fr` · `it`. Añadir uno nuevo = crear `locales/xx.json` + 1 línea en el registro. (Base de las 6 lenguas más usadas por la audiencia dev; el mecanismo admite cualquiera.)

## 4 · A11y e i18n juntos

- `aria-label`s también traducidos (desde el mismo diccionario).
- Contraste AA en **todos los idiomas** (son tokens, no dependen del texto) — [plan-t](./plan-t-excelencia.md#ta11y).
- Documentos del producto (PRD/plan) en español, UI multilenguaje.

## 5 · Fases y gate

- **I.1 — Infraestructura** (en Etapa 0): registro de locales, hook `useI18n`, detección, fallback. *Test:* unit del hook + snapshot de diccionario.
- **I.2 — Cobertura UI** (desde F.1 en adelante): toda vista nueva traduce. *Gate humano:* suite dual es+en sobre cada gate (Playwright `locale`).

## Gate humano I18N

Abro la app con `locale=de` → toda la UI en alemán → cambio a `pt` en Config → sin recargar se actualiza → una clave en alemán falta → se ve el fallback en inglés, sin romper. Suite humana verde (móvil+desktop).
