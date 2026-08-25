# Canvas AI — Plan Maestro v3.0

> **Herramienta de IA generalista** para trabajar con agentes de IA de forma organizada.
> **Híbrido:** local-first gratis (BYOK, trae tu API key) + nube multi-tenant de pago para ejecución 24/7 (ADR-006).
> Open-source, multi-agente, visual, VR-ready.

---

## Qué es Canvas AI

Canvas AI es un **entorno de trabajo** (Tauri v2 local-first) que permite a cualquier persona usar múltiples agentes de IA de forma visual y organizada. No es un chatbot más — es un espacio donde la IA y el humano colaboran en un mismo canvas.

**Problema que resuelve:** Hoy, usar IA implica pestañear entre ChatGPT, Claude, terminales, editores, y herramientas de automatización. Canvas AI unifica todo en un solo lugar: chat con sesiones, canvas visual para orquestar agentes, skills reutilizables, y automatizaciones avanzadas.

**Modelo (ADR-006):**

| | Local-first (desktop) | Nube (SaaS multi-tenant) |
|---|---|---|
| Costo | **Gratis** | **Suscripción** (solo quien la paga) |
| Agentes | Corren en tu máquina | Workers Linux 24/7 |
| Modelos | Tu API key (BYOK) + Ollama offline | Tu API key, ejecutada por el servidor |
| Datos | SQLite local | PostgreSQL + RLS por tenant |

**Referencias arquitectónicas clave:**
- **Hermes Agent** — patrón de subagentes, MoA, MCP, session persistence, **BYOK (trae tu API key)**
- **ERP AI Canvas (FlowsApp)** — canvas de automatización con deploy-spec universal
- **GrokBot** — sesiones, chief of staff pattern, **sandbox Linux por contenedor**
- **Codex/GPT-CDX** — slash commands, allowlists, sandboxed execution, memory rail

---

## Las 4 vistas principales

### 1. Control Room (Canvas visual)
Vista tipo **Affine/Miro**: un canvas infinito donde se ve todo el estado del trabajo.
- Sesiones activas como nodos conectados (CR.1)
- Acciones rápidas desde cada nodo: pausar, retomar, abrir chat (CR.2)
- Métricas en vivo y alertas (CR.3)
- Organización espacial semántica con búsqueda fuzzy (CR.4)
- Modo vigilancia para excepciones (CR.5)
- **VR-ready**: coordenadas 3D, SpatialMeta unificado

### 2. Chat con sesiones
Estilo **GrokBot**: barra lateral con sesiones, panel derecho con rendering vivo.
- **Sidebar izquierda**: lista de sesiones (proyectos, conversaciones, tareas)
- **Panel derecho**: chat con markdown vivo, código con syntax highlight, renders de apps completas (tipo Lovable)
- **Editor de archivos + editor de código** integrado (estilo VS Code ligero)
- Slash commands (`/compact`, `/agent`, `/skill`, `/run`)
- Streaming de respuestas en tiempo real

### 3. Segundo Cerebro (Grafo de archivos del proyecto)
Estilo **Obsidian**: vista en el sidepanel que muestra los archivos del proyecto como un grafo vivo.
- Grafo interactivo de archivos .md, ADRs, planes — navegar la documentación como un mapa
- Edición de archivos markdown inline con ayuda de IA (crear, editar, planeación)
- Búsqueda fuzzy, clustering por carpeta/tags, hover = preview del documento
- Wiki-style links `[[enlace]]` entre documentos
- **Consejo de Expertos**: skills auditores que auditan tu plan en paralelo
- **Discovery Hub**: explorador de repos GitHub para agregar referencias

### 4. Canvas de Automatización
Reemplazo visual de n8n/Activepieces. Basado en el **AI Canvas del ERP Docker Compose**.
- Nodos: LLM, agent, tool, code, trigger, condition, transform, output
- Deploy-spec universal (contrato TypeScript para todos los nodos)
- Canvas compiler: convierte el grafo visual en código ejecutable
- Workflow-as-code codec (serialización/deserialización)
- **Multi-runtime**: Python, TypeScript, Go, Bash, SQL — el canvas no limita el lenguaje
- **Vista Kanban** (pantalla secundaria): tablero evidencia-first con bloques animados de tests, modo autonomía prolongada, evidencia por etapa

---

## Arquitectura técnica

```
┌─────────────────────────────────────────────┐
│  Canvas AI Desktop (Tauri v2 — local-first)  │
│  ┌─────────────┐  ┌──────────────────────┐  │
│  │  Rust Core   │  │  React Frontend      │  │
│  │  (Tauri)     │  │  (@xyflow/react)     │  │
│  │             │  │  Zustand + immer      │  │
│  │  canvas-ai- │  │  React Query          │  │
│  │  core        │  │  Vite 8              │  │
│  │  (lib)       │  │                      │  │
│  │             │  │                      │  │
│  │  canvas-ai- │  │                      │  │
│  │  server      │  │                      │  │
│  │  (Axum)      │  │                      │  │
│  │             │  │                      │  │
│  │  canvas-ai- │  │                      │  │
│  │  worker      │  │                      │  │
│  │  (spawn)     │  │                      │  │
│  └─────────────┘  └──────────────────────┘  │
│                                              │
│  SQLite (SQLiteVec para embeddings)         │
│  ACP Protocol (Hermes) para subagentes      │
│  MCP (stdio/HTTP/SSE) para herramientas    │
└─────────────────────────────────────────────┘

Modo nube (suscripción, multi-tenant — ADR-006):
  Gateway axum → PostgreSQL+RLS → Workers Linux 24/7 (contenedores Ubuntu)
```

**Stack:**
- **Core**: Rust (`canvas-ai-core` — dominio puro, sin dependencias Tauri/HTTP)
- **Server**: Rust/Axum (`canvas-ai-server` — REST/WebSocket, sirve al frontend; en nube es el gateway multi-tenant)
- **Worker**: Rust (`canvas-ai-worker` — spawn de subagentes, sandbox Linux; stateless sin credenciales de DB)
- **Frontend**: React 19 + TypeScript + Vite 8 + @xyflow/react v12 + Zustand + immer
- **Almacenamiento**: SQLite + SQLiteVec (local/Tauri, offline) · PostgreSQL + RLS (nube multi-tenant)
- **Secretos**: keychain del OS (local) · envelope AES-GCM por tenant (nube) — BYOK, nunca en claro
- **Transporte**: ACP (Agent Communication Protocol) para subagentes, MCP para herramientas

**Reglas arquitectónicas (ADR-005 + ADR-006):**
- `canvas-ai-core` NO tiene dependencias de Tauri ni HTTP — es puro dominio
- Todo canvas se diseña VR-ready (coordenadas 3D, 1 unidad = 1 metro)
- El frontend NO hace llamadas HTTP directas — todo pasa por el BFF server
- `tenant_id`/`project_id` en TODO dato desde el día 1 (RLS fail-closed en nube)

---

## Hermes Agent como referencia primaria

Canvas AI adopta los patrones probados de Hermes Agent:

| Patrón Hermes | Implementación en Canvas AI |
|---|---|
| **ACP Protocol** | Comunicación entre agentes via JSON-RPC sobre stdio/HTTP/SSE |
| **Subagent Delegation** | Skills que delegan a sub-agentes con contratos claros |
| **MoA (Mixture of Agents)** | Orquestación de múltiples modelos para una misma tarea |
| **MCP (stdio/HTTP/SSE)** | Integración con herramientas externas |
| **Skills Progression** | 3 tiers: skill → skill+tools → skill+tools+memory |
| **Session Persistence** | Sesiones guardadas en SQLite, reanudables |
| **Gateway Pattern** | El server Axum como gateway entre frontend y agentes |
| **Kanban Coordination** | Tareas con estado, asignación, y tracking |
| **Executive Functions** | Resúmenes, tentacles (búsqueda), handoffs |

---

## Reglas VR-ready (obligatorias para todo canvas)

Todas las vistas canvas se diseñan para funcionar actualmente en 2D y en el futuro en **gafas holográficas 2D/3D**:

1. **Sistema de coordenadas**: origen en el centro, 1 unidad = 1 metro
2. **Sin tamaños absolutos en píxeles**: usar proporciones relativas o unidades del canvas
3. **Sin posicionamiento absolute en CSS del canvas**: usar el sistema de coordenadas de ReactFlow
4. **`vr={{}}` preparado** en ReactFlow (se activa cuando haya soporte nativo)
5. **Transiciones y animaciones**: usar `transform` y `opacity` (GPU-friendly para VR)
6. **Profundidad Z planificada**: capas de profundidad para elementos del canvas (preparado para 3D)
7. **Colores y contraste**: WCAG AAA para legibilidad en AR (aire, no pantalla)
8. **Estados de agentes**: usar iconos/animaciones, no solo color (accesibilidad)

### Modelo espacial transversal (3D)

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

- `z` es `null` en 2D — ReactFlow ignora; Three.js calcula con force-directed
- Al hacer drag → SpatialMeta se guarda inmediatamente
- Exportador a JSON espacial común (escena) para todas las ventanas
- **Visor 3D unificado** (prototipo): navegar las ventanas como capas 3D de un mismo mundo, controles orbit/touch, LOD (Level of Detail), 60fps con datos reales del proyecto

---

## Plan de construcción (Etapas)

> **Orden de ejecución = [MVP-ROADMAP](../../MVP-ROADMAP.md) + [MATRIZ](./MATRIZ-FASES-PRUEBAS.md)** (chat-first: Etapa 2 primero). Las etapas 1-10 son **capacidades**; se construyen en el orden del roadmap, no en su numeración aquí. El **Control Room (Etapa 1) se construye al final** como vista que consume todo (post-v1, Q6) — alineado con ARQUITECTURA y la MATRIZ.

### Etapa 0: Fundación — schema maestro + eventos + secretos
**Objetivo:** Base de datos y contratos desde el día 1 (antes de cualquier UI). Sin esto, todo lo demás exige retrofit.

- [ ] **Schema maestro** — modelo canónico (sesiones, mensajes, skills, canvases, event_stream, ledger) con migraciones versionadas; `tenant_id`/`project_id` en toda tabla
- [ ] **Contrato del `event_stream`** — taxonomía de rungs (PROMPT, PHASE, DIFF, TEST_RESULT, DECISION, ESCALATION) append-only; todos los componentes emiten eventos desde v0
- [ ] **Módulo de secretos BYOK** — API keys del usuario: keychain del OS (local) / envelope AES-GCM por tenant (nube); nunca en claro, nunca al webview
- [ ] **Sandbox Linux** — contrato del contenedor Ubuntu por tarea (red denegada por defecto, allowlist, timeout, kill limpio) — patrón GrokBot
- [ ] **Decision Ledger** — tabla append-only con triggers (UPDATE/DELETE rechazados)
- [ ] **Persistencia real** — sqlx/sqlite conectado (hoy el server vive en memoria `HashMap`)

**Dependencias:** Ninguna (es la base)
**Gate:** migración corre en SQLite y Postgres → seed produce sesión+evento → verificar append-only → key cifrada y descifrable con la correcta. Suite humana no aplica (fase de infraestructura).

---

### Etapa 1: Control Room Canvas *(se construye al final — post-v1, Q6)*
**Objetivo:** Canvas visual infinito donde ves TODAS las sesiones de agentes como nodos vivos — con estado en tiempo real, conexiones, métricas y acciones rápidas.

**CR.1 — Canvas de sesiones:**
- [ ] Canvas ReactFlow con pan/zoom infinito
- [ ] Nodo Session: título, avatar del agente activo, estado (active/thinking/working/done), preview del último mensaje, costo acumulado
- [ ] Nodo Skill: avatar del skill, estado, conexión a sesiones que lo usan
- [ ] Nodo Note: notas libres del usuario (contexto, ideas, pendientes)
- [ ] Nodo Result: resultado de una tarea (pass/fail, diff, archivo generado)
- [ ] Edges: conexiones entre sesiones↔skills, sesiones↔resultados
- [ ] Layout automático: sesiones activas arriba, skills a la izquierda, resultados abajo, notas a los lados (force-directed, respeta posiciones humanas)

**CR.2 — Acciones rápidas desde el nodo:**
- [ ] Click en Session → abrir chat / pausar / retomar / ver evidencia / duplicar / archivar
- [ ] Click en Skill → editar / probar (sandbox) / ver historial de ejecuciones
- [ ] Toolbar: zoom-to-fit, minimap, export PNG

**CR.3 — Métricas en vivo:**
- [ ] Sidebar o overlay con: sesiones activas, agentes trabajando, costo total del día, agentes más usados, sesiones más productivas
- [ ] Alertas: sesión stuck (>30min), provider caído, costo alto (>umbral configurable)

**CR.4 — Organización espacial semántica:**
- [ ] Agrupación opcional por proyecto, agente, o tema
- [ ] Búsqueda fuzzy que ilumina nodos relevantes
- [ ] Filtros: por agente, estado, costo, fecha

**CR.5 — Modo vigilancia:**
- [ ] Pantalla dedicada que solo muestra excepciones (sesiones stuck, provider caído, tests fallando, errores en agentes)
- [ ] Sonido/visual diferenciado por severidad

**Cross-cutting:**
- [ ] Persistencia del canvas en SQLite (posición, conexiones, metadatos)
- [ ] Store Zustand con immer para estado del canvas
- [ ] Canvas vacío con onboarding (tutorial interactivo)
- [ ] **VR-ready**: coordenadas 3D, sin absolute positioning, `vr={{}}`

**Dependencias:** Ninguna (es la base visual)
**Gate:** abro Canvas AI → veo 3 sesiones activas como nodos → click en una → abro chat → regreso → sesión sigue activa → veo métricas → busco "auth" → nodo se ilumina → pauso sesión → verifico que se pausó. Suite humana verde.

---

### Etapa 2: Chat + Sesiones (Plan A revisado)
**Objetivo:** Chat con sesiones estilo GrokBot, sidebar izquierda, rendering vivo derecho.

- [ ] Trait `AgentProvider` (Rust) — abstracción sobre Reasonix/Direct/Ollama
- [ ] Sidebar de sesiones (lista, búsqueda, filtros, carpetas)
- [ ] Panel de chat: markdown vivo, código con highlight, streaming SSE
- [ ] Slash commands (`/compact`, `/agent`, `/skill`, `/run`, `/help`)
- [ ] Memory Rail (franja vertical con rungs de la sesión)
- [ ] Editor de archivos integrado (monaco-editor light o CodeMirror)
- [ ] Editor de código con syntax highlight multi-lenguaje
- [ ] Live preview de apps (iframe sandboxed)
- [ ] Persistencia de sesiones en SQLite (mensajes, contexto, metadata)
- [ ] Reanudación de sesiones (cargar historial completo)
- [ ] Widget de costo por sesión (tokens, USD, cache hits)

**Dependencias:** Etapa 1 (canvas para mostrar sesiones)

---

### Etapa 3: Runtime de agentes (Plan C revisado)
**Objetivo:** Conectar con agentes reales con **BYOK (trae tu API key)**, como Hermes Agent.

- [ ] **Registro universal de proveedores (BYOK)** — cualquier API compatible (OpenAI, Anthropic, OpenRouter, DeepSeek…) se conecta pegando key/URL; selector muestra precio y contexto
- [ ] ReasonixProvider: spawn serve, health check, SSE streaming, stop graceful
- [ ] DeepSeekDirectProvider: HTTP directo a DeepSeek API
- [ ] OllamaProvider: local, para modelos embebidos y **offline sin internet**
- [ ] Router inteligente: chat simple → directo, tool-calls → Reasonix, razonamiento → reasoner
- [ ] Perfiles: economy / balanced / delivery (mapea a configuraciones del proveedor)
- [ ] Telemetría: métricas por sesión, costo acumulado, cache hits
- [ ] Cancelación de tareas en curso
- [ ] ACP Protocol: comunicación entre agentes via JSON-RPC
- [ ] Subagent Delegation: un skill puede delegar a sub-agentes
- [ ] **Sandbox Linux**: skills/agentes que ejecutan código corren en contenedor Ubuntu (patrón GrokBot) — red denegada por defecto

**Dependencias:** Etapa 2 (chat funcional), Etapa 0 (secretos BYOK)

---

### Etapa 4: Memoria y conocimiento (Plan D revisado)
**Objetivo:** El agente recuerda entre sesiones. Knowledge base del proyecto.

- [ ] Decision Ledger: tabla append-only con eventos de sesión
- [ ] Workspace Knowledge: ADRs, convenciones, hechos del proyecto (FTS5)
- [ ] Human-Tweak Lock: coordenadas protegidas por el humano
- [ ] Embeddings vectoriales (SQLiteVec) para búsqueda semántica
- [ ] Inyección automática de contexto en cada prompt
- [ ] `/compact` para comprimir historial viejo
- [ ] Índice semántico dual (símbolos + significado)

**Dependencias:** Etapa 3 (runtime funcionando)

---

### Etapa 5: Panel de Skills (Plan G revisado)
**Objetivo:** Crear, probar y usar skills visualmente. **Un skill es un documento `.md`** (receta) con personalidad, nombre y cara animada.

- [ ] **Modelo de skill = `.md` canónico** — frontmatter (nombre, rol, tools permitidos, presupuesto) + instrucciones; el editor visual compila a `.md`, sin YAML manual
- [ ] CRUD de skills (tabla SQLite, store Zustand, React Query)
- [ ] Editor visual (formulario por secciones, validación Zod)
- [ ] Tool-gating estricto (skill declara tools permitidos)
- [ ] Compilador a dialectos (prompt markdown, reasonix subagent, AGENTS.md)
- [ ] Laboratorio sandbox (probar skill contra input de ejemplo)
- [ ] **Avatar generado por IA** (imagen consistente de nombre+rol, fallback procedural)
- [ ] **Emoji-firma único** por skill
- [ ] **Mini-bio de personalidad** escrita por IA
- [ ] **Ceremonia de creación** (overlay festivo al guardar)
- [ ] Skills globales vs locales (por proyecto)
- [ ] Multi-agent loops (skill orquesta múltiples agentes)
- [ ] Rutinas por demostración ("follow along" — grabar y re-ejecutar)

**Dependencias:** Etapa 3 (runtime), Etapa 4 (memoria para knowledge), Etapa 0 (contrato de skill)

---

### Etapa 5.5: Segundo Cerebro — Grafo de archivos (Plan VI)
**Objetivo:** Vista estilo Obsidian en el sidepanel — el "segundo cerebro" donde navegas, editas y planeas con IA los archivos del proyecto.

- [ ] Modelo de documentos: tabla `documents` (path, title, summary, tags, embeddings SQLiteVec)
- [ ] Watcher de archivos: detecta .md nuevos/cambiados del workspace
- [ ] Indexador de enlaces wiki-style `[[enlace]]` y headings → edges del grafo
- [ ] Layout IA del grafo: clustering automático por carpeta/tags/similitud, posiciones persistidas
- [ ] Canvas interactivo estilo Obsidian: nodos-tarjeta, edges curvos, zoom/pan, minimap, búsqueda fuzzy
- [ ] Hover = preview del documento, click = abre en editor
- [ ] Edición humano+IA: sintetizar N nodos en doc-resumen, resumir, editar inline, crear nodos ETAPA/FASE/PLAN
- [ ] Planeación asistida: órdenes rápidas ("relaciona estos", "reordena", "propón estructura") con diff previo
- [ ] **Consejo de Expertos**: 5 skills auditores (Ciberseguridad, Frontend, Infraestructura, Escalabilidad, Arquitectura) que auditan tu plan en paralelo, con inbox de cards y preguntas
- [ ] **Discovery Hub**: explorador de repos GitHub, Repo Scout (sugiere repos según contexto), agregar como nodo en grafo

**Dependencias:** Etapa 4 (memoria/workspace knowledge), Etapa 8 (editor de código)
**Gate:** abro grafo de ESTE proyecto → veo clusters reales (docs/, SDDs/) → busco "kanban" → subgrafo brilla → sintetizo 3 ADRs en nota nueva enlazada → muevo nodos → layout sobrevive reinicios. Convoco consejo → expertos auditan en paralelo → respondo con clicks → diffs aplicados. Abro Discovery Hub → busco repo → agrego como referencia. Suite humana verde.

---

### Etapa 6: Canvas de Automatización + Kanban (Plan F revisado)
**Objetivo:** Visual workflow builder tipo n8n + vista Kanban de resultados.

- [ ] Node type registry (8 tipos: LLM, agent, tool, code, trigger, condition, transform, output)
- [ ] Deploy-spec universal (contrato TypeScript para ejecución)
- [ ] Canvas compiler: grafo visual → código ejecutable
- [ ] Workflow-as-code codec (serialización JSON/deserialización)
- [ ] Multi-runtime: Python, TS, Go, Bash, SQL
- [ ] Conectores: HTTP, WebSocket, MCP servers, Cron
- [ ] Modo diseño vs modo ejecución (toggle)
- [ ] Historial de ejecuciones con logs
- [ ] **VR-ready**: canvas preparado para visualización 3D
- [ ] Integración con Control Room (automatizaciones como nodos)
- [ ] **KR.1 — Tablero de resultados**: columnas objetivo→en-curso→verificado→entregado, cards con evidencia (tests, diffs, costo)
- [ ] **KR.2 — Bloques animados de pruebas**: bloque se llena verde test-por-test, fallo = rojo pulsante + diff clicable
- [ ] **KR.3 — Modo autonomía prolongada**: "trabaja X horas" con cola que se consume, digest cada N tareas, límite de costo
- [ ] **KR.4 — Vista evidencia por etapa**: click en card → panel lateral con timeline de rungs (plan→diffs→tests→review)
- [ ] **KR.5 — Filtros y salud del board**: filtrar por agente/etapa/estado, indicador de estancamiento, cuarentena de tests flaky

**Dependencias:** Etapa 1 (canvas base), Etapa 3 (runtime para ejecutar), Etapa 7 (motor de pruebas para evidencia)
**Gate kanban:** activo "trabaja 4 horas" con 15 tareas → me alejo → vuelvo: tablero muestra bloques verdes animados, 12 entregadas, 2 en revisión, 1 bloqueada. Abro evidencia y todo está ahí. Suite humana verde.

---

### Etapa 7: Motor de pruebas (Plan H revisado)
**Objetivo:** Agentes trabajan por resultados verificables.

- [ ] Tareas con criterios de aceptación estructurados
- [ ] TestRunner **sandbox Linux** (contenedor Ubuntu, ejecución aislada, allowlist, timeout) — patrón GrokBot
- [ ] Resultados en el canvas (pass/fail/cobertura)
- [ ] Shadow Workspace (pre-ejecutar checks antes de entregar)
- [ ] Auto-corrección silenciosa (bucle interno sin molestar al humano)
- [ ] Escalado inteligente (fallo → reintento → escala a modelo mejor)

**Dependencias:** Etapa 3 (runtime), Etapa 5 (skills definen el cómo)

---

### Etapa 8: Editor de código integrado (Plan B revisado)
**Objetivo:** Editor completo dentro de la app, sin necesidad de VS Code.

- [ ] Monaco Editor o CodeMirror 6 embebido
- [ ] Syntax highlight multi-lenguaje
- [ ] File explorer (sidebar de archivos del proyecto)
- [ ] Tabs múltiples
- [ ] Búsqueda global (grep)
- [ ] Git integration (diff, commit, push)
- [ ] Live preview alongside (split view)
- [ ] Integración con el chat (selección de código → preguntar al agente)

**Dependencias:** Etapa 2 (chat), Etapa 4 (workspace knowledge)

---

### Etapa 9: Marketplace de Skills
**Objetivo:** Compartir y descubrir skills de la comunidad.

- [ ] Publicación de skills (manifest + código)
- [ ] Búsqueda y descarga
- [ ] Ratings y reviews
- [ ] Versionado
- [ ] Trial/preview antes de instalar

**Dependencias:** Etapa 5 (skills funcionando)

---

### Etapa 10: Multi-plataforma + Nube
**Objetivo:** Desktop (Windows/Mac/Linux) gratis, y nube multi-tenant de pago para ejecución 24/7.

- [ ] Tauri builds para las 3 plataformas desktop
- [ ] Build web (WASM) para acceso via navegador (misma SPA, modo ligero)
- [ ] API REST completa para clientes externos
- [ ] **Modo nube (suscripción, ADR-006)**: gateway axum → Postgres+RLS → workers Linux 24/7; los agentes corren aunque cierres la app; **BYOK** (la key del usuario, cifrada por tenant)
- [ ] **Sandbox Linux** en el worker (contenedores Ubuntu provisionados, patrón GrokBot)
- [ ] **Sync multi-dispositivo** (sesiones/canvas/skills) para suscriptores
- [ ] Preparación VR (coordenadas 3D, rendering por capas) — post-v1

**Dependencias:** Etapas 1-8 completas; nube requiere Etapa 0 (RLS/migraciones) + ADR-006

---

## Qué NO es Canvas AI

- **No es un chatbot** — es un entorno de trabajo visual con múltiples sesiones y agentes
- **No es una "empresa autónoma"** — no gestiona jerarquías de "empleados IA", presupuestos de empleados ni dashboards de empresa (eliminado, ADR-006)
- **No es un reemplazo de ChatGPT** — lo complementa con visualización, orquestación y memoria
- **No es un ERP** — aunque referencia el AI Canvas del ERP, es una herramienta independiente
- **No es n8n/Activepieces** — los supera con código nativo multi-runtime y agentes de IA
- **La nube no es gratuita** — el modo 24/7 es de pago (suscripción); local siempre es gratis con tu API key

---

## Archivos de referencia

| Documento | Contenido |
|---|---|
| [PRD](../../PRD.md) | **Producto: personas, JTBD y features → resultado medible Playwright humano** |
| [PRODUCT-METRICS](../../PRODUCT-METRICS.md) | **North-star, activación, retención, eventos y telemetría** |
| [MVP-ROADMAP](../../MVP-ROADMAP.md) | **MVP-1/2/3 time-boxed** con entregables por fase |
| [SCHEMA-MAESTRO](../../SCHEMA-MAESTRO.md) | **Etapa 0 concreta: modelo canónico + migraciones + event_stream** |
| [CONTRATO-SKILL](../../CONTRATO-SKILL.md) | **Formato `.md` de skills (frontmatter + ejemplo)** |
| [THREAT-MODEL](../../THREAT-MODEL.md) | **Modelo de amenazas, sandbox Linux y flujo BYOK** |
| [ADR-006](../../ADRs/ADR-006-vision-hibrida-local-nube.md) | **Visión híbrida: local-first + nube SaaS de pago (Q1-Q12)** |
| [SDD-011](../SDD-011-integracion-hermes-agent.md) | Integración con Hermes Agent (BYOK, ACP, MCP, subagents) |
| [SDD-012](../SDD-012-multi-agent-grokbot-patterns.md) | Patrones multi-agente de GrokBot (sesiones, sandbox Linux) |
| [SDD-013](../SDD-013-gui-visual-spec.md) | Design system Obsidian Glass |
| [plan-a](./plan-a-chat-codex.md) | Chat con sesiones (A.0-A.9, BYOK) |
| [plan-b](./plan-b-sidepanels-lovable.md) | Editor de código + live preview |
| [plan-c](./plan-c-reasonix-deepseek.md) | Runtime de agentes (BYOK, circuit breaker) |
| [plan-d](./plan-d-memoria-v3code.md) | Memoria y knowledge base |
| [plan-f](./plan-f-canva-oficina.md) | Canvas de automatización + Kanban de resultados |
| [plan-g](./plan-g-skills-lab.md) | Skills Lab (recetas `.md` + avatares) |
| [plan-h](./plan-h-motor-pruebas.md) | Motor de pruebas y resultados (sandbox Linux) |
| [plan-i18n](./plan-i18n.md) | **Multilenguaje simple desde el día 1** |
| [plan-vi](./plan-vi-second-brain.md) | Segundo Cerebro — grafo de archivos del proyecto |

> **Post-v1 (Q6):** Voz (K), 3D/VR, Control Room completo (CR), Consejo de Expertos (VI.5+) y dopamina (U.2-U.8) permanecen en el plan marcados como post-v1 — se diseñan pero no bloquean base ni MVP-3.

---

## Estado actual

| Componente | Estado |
|---|---|
| Core Rust (canvas-ai-core) | ✅ Compila, tests pasan |
| Server Axum (canvas-ai-server) | ✅ Compila, API funcional |
| Worker (canvas-ai-worker) | ✅ Compila |
| Tauri integration | ✅ Compila, identificador actualizado |
| Frontend React | ✅ Build exitoso, dev server en :1420 |
| Canvas ReactFlow | ✅ Componente base funcional |
| Residuo "empresa autónoma" (teams/company) | ✅ Eliminado (ADR-006) |
| **PRD + Métrica norte + MVP roadmap** | ✅ Escritos ([PRD](../../PRD.md), [PRODUCT-METRICS](../../PRODUCT-METRICS.md), [MVP-ROADMAP](../../MVP-ROADMAP.md)) |
| **Etapa 0 — Schema maestro + eventos + secretos** | ✅ **Concretada** ([SCHEMA-MAESTRO](../../SCHEMA-MAESTRO.md), [THREAT-MODEL](../../THREAT-MODEL.md)) — pendiente implementación (persistencia real) |
| Contrato de skill `.md` | ✅ Escrito ([CONTRATO-SKILL](../../CONTRATO-SKILL.md)) |
| i18n multilenguaje | ✅ Plan aprobado ([plan-i18n](./plan-i18n.md)) |
| Control Room Canvas (Etapa 1) | 🚧 En progreso |
| Chat + Sesiones (Etapa 2) | ⬜ Pendiente |
| Runtime agentes (Etapa 3) | ⬜ Pendiente |
| Memoria (Etapa 4) | ⬜ Pendiente |
| Skills (Etapa 5) | ⬜ Pendiente |
| Segundo Cerebro (Etapa 5.5) | ⬜ Pendiente |
| Automatización + Kanban (Etapa 6) | ⬜ Pendiente |
| Pruebas (Etapa 7) | ⬜ Pendiente |
| Editor código (Etapa 8) | ⬜ Pendiente |
| Marketplace (Etapa 9) | ⬜ Pendiente |
| Nube 24/7 multi-tenant (Etapa 10) | ⬜ Pendiente (requiere ADR-006) |
| Voz / 3D / Consejo de Expertos / Dopamina | 🔜 Post-v1 (marcados, no bloquean) |

---

*Última actualización: 2026-08-25 (v3.0 — visión híbrida ADR-006)*
