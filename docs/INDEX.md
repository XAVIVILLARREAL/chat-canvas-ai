# INDEX DE DOCUMENTACIÓN

> Mapa completo de todos los .md del proyecto. Actualizado 2026-08-25.

## Documentos principales

| Documento | Descripción | Ubicación |
|---|---|---|
| AGENTS.md | Guía de trabajo para agentes AI | `./AGENTS.md` |
| ESTADO.md | Estado actual | `./docs/ESTADO.md` |
| CHANGELOG.md | Historial append-only | `./docs/CHANGELOG.md` |
| ARQUITECTURA.md | Arquitectura del proyecto | `./docs/ARQUITECTURA.md` |
| **PRD.md** | **Producto: personas, JTBD, features→resultado humano** | `./docs/PRD.md` |
| **PRODUCT-METRICS.md** | **North-star, activación, eventos, telemetría** | `./docs/PRODUCT-METRICS.md` |
| **MVP-ROADMAP.md** | **MVP-1/2/3 time-boxed** | `./docs/MVP-ROADMAP.md` |
| **SCHEMA-MAESTRO.md** | **Modelo canónico de datos (Etapa 0)** | `./docs/SCHEMA-MAESTRO.md` |
| **CONTRATO-SKILL.md** | **Formato `.md` de skills** | `./docs/CONTRATO-SKILL.md` |
| **THREAT-MODEL.md** | **Amenazas, sandbox Linux, BYOK** | `./docs/THREAT-MODEL.md` |

## Plan Base (SDD-001) — v2.0

| Plan | Contenido | Ubicación |
|---|---|---|
| **README.md** | Plan Maestro: 10 etapas, arquitectura, reglas VR-ready | `./docs/SDDs/SDD-001-plan-base/README.md` |
| Plan A | Chat con sesiones (Hermes patterns, Memory Rail) | `./docs/SDDs/SDD-001-plan-base/plan-a-chat-codex.md` |
| Plan B | Editor de código + live preview (Monaco, file explorer) | `./docs/SDDs/SDD-001-plan-base/plan-b-sidepanels-lovable.md` |
| Plan C | Runtime de agentes (Reasonix, DeepSeek, Ollama) | `./docs/SDDs/SDD-001-plan-base/plan-c-reasonix-deepseek.md` |
| Plan D | Memoria y knowledge (SQLiteVec, FTS5) | `./docs/SDDs/SDD-001-plan-base/plan-d-memoria-v3code.md` |
| Plan E | Integración total | `./docs/SDDs/SDD-001-plan-base/plan-e-integracion-total.md` |
| Plan F | Canvas de automatización + Kanban de resultados | `./docs/SDDs/SDD-001-plan-base/plan-f-canva-oficina.md` |
| Plan G | Skills Lab (avatares IA, multi-agent loops) | `./docs/SDDs/SDD-001-plan-base/plan-g-skills-lab.md` |
| Plan H | Motor de pruebas y resultados | `./docs/SDDs/SDD-001-plan-base/plan-h-motor-pruebas.md` |
| Plan I | Revisión y superposiciones | `./docs/SDDs/SDD-001-plan-base/plan-i-revision-superposiciones.md` |
| Plan J | Grafo 3D / RepoMap | `./docs/SDDs/SDD-001-plan-base/plan-j-grafo3d-repomap.md` |
| Plan K | Voz (STT/TTS) | `./docs/SDDs/SDD-001-plan-base/plan-k-voz.md` |
| Plan L | Local-first / offline | `./docs/SDDs/SDD-001-plan-base/plan-l-local-first.md` |
| Plan M | GitHub integration | `./docs/SDDs/SDD-001-plan-base/plan-m-github.md` |
| Plan N | Orquestación de sesiones y agentes | `./docs/SDDs/SDD-001-plan-base/plan-n-orchestration.md` |
| **Plan I18N** | **Multilenguaje simple desde el día 1** | `./docs/SDDs/SDD-001-plan-base/plan-i18n.md` |
| Plan VI | Segundo Cerebro — grafo de archivos del proyecto | `./docs/SDDs/SDD-001-plan-base/plan-vi-second-brain.md` |
| Plan P | Pixel-perfect GUI | `./docs/SDDs/SDD-001-plan-base/plan-p-pixel-perfect-gui.md` |
| Plan T | Excelencia (calidad total) | `./docs/SDDs/SDD-001-plan-base/plan-t-excelencia.md` |
| Plan U | Motivación / neuro-gratificación | `./docs/SDDs/SDD-001-plan-base/plan-u-motivacion.md` |
| Plan V | Visual GrokBot | `./docs/SDDs/SDD-001-plan-base/plan-v-visual-grokbot.md` |
| Plan X | Data apps | `./docs/SDDs/SDD-001-plan-base/plan-x-data-apps.md` |
| MATRIZ-FASES | Matriz de ejecución | `./docs/SDDs/SDD-001-plan-base/MATRIZ-FASES-PRUEBAS.md` |

## SDD-005 — Referencia de fusión (historical)

| Documento | Contenido | Ubicación |
|---|---|---|
| **SDD-005** | Referencia de fusión — CR→Etapa1, VI→segundo cerebro, KR→Plan F, 3D→VR-ready | `./docs/SDDs/SDD-005-plan-intermedio.md` |

> **Nota:** SDD-005 fue fusionado en el Plan Base v2.1. El Control Room vive en Etapa 1 del README, el Segundo Cerebro en plan-vi, el Kanban en plan-f, y el 3D en las reglas VR-ready.

## SDDs complementarios

| SDD | Contenido | Ubicación |
|---|---|---|
| SDD-002 | Sistema de pruebas spec-driven | `./docs/SDDs/SDD-002-testing-spec-driven.md` |
| SDD-003 | Torneo 500 ideas → 20 ganadoras | `./docs/SDDs/SDD-003-torneo-500-ideas.md` |
| SDD-004 | Análisis Grok Bot | `./docs/SDDs/SDD-004-analisis-grokbot.md` |
| SDD-006 | Investigación cache/memoria | `./docs/SDDs/SDD-006-investigacion-cache-memoria.md` |
| SDD-007 | Análisis OpenCode | `./docs/SDDs/SDD-007-analisis-opencode-modelsdev.md` |
| SDD-008 | Análisis cliente-servidor | `./docs/SDDs/SDD-008-analisis-cliente-servidor-k8s.md` |
| SDD-009 | Debate decisiones | `./docs/SDDs/SDD-009-debate-decisiones.md` |
| SDD-010 | Modelo de negocio | `./docs/SDDs/SDD-010-modelo-negocio.md` |
| SDD-011 | Integración Hermes Agent | `./docs/SDDs/SDD-011-integracion-hermes-agent.md` |
| SDD-012 | Multi-Agent GrokBot | `./docs/SDDs/SDD-012-multi-agent-grokbot-patterns.md` |
| SDD-013 | GUI Visual Spec (Obsidian Glass) | `./docs/SDDs/SDD-013-gui-visual-spec.md` |
| SDD-014 | Cierre multiplataforma | `./docs/SDDs/SDD-014-cierre-multiplataforma.md` |

## ADRs

| ADR | Tema | Estado |
|---|---|---|
| ADR-001 | Responsive Design | Aprobado |
| ADR-002 | Arquitectura Híbrida Monorepo | Aprobado |
| ADR-003 | Voz y Sincronización | Pendiente |
| ADR-004 | Integración GitHub | Pendiente |
| ADR-005 | Modelo Despliegue Dual | Aceptado |
| ADR-006 | **Visión híbrida: local-first gratis + nube SaaS multi-tenant de pago (Q1-Q12)** | **Aceptado** |

## Decisiones del análisis de plan (Q1-Q12)

Ver [`ADR-006`](./ADRs/ADR-006-vision-hibrida-local-nube.md) — híbrido local+nube, BYOK, skills `.md`, sandbox Linux (GrokBot), sin "empresa autónoma".

## Otros

| Documento | Ubicación |
|---|---|
| MULTIPLATAFORMA.md | `./docs/MULTIPLATAFORMA.md` |
| RESPONSIVE.md | `./docs/RESPONSIVE.md` |
| INFRA.md | `./docs/INFRA.md` |
| referencia de diseño.md | `./docs/referencia de diseno.md` |
