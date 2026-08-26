# FEATURE-FLAGS — Mecanismo de flags (pricing + features arriesgadas)

> **Producto:** Canvas AI · **Estado:** v1.0 · 2026-08-25 · Base: [PRICING-TIERS](./PRICING-TIERS.md) y [T.BIZ](./SDDs/SDD-001-plan-base/plan-t-excelencia.md#tbiz)

## 1 · Por qué

Necesitamos: (a) **tiers de pricing** sin recompilar (Free/Pro/Teams), (b) **features arriesgadas** (Co-Work, dopamina, Consejo) que se activan de a poco, (c) **dark-launch** para rollout seguro. Sin un mecanismo, esto se vuelve `if` por todo el código.

## 2 · Mecanismo (simple, sin dependencia externa en local)

| Capa | Dónde | Qué controla |
|---|---|---|
| **Build-time** | env `VITE_FEATURE_*` / `cfg!(feature)` | bundle Free NO compila código Pro (regla T.BIZ) |
| **Runtime local** | tabla `settings` (por proyecto) | flags de UX/features arriesgadas |
| **Runtime nube** | `settings` por tenant + override de plan | límites de tier (sesiones, horas, dispositivos) |

Definición centralizada en un solo mapa:

```ts
// src/config/flags.ts (fuente de verdad de flags del frontend)
export const FLAGS = {
  sync:           { tiers: ["pro", "teams"] },
  nube247:        { tiers: ["pro", "teams"] },
  kanban:         { defaultOn: true, tiers: ["free", "pro", "teams"] },
  cowork:         { defaultOn: false, darkLaunch: true },   // post-v1
  dopamina:       { defaultOn: false, darkLaunch: true },   // post-v1
  consejoExpertos:{ defaultOn: false, darkLaunch: true },   // post-v1
} as const;
```

## 3 · Reglas

1. Todo acceso a feature flag pasa por `useFlag('nombre')` (hook) / `flags.get()` — **nunca `if` suelto**.
2. El **default es OFF** para lo nuevo; ON solo tras gate humano verde.
3. Los **flags de tier se evalúan en el servidor** (nube): el cliente puede ocultar UI, pero el enforcement real (límites) es server-side.
4. Los flags se **persisten** (settings) y se pueden sobreescribir por proyecto.
5. **Telemetría**: cada flag emitido al `event_stream` (para saber adopción de features arriesgadas).

## 4 · Verificación

- **Unit:** `useFlag` con mapa de tiers; bundle Free sin código Pro compilado (grep del bundle).
- **E2E humano:** probar las 3 experiencias (free/pro/teams) **sin recompilar** — solo flags; una feature dark-launch no aparece por defecto y sí con el flag.
- **Server:** request con tier free intentando nube 24/7 → 403 con mensaje de upgrade.
