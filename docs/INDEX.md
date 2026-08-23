# INDEX DE DOCUMENTACION

> Mapa completo de todos los .md del proyecto. Actualizado automaticamente.

## Documentos principales

| Documento | Descripcion | Ubicacion |
|---|---|---|
| AGENTS.md | Guia de trabajo para agentes AI | `./AGENTS.md` |
| copia.md | Analisis maestro y lecciones de V3Code | `./copia.md` |
| ESTADO.md | Estado actual (autoadministrado) | `./docs/ESTADO.md` |
| CHANGELOG.md | Historial append-only | `./docs/CHANGELOG.md` |
| INFRA.md | Mejoras de infraestructura | `./docs/INFRA.md` |
| SDD-001 | Plan Base: maestro + 5 planes referenciados (Chat Codex, Sidepanels Lovable, Reasonix+DeepSeek, Memoria V3Code, Integración) | `./docs/SDDs/SDD-001-plan-base/README.md` |
| SDD-002 | Sistema de pruebas spec-driven + suite Playwright humano | `./docs/SDDs/SDD-002-testing-spec-driven.md` |
| SDD-003 | Torneo 500 ideas → 20 ganadoras (backlog vivo incluido) | `./docs/SDDs/SDD-003-torneo-500-ideas.md` |
| SDD-004 | Análisis Grok Bot (xAI/Cursor): 12 ideas robadas mapeadas | `./docs/SDDs/SDD-004-analisis-grokbot.md` |
| SDD-005 | Cierre Multiplataforma (Android versionado, CI 3 SO) | `./docs/SDDs/SDD-005-cierre-multiplataforma.md` |
| MULTIPLATAFORMA.md | Comandos para compilar en Windows/macOS/Linux/Android/iOS | `./docs/MULTIPLATAFORMA.md` |
| referencia de diseno.md | Catalogo de skills de diseno en `reference/` con links | `./docs/referencia de diseno.md` |
| INDEX.md | Este archivo | `./docs/INDEX.md` |
| RESPONSIVE.md | Guia de responsive design | `./docs/RESPONSIVE.md` |
| ARQUITECTURA.md | Arquitectura del proyecto | `./docs/ARQUITECTURA.md` |

## Directorios de documentacion

| Directorio | Contenido |
|---|---|
| `docs/SDDs/` | Software Design Documents (creados por AI) — SDD-001 Plan Base vigente · SDD-005 multiplataforma |
| `docs/ADRs/` | Architecture Decision Records (creados por AI) |
| `reference/` | Recursos de diseno y arquitectura de referencia (`v3code`, `apple-design-skill`, `ui-ux-pro-max`, etc.) |
| `_reciclaje/` | Archivos obsoletos de versiones anteriores |

## ADRs vigentes

| ADR | Tema | Estado |
|---|---|---|
| ADR-001 | Responsive Design y Cross-Platform | Aprobado |
| ADR-002 | Arquitectura Hibrida Monorepo | Aprobado |
| ADR-003 | Voz y Sincronizacion | Pendiente |
| ADR-004 | Integracion GitHub | Pendiente |

## Documentos archivados (no vigentes)

Los siguientes documentos estan en `_reciclaje/docs_obsoletos/` y no reflejan el estado actual:

- ETAPA1.md, FUNDACION.md, PLAN.md, ROADMAP.md, PRODUCTO.md, SUPER_PLAN.md
- ARQUITECTURA.md, MEJORAS.md
- SDDs (SDD-102 a SDD-128) — eran de la version Flutter
- ADRs (ADR-001 a ADR-005) — eran de la version Flutter
- legacy/ — docs antiguos
