# SDD-005 · Plan Intermedio — Referencia de fusión

> Fecha: 2026-08-25 · Estado: **FUSIONADO** en el Plan Base v2.1
> Este documento es solo una referencia. Todo el detalle vive en el Plan Base.

---

## Qué era

SDD-005 definía 4 "ventanas visuales" intermedias entre etapas del plan base. Ahora todo está **fusionado** en el plan maestro y sus archivos de plan individuales.

## Dónde vive cada pieza ahora

| Pieza original | Dónde está ahora | Referencia |
|---|---|---|
| **CR — Control Room** (CR.1–CR.5) | Etapa 1 del Plan Base (detail expandido) | [README.md §Etapa 1](./SDD-001-plan-base/README.md) |
| **VI — Canvas de Planeación** (VI.1–VI.6) | **Plan VI — Segundo Cerebro** (nuevo concepto: grafo de archivos en el sidepanel, estilo Obsidian) | [plan-vi-second-brain.md](./SDD-001-plan-base/plan-vi-second-brain.md) |
| **KR — Kanban de Resultados** (KR.1–KR.5) | Sección KR del **Plan F — Canvas de Automatización** (pantalla secundaria del canvas de oficina) | [plan-f-canva-oficina.md](./SDD-001-plan-base/plan-f-canva-oficina.md) |
| **3D — Preparación Espacial** (3D.1–3D.2) | Sección "Modelo espacial transversal" en VR-ready rules del Plan Base | [README.md §VR-ready](./SDD-001-plan-base/README.md) |

## Cambios clave en la fusión

1. **CR** se fusionó directo en Etapa 1 — el Control Room **es** la Etapa 1, no un documento separado
2. **VI** cambió de concepto: ya no es "canvas de planeación separado" → es un **sidepanel estilo Obsidian** (segundo cerebro) para ver/editar/archivos del proyecto como grafo
3. **KR** dejó de ser una ventana independiente → es una **vista/tab dentro del Canvas de Automatización** (Plan F)
4. **3D** dejó de ser un plan separado → es parte de las **reglas VR-ready** transversales del plan base

## Regla VR-ready (transversal a todo)

`SpatialMeta {x, y, z?, cluster, camera}` se usa en todas las ventanas. El visor 3D unificado es un prototipo que navega todas las capas.

---

*Este documento se mantiene como referencia histórica. El Plan Base v2.1 es la fuente canónica.*
