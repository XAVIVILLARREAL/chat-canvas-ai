# Canvas AI — Plan Maestro v2.0

> **Herramienta de IA generalista** para trabajar con agentes de IA de forma organizada.
> Open-source, multi-agente, visual, VR-ready.

---

## Qué es Canvas AI

Canvas AI es un **desktop app** (Tauri v2) que permite a cualquier persona usar múltiples agentes de IA de forma visual y organizada. No es un chatbot más — es un **entorno de trabajo** donde la IA y el humano colaboran en un mismo espacio visual.

**Problema que resuelve:** Hoy, usar IA implica pestañear entre ChatGPT, Claude, terminales, editores, y herramientas de automatización. Canvas AI unifica todo en un solo lugar: chat con sesiones, canvas visual para orquestar agentes, skills reutilizables, y automatizaciones avanzadas.

**Referencias arquitectónicas clave:**
- **Hermes Agent** — patrón de subagentes, MoA, MCP, session persistence, skill system
- **ERP AI Canvas (FlowsApp)** — canvas de automatización con deploy-spec universal
- **GrokBot** — modelo de sesiones con invocación de agentes, chief of staff pattern
- **Codex/GPT-CDX** — slash commands, allowlists, sandboxed execution, memory rail

---

## Las 4 vistas principales

### 1. Control Room (Canvas visual)
Vista tipo **Affine/Miro**: un canvas infinito donde se ve todo el estado del trabajo.
- Sesiones activas como nodos conectados
- Agentes trabajando (animaciones de progreso en tiempo real)
- Notas, resultados, artefactos colocados libremente
- **VR-ready**: todo el canvas se diseña para funcionar en gafas holográficas en el futuro (coordenadas 3D, sin tamaños absolutos en píxeles, sistema de unidades en metros)

### 2. Chat con sesiones
Estilo **GrokBot**: barra lateral con sesiones, panel derecho con rendering vivo.
- **Sidebar izquierda**: lista de sesiones (proyectos, conversaciones, tareas)
- **Panel derecho**: chat con markdown vivo, código con syntax highlight, renders de apps completas (tipo Lovable)
- **Editor de archivos + editor de código** integrado (estilo VS Code ligero)
- Slash commands (`/compact`, `/agent`, `/skill`, `/run`)
- Streaming de respuestas en tiempo real

### 3. Panel de Skills
Skills como **ciudadanos de primera clase** con identidad visual.
- Lista visual de skills (cada uno con avatar generado por IA)
- **Multi-agent loops**: un skill puede orquestar múltiples agentes en secuencia o en paralelo
- Skills globales (compartidos entre proyectos) y locales (por proyecto)
- Creación visual de skills (formulario, no YAML)
- **Neuro-psicológicamente gratificante**: avatares animados, estados visuales de progreso, ceremonias de creación

### 4. Canvas de Automatización
Reemplazo visual de n8n/Activepieces. Basado en el **AI Canvas del ERP Docker Compose**.
- Nodos: LLM, agent, tool, code, trigger, condition, transform, output
- Deploy-spec universal (contrato TypeScript para todos los nodos)
- Canvas compiler: convierte el grafo visual en código ejecutable
- Workflow-as-code codec (serialización/deserialización)
- **Multi-runtime**: Python, TypeScript, Go, Bash, SQL — el canvas no limita el lenguaje

---

## Arquitectura técnica

```
┌─────────────────────────────────────────────┐
│  Canvas AI Desktop (Tauri v2)               │
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
```

**Stack:**
- **Core**: Rust (`canvas-ai-core` — dominio puro, sin dependencias Tauri/HTTP)
- **Server**: Rust/Axum (`canvas-ai-server` — REST/WebSocket, sirve al frontend)
- **Worker**: Rust (`canvas-ai-worker` — spawn de subagentes, procesamiento pesado)
- **Frontend**: React 19 + TypeScript + Vite 8 + @xyflow/react v12 + Zustand + immer
- **Almacenamiento**: SQLite con SQLiteVec para embeddings vectoriales
- **Transporte**: ACP (Agent Communication Protocol) para subagentes, MCP para herramientas

**Reglas arquitectónicas (ADR-005):**
- `canvas-ai-core` NO tiene dependencias de Tauri ni HTTP — es puro dominio
- Todo canvas se diseña VR-ready (coordenadas 3D, 1 unidad = 1 metro)
- El frontend NO hace llamadas HTTP directas — todo pasa por el BFF server

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

---

## Plan de construcción (Etapas)

### Etapa 1: Control Room Canvas (SDD-005)
**Objetivo:** Canvas visual infinito con nodos de sesión, agentes, notas y resultados.

- [ ] Canvas ReactFlow con pan/zoom infinito
- [ ] Tipos de nodos: Session, Agent, Note, Result, Skill, Automation
- [ ] Conexiones entre nodos (edges con label)
- [ ] Sidebar de nodos (palette) para arrastrar al canvas
- [ ] Persistencia del canvas en SQLite (posición, conexiones, metadatos)
- [ ] Toolbar: zoom-to-fit, minimap, export PNG
- [ ] **VR-ready**: coordenadas 3D, sin absolute positioning, `vr={{}}`
- [ ] Store Zustand con immer para estado del canvas
- [ ] Canvas vacío con onboarding (tutorial interactivo)

**Dependencias:** Ninguna (es la base visual)

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
**Objetivo:** Conectar con agentes reales (Reasonix, DeepSeek directo, Ollama local).

- [ ] ReasonixProvider: spawn serve, health check, SSE streaming, stop graceful
- [ ] DeepSeekDirectProvider: HTTP directo a DeepSeek API
- [ ] OllamaProvider: local, para modelos embebidos
- [ ] Router inteligente: chat simple → directo, tool-calls → Reasonix, razonamiento → reasoner
- [ ] Perfiles: economy / balanced / delivery (mapea a configuraciones del proveedor)
- [ ] Telemetría: métricas por sesión, costo acumulado, cache hits
- [ ] Cancelación de tareas en curso
- [ ] ACP Protocol: comunicación entre agentes via JSON-RPC
- [ ] Subagent Delegation: un skill puede delegar a sub-agentes

**Dependencias:** Etapa 2 (chat funcional)

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
**Objetivo:** Crear, probar y usar skills visualmente con identidad.

- [ ] CRUD de skills (tabla SQLite, store Zustand, React Query)
- [ ] Editor visual (formulario por secciones, validación Zod, sin YAML)
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

**Dependencias:** Etapa 3 (runtime), Etapa 4 (memoria para knowledge)

---

### Etapa 6: Canvas de Automatización (Plan F revisado)
**Objetivo:** Visual workflow builder tipo n8n, basado en el AI Canvas del ERP.

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

**Dependencias:** Etapa 1 (canvas base), Etapa 3 (runtime para ejecutar)

---

### Etapa 7: Motor de pruebas (Plan H revisado)
**Objetivo:** Agentes trabajan por resultados verificables.

- [ ] Tareas con criterios de aceptación estructurados
- [ ] TestRunner sandbox (ejecución aislada, allowlist, timeout)
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

### Etapa 10: Multi-plataforma
**Objetivo:** Desktop (Windows/Mac/Linux), Web, y preparación VR.

- [ ] Tauri builds para las 3 plataformas desktop
- [ ] Build web (WASM) para acceso via navegador
- [ ] API REST completa para clientes externos
- [ ] Preparación VR (coordinadas 3D, rendering por capas)
- [ ] Pair programming via WebRTC

**Dependencias:** Etapas 1-8 completas

---

## Qué NO es Canvas AI

- **No es un chatbot** — es un entorno de trabajo visual con múltiples sesiones y agentes
- **No es una empresa autónoma** — no gestiona presupuestos, roles, jerarquías ni contratos de "empleados IA"
- **No es un reemplazo de ChatGPT** — lo complementa con visualización, orquestación y memoria
- **No es un ERP** — aunque referencia el AI Canvas del ERP, es una herramienta independiente
- **No es n8n/Activepieces** — los supera con código nativo multi-runtime y agentes de IA

---

## Archivos de referencia

| Documento | Contenido |
|---|---|
| [SDD-005](../SDD-005-plan-intermedio.md) | Diseño visual de las 4 ventanas |
| [SDD-011](../SDD-011-integracion-hermes-agent.md) | Integración con Hermes Agent (ACP, MCP, subagents) |
| [SDD-012](../SDD-012-multi-agent-grokbot-patterns.md) | Patrones multi-agente de GrokBot |
| [SDD-013](../SDD-013-gui-visual-spec.md) | Design system Obsidian Glass |
| [plan-a](./plan-a-chat-codex.md) | Chat con sesiones (detallado) |
| [plan-b](./plan-b-sidepanels-lovable.md) | Editor de código + live preview |
| [plan-c](./plan-c-reasonix-deepseek.md) | Runtime de agentes (Reasonix, DeepSeek) |
| [plan-d](./plan-d-memoria-v3code.md) | Memoria y knowledge base |
| [plan-f](./plan-f-canva-oficina.md) | Canvas de automatización |
| [plan-g](./plan-g-skills-lab.md) | Skills Lab (creación visual) |
| [plan-h](./plan-h-motor-pruebas.md) | Motor de pruebas y resultados |

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
| Control Room Canvas (Etapa 1) | 🚧 En progreso |
| Chat + Sesiones (Etapa 2) | ⬜ Pendiente |
| Runtime agentes (Etapa 3) | ⬜ Pendiente |
| Memoria (Etapa 4) | ⬜ Pendiente |
| Skills (Etapa 5) | ⬜ Pendiente |
| Automatización (Etapa 6) | ⬜ Pendiente |
| Pruebas (Etapa 7) | ⬜ Pendiente |
| Editor código (Etapa 8) | ⬜ Pendiente |

---

*Última actualización: 2026-08-25*
