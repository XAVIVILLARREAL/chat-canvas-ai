# SDD-005 · PLAN INTERMEDIO — Las 4 Ventanas visuales del proyecto

> Fecha: 2026-08-23 · Estado: Propuesto · **Es el plan que SIGUE a la [base](./SDD-001-plan-base/README.md)** — se ejecuta tras cerrar Gate F (canva base) y alimenta a N (empresas lo usan todo)
> Lógica de negocio documentada en AGENTS.md §"Las 4 Ventanas". Pruebas según [SDD-002](./SDD-002-testing-spec-driven.md).

## Objetivo

Cada proyecto-tenant ([A.0](./SDD-001-plan-base/plan-a-chat-codex.md#a0)) obtiene SU PROPRIO conjunto de ventanas visuales espectaculares, todas vistas sobre los mismos datos (Ledger/knowledge/sesiones) — nunca silos:

| # | Ventana | Qué es | Inspiración |
|---|---|---|---|
| V1 | 🏢 Canva Multiagentes | Organigrama editable: equipos, flujos de skills, bots complejos | **YA EXISTE**: [Etapa 6 / plan-f](./SDD-001-plan-base/plan-f-canva-oficina.md) |
| V2 | 🕸️ Grafo de Documentos | Grafo vivo de los .md del proyecto, ordenado por IA, 100% editable humano+IA | Obsidian graph / Graphify |
| V3 | 📋 Kanban de Resultados | Tablero evidencia-first con animaciones de tests/resultados, para autonomía de horas | Jira optimizado para agentes |
| V4 | 💬 Canvas de Sesiones | Cards de sesiones por agente: hablar (TTS/STT), ver resultados, retomar | Grok Bot threads + chat apps |

**Regla de terreno 3D/gafas**: toda posición/clúster/profundidad que calculemos se guarda en el modelo de datos (no solo en memoria de UI) — Etapa 10 ya proyecta Three.js; las demás ventanas heredan la preparación.

## Ganchos dejados en la BASE (ya existen, no bloquean nada)

- `event_stream` captura `TEST_RESULT` con payload → V3 lee evidencia sin tablas nuevas
- Knowledge/docs son entidades propias ([D·D.2](./SDD-001-plan-base/plan-d-memoria-v3code.md#d2)) → V2 las grafica
- Sesiones/rungs son entidades navegables ([D·D.3](./SDD-001-plan-base/plan-d-memoria-v3code.md#d3)) → V4 las muestra como cards
- Three.js + repo_symbols+pagerank ([PLAN J](./SDD-001-plan-base/plan-j-grafo3d-repomap.md)) → motor 3D reutilizable por todas las ventanas
- Design System F.0 → primitivas compartidas; skills de `reference/` (magic-ui Animated Beams, react-bits, liquid-glass) dan el look

---

# PLAN VI — Etapa 16: Grafo de Documentos (Obsidian/Graphify propio)

**Entregable:** el cerebro visible del proyecto: sus .md como grafo hermoso, curado por IA, editable por humanos — con síntesis y resúmenes al click.

| Fase | Contenido | Pruebas |
|---|---|---|
| VI.1 **Modelo de documentos** | Tabla `documents` (path, título IA, resumen IA, tags, embeddings opcionales vía [D·D.5](./SDD-001-plan-base/plan-d-memoria-v3code.md#d5)); watcher detecta .md nuevos/cambiados del workspace; indexador extrae enlaces wiki-style `[[enlace]]` y headings → edges | Cargo test parser enlaces/headings con fixture .md real. Integration: crear/editar/borrar doc actualiza grafo |
| VI.2 **Layout IA del grafo** | Clustering automático por carpeta/tags/similitud; posiciones calculadas y PERSISTIDAS (terreno 3D); force-directed al abrir, pero posiciones humanas se respetan (drag = guardado) | Unit clustering determinista con seeds. E2E: arrastrar nodo, recargar app → posición conservada |
| VI.3 **Canvas interactivo** | Render estilo Obsidian: nodos-tarjeta (título+tags+resumen-corto), edges curvos, zoom/pan fluido, minimap, búsqueda fuzzy que ilumina subgrafo, fisión/fusión visual por cluster; hover = preview del documento; click = abre en editor ([B·B.2](./SDD-001-plan-base/plan-b-sidepanels-lovable.md#b2)); look premium con liquid-glass/magic-ui de `reference/` | E2E humano: navegar grafo grande (>200 docs) sin jank; buscar→subgrafo resaltado; abrir doc desde nodo |
| VI.4 **Edición humano+IA sobre el grafo** | Seleccionar N nodos → "sintetizar" genera doc-resumen enlazado (agente barato); "resumir" rellena resumen de un nodo; editar título/tags inline; TODO cambio humano marca el nodo como `human_touched` (lock suave: la IA no lo reorganiza sin permiso — coherente con [D·D.2](./SDD-001-plan-base/plan-d-memoria-v3code.md#d2)); deshacer global | Integration síntesis crea doc+edges. E2E humano: selecciona 3 notas→sintetiza→edita resultado→deshacer→re-hacer |

**🚪 GATE VI:** abro el grafo de ESTE mismo proyecto: veo clusters reales (docs/, SDDs/, ADRs/), busco "kanban" y solo ese subgrafo brilla, sintetizo 3 ADRs en una nota nueva enlazada, muevo nodos y mi layout sobrevive reinicios. Video + suites verdes.

---

# PLAN KR — Etapa 17: Kanban de Resultados animados (evidencia-first)

**Entregable:** el tablero donde delegas horas de trabajo autónomo y VES qué se consiguió — cada card es evidencia viva, no texto muerto.

| Fase | Contenido | Pruebas |
|---|---|---|
| KR.1 **Tablero de resultados** | Columnas objetivo→en-curso→verificado→entregado (ciclo SOP); cards = tareas ([H·H.1](./SDD-001-plan-base/plan-h-motor-pruebas.md#h1)) enriquecidas con evidencia: mini-gráfica de tests, contador criterios ✓, coste, duración | Unit estados. E2E: tarea avanza columnas automáticamente con eventos reales |
| KR.2 **Bloques animados de pruebas** | Al correr tests ([H·H.2](./SDD-001-plan-base/plan-h-motor-pruebas.md#h2)): bloque de la card se llena verde test-por-test (Playwright results parseados); fallo → bloque rojo pulsante + diff clicable; animación de "batería completada" al pasar todos (confetti sutil opcional, respeta reduced-motion) | Parser resultados Playwright/vitest→eventos UI. E2E con mock runner: secuencia animada correcta |
| KR.3 **Modo autonomía prolongada** | Botón "trabaja X horas": cola de tareas del proyecto se consume sola; kanban muestra progreso en vivo, digest cada N tareas ([N·N.6](./SDD-001-plan-base/plan-n-empresas-autonomas.md#n6)), presupuesto visible y corte seguro ([N·N.3](./SDD-001-plan-base/plan-n-empresas-autonomas.md#n3)) | Integration: cola mock de 20 tareas → consumo ordenado + corte por presupuesto. Chaos: provider cae a mitad → pausa limpia |
| KR.4 **Vista evidencia por etapa** | Click en card → panel lateral con timeline de rungs de ESA tarea ([D·D.1](./plan-d-memoria-v3code.md#d1)): plan→diffs→tests→review ([I·I.1](./plan-i-revision-superposiciones.md#i1)) con thumbnails de screenshots de la suite humana cuando existan | E2E humano: recorrer evidencia completa de una tarea sin salir del kanban |
| KR.5 **Filtros y salud del board** | Filtrar por agente/etapa/estado-de-tests; indicadores de estancamiento ([I·I.2](./plan-i-revision-superposiciones.md#i2)) y flaky cuarentena ([H·H.8](./plan-h-motor-pruebas.md#h8)) visibles en las cards | E2E: filtros combinados; card estancada muestra badge |

**🚪 GATE KR:** activo "trabaja 4 horas" con 15 tareas → me alejo → vuelvo: el tablero muestra bloques verdes animados de tests, 12 entregadas, 2 en revisión con risk-score, 1 bloqueada con causa; abro evidencia de cualquiera y todo está ahí. Video timelapse + suites verdes.

---

# PLAN SS — Etapa 18: Canvas de Sesiones (cards vivas por agente)

**Entregable:** un lienzo donde cada conversación/sesión es una CARD viva — entras a hablarle (texto o voz), ves sus resultados, retomas donde quedó.

| Fase | Contenido | Pruebas |
|---|---|---|
| SS.1 **Cards de sesión** | Card por sesión ([A·A.0](./plan-a-chat-codex.md#a0) scoped): avatar del agente ([N·N.6](./plan-n-empresas-autonomas.md#n6)), último mensaje, estado (activa/en-espera/terminada), mini-rail de rungs, coste acumulado; layout libre persistido (mismo motor de posiciones que [VI.2](#vi2)) | E2E: cards aparecen/desaparecen con sesiones reales; layout persiste |
| SS.2 **Acciones rápidas en card** | Hablar: abre chat de esa sesión anclado; 🎙️ push-to-talk directo ([K·K.2](./plan-k-voz.md#k2)); 🔊 escuchar último resumen en TTS ([K·K.1](./plan-k-voz.md#k1)); ver evidencia (salta a [KR.4](#kr4)); fork/resume ([A·A.4](./SDD-001-plan-base/plan-a-chat-codex.md#a4)) | E2E humano: desde card, hablar por voz y recibir TTS sin abrir el chat completo |
| SS.3 **Organización espacial semántica** | Agrupación opcional por agente/proyecto-tema usando el índice dual ([D·D.5](./plan-d-memoria-v3code.md#d5)): sesiones parecidas se atraen; buscador "sesiones sobre auth" las ilumina | Unit similitud→layout sugerido. E2E: buscar agrupa/ilumina correctamente |

**🚪 GATE SS:** lienzo con 12 sesiones históricas organizadas por tema; localizo "la sesión de auth", le hablo por voz desde la card, escucho su resumen, salto a su evidencia en el kanban. Video + suites verdes.

---

# PLAN 3D — Etapa 19: Preparación espacial (gafas/futuro)

| Fase | Contenido | Pruebas |
|---|---|---|
| 3D.1 **Modelo espacial transversal** | Todas las ventanas guardan `{x,y,z?,cluster,camera}` en el modelo de datos; exportador a formato escena (JSON espacial) común para las 4 ventanas | Unit schema escena. Roundtrip export/import |
| 3D.2 **Visor 3D unificado (prototipo)** | Reutiliza el motor de [PLAN J](./plan-j-grafo3d-repomap.md#j3) para navegar grafo-docs + kanban + sesiones como capas 3D de un mismo mundo; controles orbit/touch; LOD | Demo navegación de las 3 capas; perf 60fps con datos reales del proyecto |

**🚪 GATE 3D:** prototipo navegable del "mundo Empresa Dev" en 3D con los documentos, el tablero y las sesiones flotando por clusters — prueba de concepto para gafas. Video.

## Estimación del Plan Intermedio

| Plan | Semanas |
|---|---|
| VI Grafo documentos | 2–2.5 |
| KR Kanban resultados | 2–2.5 |
| SS Canvas sesiones | 1.5–2 |
| 3D preparación | 1–1.5 |
| **Total intermedio** | **~6.5–8.5 semanas** (tras Gate F/N según dependencias: VI y KR pueden ir en paralelo tras F+H; SS tras K) |

## Reglas

1. Mismas reglas no negociables del maestro (mini-SDD por plan, 4 capas de prueba, gates con evidencia)
2. NINGUNA ventana duplica datos: todas leen Ledger/knowledge/sesiones — si necesitas tabla nueva, primero justifica por qué un rung no alcanza
3. Look premium OBLIGATORIO usando tokens F.0 + recursos de `reference/` — prohibido CSS improvisado
4. Todo layout/calculo espacial persistido (terreno gafas)
