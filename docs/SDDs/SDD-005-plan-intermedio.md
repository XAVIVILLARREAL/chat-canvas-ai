# SDD-005 · Plan Intermedio — Las 4 Ventanas Visuales

> Fecha: 2026-08-25 · Estado: **v2.0 REESCRITO** — alineado con la nueva dirección de Canvas AI como herramienta de IA generalista.
> **Canvas AI NO crea empresas autónomas.** Es un entorno de trabajo visual donde el usuario orquesta sesiones y agentes de IA.

---

## Objetivo

Canvas AI obtiene **4 vistas visuales espectaculares**, todas sobre los mismos datos (sesiones, skills, memoria) — nunca silos:

| # | Ventana | Qué es | Inspiración |
|---|---|---|---|
| V1 | 🏠 **Control Room** | Vista maestro: todas las sesiones activas como nodos en un canvas infinito | Mission control / GrokBot |
| V2 | 💬 **Chat + Editor** | Sesiones con chat, editor de código, y live preview | Codex / Lovable / VS Code |
| V3 | 🧠 **Canvas de Planeación** | Grafo de documentos del proyecto, editable humano+IA | Obsidian graph / Graphify |
| V4 | ⚡ **Canvas de Automatización** | Workflow builder visual con agentes de IA | n8n mejorado / Hermes Agent |

**Regla VR-ready**: toda posición/clúster/profundidad se guarda en el modelo de datos — preparado para gafas holográficas futuras.

---

## Ganchos del plan base (ya existen)

- `event_stream` captura `TEST_RESULT` → V3 lee evidencia sin tablas nuevas
- Knowledge/docs son entidades propias (Plan D) → V2 las grafica
- Sesiones/rungs son entidades navegables (Plan A) → V1 las muestra como nodos
- Design System Obsidian Glass → primitivas compartidas

---

# PLAN CR — Control Room (Vista Maestro)

> Depende de: Etapa 1 (canvas base) + Etapa 2 (chat/sesiones)

**Entregable:** Un solo lugar donde ves TODAS las sesiones de agentes como nodos vivas en un canvas infinito — con estado en tiempo real, conexiones, y acciones rápidas.

---

### CR.1 — Canvas de sesiones

Nodos en un canvas infinito (ReactFlow):
- **Nodo Session**: título, avatar del agente activo, estado (active/thinking/working/done), último mensaje (preview), costo acumulado
- **Nodo Skill**: avatar del skill, estado, conexión a sesiones que lo usan
- **Nodo Note**: notas libres del usuario (contexto, ideas, pendientes)
- **Nodo Result**: resultado de una tarea (pass/fail, diff, archivo generado)
- **Edges**: conexiones entre sesiones y skills, sesiones y resultados

Layout automático:
- Sesiones activas arriba
- Skills a la izquierda
- Resultados abajo
- Notas a los lados
- Fuerza-directed para organizar (respeta posiciones humanas)

**Pruebas:** E2E: 3 sesiones activas en el canvas → verificar layout → interactuar.

---

### CR.2 — Acciones rápidas desde el nodo

Click en nodo Session:
- **Abrir chat**: saltar a la vista Chat con esa sesión activa
- **Pausar**: pausar la sesión (agente deja de trabajar)
- **Retomar**: reanudar una sesión pausada
- **Ver evidencia**: mostrar resultados/recursos de la sesión
- **Duplicar**: clonar sesión con su contexto
- **Archivar**: mover a historial

Click en nodo Skill:
- **Editar**: abrir editor de skills
- **Probar**: abrir laboratorio sandbox
- **Ver historial**: ejecuciones pasadas de este skill

**Pruebas:** E2E: click en nodo → acción funciona → resultado visible.

---

### CR.3 — Métricas en vivo

Sidebar o overlay con métricas:
- Sesiones activas ahora
- Agentes trabajando
- Costo total del día
- Agentes más usados
- Sesiones más productivas
- Alertas (sesión stuck, provider caído, costo alto)

**Pruebas:** Unit: cálculo de métricas. E2E: verificar dashboard muestra datos reales.

---

### CR.4 — Organización espacial semántica

- Agrupación opcional por proyecto, agente, o tema
- Búsqueda fuzzy que ilumina nodos relevantes
- Filtros: por agente, por estado, por costo, por fecha
- Minimap para navegar canvas grande

**Pruebas:** E2E: buscar → nodos relevantes iluminados.

---

### CR.5 — Modo vigilancia

Pantalla dedicada que solo muestra excepciones:
- Sesiones stuck (>30min sin respuesta)
- Provider caído
- Costo alto (>umbral configurable)
- Tests fallando
- Errores en agentes

Sonido/visual diferenciado por severidad.

**Pruebas:** E2E: inyectar eventos → solo los que superan umbral aparecen.

---

**🚪 GATE CR:** abro Canvas AI → veo 3 sesiones activas como nodos en el canvas → click en una → abro el chat → regreso al canvas → la sesión sigue activa → veo las métricas → busco "auth" → un nodo se ilumina → pauso una sesión por acción rápida → verifico que se pausó. Suite humana verde.

---

# PLAN VI — Canvas de Planeación (Grafo de Documentos)

> Depende de: Etapa 4 (memoria/workspace knowledge)

**Entregable:** Grafo vivo de los documentos del proyecto (.md, ADRs, planes) — el "segundo cerebro" donde se crean, editan y conectan ideas con ayuda de IA.

---

### VI.1 — Modelo de documentos

Tabla `documents`:
- `path, title, summary, tags, embeddings (SQLiteVec)`
- Watcher detecta .md nuevos/cambiados del workspace
- Indexador extrae enlaces wiki-style `[[enlace]]` y headings → edges

**Pruebas:** Cargo test parser. Integration: crear/editar/borrar doc actualiza grafo.

---

### VI.2 — Layout IA del grafo

- Clustering automático por carpeta/tags/similitud
- Posiciones calculadas y PERSISTIDAS (terreno 3D)
- Force-directed al abrir, pero posiciones humanas se respetan

**Pruebas:** Unit clustering determinista. E2E: arrastrar nodo → recargar → posición conservada.

---

### VI.3 — Canvas interactivo

Render estilo Obsidian:
- Nodos-tarjeta (título + tags + resumen corto)
- Edges curvos, zoom/pan fluido, minimap
- Búsqueda fuzzy que ilumina subgrafo
- Fisión/fusión visual por cluster
- Hover = preview del documento
- Click = abre en editor (Plan B)
- Look premium con liquid-glass/magic-ui

**Pruebas:** E2E: navegar grafo grande (>200 docs) sin jank.

---

### VI.4 — Edición humano+IA

- Seleccionar N nodos → "sintetizar" genera doc-resumen enlazado
- "resumir" rellena resumen de un nodo
- Editar título/tags inline
- Todo cambio humano marca el nodo como `human_touched`
- **Planeación asistida**: crear nodos-tipo ETAPA/FASE/PLAN desde el grafo
- Órdenes rápidas: "relaciona estos", "reordena", "propón estructura"
- Siempre con diff previo aceptable por el humano

**Pruebas:** Integration síntesis crea doc+edges. E2E humano.

---

### VI.5 — Consejo de Expertos (skills auditores visuales)

Skills que auditan tu plan, detectan puntos ciegos, y hacen preguntas para definir lo indefinido.

**Roster inicial (5 expertos precargados):**
- 🔐 Ciberseguridad
- 🎨 Frontend
- 🏗️ Infraestructura
- 📈 Escalabilidad
- 🧭 Arquitectura

Cada experto es un skill estándar con:
- **Tool-gating READ-only** sobre documents/knowledge
- **Identidad viva**: avatar IA, emoji-firma, mini-bio
- **Invocación desde el grafo**: seleccionas nodo(s) → "Auditar con…"

**Panel derecho "Consejo":**
- Inbox de cards animadas por experto
- Cada card = 1 pregunta con contexto citado + opciones clicables
- Los expertos trabajan EN PARALELO
- Respuesta = rung DECISION + diff aplicado al .md
- Cards-debate ante conflictos entre expertos

**Pruebas:** E2E: convoco 2 expertos → preguntas llegan → respondo → diffs aplicados.

---

### VI.6 — Discovery Hub (explorador de repos)

Panel inferior derecho del Canvas Planeación:
- **Explorador GitHub**: buscar repos por nombre, descripción, topic
- **Repo Scout** (skill IA): sugiere repos relevantes según contexto del proyecto
- **Acciones**: agregar como referencia (nodo en grafo), clonar al workspace, copiar URL
- **Preview inline**: README renderizado, estructura de archivos
- **Historial de búsquedas** persistido por proyecto

**Pruebas:** E2E: buscar "react table" → preview → agregar como referencia → nodo aparece en grafo.

---

**🚪 GATE VI:** abro el grafo de ESTE mismo proyecto → veo clusters reales (docs/, SDDs/) → busco "kanban" → solo ese subgrafo brilla → sintetizo 3 ADRs en una nota nueva enlazada → muevo nodos → mi layout sobrevive reinicios. Convoco al consejo → expertos auditan en paralelo → respondo con clicks → diffs aplicados. Abro Discovery Hub → busco repo → agrego como referencia. Suite humana verde.

---

# PLAN KR — Kanban de Resultados

> Depende de: Etapa 7 (motor de pruebas)

**Entregable:** Tablero evidencia-first donde se ve el progreso de las tareas — cada card tiene evidencia real (tests, diffs, costo), no solo texto.

---

### KR.1 — Tablero de resultados

Columnas: objetivo → en-curso → verificado → entregado
- Cards = tareas con evidencia: mini-gráfica de tests, contador criterios ✓, costo, duración
- Filtros por agente, estado, proyecto

**Pruebas:** Unit estados. E2E: tarea avanza columnas con eventos reales.

---

### KR.2 — Bloques animados de pruebas

Al correr tests:
- Bloque de la card se llena verde test-por-test
- Fallo → bloque rojo pulsante + diff clicable
- Animación de "batería completada" al pasar todos

**Pruebas:** Parser resultados → eventos UI. E2E con mock runner.

---

### KR.3 — Modo autonomía prolongada

Botón "trabaja X horas":
- Cola de tareas se consume sola
- Kanban muestra progreso en vivo
- Digest cada N tareas (resumen automático)
- Límite de costo configurable (corte seguro)

**Pruebas:** Integration: cola mock → consumo ordenado + corte por presupuesto.

---

### KR.4 — Vista evidencia por etapa

Click en card → panel lateral con timeline de rungs de ESA tarea:
- plan → diffs → tests → review
- Thumbnails de screenshots cuando existan
- Costo total de la tarea

**Pruebas:** E2E humano: recorrer evidencia completa sin salir del kanban.

---

### KR.5 — Filtros y salud del board

- Filtrar por agente/etapa/estado-de-tests
- Indicadores de estancamiento (tarea >X horas sin cambio)
- Indicador de tests flaky (cuarentena)

**Pruebas:** E2E: filtros combinados; card estancada muestra badge.

---

**🚪 GATE KR:** activo "trabaja 4 horas" con 15 tareas → me alejo → vuelvo: tablero muestra bloques verdes animados de tests, 12 entregadas, 2 en revisión, 1 bloqueada con causa. Abro evidencia de cualquiera y todo está ahí. Suite humana verde.

---

# PLAN 3D — Preparación Espacial (Gafas/Futuro)

> Depende de: todas las ventanas anteriores

**Entregable:** Todas las ventanas usan un modelo espacial unificado, preparado para visualización en gafas holográficas 2D/3D.

---

### 3D.1 — Modelo espacial transversal

Tipo `SpatialMeta` reutilizado por todas las ventanas:
```typescript
interface SpatialMeta {
  x: number;          // posición horizontal (unidades = metros)
  y: number;          // posición vertical
  z?: number | null;  // profundidad (null en 2D, calculada en 3D)
  cluster?: string;   // agrupación semántica
  camera?: { position: [number, number, number]; target: [number, number, number] };
}
```

Reglas:
1. `z` es `null` en 2D — ReactFlow ignora; Three.js calcula con force-directed
2. Al hacer drag → SpatialMeta se guarda inmediatamente
3. Exportador a JSON espacial común (escena) para las 4 ventanas

**Pruebas:** Unit schema + persistencia. Integration: drag → recargar → posición conservada.

---

### 3D.2 — Visor 3D unificado (prototipo)

Prototipo con Three.js:
- Navegar las 4 ventanas como capas 3D de un mismo mundo
- Controles orbit/touch
- LOD (Level of Detail) para performance
- 60fps con datos reales del proyecto

**Pruebas:** Demo navegación de las 3 capas; perf 60fps.

---

**🚪 GATE 3D:** prototipo navegable del "mundo Canvas AI" en 3D con sesiones, documentos, automatizaciones flotando por clusters — prueba de concepto para gafas. Video.

---

## Estimación

| Plan | Semanas |
|---|---|
| CR Control Room | 2–2.5 |
| VI Canvas Planeación + Consejo | 3–3.5 |
| KR Kanban Resultados | 2–2.5 |
| 3D Preparación Espacial | 1.5–2 |
| **Total** | **~9–10.5 semanas** |

## Reglas

1. Mismas reglas del plan maestro (mini-SDD por plan, 4 capas de prueba, gates con evidencia)
2. Ninguna ventana duplica datos: todas leen sesiones/knowledge/skills
3. Look premium OBLIGATORIO usando tokens Obsidian Glass
4. Todo layout/calculo espacial persistido (terreno gafas)
5. **Canvas AI NO es una empresa autónoma** — es una herramienta de IA generalista

---

*Última actualización: 2026-08-25*
