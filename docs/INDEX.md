# INDEX DE DOCUMENTACIÓN

> Mapa completo de todos los .md del proyecto. **Organizado en niveles lógicos** — lee de arriba hacia abajo. Actualizado 2026-08-25.
> Términos: [GLOSARIO](./GLOSARIO.md) · Orden de construcción: [EJECUCION-ORDEN](./EJECUCION-ORDEN.md)

## Nivel 1 · Producto (qué construimos y para quién)

| Documento | Contenido |
|---|---|
| [PRD](./PRD.md) | Personas + JTBD + features → resultado medible Playwright humano |
| [FEATURE-BACKLOG](./FEATURE-BACKLOG.md) | Análisis de funciones: agregadas F17-F28, post-v1 y rechazadas |
| [MERCADO-ANALISIS](./MERCADO-ANALISIS.md) | Investigación de mercado 2026: F33-F36 y validaciones |
| [PRODUCT-DIFFERENTIATORS](./PRODUCT-DIFFERENTIATORS.md) | Los 7 diferenciadores "increíbles" (brújula anti-scope) |
| [PRODUCT-METRICS](./PRODUCT-METRICS.md) | North-star, activación, retención, eventos, telemetría |
| [PRICING-TIERS](./PRICING-TIERS.md) | Free local $0 / Pro $29 / Teams $99 |
| [SDD-013](./SDDs/SDD-013-gui-visual-spec.md) | Obsidian Glass + Liquid Glass + escalera §8 hacia VR (fuente canónica visual) |
| [UX-STANDARDS](./UX-STANDARDS.md) | Atajos, estados de UI, ayuda in-app |

## Nivel 2 · Arquitectura y decisiones

| Documento | Contenido |
|---|---|
| [ARQUITECTURA](./ARQUITECTURA.md) | Arquitectura (client-first, híbrido) |
| [ADRs](./ADRs/) | Decisiones registradas (ADR-006 = visión híbrida) |
| [THREAT-MODEL](./THREAT-MODEL.md) | Amenazas por capa, sandbox, BYOK |
| [AUTH](./AUTH.md) | Local sin cuenta · nube con RLS |
| [PLATAFORMAS-TARGETS](./PLATAFORMAS-TARGETS.md) | Qué se instala dónde (servidor + 6 clientes) |
| [DEV-ENVIRONMENT](./DEV-ENVIRONMENT.md) | Cómo correr el stack |

## Nivel 3 · Plan maestro y ejecución

| Documento | Contenido |
|---|---|
| [Plan Maestro](./SDDs/SDD-001-plan-base/README.md) | 10 etapas + Etapa 0, arquitectura, gates |
| [MATRIZ-FASES-PRUEBAS](./SDDs/SDD-001-plan-base/MATRIZ-FASES-PRUEBAS.md) | 149 fases en orden de ejecución (fuente de verdad) |
| [MVP-ROADMAP](./MVP-ROADMAP.md) | MVP-1/2/3 time-boxed |
| [EJECUCION-ORDEN](./EJECUCION-ORDEN.md) | Checklist de construcción en orden exacto |
| [ETAPA-0-IMPLEMENTACION](./ETAPA-0-IMPLEMENTACION.md) | Plan accionable de la Fundación (slices) |
| [COVERAGE-GUI](./COVERAGE-GUI.md) | Cobertura 100%: botón/función → test humano |
| [WORKFLOW-AGENTICO](./WORKFLOW-AGENTICO.md) | Loop: 5 sub-agentes en paralelo + debug en vivo |
| [TARJETAS-ETAPA-0](./TARJETAS-ETAPA-0.md) | Fases de la Fundación en formato canónico (tarjetas) |
| [SCHEMA-MAESTRO](./SCHEMA-MAESTRO.md) | Modelo canónico de datos + migraciones |
| [CONTRATO-SKILL](./CONTRATO-SKILL.md) | Formato `.md` de skills |
| [API](./API.md) | Inventario REST del gateway |
| [DATA-LIFECYCLE](./DATA-LIFECYCLE.md) | Migraciones, backup, GDPR |
| [FEATURE-FLAGS](./FEATURE-FLAGS.md) | Flags de tiers + dark-launch |
| [Planes base](./SDDs/SDD-001-plan-base/) | A (chat) · B (editor) · C (runtime) · D (memoria) · F (canvas) · G (skills) · H (pruebas) · I18N · N (orquestación) · VI (segundo cerebro) |
| [SDDs complementarios](./SDDs/) | 002 testing · 010 negocio · 011 Hermes · 012 GrokBot · 013 GUI |

## Nivel 4 · Calidad y operación

| Documento | Contenido |
|---|---|
| [SLO-RELIABILITY](./SLO-RELIABILITY.md) | TTFT, uptime, RTO/RPO, error budget |
| [PERFORMANCE-BUDGETS](./PERFORMANCE-BUDGETS.md) | Presupuestos de rendimiento |
| [SDD-002](./SDDs/SDD-002-testing-spec-driven.md) | Sistema de pruebas spec-driven + humano |
| [INFRA](./INFRA.md) | Herramientas de build (tsgo, Vite 8, oxc) |

## Nivel 5 · Lanzamiento, contribución y seguridad

| Documento | Contenido |
|---|---|
| [LAUNCH-CHECKLIST](./LAUNCH-CHECKLIST.md) | Lanzamiento profesional + feedback loop |
| [CONTRIBUTING](../CONTRIBUTING.md) | Guía de contribución (spec-driven + cobertura 100%) |
| [SECURITY](../SECURITY.md) | Reportar vulnerabilidades |
| [CODE_OF_CONDUCT](../CODE_OF_CONDUCT.md) | Código de conducta |

## Nivel 6 · Estado y meta

| Documento | Contenido |
|---|---|
| [ESTADO](./ESTADO.md) | Dónde estamos |
| [CHANGELOG](./CHANGELOG.md) | Historial append-only |
| [MULTIPLATAFORMA](./MULTIPLATAFORMA.md) | Compilar en cada plataforma |
| [RESPONSIVE](./RESPONSIVE.md) | Reglas responsive |
| [GLOSARIO](./GLOSARIO.md) | Terminología canónica |
