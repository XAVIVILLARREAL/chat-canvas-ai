# LAUNCH-CHECKLIST — De "compila" a producto lanzado

> **Producto:** Canvas AI · **Estado:** v1.0 · 2026-08-25 · Base: [SDD-010](./SDDs/SDD-010-modelo-negocio.md) (growth) y [PRD](./PRD.md)
> Objetivo: checklist de lanzamiento profesional, incluyendo distribución, feedback loop y soporte. Se completa ANTES de v1.0 (tag).

## 1 · Producto (cerrado en MVP-3)

- [ ] Gates humanos de los 3 MVPs verdes con video en `evidence/`
- [ ] **[ACEPTACIÓN FINAL](./ACEPTACION-FINAL.md) completa**: 20/20 recorridos humanos verdes (móvil+desktop) con video — TODAS las features operadas como persona antes del tag
- [ ] [PRD](./PRD.md) F1-F28 operadas como humano en los 3 tamaños (375/768/1440)
- [ ] **Métrica norte instrumentada** ("sesiones que terminan en ENTREGA") y activación visible
- [ ] Onboarding <5 min cronometrado ([T.ONB](./SDDs/SDD-001-plan-base/plan-t-excelencia.md))
- [ ] Empty-states y ayuda en las 4 vistas · error boundaries sin pantallas muertas

## 2 · Distribución y actualizaciones

- [ ] **GitHub Releases** por tag (semver + CHANGELOG): instaladores Windows/macOS/Linux vía [release workflow](../.github/workflows/release.yml)
- [ ] **Auto-update firmado** (minisignv2, S.3) — sin delta updates; sidecars/modelos descarga lazy
- [ ] Canales extra opcionales: Homebrew (macOS), winget (Windows), npm para el MCP del cerebro
- [ ] `security.txt` + página Acerca-de con licencias/atribuciones

## 3 · Feedback loop (imprescindible para "increíble")

- [ ] **Botón "Feedback" in-app** que abre el diálogo de diagnostico exportable (sin datos sensibles) + enlace a Issues
- [ ] Plantillas de issue (bug + feature) con checkboxes de repro
- [ ] Métrica de **NPS ligera** (1 tap) en el flujo de primera entrega
- [ ] Canal de comunidad (Discord/GitHub Discussions) + moderación (CoC)
- [ ] Triage semanal de issues; post-mortems en `docs/INCIDENTES/`

## 4 · Legal y negocio

- [ ] ToS + Privacy Policy publicados ("tus datos nunca salen" = pitch local-first)
- [ ] [PRICING-TIERS](./PRICING-TIERS.md) implementado con flags (bundle Free sin código Pro)
- [ ] Pago self-serve (Stripe/Recharge) + facturación; free-tier de nube con muros claros
- [ ] Licencia MIT del core + features Pro comerciales ([T.BIZ](./SDDs/SDD-001-plan-base/plan-t-excelencia.md#tbiz))

## 5 · Calidad y seguridad finales (GATE T)

- [ ] cargo-audit/deny limpios · axe-core verde · i18n sin strings duras · contraste AA
- [ ] Chaos suite 6/6 · drill de backup ≤ 30 min · perf budgets en CI
- [ ] [SECURITY.md](../SECURITY.md) activo + `security.txt` publicado

## 6 · Launch (growth, SDD-010)

- [ ] Show HN sábado, título numérico sin la palabra "AI" · build-in-public · MCP en los 7 registros
- [ ] KPI de launch: % de nuevos que comparten/exportan un artefacto en su primera sesión
- [ ] Release del video demo: agente trabajando + evidencia en vivo (el "demo primitive")

## 7 · Post-launch (primeros 30 días)

- [ ] Vigilar activación + retención D7 + costo/entrega · re-triage de issues
- [ ] Incidentes → post-mortem en 72 h · hotfix fuera de cadencia si es crítico
- [ ] Segunda pasada de onboarding con datos reales de abandono
