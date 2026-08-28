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
| 2026-08-28 | A.5 completada: medidor de contexto (core/context.rs + GET /api/sessions/:id/context + truncado en chat + ContextMeter en memory rail + 13 keys × 12 locales + OpenAPI 47 paths) |
| 2026-08-28 | A.6 completada: Centro de Configuración (settings por scope Agente>Sesión>Proyecto>Global con valor efectivo+origen, /api/settings/:pid/effective, overrides de sesión en agent_config, chat usa temperature/model, ConfigCenter 2 públicos, 19 keys × 12 locales, OpenAPI 50 paths) |
| 2026-08-28 | A.7 completada: Modo ENCARGO (migración 0006 encargos sqlite+postgres+RLS, POST/GET /api/encargos con runner en background que compone el prompt de título+criterios, evidencia en encargo+sesión+event_stream, EncargosPanel en memory rail con toasts, 11 keys × 12 locales, OpenAPI 52 paths) |

---

## §15 · Notas de ejecución (living log)

### §15.0 Quick Resume

> **📌 PUNTO DE CONTINUIDAD — leer esto primero en una sesión nueva**

- **Última sesión (2026-08-28)**: **ETAPA 0 CERRADA (GATE 0 ✅)** + **Etapa 1: A.0 ✅ A.1 ✅ A.2 ✅ A.3 ✅ A.4 ✅ A.5 ✅ A.6 ✅ A.7 ✅**
- **Próxima acción**: **Etapa 1 A.8 — Resume inteligente (v1)** (reanudar sesión interrumpida: card de resumen; `/compact` comprime historial viejo). Spec: [plan-a-chat-codex §A.8](docs/SDDs/SDD-001-plan-base/plan-a-chat-codex.md). Luego A.9 (ramas) → **GATE A**.

**Estado del código (todo en main, verificado):**
- Rust **53/53** (SQLite + PG 16 real + Docker real + context A.5 + scopes A.6 + encargos A.7) · vitest 7/7 · typecheck (tsgo) ✅ · build ✅ · i18n 12/12 (167 keys) · humana: A.0 6/6, A.1/A.4 8/8, A.5 6/6, A.6 6/6, A.7 7/7, móvil 3/3
- Etapa 0: migraciones {sqlite,postgres}/0001-0005 · repos sqlx · server axum persistido (ADR-007) · RLS fail-closed 13 tablas · event_stream append-only · vault BYOK AES-256-GCM · sandbox Linux (bollard) · OpenAPI 43 paths + `src/types/api-generated.ts` · i18n 12 locales + RTL
- Etapa 1: A.0 proyectos+settings scopes+switcher/grid+skills global/copia · A.1 /api/sessions+messages + ChatPanel + SessionsList + BottomNav · A.2 settings cifradas (`{__secret: key_ref}`) · A.3 `AgentProvider` + OpenAICompatProvider universal + `/chat` · A.4 streaming SSE + slash honestos + usage · A.5 medidor de contexto (desglose por fuentes en vivo + límite `context_max_tokens` con truncado real del request) · A.6 Centro de Configuración (4 scopes Agente>Sesión>Proyecto>Global con valor efectivo+origen, 2 públicos, chat usa temperature/model reales) · A.7 Modo ENCARGO (título+criterios sin prompt, runner en background, evidencia en encargo+sesión, toast de vuelta)

**Cómo correr las verificaciones (comandos exactos):**
```bash
# Rust completo con PG real (docker empresa-dev-postgres en :5433)
docker exec -e PGPASSWORD=empresa_dev empresa-dev-postgres psql -h localhost -U empresa -d empresa_dev \
  -c "DROP DATABASE IF EXISTS canvas_ai_test;" -c "CREATE DATABASE canvas_ai_test OWNER empresa;"
CANVAS_TEST_PG_URL="postgres://empresa:empresa_dev@localhost:5433/canvas_ai_test" cargo test --workspace

# i18n + frontend
node scripts/i18n-check.mjs && pnpm typecheck && pnpm build:frontend && pnpm test

# gateway + vite para pruebas humanas (Playwright human config):
cargo build -p canvas-ai-server --bin canvas-ai-server
export CANVAS_KEK=$(python3 -c "import base64,os; print(base64.b64encode(os.urandom(32)).decode())")  # OBLIGATORIO para flujos con secretos
CANVAS_AI_PORT=3031 setsid ./target/debug/canvas-ai-server > /tmp/gateway.log 2>&1 < /dev/null &
CANVAS_GATEWAY=http://127.0.0.1:3031 setsid npx vite --port 1420 --host > /tmp/vite.log 2>&1 < /dev/null &
A1_GATEWAY=1 npx playwright test --config=e2e/playwright.human.config.ts --project=human-desktop e2e/human/tests/chat-shell.spec.ts

# LLM real free-first (opt-in; fallback multi-modelo ante 429 del pool)
set -a; source .env; set +a; export CANVAS_REAL_LLM=1
cargo test -p canvas-ai-core --test providers_byok openrouter_free_real -- --nocapture
```

**Gotchas críticos del entorno (leer antes de tocar):**
- Host compartido: zombie SUPERVISADO `empresa-dev-server` en :3030 (renace al matarlo) → gateway canvas SIEMPRE en `CANVAS_AI_PORT=3031` + vite con `CANVAS_GATEWAY=http://127.0.0.1:3031`
- El gateway DEBE arrancar con `CANVAS_KEK` (base64 32B) o el vault no puede cifrar (providers/settings-secret fallan)
- `.env` define `VITE_API_BASE=/api` → el cliente normaliza (no duplicar /api/api)
- `pkill -f` con patrón presente en tu propio comando mata tu shell; matar por PID (ss -tlnp)
- Edits por script (python/sed): SIEMPRE grep-verify después (anchors silenciosos)
- Los errores de handlers axum `(StatusCode, String)` van como texto plano → tests HTTP aserten status, no body
- Deuda lint legacy documentada: 15 noExplicitAny en `src/types.ts` + Header.css (17 antes de Etapa 0 — NO tocar sin suite)

**Bloqueos activos**: Ninguno

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
| **A.5 — Medidor y debug de contexto** | ✅ Cerrada 2026-08-28 |
| Deliverables | `core/context.rs` (estimación chars/4 + desglose 5 fuentes + política: system y el más reciente siempre viajan, historial viejo se recorta primero) · `GET /api/sessions/:id/context` (SessionContextResponse + OpenAPI/schema/TS regenerados, 47 paths) · truncado real en `chat_in_session` y `chat_in_session_stream` (meta SSE `context` = lo que el medidor muestra) · setting `context_max_tokens` (herencia Global→Proyecto, default 8192, piso 256) · `ContextMeter.tsx` en el memory rail (barras por fuente, ajuste de límite, aviso de truncado) · 13 keys i18n × 12 locales |
| Archivos | `crates/core/src/context.rs` · `crates/server/src/api.rs` · `src/components/ContextMeter.tsx` · `src/components/ChatPanel.tsx` · `src/lib/chatApi.ts` · `src/hooks/useSessions.ts` · `src/i18n/locales/*.json` · `crates/server/tests/context_meter.rs` · `e2e/human/tests/context-meter.spec.ts` |
| Tests | unit core 5/5 (fixtures: sin truncado, truncado, mensaje único excedido, vacío, estimación) · integration server 2/2 (**request capturado por mock provider == sent_tokens del medidor** + 404 + límite heredado) · E2E humana @core desktop 6/6 pasos · workspace cargo completo 0 failed · typecheck/build/vitest/i18n-check ✅ |
| Lecciones | (1) el `useEffect` que sincroniza el input del límite PISA lo tecleado si llega una refetch a mitad de edición → flag `editing` + `onFocus select()` (escribir reemplaza, además UX real) · (2) barra con width 0% no es "visible" para Playwright → asertar la fila con testid, no la barra · (3) tras `page.reload()` la sesión activa NO se restaura (Zustand en memoria) — el spec humano debe re-seleccionarla; el límite persiste porque vive en settings · (4) el fixture `humanFill` usa `pressSequentially` que NO limpia el valor previo · (5) el log de `h.step` sale al TERMINAR el paso — un paso que falla nunca imprime su nombre (costó localizar que el fallo real era el paso 6, no el 5) |
| **A.6 — Centro de Configuración** | ✅ Cerrada 2026-08-28 |
| Deliverables | `repo.rs`: `merge_settings` (puro, precedencia Agente>Sesión>Proyecto>Global) + `session_settings_{map,set,clear}` (overrides de sesión en `sessions.agent_config`) + `settings_effective` · `GET /api/settings/:pid/effective` (items con origen + resolved) · `PUT/DELETE /api/sessions/:id/settings` · chat consume settings reales (temperature/model por request; context_limit con capa sesión) · `ConfigCenter.tsx` (scope selector, modo simple con knobs + badge de origen, modo JSON validado) · `configApi.ts` + `useConfig.ts` (React Query) · 19 keys i18n × 12 locales · OpenAPI 50 paths + TS regenerado |
| Decisiones | Scope **Subagente diferido a Etapa C** (no hay infra de subagentes aún — no se inventa storage especulativo) · overrides de sesión viven en `agent_config` (columna existente sin uso, sin migración) · capa agente = `AgentConfig` del dominio (model/temperature/max_tokens ya existían) · perillas v1 = `model`, `temperature`, `context_max_tokens` (todas con efecto real en el gateway) |
| Archivos | `crates/core/src/repo.rs` · `crates/server/src/api.rs` · `crates/server/tests/config_scopes.rs` · `src/components/ConfigCenter.tsx` · `src/components/Sidebar.tsx` · `src/lib/configApi.ts` · `src/hooks/useConfig.ts` · `src/i18n/locales/*.json` · `e2e/human/tests/config-center.spec.ts` |
| Tests | unit herencia 3/3 (más específico gana, solo global, vacío) · integration 3/3 (herencia por capa HTTP, capa agente gana, **chat capturado usa temperature/model de settings**) · E2E humana @core desktop 6/6 (clicks + JSON válido/inválido + override de proyecto persiste) · workspace cargo 50/0 · suite @core 8 passed |
| Lecciones | (1) `AgentConfig.temperature` es f32 → al comparar en tests usar tolerancia (0.7 ≠ 0.699999988079071 en f64) · (2) `PutSettingRequest` usado en un Op nuevo pero no registrado en `schemas` → el gate de OpenAPI detecta `$ref` roto (buen gate) · (3) el tab del sidebar se llama "Config" (es) pero el botón del header "Configuración" — regex del spec debe distinguir |
| **A.7 — Modo ENCARGO (v1)** | ✅ Cerrada 2026-08-28 |
| Deliverables | migración `0006_encargos` (sqlite+postgres, RLS fail-closed pg, down en ambos) · `repo.rs`: `Encargo` + `encargo_{create,get,list_by_project,finish,set_running}` · API: `POST /api/encargos` (valida título+criterios, auto-crea sesión "Encargo: {título}", lanza runner `tokio::spawn`) + `GET /api/encargos[/:id]` · runner compone el prompt (system agente + user título+criterios — el usuario NO escribe prompt), reusa context A.5 + settings A.6, persiste evidencia como mensajes y en `event_stream` (task.created/task.completed/provider.error) · `EncargosPanel` en memory rail (mini-form, lista con estado, evidencia expandible, toasts de vuelta) · polling React Query solo mientras hay encargos en curso · 11 keys × 12 locales · OpenAPI 52 paths |
| Archivos | `crates/core/migrations/{sqlite,postgres}/0006_encargos.sql` (+down) · `crates/core/src/repo.rs` · `crates/server/src/api.rs` · `crates/server/tests/encargos.rs` · `src/components/EncargosPanel.tsx` · `src/components/ChatPanel.tsx` · `src/lib/encargosApi.ts` · `src/hooks/useEncargos.ts` · `src/styles.css` · `e2e/human/tests/encargo.spec.ts` |
| Tests | integration 3/3 (completado con mock: evidencia+tokens+mensajes en sesión auto-creada; sin provider → failed honesto; validación 400) · E2E humana @core desktop 7/7 (delegar con clicks → mock completa → toast → evidencia en panel y en su sesión) · workspace cargo 53/0 · suite @core 9 passed |
| Lecciones | (1) el test de migraciones mantiene la reversa MANUAL en `repo_sqlite.rs` (DOWN_000X + run_all_down) — nueva tabla ⇒ sumar su DOWN ahí y actualizar el conteo de `_sqlx_migrations` · (2) los toasts son efímeros (4-6s): asertarlos con `toContainText` (reintenta) y locator simple, nunca `toBeVisible` con filtros complejos · (3) el encargo auto-crea SU propia sesión "Encargo: …" — para ver mensajes el spec debe navegar a ella desde el tab Sesiones |

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
