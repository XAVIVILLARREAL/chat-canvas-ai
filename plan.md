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

---

## §15 · Notas de ejecución (living log)

### §15.0 Quick Resume

- **Última sesión**: 2026-08-25 — Plan multi-idioma creado
- **Fase actual**: Planificación (fases I.1-I.5 definidas, I.1 ya implementado)
- **Próxima acción**: Ejecutar I.2 (pipeline translate.ts + 5 idiomas)
- **Bloqueos activos**: Ninguno

### §15.1 Estado global

| Fase | Estado | % | Último commit | Próxima acción |
|------|--------|---|---------------|----------------|
| I.1 Infra i18n | ✅ Hecho | 100% | c2ccfa6 | — |
| I.2 Pipeline + 5 idiomas | 🔲 Pendiente | 0% | — | Crear translate.ts |
| I.3 Cobertura UI | 🔲 Pendiente | 0% | — | Reemplazar strings |
| I.4 +5 idiomas | 🔲 Pendiente | 0% | — | Ejecutar translate.ts |
| I.5 RTL ar | 🔲 Pendiente | 0% | — | Tailwind logical |

### §15.2 Detalle por fase

| Aspecto | Valor |
|---------|-------|
| **I.1 — Infra i18n** | ✅ Cerrada 2026-08-25 |
| Commits clave | `c2ccfa6` (suite humana 17/17 + i18n es/en) |
| Deliverables | hook `useI18n` · locales es.json/en.json · selector idioma Header/Config · detección navigator |
| Archivos | `src/i18n/index.ts` · `src/i18n/locales/*.json` · `src/components/Header.tsx` |
| Tests | temas.spec ✅×2 · idioma.spec ✅×2 · suite completa 17/17 |

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
| 🔴 | Crear `scripts/translate.ts` (pipeline AI) | IA | plan-i18n.md §4 |
| 🔴 | Generar zh-CN, pt-BR, de, fr, it con translate.ts | IA | plan-i18n.md §3 |
| 🟡 | Reemplazar strings hardcodeadas por `t()` | IA | F-i18n-3 |
| 🟡 | Crear `scripts/i18n-check.mjs` CI | IA | plan-i18n.md §2.3 |
| 🟢 | +5 idiomas: ja, ko, hi, ru, ar | IA | F-i18n-4 |
| 🟢 | RTL ar + Tailwind logical | IA | F-i18n-5 |

### §15.6 Convenciones del log

- 1 línea por evento, cero prosa
- Commit refs como `abc1234`
- Decisiones → Engram #ID
- Fases cerradas se compactan a 5-10 líneas
