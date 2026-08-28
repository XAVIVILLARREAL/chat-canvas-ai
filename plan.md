# PLAN: Multi-Idioma con Traducción Automática (12 idiomas SaaS)

> **Producto:** Canvas AI · **Inicio:** 2026-08-25 · **Autor:** Planificador pla
> **Referencia canónica:** `docs/SDDs/SDD-001-plan-base/plan-i18n.md`

---

## §1.7 — Resumen intermedio

| Campo | Contenido |
|---|---|
| 🎯 Idea (1 frase) | Expandir Canvas AI de 2 idiomas (es/en) a 12 idiomas SaaS con traducción automática via AI |
| 👤 Usuario y dolor | Devs international necesitan UI en su idioma; 12 idiomas = ~90% mercado SaaS global |
| 💰 Monetización | Multi-idioma incrementa retención y expands TAM (mercado addressable) |
| 🛠️ Stack principal | React + custom hook `useI18n` + JSON dictionaries + `scripts/translate.ts` (OpenAI/Ollama) |
| ⚠️ Top 3 riesgos | 1) Calidad de traducciones AI 2) RTL layout (ar) 3) Strings hardcodeados sin detectar |
| 📏 Métricas de éxito | 12 idiomas con 100% coverage · CI catcha missing keys · Suite humana verde en ≥3 idiomas |
| ✅ ASUMIDO por confirmar | en=json fuente · fallback chain: exacto→parcial→en · pipeline batch 50 keys |

---

## §1 · Discovery

### §1.1 Problema y usuario

- **¿Quién?** Desarrolladores y profesionales no-angloparlantes que usan Canvas AI
- **¿Dolor?** UI solo en es/en → excluye mercados enormes (zh-CN, pt-BR, de, ja)
- **¿Cómo resuelve?** 12 idiomas nativos, detectados automáticamente, con traducción AI para facilitar adding nuevos

### §1.2 Alcance y no-objetivos

| SÍ entra | NO entra (explícitamente) |
|----------|--------------------------|
| 12 idiomas SaaS (en/es/zh-CN/pt-BR/de/fr/ja/ko/ar/hi/it/ru) | Traducción de contenido generado por AI (eso es otro feature) |
| Pipeline de traducción automática | RTL completo para ar/he (solo ar en P3) |
| Selector de idioma en Settings | Localización de assets (imágenes por cultura) |
| Fallback a en para keys faltantes | i18next/react-intl (demasiado pesado para v1) |
| Formato Intl (fechas/números/moneda) | Traducción de menus nativos Tauri |

### §1.3 Modelo de negocio

Multi-idioma = **mayor TAM**. Un SaaS con 12 idiomas cubre ~90% del mercado de software global. Costo marginal ~$0.10-0.50 total (AI translate) + ~20h dev.

### §1.4 Stack

| Capa | Elección | Alternativa descartada | Por qué |
|------|----------|----------------------|---------|
| i18n runtime | Custom hook `useI18n` (~40 LOC) | i18next (8KB gz) | Suficiente para v1, cero deps |
| Locale files | JSON dictionaries | ICU/PO/XLIFF | Simple, git-friendly, audit-friendly |
| Traducción | `scripts/translate.ts` + AI | Manual / Crowdin / Lokalise | AI es gratis (Ollama) o ~$0.10 (OpenAI) |
| Formato | `Intl` API nativa | date-fns/moment | Zero deps, built-in en todos los runtimes |
| RTL | Tailwind logical properties | CSS custom | Ya soportado, sin refactor |

### §1.5 No funcionales

- **Performance**: locales lazy-loaded (~1-5KB gz c/u), solo el activo se carga
- **Seguridad**: sin datos sensibles en traducciones, solo UI strings
- **A11y**: aria-labels traducidos, contraste AA universal

### §1.6 Operación

- **Who ops**: el mismo dev (pipeline CI automatiza detection de missing keys)
- **SLA**: fallback a en garantiza que la UI nunca se rompe

---

## §5 · Stack técnico detallado

### Runtime i18n (ya implementado)

```
src/i18n/
├── index.ts          # useI18n hook, detect(), SUPPORTED_LOCALES
└── locales/
    ├── en.json       # fuente canónica
    ├── es.json       # español
    ├── zh-CN.json    # chino simplificado (P1)
    └── ...
```

### Pipeline de traducción (nuevo)

```
scripts/
└── translate.ts      # AI translation script (provider-agnostic)
```

### CI checks

```
scripts/
├── i18n-check.mjs    # detecta missing keys entre locales
└── check-coverage.mjs # ya existe, agregar i18n rows
```

---

## §6 · Modelo de datos

### Estructura locale JSON

```json
{
  "common": { "save": "Save", "cancel": "Cancel", ... },
  "canvas": { "title": "AI Canvas", "nodes.add": "Add Node", ... },
  "settings": { "language": "Language", ... }
}
```

### Claves: planas con dot-notation, camelCase, sin texto inglés como key

### Pluralización: sufijo `_plural` (i18next-style) o ICU `{n, plural, ...}`

---

## §7 · Roadmap (5 fases)

| Fase | Qué | Duración | Dependencia | Gate |
|------|-----|----------|-------------|------|
| **I.1** | Infra i18n (✅ ya hecho) | 1 semana | — | hook funcional, es/en |
| **I.2** | Pipeline AI + 5 idiomas (zh-CN, pt-BR, de, fr, it) | 1 semana | I.1 | translate.ts funcional, 7 locales |
| **I.3** | Cobertura UI: zero strings hardcodeadas | 2 semanas | I.2 | i18n-check CI verde |
| **I.4** | +5 idiomas (ja, ko, hi, ru, ar) | 1 semana | I.3 | 12 locales completos |
| **I.5** | RTL ar + Tailwind logical properties | 1 semana | I.4 | Visual check ar locale |

**Total estimado**: ~6 semanas (1 persona)

**Integración con Etapa 0:** I.1+I.2 van en slice 0.7 de ETAPA-0-IMPLEMENTACION. Todo el resto (I.3-I.5) corre transversalmente desde Etapa 1 en adelante — cada feature nueva DEBE incluir sus strings i18n en el mismo PR (regla en COVERAGE-GUI §5 + EJECUCION-ORDEN DoD).

---

## §8 · Features del producto (ligadas a fases)

| Feature | Fase | Descripción |
|---------|------|-------------|
| F-i18n-1 | I.1 | Hook `useI18n` + detección + fallback (✅ hecho) |
| F-i18n-2 | I.2 | Pipeline de traducción automática + 5 idiomas nuevos |
| F-i18n-3 | I.3 | Cobertura 100% strings UI + CI check |
| F-i18n-4 | I.4 | 12 idiomas completos |
| F-i18n-5 | I.5 | RTL layout para ar |

---

## §9 · Testing

### Suite humana i18n (Playwright CLI)

| Test | Qué verifica | Idiomas |
|------|-------------|---------|
| Selector idioma | Cambio instantáneo sin recargar | Todos |
| Persistencia | Recarga mantiene idioma | Todos |
| Fallback | Key falta → muestra en, sin romper | Aleatorio |
| Layout | Strings largos no desbordan | zh-CN, de, ru |
| Formato | Fechas/números format correcto | Todos |

---

## §11 · Riesgos

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|--------|-------------|---------|------------|
| R1 | Traducciones AI de baja calidad | Media | Medio | Human review para idiomas principales |
| R2 | RTL rompe layout existente | Alta | Alto | Diferido a P3, Tailwind logical properties |
| R3 | Strings hardcodeadas no detectadas | Media | Bajo | i18n-check.mjs en CI |
| R4 | Locale files crecen mucho | Baja | Bajo | ~1-5KB gz por locale, lazy loading |

---

## §13.5 · Detector de huecos

| Hueco | Estado |
|-------|--------|
| ¿Pipeline de traducción documentado? | ✅ plan-i18n.md §4 |
| ¿12 idiomas priorizados? | ✅ plan-i18n.md §3 |
| ¿CI check para missing keys? | ✅ plan-i18n.md §2.3 |
| ¿RTL considerado? | ✅ diferido a P3 con justificación |
| ¿Formato fechas/números? | ✅ Intl API nativa |
| ¿Testing por idioma? | ✅ §9 de este plan |

---

## §14 · Historial de cambios

| Fecha | Cambio |
|-------|--------|
| 2026-08-25 | Plan-i18n.md creado (v1): 6 idiomas, infra básica |
| 2026-08-25 | plan-i18n.md expandido a v2: 12 idiomas + pipeline AI automático |
| 2026-08-25 | plan.md creado siguiendo template pla |
| 2026-08-27 | Fase I.2 completada: translate.ts + i18n-check.mjs + 5 locales (zh-CN, pt-BR, de, fr, it) + Locale type extendido a 7 idiomas |

---

## §15 · Notas de ejecución (living log)

### §15.0 Quick Resume

- **Última sesión**: 2026-08-27 — i18n CERRADO (I.1–I.5) + **Etapa 0 slices 0.1–0.4 y 0.5 COMPLETOS** (SQLite + Postgres/RLS + ledger + BYOK vault + sandbox Linux)
- **Fase actual**: Etapa 0 de [ETAPA-0-IMPLEMENTACION](docs/ETAPA-0-IMPLEMENTACION.md) — orden estricto 0.1→0.8
- **Próxima acción**: **slice 0.6** — OpenAPI del gateway (specta → openapi.yml, tipos generados para el frontend)
- **Progreso Etapa 0**: 0.1 ✅ · 0.2 ✅ · 0.3 ✅ · 0.4 ✅ · 0.5 ✅ · 0.7 ✅ · solo 0.6 pendiente · 0.8 (GATE 0) tras 0.6
- **Bloqueos activos**: Ninguno

### §15.1 Estado global

| Fase | Estado | % | Último commit | Próxima acción |
|------|--------|---|---------------|----------------|
| I.1 Infra i18n | ✅ Hecho | 100% | c2ccfa6 | — |
| I.2 Pipeline + 5 idiomas | ✅ Hecho | 100% | pendiente | Reemplazar strings hardcodeadas |
| I.3 Cobertura UI | ✅ Completada | 100% | 125 keys × 6 idiomas | `t()` en Canvas, Sidebar, Modal, ToastContainer |
| I.4 +5 idiomas | ✅ Completada | 100% | 125 keys × 11 locales | ja, ko, hi, ru, ar escritos a mano |
| I.5 RTL ar | ✅ Completada | 100% | Tailwind logical props | dir=rtl en ar + panels del canvas espejados |

### §15.2 Detalle por fase

| Aspecto | Valor |
|---------|-------|
| **I.1 — Infra i18n** | ✅ Cerrada 2026-08-25 |
| Commits clave | `c2ccfa6` (suite humana 17/17 + i18n es/en) |
| Deliverables | hook `useI18n` · locales es.json/en.json · selector idioma Header/Config · detección navigator |
| Archivos | `src/i18n/index.ts` · `src/i18n/locales/*.json` · `src/components/Header.tsx` |
| Tests | temas.spec ✅×2 · idioma.spec ✅×2 · suite completa 17/17 |
| **I.2 — Pipeline + 5 idiomas** | ✅ Cerrada 2026-08-27 |
| Commits clave | pendiente |
| Deliverables | `scripts/translate.ts` (OpenAI/Ollama) · `scripts/i18n-check.mjs` (CI) · 5 locales nuevos (zh-CN, pt-BR, de, fr, it) · tipo Locale extendido a 7 idiomas · npm scripts i18n:check + i18n:translate |
| Archivos | `scripts/translate.ts` · `scripts/i18n-check.mjs` · `src/i18n/index.ts` · `src/i18n/locales/*.json` · `package.json` |
| Tests | `i18n-check.mjs` ✅ 6/6 locales · `typecheck` ✅ · `translate.ts --dry-run` ✅ · `idioma.spec.ts` actualizado (7 locales) |
| Lecciones | translate.ts soporta batch 50 keys, fallback a en si falla, dry-run para preview · Header ya usa SUPPORTED_LOCALES.map() así que el selector mostró 7 opciones automáticamente |
| **I.4 — +5 idiomas** | ✅ Cerrada 2026-08-27 |
| Commits clave | pendiente |
| Deliverables | 5 locales nuevos (ja, ko, hi, ru, ar) con 125 keys cada uno · tipo Locale extendido a 12 idiomas · prefijos detect() (ja/ko/hi/ru/ar sin mapping extra) · idioma.spec.ts cubre 12 locales |
| Archivos | `src/i18n/index.ts` · `src/i18n/locales/{ja,ko,hi,ru,ar}.json` · `e2e/human/tests/idioma.spec.ts` |
| Tests | `i18n-check.mjs` ✅ 11/11 locales × 125 keys · `typecheck` ✅ · idioma.spec.ts (12 locales) |
| Lecciones | Traducciones escritas a mano (sin API key) — la calidad para ja/ko/hi/ru/ar es mejor que el pipeline AI · Header ya muestra 12 opciones automáticamente · la rama móvil del test ahora usa el `search` placeholder por locale (antes hardcodeaba "Search...") · ar queda pendiente para I.5 (RTL) |
| **I.5 — RTL ar + Tailwind logical properties + Intl formato + fallback test** | ✅ Cerrada 2026-08-27 |
| Commits clave | pendiente |
| Deliverables | `RTL_LOCALES=['ar']` + `applyDocAttrs()` (setea `dir` en `<html>` en `initial()` y `setLocale()`) · conversión de props físicas → lógicas en CSS (Sidebar, Header, Canvas, Modal, ToastContainer, styles.css) · swap de `Panel` position en Canvas.tsx (paleta a la derecha, propiedades a la izquierda en RTL) · test @rtl en idioma.spec.ts (assert dir=rtl + sidebar al inline-start) · **Intl.NumberFormat/DateTimeFormat/RelativeTimeFormat** en `useI18n()` (`formatNumber`, `formatDate`, `formatDateTime`, `formatRelative`) aplicados a Sidebar (usageCount, successRate, skills/tools counts) · **test unitario fallback** (`src/i18n/index.test.ts` 4 tests) · `translateWith` exportado para testing |
| Archivos | `src/i18n/index.ts` · `src/components/Canvas.tsx` · `src/components/{Sidebar,Header,Canvas,Modal,ToastContainer}.css` · `src/styles.css` · `e2e/human/tests/idioma.spec.ts` · `src/i18n/index.test.ts` |
| Tests | `typecheck` ✅ · `i18n-check.mjs` ✅ 11/11 · `vite build` ✅ · vitest `index.test.ts` 4/4 · verificación programática: AR dir=rtl/sidebar-izquierda (sidebarLeft:0/canvasLeft:321), LTR sidebar-derecha (sidebarLeft:960) ✅ |
| Lecciones | El grid desktop `.app-main` (1fr 320px) se espeja solo en RTL (flujo inline) — sin cambio · `text-align:right` en `.node-ports.inputs .port-label` se mantiene físico (geometría del nodo, no flujo de documento) · selector de idioma fragile al cambiar locale (el aria-label se traduce → el test de re-check EN falla por selector, no por el app) · verificación visual humana pendiente (screenshot `/tmp/ar-arabic.png`) · Intl formatters creados per-locale (memoizados) y expuestos vía `useI18n()` — React Compiler los re-renderiza en cambio de idioma · fallback test cubre: key real → string no vacío; key missing → devuelve key; key en en pero no en locale → cae a en; vars no rompe sin placeholders |

### §15.3 Pausas y reanudaciones

| Fecha | Motivo | Al reanudar |
|-------|--------|-------------|
| — | — | — |

### §15.4 Decisiones en Engram

| ID | Decisión | Fecha |
|----|----------|-------|
| #948 | Suite humana 17/17: temas+i18n+responsive | 2026-08-25 |

### §15.5 Pendientes activos

| Pri | Tarea | Responsable | Ref |
|-----|-------|-------------|-----|
| 🟢 | ~~RTL ar + Tailwind logical properties (Fase I.5)~~ ✅ 2026-08-27 | IA | F-i18n-5 |
| 🟢 | ~~Intl.NumberFormat/DateTimeFormat en useI18n (plan-i18n §2.4)~~ ✅ 2026-08-27 | IA | — |
| 🟢 | ~~Test unitario fallback (plan-i18n §9)~~ ✅ 2026-08-27 | IA | — |
| 🟢 | ~~Visual check del RTL ar~~ ✅ 2026-08-27 — suite humana: @rtl desktop 3/3 + @core 12 locales desktop+mobile 35/35 pasos (video+screenshots en `evidence/human/idioma_spec_ts/`) | IA | I.5 gate |

**Plan de i18n CERRADO al 100%** (I.1–I.5 + Intl + fallback + verificación humana).

### §15.6 Convenciones del log

- 1 línea por evento, cero prosa
- Commit refs como `abc1234`
- Decisiones → Engram #ID
- Fases cerradas se compactan a 5-10 líneas
