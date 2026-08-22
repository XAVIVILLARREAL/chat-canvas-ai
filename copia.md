# ARQUITECTURA MAESTRA DE FÁBRICA MULTIAGENTE: SOTA & SÍNTESIS OPEN SOURCE

> **Documento de Arquitectura y Referencia Técnica**  
> *Sintetiza lo mejor de:* **V3Code**, **Aider**, **OpenHands**, **Cursor (Shadow Workspace & Fast Apply)**, **LightRAG**, **DSPy**, **Cline / Roo Code**, **MetaGPT** y **Zed**.  
> *Adaptado y Mejorado para:* **Empresa de Desarrollo Autónoma (Tauri 2.0 + React 19 + Rust + Python LangGraph/CrewAI)**  
> *Filosofía Central:* Los agentes son empleados que trabajan por resultados, pruebas y evidencia verificable, con máxima eficiencia de tokens y cero amnesia.

---

## 1. Matriz de Innovaciones y Tecnologías SOTA Adoptadas

| Componente | Origen / Inspiración | Función en Empresa Dev |
|---|---|---|
| **Memoria de 6 Capas** | V3Code | Estructuración atómica de la memoria (desde logs volátiles hasta conocimiento corporativo). |
| **Human-Tweak Lock** | V3Code | Invariantes inmutables a coste 0 tokens: nunca sobreescribir código ni nodos editados por humanos. |
| **Shadow Workspace** | Cursor / SWE-bench SOTA | Instancia invisible en memoria donde se pre-ejecutan linters/compiladores antes de mostrar código al usuario. |
| **Fast Apply & Speculative Diff** | Cursor / Morph Labs | Desacoplamiento de razonamiento y escritura para aplicar diffs a +1.000 tokens/segundo sin truncamientos. |
| **Repo-Map con PageRank** | Aider + Tree-sitter | Compresión del AST del repositorio completo a <1.000 tokens priorizando símbolos por importancia topológica. |
| **LightRAG + `sqlite-vec`** | SOTA Graph-RAG / C-Extension | RAG de grafo dual (código específico + arquitectura global) con búsqueda vectorial nativa en SQLite embebido. |
| **EventStream Pub/Sub** | OpenHands | Flujo inmutable de eventos para reactividad en tiempo real, auditoría forense y *Time-Travel Replay*. |
| **SOP Artifact Assembly Line** | MetaGPT / ChatDev | Ciclo estricto de entrega de artefactos estructurados (PRD -> SDD -> Contratos -> Código -> Tests -> Aprobación). |
| **Tool-Gated Custom Modes** | Cline / Roo Code | Roles de agente (Dev, QA, PM, Reviewer) con montaje dinámico estricto de herramientas MCP para evitar congestión. |
| **DSPy Prompt Compilers** | Stanford NLP | En el *Skills Lab*, auto-optimización declarativa de prompts y few-shot examples basada en métricas de tests. |
| **Context Servers & Rust Core** | Zed | Backend en Rust ultra-rápido con comandos `/slash` sobre el estándar MCP. |

---

## 2. El Sistema de Memoria Unificada de 6 Capas

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ CAPA 6: PROCEDIMENTAL / ROLES, SKILLS & DSPY (Cline + MetaGPT + DSPy)       │
│         Roles (dev, QA, reviewer, PM), SOPs y skills auto-optimizados.      │
├─────────────────────────────────────────────────────────────────────────────┤
│ CAPA 5: EMPRESARIAL / WORKSPACE KNOWLEDGE & LightRAG (V3Code + sqlite-vec)  │
│         ADRs, arquitectura, convenciones, contratos y embeddings vectoriales│
├─────────────────────────────────────────────────────────────────────────────┤
│ CAPA 4: ESTRUCTURAL / REPO-MAP AST CON PAGERANK (Aider + Tree-sitter)       │
│         Grafo topológico de dependencias comprimido (<1.000 tokens) y 3D.   │
├─────────────────────────────────────────────────────────────────────────────┤
│ CAPA 3: INVARIANTES / HUMAN-TWEAK LOCK (V3Code)                             │
│         Líneas de código y nodos del Canva protegidos a coste 0 tokens.     │
├─────────────────────────────────────────────────────────────────────────────┤
│ CAPA 2: AUDITORÍA / EVENTSTREAM & RUNG LEDGER (OpenHands + V3Code)          │
│         Stream inmutable de eventos (PROMPT, PHASE, DIFF, TEST_RESULT, ESC).│
├─────────────────────────────────────────────────────────────────────────────┤
│ CAPA 1: EPISÓDICA / SCRATCHPAD VOLÁTIL & SHADOW WORKSPACE (Cursor/SOTA)     │
│         Pre-validación silenciosa y logs de terminal (auto-purgados).       │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### Capa 1: Memoria Episódica & Shadow Workspace *(Ciclo: Tarea en Curso)*
* **Shadow Workspace:** Antes de presentar un cambio al usuario o marcar una tarea como lista, el backend Tauri aplica el diff en una copia invisible en memoria y ejecuta en milisegundos `tsgo`, `biome` o `cargo check`.
* **Bucle de Auto-Corrección:** Si hay errores de compilación o linter, el agente los recibe como feedback inmediato en su *Scratchpad*.
* **Auto-Purgado:** Al completarse la tarea, los cientos de líneas de logs se descartan por completo; solo se extrae un *Rung de resumen* para la Capa 2.

---

### Capa 2: Auditoría / EventStream & Rung Ledger *(Ciclo: Sesión / Repositorio)*
* **EventStream Pub/Sub:** Cada acción en el sistema es un evento atómico inmutable publicado en el bus central.
* **Taxonomía de Rungs:**
  * `PROMPT`: Requerimiento asignado al agente.
  * `PHASE`: Fase del SOP (`Plan -> Implement -> Test -> Review`).
  * `DIFF`: Modificación concreta (+/- líneas) y patch unificado.
  * `TEST_RESULT`: Evidencia de ejecución de tests (Pass/Fail, assertions).
  * `DECISION`: Decisión técnica aprobada o descartada.
  * `ESCALATION`: Escalado de modelo motivado por doble fallo de pruebas.
* **Time-Travel Replay:** Permite que el **Time-Scrubber** en la UI rebobine el estado del código en Monaco y la oficina animada en ReactFlow a cualquier punto del historial.

---

### Capa 3: Invariantes / Human-Tweak Lock *(Ciclo: Permanente hasta desbloqueo)*
* **Protección Incondicional:** Cualquier modificación manual hecha por el desarrollador humano en Monaco Editor o en el Canva se registra con `is_human_locked = true`.
* **Restricción Negativa Infranqueable:** El agente recibe la orden explícita de no tocar ni sobreescribir esas coordenadas, logrando **cero fricción y cero tokens de negociación**.

---

### Capa 4: Estructural / Repo-Map AST con PageRank *(Ciclo: Indexado en segundo plano)*
* **Tree-sitter + PageRank:** Parsea el código completo en Abstract Syntax Trees, genera el grafo de dependencias de llamadas/imports y aplica PageRank para rankear la relevancia arquitectónica.
* **Compresión Extrema:** Proporciona un mapa de alta fidelidad de todo el repositorio en **menos de 1.000 tokens**.
* **Grafo 3D (Three.js):** Proyecta este grafo en 3D con colores térmicos según la actividad y los fallos de tests.

---

### Capa 5: Empresarial / Workspace Knowledge con LightRAG & `sqlite-vec` *(Ciclo: Histórico)*
* **LightRAG (Grafo Dual):**
  * *Nivel Bajo:* Localiza fragmentos de código, interfaces y funciones específicas.
  * *Nivel Alto:* Conecta conceptos arquitectónicos, ADRs y módulos globales.
* **`sqlite-vec` Nativo:** Búsqueda vectorial KNN directa dentro de SQLite local sin necesidad de servicios externos ni contenedores Docker adicionales.

---

### Capa 6: Procedimental / Roles, Skills Lab & DSPy *(Ciclo: Configuración de Empresa)*
* **Tool Gating por Rol:**
  * *Agente Dev:* Herramientas de edición de código y compilación.
  * *Agente QA:* Herramientas de suites de tests, mocking y cobertura.
  * *Agente PM:* Herramientas de planificación y descomposición de tareas.
* **DSPy Prompt Compilers:** En el *Skills Lab*, los prompts y ejemplos few-shot de los skills se compilan y optimizan automáticamente evaluando la tasa de aprobación de las pruebas.

---

## 3. Protocolo Multiagente SOP: "Code = SOP(Team)"

Los agentes colaboran bajo una línea de montaje estricta basada en el intercambio de artefactos verificables:

```
 ┌─────────────┐        PRD         ┌─────────────┐      Design Doc     ┌─────────────┐
 │ Project Mgr │ ─────────────────> │  Architect  │ ──────────────────> │     Dev     │
 └─────────────┘                    └─────────────┘                     └─────────────┘
                                                                               │
                                                                       Código  │ + Diffs
                                                                               ▼
 ┌─────────────┐     Aprobación     ┌─────────────┐      Test Report    ┌─────────────┐
 │   Humano    │ <───────────────── │  Reviewer   │ <────────────────── │  QA Tester  │
 └─────────────┘      Evidencia     └─────────────┘     (Pass/Fail)     └─────────────┘
```

1. **PM:** Desglosa los requerimientos del usuario en un PRD con criterios de aceptación.
2. **Architect (Modelo Pro):** Elabora el SDD (`docs/SDDs/`) y los contratos de interfaz.
3. **Dev (Modelo Fast):** Escribe el código en el Shadow Workspace.
4. **QA Tester (Automático):** Ejecuta la batería de pruebas (Playwright, Cargo test, Vitest).
5. **Reviewer:** Valida la cobertura, el linter y los criterios de aceptación.
6. **Humano:** Aprueba o rechaza en el Canva basándose en **evidencia verificable**.

---

## 4. Enrutamiento y Escalado Inteligente por Pruebas

```
                       [ Tarea del Ciclo SOP ]
                                  │
                                  ▼
                  [ Modelo Fast / Lite (Dev Agent) ]
                                  │
                                  ▼
                  [ Ejecución de Pruebas en Shadow WS ]
                                  │
                  ┌───────────────┴───────────────┐
                  ▼                               ▼
             [ ✓ PASS ]                       [ ✗ FAIL ]
                  │                               │ (1er fallo: Reintento Fast)
                  ▼                               ▼
         [ Continúa al Reviewer ]          [ ✗ FAIL x2 ]
                                                  │
                                                  ▼
                                       [ Invocación Nivel 2 ]
                                       [ Modelo Pesado (Opus) ]
                                       [ Diagnóstico y Fix ]
```

---

## 5. Esquema de Base de Datos Local en Rust (SQLite + `sqlite-vec`)

```sql
-- Habilitar extensión vectorial en SQLite embebido
-- SELECT load_extension('sqlite_vec');

-- Capa 6: Roles y Permisos Gated
CREATE TABLE IF NOT EXISTS agent_roles (
    id TEXT PRIMARY KEY,
    role_name TEXT NOT NULL,
    sop_phase TEXT NOT NULL,
    allowed_tools TEXT NOT NULL,       -- JSON Array: ["edit_code", "run_linter"]
    model_tier TEXT DEFAULT 'fast'
);

CREATE TABLE IF NOT EXISTS agent_sessions (
    id TEXT PRIMARY KEY,
    role_id TEXT NOT NULL REFERENCES agent_roles(id),
    agent_name TEXT NOT NULL,
    tint_color TEXT NOT NULL,          -- Color hexadecimal (#9a8cf2)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Capa 2: EventStream & Rung Ledger
CREATE TABLE IF NOT EXISTS event_stream (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES agent_sessions(id),
    event_type TEXT NOT NULL,          -- 'PROMPT','PHASE','DIFF','TEST_RESULT','DECISION','ESCALATION'
    summary TEXT NOT NULL,
    payload TEXT,                      -- JSON estructurado
    lines_added INTEGER DEFAULT 0,
    lines_deleted INTEGER DEFAULT 0,
    test_passed BOOLEAN,
    escalation_tier TEXT DEFAULT 'None',
    model_used TEXT NOT NULL,
    tokens_used INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Capa 3: Invariantes y Human-Tweak Lock
CREATE TABLE IF NOT EXISTS human_invariants (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    target_type TEXT NOT NULL,         -- 'CODE_RANGE', 'CANVA_NODE', 'CONFIG'
    file_path TEXT NOT NULL,
    start_line INTEGER,
    end_line INTEGER,
    reason TEXT,
    is_locked BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Capa 4: Repo-Map y Símbolos AST (Tree-sitter)
CREATE TABLE IF NOT EXISTS repo_symbols (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    file_path TEXT NOT NULL,
    symbol_name TEXT NOT NULL,
    symbol_kind TEXT NOT NULL,         -- 'FUNCTION', 'STRUCT', 'CLASS', 'INTERFACE'
    pagerank_score REAL DEFAULT 0.0,
    start_line INTEGER NOT NULL,
    end_line INTEGER NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Capa 5: Base de Conocimiento y Vectores (LightRAG / sqlite-vec)
CREATE TABLE IF NOT EXISTS workspace_knowledge (
    id TEXT PRIMARY KEY,
    category TEXT NOT NULL,            -- 'ADR', 'SDD', 'CONVENTION', 'SCHEMA'
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    tags TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabla virtual de vectores para búsqueda KNN local (sqlite-vec)
CREATE VIRTUAL TABLE IF NOT EXISTS vec_knowledge USING vec0(
    id TEXT PRIMARY KEY,
    embedding float[384]               -- Dimensión de embeddings locales ligeros
);
```

---

## 6. Proyección en la Experiencia Visual de Empresa Dev

1. **Monaco Editor (Memory Rail + Gutter de Atribución):**
   * Franjas de color por sesión en el margen izquierdo.
   * Iconos de candado en líneas con *Human-Tweak Lock*.
2. **Canva 2D ReactFlow (Oficina Animada y Flujo de Trabajo):**
   * Nodos de agentes con estado animado (*Working*, *Blocked*, *Waiting Approval*).
   * Partículas y aristas iluminadas (*Animated Beams* de Magic UI) para el traspaso de artefactos del SOP.
   * **Time-Scrubber** en la parte inferior para reproducir la evolución temporal de la empresa.
3. **Grafo 3D Three.js (Capa 4 — Repo-Map Visual):**
   * Nodos con escala según su puntuación de **PageRank** y colores térmicos según fallos de pruebas.
