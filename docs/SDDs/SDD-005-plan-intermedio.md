# SDD-005 · PLAN INTERMEDIO — Las 4 Ventanas visuales del proyecto

> Fecha: 2026-08-23 · Estado: Propuesto → **v3.8 (2026-08-24): INTERCALADO** — NO es "el plan que sigue a la base": es un **carril de vistas** que se construye ENTRE fases base (VI tras F/G, KR tras H, 3D tras J, CR al final paralelo a N/O). Ratificado por el usuario 2026-08-24.
> **Absorbe del base (v3.8)**: **J.3** (visor 3D → sección 3D) y **K.1/K.2** (voz TTS/STT → las consume CR). **K.3** (política de interrupción) SE QUEDA en la base.
> Lógica de negocio documentada en AGENTS.md §"Las 4 Ventanas". Pruebas según [SDD-002](./SDD-002-testing-spec-driven.md).

## Objetivo

Cada proyecto-tenant ([A.0](./SDD-001-plan-base/plan-a-chat-codex.md#a0)) obtiene SU PROPRIO conjunto de ventanas visuales espectaculares, todas vistas sobre los mismos datos (Ledger/knowledge/sesiones) — nunca silos:

| # | Ventana | Qué es | Inspiración |
|---|---|---|---|
| V1 | 🏢 Canva Oficina/Multiagentes | Crear y organizar agentes/equipos; organigrama editable con estados vivos | **YA EXISTE**: [Etapa 6 / plan-f](./SDD-001-plan-base/plan-f-canva-oficina.md) |
| V2 | 🕸️ **CANVAS PLANEACIÓN** | El "segundo cerebro": grafo vivo de los .md del proyecto ordenado por IA, 100% editable humano+IA — **pantalla de planeación y orden**: crear etapas/fases/planes interactuando con los nodos; la IA crea/modifica/resume .md y hace relaciones directamente. **+ CONSEJO DE EXPERTOS**: skills auditores visuales (ciberseguridad, frontend, infraestructura, escalabilidad, arquitectura) que auditan el plan EN PARALELO, hacen preguntas con opciones en un panel animado y refinan el plan contigo | Obsidian graph / Graphify / segundo cerebro de Karpaty |
| V3 | 📋 Kanban de Resultados | Tablero evidencia-first con animaciones de tests/resultados, para autonomía de horas | Jira optimizado para agentes |
| V4 | 💬 Canvas de Sesiones | Cards de sesiones por agente: hablar (TTS/STT), ver resultados, retomar | Grok Bot threads + chat apps |
| V5 | 🎛️ **CONTROL ROOM** | Mapa maestro GLOBAL: todos los proyectos + todas las sesiones de agentes en acción; dar órdenes por voz (STT/TTS) desde un solo lugar | Centro de misión / mission control |

**Regla de terreno 3D/gafas**: toda posición/clúster/profundidad que calculemos se guarda en el modelo de datos (no solo en memoria de UI) — Etapa 10 ya proyecta Three.js; las demás ventanas heredan la preparación.

## Ganchos dejados en la BASE (ya existen, no bloquean nada)

- `event_stream` captura `TEST_RESULT` con payload → V3 lee evidencia sin tablas nuevas
- Knowledge/docs son entidades propias ([D·D.2](./SDD-001-plan-base/plan-d-memoria-v3code.md#d2)) → V2 las grafica
- Sesiones/rungs son entidades navegables ([D·D.3](./SDD-001-plan-base/plan-d-memoria-v3code.md#d3)) → V4 las muestra como cards
- Three.js + repo_symbols+pagerank ([PLAN J](./SDD-001-plan-base/plan-j-grafo3d-repomap.md)) → motor 3D reutilizable por todas las ventanas
- Design System F.0 → primitivas compartidas; skills de `reference/` (magic-ui Animated Beams, react-bits, liquid-glass) dan el look

---

# PLAN VI — Etapa 16: CANVAS PLANEACIÓN (grafo de documentos estilo Obsidian/Graphify)

**Entregable:** la pantalla de PLANEACIÓN Y ORDEN del proyecto — el segundo cerebro: sus .md como grafo hermoso curado por IA y totalmente editable por el humano, donde se crean etapas, fases y planes interactuando con los nodos.

| Fase | Contenido | Pruebas |
|---|---|---|

<a id="vi1"></a>
### VI.1 — Modelo de documentos
Tabla `documents` (path, título IA, resumen IA, tags, embeddings opcionales vía [D·D.5](./SDD-001-plan-base/plan-d-memoria-v3code.md#d5)); watcher detecta .md nuevos/cambiados del workspace; indexador extrae enlaces wiki-style `[[enlace]]` y headings → edges
- **Pruebas:** Cargo test parser enlaces/headings con fixture .md real. Integration: crear/editar/borrar doc actualiza grafo

<a id="vi2"></a>
### VI.2 — Layout IA del grafo
Clustering automático por carpeta/tags/similitud; posiciones calculadas y PERSISTIDAS (terreno 3D); force-directed al abrir, pero posiciones humanas se respetan (drag = guardado)
- **Pruebas:** Unit clustering determinista con seeds. E2E: arrastrar nodo, recargar app → posición conservada

<a id="vi3"></a>
### VI.3 — Canvas interactivo
Render estilo Obsidian: nodos-tarjeta (título+tags+resumen-corto), edges curvos, zoom/pan fluido, minimap, búsqueda fuzzy que ilumina subgrafo, fisión/fusión visual por cluster; hover = preview del documento; click = abre en editor ([B·B.2](./SDD-001-plan-base/plan-b-sidepanels-lovable.md#b2)); look premium con liquid-glass/magic-ui de `reference/`
- **Pruebas:** E2E humano: navegar grafo grande (>200 docs) sin jank; buscar→subgrafo resaltado; abrir doc desde nodo

<a id="vi4"></a>
### VI.4 — Edición humano+IA sobre el grafo
Seleccionar N nodos → "sintetizar" genera doc-resumen enlazado (agente barato); "resumir" rellena resumen de un nodo; editar título/tags inline; TODO cambio humano marca el nodo como `human_touched` (lock suave: la IA no lo reorganiza sin permiso — coherente con [D·D.2](./SDD-001-plan-base/plan-d-memoria-v3code.md#d2)); deshacer global
- **PLANEACIÓN ASISTIDA**: crear nodos-tipo ETAPA/FASE/PLAN desde el grafo (con criterios); invocar a la IA sobre una selección para que cree/modifique/resuma .md directamente ("ordena estos docs", "resume y propón fases"); los nodos-PLAN creados aquí alimentan automáticamente el Kanban ([KR·KR.1](#kr1)) y las tareas del motor ([H·H.1](./SDD-001-plan-base/plan-h-motor-pruebas.md#h1))
- Órdenes rápidas sobre selección: "relaciona estos", "reordena bajo este criterio", "propón estructura" — siempre con diff previo aceptable por el humano
- **Pruebas:** Integration síntesis crea doc+edges. E2E humano: selecciona 3 notas→sintetiza→edita resultado→deshacer→re-hacer

<a id="vi5"></a>
### VI.5 — CONSEJO DE EXPERTOS: skills auditores visuales del plan
**El sistema de skills visual dentro del Canvas Planeación:** un consejo de expertos invocables que AUDITAN tu plan, detectan lo que no viste y te hacen preguntas para definir lo indefinido — refinando el plan cada vez más.

- **Roster inicial de 5 expertos** (skills precargados en biblioteca GLOBAL [G·G.1](./SDD-001-plan-base/plan-g-skills-lab.md#g1), copiables a local [A·A.0](./SDD-001-plan-base/plan-a-chat-codex.md#a0)): 🔐 **Ciberseguridad** · 🎨 **Frontend** · 🏗️ **Infraestructura** · 📈 **Escalabilidad** · 🧭 **Arquitectura** — cada uno con conocimiento profundo de dominio (system-prompt curado + checklist propio de auditoría) y creables/editables en Skills Lab como cualquier skill; el usuario puede sumar sus propios expertos (legal, finanzas, UX…)
- **ADELANTADO como DOGFOOD (v3.8)**: VI.5–VI.7 se construyen en cuanto existan G.1/G.2 (Gate G de la base) y se usan para **AUDITAR los gates de la propia base** — el Consejo revisa el plan maestro mientras se construye (comer nuestro propio dogfood); el primer gate auditado es el propio Gate G
- Cada experto es un skill estándar con **tool-gating estricto READ-ONLY** sobre `documents`/knowledge ([G·G.2](./SDD-001-plan-base/plan-g-skills-lab.md#g2)) — audita y pregunta, JAMÁS escribe sin aprobación humana
- **Identidad viva total** ([G·G.7](./SDD-001-plan-base/plan-g-skills-lab.md#g7)): avatar IA, emoji-firma, mini-bio con personalidad, color de departamento ([F·F.0](./SDD-001-plan-base/plan-f-canva-oficina.md#f0) tokens) — el experto SE VE como especialista real, no como un menú
- **Invocación desde el grafo**: seleccionas nodo(s) ETAPA/FASE/PLAN → "Auditar con…" (elige 1 experto) o "Convocar al consejo" (todos); los expertos aparecen como personajes-nodo alrededor del subgrafo auditado (posiciones persistidas [VI.2](#vi2)); también invocables desde ⌘K ([F·F.7](./SDD-001-plan-base/plan-f-canva-oficina.md#f7))
- Cada experto LEE el subgrafo y produce: **hallazgos** (brechas, riesgos y puntos ciegos de tu plan que quizá no viste) + **preguntas con opciones** sobre lo que NO está definido — con cita del nodo/doc exacto que motiva cada una
- **Pruebas:** Unit: skill experto compila y su gating bloquea escritura. E2E: convoco 2 expertos sobre un nodo-PLAN → sus personajes aparecen conectados al subgrafo; intento de escritura directa del experto → bloqueado por gating

<a id="vi6"></a>
### VI.6 — Panel del Consejo: auditoría EN PARALELO + preguntas con opciones
- **Los N expertos trabajan EN PARALELO** (una sesión por experto vía provider [C·C.1](./SDD-001-plan-base/plan-c-reasonix-deepseek.md#c1); subagentes reasonix `review`/`security-review` como motor barato donde aplique): mientras piensan, su personaje pulsa "ocupado" y sus hallazgos caen en vivo al panel
- **Panel derecho "Consejo"**: inbox de cards/bloques ANIMADOS — cada card = 1 pregunta con contexto citado, **OPCIONES clicables** (2–4 radio-cards + "otra…" texto libre + "posponer"); agrupadas por experto con ProgressRing de avance ([U·U.1](./SDD-001-plan-base/plan-u-motivacion.md#u1)); eliges con clicks, sin teclear si no quieres · **usa la MISMA primitiva visual de opciones numeradas que [PLAN V·V.2](./SDD-001-plan-base/plan-v-visual-grokbot.md#v2)** (aprobaciones del agente y preguntas del Consejo comparten componente)
- **Responder REFINA EL PLAN**: cada respuesta queda como rung DECISION gobernada ([D·D.4](./SDD-001-plan-base/plan-d-memoria-v3code.md#d4)) y dispara al experto a ACTUALIZAR el .md correspondiente — SIEMPRE con diff previo aceptable por el humano (mismo contrato que [VI.4](#vi4)); nodos-fase/etapa nuevos sugeridos se crean como propuesta enlazada
- **Cards-debate ante conflictos entre expertos** (p.ej. 🔐 seguridad vs 🎨 velocidad de entrega): ambos exponen punto + trade-off y proponen síntesis; tú eliges opción A/B/síntesis/custom — la discrepancia queda documentada como decisión, no se pierde
- Barra de progreso global del consejo · responder en cualquier orden · cerrar el panel NO mata sesiones (siguen en background con badge de pendientes)
- **Pruebas:** Integration: 3 expertos mock en paralelo → preguntas llegan agrupadas sin cruzarse; responder aplica rung+diff correcto al doc. Chaos: un experto falla a mitad → sus preguntas quedan marcadas "sin resolver", el resto sigue. E2E humano: respondo 5 preguntas de 3 expertos → veo los diffs aceptados aplicados al plan

<a id="vi7"></a>
### VI.7 — Juice del Consejo (GUI dopaminérgica neuropsicológica)
La sesión de planeación debe SENTIRSE como ser asesorado por un equipo élite — flow + recompensa variable, cero fricción:
- **Micro-vida de los expertos**: idle (respiración sutil) → thinking (partículas concentrándose en su nodo) → speaking (burbuja resumiendo su hallazgo) → done (check + pose satisfecha) — SOLO transform/opacity, respeta `prefers-reduced-motion`
- **Respuesta elegida → cascada de juice** ([U·U.1](./SDD-001-plan-base/plan-u-motivacion.md#u1)): squash&stretch de la card + tick verde con hit-stop 100ms + arpegio ascendente; el nodo del grafo afectado PULSA y muestra badge "+refinado"
- **Recompensa impredecible**: variantes aleatorias de celebración por respuesta (nunca la misma dos veces seguidas = más dopamina)
- **Hitos del consejo**: "Consenso alcanzado" / "Plan refinado a nivel N" → CelebrationOverlay festivo ([U·U.3](./SDD-001-plan-base/plan-u-motivacion.md#u3)) + **score de madurez del plan** visible (huecos detectados vs respondidos — ver tu progreso es la recompensa)
- **Cierre de sesión**: "Acta del Consejo" — digest animado de todo lo definido (hallazgos×experto, decisiones tomadas, diffs aplicados) exportable a un doc nuevo enlazado en el grafo
- Intensidad Apagado/Sutil/Normal/Festivo por scope ([A·A.6](./SDD-001-plan-base/plan-a-chat-codex.md#a6)) · **cero dark patterns**: todas las preguntas son reales del dominio, nunca artificiales para retener
- **Pruebas GUI:** snapshot visual por estado de experto × intensidad · E2E: responder 3 veces seguidas → variantes distintas + arpegio audible (audio spy) · reduced-motion → sin partículas pero flujo completo funcional

<a id="vi8"></a>
### VI.8 — Discovery Hub: explorador de repos + Repo Scout (IA proactiva)
**Panel inferior derecho del Canvas Planeación** — la tercera zona junto al grafo y el Consejo de Expertos. Combina un navegador de GitHub con un skill de IA que sugiere repos relevantes según el contexto del proyecto.

**Layout del Canvas Planeación (actualizado):**
```
┌─────────────────────────────────┬──────────────────────┐
│                                 │  🧠 Consejo Expertos  │
│       GRAFO DE DOCUMENTOS       │  (panel derecho)     │
│       (nodos .md, edges,        │  VI.5-VI.7           │
│        clusters, zoom/pan)      │                      │
│                                 │  ┌──────────────────┐│
│                                 │  │ 🔍 Discovery Hub ││
│                                 │  │ (abajo-derecha)  ││
│                                 │  │ VI.8             ││
├─────────────────────────────────┤  └──────────────────┘│
```

#### VI.8a — Explorador GitHub (navegador integrado)
- **Barra de búsqueda** con fuzzy-match: buscar repos por nombre, descripción, topic, lenguaje
- **Resultados en cards**: avatar del repo, nombre, descripción corta, stars, lenguaje, última actualización, badge "trending" si aplica
- **Preview inline**: click en card → mini-preview con README renderizado, estructura de archivos (tree), dependencias principales
- **Acciones sobre el repo encontrado**:
  - 📌 **Agregar como referencia** → crea nodo `reference` en el grafo con edges a los nodos relacionados
  - 📋 **Clonar al workspace** → shallow clone vía [PLAN M](./SDD-001-plan-base/plan-m-github.md) (Etapa 13) — requiere GitHub auth
  - 🔗 **Copiar URL** → clipboard
- **Filtros**: lenguaje, rango de stars, última actualización, licencia, topic
- **Historial de búsquedas** recientes (persistido por proyecto)
- **Fuente**: GitHub API v3 (REST) con paginación; rate limit 30 req/min sin auth, 5000 con token

#### VI.8b — Repo Scout (skill de IA proactivo)
- **Skill estándar** en Skills Lab ([G·G.1](./SDD-001-plan-base/plan-g-skills-lab.md#g1)) con tool-gating READ-ONLY sobre la API de GitHub y sobre el grafo de documentos
- **Modo proactivo**: cuando el usuario crea/modifica nodos de tipo ETAPA/FASE/PLAN que mencionan conceptos conocidos (auth, CRUD, real-time, deploy, testing, etc.), el scout sugiere repos relevantes automáticamente — aparece como notificación sutil en el Discovery Hub ("💡 3 repos encontrados para 'real-time sync'")
- **Modo manual**: el usuario puede invocar al scout desde ⌘K o desde un botón "Sugerir repos" sobre una selección de nodos del grafo
- **Output del scout**:
  - Lista de repos con **explicación de por qué sirven** para el contexto actual
  - Mapeo automático: qué parte del plan se beneficia de qué repo (edge sugerido)
  - Métricas de relevancia: stars, actividad reciente, calidad de docs, licencia compatible
  - **"Este patrón ya se resolvió en X"** — cita el repo y el archivo relevante
- **Identidad viva** ([G·G.7](./SDD-001-plan-base/plan-g-skills-lab.md#g7)): avatar de explorador, emoji 🔍, mini-bio "Busco soluciones que ya funcionan para que no reinventes la rueda"
- **Integración con el grafo**: repos sugeridos se agregan como nodos `reference` con edges semánticos a los nodos del plan que describen el mismo problema
- **Integración con el Consejo**: los expertos pueden LEER los repos referenciados al auditar ("este enfoque tiene vulnerabilidades conocidas en X issue")

#### VI.8c — Panel de repos guardados
- Lista de repos marcados como referencia para este proyecto
- Cada repo guardado muestra: nombre, por qué se guardó (reasoning del scout o nota manual), edges en el grafo
- **"Refresco"**: el scout re-evalúa repos guardados periódicamente (¿siguen activos? ¿hay alternativas mejores?)
- Exportable: lista de referencias como .md enlazado en el grafo

#### Layout responsive
- **Desktop (>1024px)**: panel inferior derecho, 320px ancho, colapsable
- **Tablet (640-1024px)**: panel flotante que se abre con botón
- **Mobile (<640px)**: pantalla completa al abrir, se cierra con swipe down

- **Pruebas:** Unit: skill Repo Scout compila y su gating bloquea escritura. Integration: buscar "react table" → results con preview; scout sobre nodo "necesito auth" → sugiere repos de auth. E2E humano: abro Discovery Hub, busco un repo, lo agrego como referencia → aparece nodo en el grafo con edge; scout sugiere 3 repos → selecciono 1 → se agrega; preview de README renderizado; filter por stars funciona; historial persiste tras reinicio

---

**🚪 GATE VI (ampliado):** abro el grafo de ESTE mismo proyecto: veo clusters reales (docs/, SDDs/, ADRs/), busco "kanban" y solo ese subgrafo brilla, sintetizo 3 ADRs en una nota nueva enlazada, muevo nodos y mi layout sobrevive reinicios. **Convoco al consejo completo sobre este plan: los 5 expertos auditan en paralelo, me llegan preguntas con opciones al panel derecho, respondo con clicks, veo los diffs aplicados y recibo el acta final — todo fluido y celebratorio.** Abro el Discovery Hub: busco "react data table" → preview de 3 repos → agrego 1 como referencia → aparece nodo en el grafo; el Repo Scout sugiere "para auth usa NextAuth" → lo acepto → nodo reference conectado. **Video + suites verdes.**

---

# PLAN KR — Etapa 17: Kanban de Resultados animados (evidencia-first)

**Entregable:** el tablero donde delegas horas de trabajo autónomo y VES qué se consiguió — cada card es evidencia viva, no texto muerto.

| Fase | Contenido | Pruebas |
|---|---|---|

<a id="kr1"></a>
### KR.1 — Tablero de resultados
Columnas objetivo→en-curso→verificado→entregado (ciclo SOP); cards = tareas ([H·H.1](./SDD-001-plan-base/plan-h-motor-pruebas.md#h1)) enriquecidas con evidencia: mini-gráfica de tests, contador criterios ✓, coste, duración
- **Pruebas:** Unit estados. E2E: tarea avanza columnas automáticamente con eventos reales

<a id="kr2"></a>
### KR.2 — Bloques animados de pruebas
Al correr tests ([H·H.2](./SDD-001-plan-base/plan-h-motor-pruebas.md#h2)): bloque de la card se llena verde test-por-test (Playwright results parseados); fallo → bloque rojo pulsante + diff clicable; animación de "batería completada" al pasar todos (confetti sutil opcional, respeta reduced-motion)
- **Pruebas:** Parser resultados Playwright/vitest→eventos UI. E2E con mock runner: secuencia animada correcta

<a id="kr3"></a>
### KR.3 — Modo autonomía prolongada
Botón "trabaja X horas": cola de tareas del proyecto se consume sola; kanban muestra progreso en vivo, digest cada N tareas ([N·N.6](./SDD-001-plan-base/plan-n-empresas-autonomas.md#n6)), presupuesto visible y corte seguro ([N·N.3](./SDD-001-plan-base/plan-n-empresas-autonomas.md#n3))
- **Pruebas:** Integration: cola mock de 20 tareas → consumo ordenado + corte por presupuesto. Chaos: provider cae a mitad → pausa limpia

<a id="kr4"></a>
### KR.4 — Vista evidencia por etapa
Click en card → panel lateral con timeline de rungs de ESA tarea ([D·D.1](./plan-d-memoria-v3code.md#d1)): plan→diffs→tests→review ([I·I.1](./plan-i-revision-superposiciones.md#i1)) con thumbnails de screenshots de la suite humana cuando existan
- **Pruebas:** E2E humano: recorrer evidencia completa de una tarea sin salir del kanban

<a id="kr5"></a>
### KR.5 — Filtros y salud del board
Filtrar por agente/etapa/estado-de-tests; indicadores de estancamiento ([I·I.2](./plan-i-revision-superposiciones.md#i2)) y flaky cuarentena ([H·H.8](./plan-h-motor-pruebas.md#h8)) visibles en las cards
- **Pruebas:** E2E: filtros combinados; card estancada muestra badge

**🚪 GATE KR:** activo "trabaja 4 horas" con 15 tareas → me alejo → vuelvo: el tablero muestra bloques verdes animados de tests, 12 entregadas, 2 en revisión con risk-score, 1 bloqueada con causa; abro evidencia de cualquiera y todo está ahí. Video timelapse + suites verdes.

---

# PLAN CR — Etapa 18: CONTROL ROOM (sesiones + mapa global, fusionadas)

> Depende de: A.0 tenants + ventanas anteriores + [K voz](./plan-k-voz.md). Unifica lo que eran dos ventanas: **las cards de sesión viva** Y **el mapa global** — es la mission control del sistema entero.

**Entregable:** un solo lugar donde ves TODOS los proyectos, TODAS las sesiones de agentes como cards vivas (hablarles, ver resultados, retomar), su salud y costos — y das órdenes por voz o texto a cualquiera.

<a id="cr1"></a>
### CR.1 — Mapa global en vivo
- Vista agregada cross-proyecto: cada proyecto como tarjeta-zona con sus agentes activos dentro (estados en tiempo real vía EventBus [C·C.1](./plan-c-reasonix-deepseek.md#c1))
- Métricas globales: agentes corriendo · tareas activas · gasto hoy · alertas abiertas ([I·I.2](./plan-i-revision-superposiciones.md#i2))
- Drill-down sin perder contexto global
- **Pruebas:** E2E humano: 3 proyectos con actividad simulada → mapa refleja estados <1s tras cada evento

<a id="cr2"></a>
### CR.2 — Cards de sesión vivas
Card por sesión ([A·A.0](./plan-a-chat-codex.md#a0) scoped): avatar del agente ([N·N.6](./plan-n-empresas-autonomas.md#n6)), último mensaje, estado (activa/en-espera/terminada), mini-rail de rungs, coste acumulado; layout libre persistido (mismo motor de posiciones que [VI.2](#vi2))
- **Pruebas:** E2E: cards aparecen/desaparecen con sesiones reales; layout persiste
- **Acciones rápidas desde la card**: abrir chat anclado · 🎙️ push-to-talk directo ([K·K.2](./plan-k-voz.md#k2)) · 🔊 escuchar último resumen TTS ([K·K.1](./plan-k-voz.md#k1)) · ver evidencia (salta a [KR.4](#kr4)) · fork/resume
- **Pruebas:** E2E humano: cards aparecen/desaparecen con sesiones reales; hablar por voz desde la card y recibir TTS sin abrir el chat

<a id="cr3"></a>
### CR.3 — Órdenes maestras por voz/texto
- Composer global con STT/TTS: "pausa el dev del proyecto café", "dale prioridad al fix de login", "resume qué hizo QA hoy" — enrutamiento al proyecto/agente correcto CON confirmación de destino antes de ejecutar
- Órdenes grupales: "pausa TODOS los agentes", "modo economía en todo"
- Cada orden queda como rung DECISION auditado en el Ledger del proyecto afectado
- **Pruebas:** Integration routing comando→destino correcto. E2E humano: 5 órdenes habladas consecutivas, todas enrutadas y confirmadas

<a id="cr4"></a>
### CR.4 — Organización espacial semántica
Agrupación opcional por agente/proyecto-tema usando el índice dual ([D·D.5](./plan-d-memoria-v3code.md#d5)): sesiones parecidas se atraen; buscador "sesiones sobre auth" las ilumina
- **Pruebas:** Unit similitud→layout sugerido. E2E: buscar agrupa/ilumina correctamente

<a id="cr5"></a>
### CR.5 — Alertas y modo vigilancia
- Modo "vigilancia": pantalla dedicada que solo muestra excepciones (bloqueados, presupuestos al 80%+, tests rotos en main) usando la política de interrupción [K·K.3](./plan-k-voz.md#k3)
- Sonido/visual diferenciado por severidad; acuse recibo desde la misma pantalla
- **Pruebas:** E2E: inyectar eventos de severidad mixta → solo los que superan umbral aparecen; acuse limpia alerta

## 🚪 GATE CR (demo verificable)

Demo de misión control: 4 proyectos vivos, agentes trabajando en 3; el mapa muestra las cards de sesión en tiempo real; por voz pido "resumen del proyecto cafetería" → TTS responde; hablo directo a un agente desde su card; detecto uno bloqueado → le doy orden → se desbloquea; pauso toda una empresa por voz. Video + suites verdes.

---

# PLAN 3D — Etapa 19: Preparación espacial (gafas/futuro)

| Fase | Contenido | Pruebas |
|---|---|---|

<a id="3d1"></a>
### 3D.1 — Modelo espacial transversal
Todas las ventanas usan el tipo `SpatialMeta` definido en [F.0](./SDD-001-plan-base/plan-f-canva-oficina.md#f0) y lo persisten desde [F.4](./SDD-001-plan-base/plan-f-canva-oficina.md#f4). El schema formal:

```typescript
// Tipo definido en F.0, reutilizado por todas las ventanas
interface SpatialMeta {
  x: number;          // posición horizontal
  y: number;          // posición vertical
  z?: number | null;  // profundidad (null en 2D, calculada en 3D)
  cluster?: string;   // agrupación semántica
  camera?: { position: [number, number, number]; target: [number, number, number] };
}

// Persistencia: cada ventana guarda SpatialMeta en su tabla/evento correspondiente
// - Oficina (F.4): event_stream con tipo SPATIAL_POSITION
// - Planeación (VI.2): tabla documents con columna spatial JSONB
// - Kanban (KR.1): event_stream con tipo SPATIAL_POSITION
// - Control Room (CR.2): event_stream con tipo SPATIAL_POSITION
```

**Reglas de persistencia:**
1. `z` es `null` en 2D — ReactFlow ignora; Three.js lo calcula con force-directed
2. Al hacer drag → `SpatialMeta` se guarda inmediatamente (no al cerrar sesión)
3. Force-directed al abrir respeta posiciones humanas (si hay `z` guardado, úsalo; si no, calcular)
4. Exportador a JSON espacial común (escena) para las 4 ventanas — roundtrip export/import
- **Pruebas:** Unit schema SpatialMeta + persistencia. Integration: drag nodo → recargar → posición conservada. Roundtrip export/import de escena completa

<a id="3d2"></a>
### 3D.2 — Visor 3D unificado (prototipo)
Reutiliza el motor de [PLAN J](./plan-j-grafo3d-repomap.md#j3) para navegar grafo-docs + kanban + sesiones como capas 3D de un mismo mundo; controles orbit/touch; LOD
- **Pruebas:** Demo navegación de las 3 capas; perf 60fps con datos reales del proyecto

**🚪 GATE 3D:** prototipo navegable del "mundo Empresa Dev" en 3D con los documentos, el tablero y las sesiones flotando por clusters — prueba de concepto para gafas. Video.

## Estimación del Plan Intermedio (intercalado v3.8)

| Plan | Semanas | Cuándo (intercalado en la base) |
|---|---|---|
| VI.1–VI.4 Canvas Planeación | 2.5–3 | tras Gate F |
| VI.5–VI.7 **Consejo de Expertos** | 1.5–2 | tras Gate G — DOGFOOD: audita los gates de la base |
| VI.8 **Discovery Hub** (explorador GitHub + Repo Scout) | 1–1.5 | tras Gate G — exploración de repos + nodos-referencia |
| KR Kanban resultados | 2–2.5 | tras Gate H (KR.3 tras N.3/N.6) |
| 3D (3D.1 + **J.3** + 3D.2) | 1.5–2 | tras Gate J |
| Voz (**K.1/K.2**) | 1 | junto a CR |
| CR Control Room | 2.5–3 | al final (paralelo a N/O) — la vista que unifica |
| **Total intermedio** | **~11–13 semanas** | intercaladas en la línea de la base (no suman a su camino crítico completo) |

## Reglas

1. Mismas reglas no negociables del maestro (mini-SDD por plan, 4 capas de prueba, gates con evidencia)
2. NINGUNA ventana duplica datos: todas leen Ledger/knowledge/sesiones — si necesitas tabla nueva, primero justifica por qué un rung no alcanza
3. Look premium OBLIGATORIO usando tokens F.0 + recursos de `reference/` — prohibido CSS improvisado
4. Todo layout/calculo espacial persistido (terreno gafas)
