# PRICING & TIERS — Límites Free / Pro / Teams (v1)

> **Producto:** Canvas AI · **Estado:** propuesta v1.0 · 2026-08-25 · Base: [SDD-010](./SDDs/SDD-010-modelo-negocio.md) (hosting $29-149/mes, margen 60-80%)
> Regla: **local-first siempre gratis** (BYOK). La nube 24/7 es el producto de pago. Pricing self-serve transparente (patrón PostHog).

## 1 · Los 3 planes

| Capacidad | **Free (local)** | **Pro (nube 24/7)** | **Teams** |
|---|---|---|---|
| Precio | **$0** | **$29/mes** | **$99/mes** (hasta 5 usuarios) |
| App local (BYOK) | ✅ ilimitado | ✅ + sync | ✅ + sync |
| Nube 24/7 (workers Linux) | ❌ | ✅ | ✅ |
| Modelos | tu key / Ollama | tu key (BYOK) | tu key |
| Sesiones simultáneas en nube | — | 3 | 15 |
| Horas de agente/día en nube | — | 8 h | ilimitado (fair-use) |
| Skills | ilimitados | ilimitados | ilimitados + compartidos |
| Sync multi-dispositivo | ❌ | ✅ 2 dispositivos | ✅ ilimitado |
| Marketplace (publicar) | ✅ | ✅ | ✅ |
| Segundo Cerebro | ✅ local | ✅ + en nube | ✅ |
| Guardrail de costo | por sesión/día | por sesión/día/mes | por equipo |
| Soporte | docs + comunidad | email | email prioritario + onboarding |

## 2 · Reglas de diseño del pricing

1. **BYOK en todos los planes** — no vendemos tokens; vendemos hosting 24/7, sync y límites de ejecución.
2. **El Free local es completo** — la conversión es por "necesito que corra sin mi máquina", no por castración de features (patrón Windsurf free-bottom-up).
3. **Free tier de nube** (para enganchar): 10 h de nube/mes, 1 dispositivo sync — suficiente para probar, muro claro al proyecto serio.
4. **Flags en código desde v1** (T.BIZ): `FREE/PRO/TEAMS` como feature-flags; el bundle Free **no compila** código Pro.
5. **Migración** entre planes automática (pausa/retoma en nube según el tier al volver).

## 3 · Métricas de negocio que vigilar

- Conversión Free→Pro · % de usuarios que tocan el muro (free nube) · **costo por entrega** en nube (debe ser < 20% del precio) · churn Pro. Ver [PRODUCT-METRICS](./PRODUCT-METRICS.md).

## 4 · Verificación

- **T.BIZ:** flags verificados; bundle Free sin código Pro compilado; docs legales (ToS/Privacy) publicados.
- **Gate humano:** probar las 3 experiencias (free local / free nube con límites / pro) sin recompilar — solo flags.
