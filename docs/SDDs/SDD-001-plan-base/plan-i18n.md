# PLAN I18N — Multilenguaje con traducción automática (12 idiomas)

> **Producto:** Canvas AI · **Estado:** aprobado v2 · 2026-08-25
> **Decisión:** soporte multilenguaje con **pipeline de traducción automática** (AI-powered). 12 idiomas SaaS estándar, trivial añadir más.
> **✅ IMPLEMENTADO (infra):** `src/i18n/` (hook `useI18n` + locales es/en JSON + fallback en + detección navigator) + selector en Header/Config.
> **🔲 PENDIENTE:** expandir a 12 idiomas, pipeline de traducción automática, cobertura completa de strings.

---

## 1 · Enfoque

| Elección | Por qué |
|---|---|
| **Diccionarios JSON** por idioma (`locales/es.json`, `locales/en.json`…) | Sin framework pesado; un archivo = un idioma |
| **Hook `useI18n()`** ligero (React Context) con `t('key', {vars})` | ~40 líneas, sin deps nuevas |
| **Detección automática** (navigator.language / preferencia del OS) + selector en Config | Primer arranque ya en tu idioma |
| **Fallback a `en`** para claves faltantes | Traducción parcial nunca rompe la UI |
| **Claves planas** con nombres semánticos (`session.new`, `agent.invoke`) | Fácil de auditar qué falta |
| **Pipeline AI** de traducción automática (OpenAI/Anthropic/Ollama) | Traducir 12 idiomas sin manual work |
| RTL-ready (dirección `rtl` por locale) | Árabe/hebreo sin refactor futuro |
| Pluralización ICU minimal (`{n, plural, one{# item} other{# items}}`) | Correcto en todos los idiomas |

## 2 · Reglas obligatorias

1. **NUNCA strings hardcodeadas** en JSX — todo pasa por `t()` o el diccionario.
2. **`locales/en.json` = fuente canónica** (los demás se traducen de ahí).
3. Script CI: **falla si hay claves faltantes** entre idiomas (`scripts/i18n-check.mjs`).
4. Fechas con `Intl.DateTimeFormat(locale)`, números con `Intl.NumberFormat`.
5. **Nombre del producto y skills** no se traducen (marcas/personajes).
6. Móvil 375 + desktop 1440: strings largos nunca rompen layout.
7. IDs de eventos y claves técnicas en inglés; solo UI se traduce.
8. Cada idioma nuevo pasa por: AI translate → human review → merge.

## 3 · 12 Idiomas SaaS (orden de prioridad)

| # | Locale | Idioma | Mercado | Fase |
|---|--------|--------|---------|------|
| 1 | `en` | English | Global (fuente) | ✅ existente |
| 2 | `es` | Español | LATAM + España (500M+) | ✅ existente |
| 3 | `zh-CN` | 简体中文 | Mayor mercado digital | P1 |
| 4 | `pt-BR` | Português | Brasil (mayor SaaS LATAM) | P1 |
| 5 | `de` | Deutsch | Mayor economía EU | P1 |
| 6 | `fr` | Français | Europa + África francófona | P1 |
| 7 | `ja` | 日本語 | Alto LTV, mercado desktop | P2 |
| 8 | `ko` | 한국어 | Tech-savvy, alta adopción SaaS | P2 |
| 9 | `ar` | العربية | RTL, mercado creciente | P3 (RTL) |
| 10 | `hi` | हिन्दी | India masivo | P2 |
| 11 | `it` | Italiano | EU completo | P1 |
| 12 | `ru` | Русский | Dev/creative market | P2 |

**MVP**: en + es + zh-CN + pt-BR + de + fr + it (7 idiomas, ~80% demanda SaaS).

## 4 · Pipeline de traducción automática

```
en.json (fuente) → scripts/translate.ts → AI Engine → locale.json (draft)
                                              ↓
                                    OpenAI / Anthropic / Ollama
                                    Batch 50 keys, provider-agnostic
                                              ↓
                                    Human review (opcional) → approved
```

### Script `scripts/translate.ts`

- **Input**: locale目标 (ej: `de`)
- **Lee** en.json, compara con locale existente, traduce solo keys faltantes
- **Batch**: 50 keys por llamada API (evita rate limits)
- **Providers**: OpenAI (default), Anthropic, Ollama (local, gratis)
- **Output**: locale.json anidado, preservando estructura
- **Costo estimado**: ~$0.01-0.05 por idioma completo (~200 keys)

### Uso

```bash
# Traducir a alemán con OpenAI
TRANSLATION_API_KEY=sk-... npx tsx scripts/translate.ts de

# Traducir a chino con Ollama local (gratis)
TRANSLATION_PROVIDER=ollama npx tsx scripts/translate.ts zh-CN

# Detectar claves faltantes sin traducir
npx tsx scripts/translate.ts --check pt-BR
```

## 5 · A11y e i18n juntos

- `aria-label`s traducidos (mismo diccionario).
- Contraste AA en todos los idiomas (tokens, no dependen del texto).
- RTL: `dir="rtl"` en `<html>` + Tailwind logical properties (`ps-`/`pe-`).

## 6 · Fases

| Fase | Qué | Duración | Gate |
|------|-----|----------|------|
| **I.1** | Infra: registro locales, hook, detección, fallback | 1 semana | ✅ Ya hecho (es/en) |
| **I.2** | Pipeline: `scripts/translate.ts` + 5 idiomas (zh-CN, pt-BR, de, fr, it) | 1 semana | Suite humana 7 idiomas verde |
| **I.3** | Cobertura: todas las vistas usan `t()`, zero strings hardcodeadas | 2 semanas | `i18n-check.mjs` CI verde |
| **I.4** | +5 idiomas: ja, ko, hi, ru, ar (pipeline ya funcional) | 1 semana | Suite humana 12 idiomas |
| **I.5** | RTL: ar con layout invertido, Tailwind logical properties | 1 semana | Visual check ar locale |

## 7 · Gate humano I18N

Abro la app → selector de idioma muestra 12 opciones → cambio a `zh-CN` → UI en chino → cambio a `de` → UI en alemán → recargo → persiste → una clave falta → fallback a `en` sin romper. Suite humana verde (móvil+desktop) en ≥3 idiomas al azar.
