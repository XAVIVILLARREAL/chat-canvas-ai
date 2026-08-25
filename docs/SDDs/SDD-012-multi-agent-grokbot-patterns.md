# SDD-012 — Multi-Agent: Patrones GrokBot + A2A Hermes

> Fecha: 2026-08-24 · Estado: Propuesto · Fuente: GrokBot (SpaceXAI), Hermes Agent (Nous Research), Microsoft Agent Framework

---

## 1. Resumen Ejecutivo

Este SDD define la arquitectura multi-agente de Canvas AI inspirada en:
- **GrokBot**: Group chat, Chief of Staff, Routine Learning, comportamiento proactivo
- **Hermes Agent**: A2A Protocol, Skills format (SKILL.md), Subagent lifecycle
- **Microsoft Agent Framework**: Orchestration patterns (sequential, concurrent, handoff, group)

**Objetivo**: Agentes que se coordinan entre sí como un equipo humano, aprenden rutinas, y ejecutan trabajo en paralelo — sin intervención humana constante.

---

## 2. Análisis Comparativo

### 2.1 GrokBot vs Hermes vs Canvas AI

| Característica | GrokBot | Hermes | Canvas AI (actual) | Canvas AI (SDD-012) |
|---|---|---|---|---|
| **Group Chat** | ✅ Bots coordinan en thread | ❌ No tiene | ❌ No existe | ✅ A2A + shared context |
| **Chief of Staff** | ✅ Un bot gestiona especialistas | ⚠️ delegate_task | ⚠️ Plan N (concepto) | ✅ Orchestrator pattern |
| **Routine Learning** | ✅ "Follow along" → routine | ⚠️ Skills manuales | ⚠️ Plan G (skills lab) | ✅ Auto-generación SKILL.md |
| **Comportamiento proactivo** | ✅ "Picking up work before you ask" | ❌ No tiene | ❌ No existe | ✅ Watchdog + triggers |
| **A2A Protocol** | ❌ Propietario | ✅ A2A v1.0 | ❌ No tiene | ✅ Hermes A2A |
| **Computer Use** | ✅ Cloud computer | ❌ Terminal local | ❌ No tiene | ⚠️ Terminal + browser |
| **Multi-platform** | ✅ Desktop + iOS | ✅ CLI + TUI + Desktop | ✅ Tauri (desktop) | ✅ Tauri + A2A |
| **Open-source** | ❌ Closed | ✅ MIT | ✅ Nuestro código | ✅ Nuestro código |

### 2.2 Lo que copiamos de cada uno

| Fuente | Patrón | Implementación |
|---|---|---|
| **GrokBot** | Group Chat | A2A protocol + shared thread |
| **GrokBot** | Chief of Staff | Orchestrator pattern (Plan N) |
| **GrokBot** | Routine Learning | Auto-generación SKILL.md |
| **Hermes** | A2A Protocol | Adaptado a Rust/Tauri |
| **Hermes** | SKILL.md Format | Formato portable estándar |
| **Hermes** | Subagent Lifecycle | Registry + state machine |
| **MS Agent Framework** | Orchestration Patterns | Sequential, concurrent, handoff, group |

---

## 3. Arquitectura Propuesta

### 3.1 Componentes Principales

```
┌─────────────────────────────────────────────────────────────────┐
│                    EMPRESA DEV MULTI-AGENT                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│  │   AGENT A    │    │   AGENT B    │    │   AGENT C    │     │
│  │  (Research)  │    │   (Code)     │    │  (Review)    │     │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘     │
│         │                   │                   │               │
│         └───────────────────┼───────────────────┘               │
│                             │                                   │
│                    ┌────────▼────────┐                          │
│                    │  A2A PROTOCOL   │                          │
│                    │  (JSON-RPC 2.0) │                          │
│                    └────────┬────────┘                          │
│                             │                                   │
│  ┌──────────────────────────┼──────────────────────────┐       │
│  │            ORCHESTRATOR LAYER                       │       │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐│       │
│  │  │Chief of Staff│  │Group Chat   │  │Routine      ││       │
│  │  │  (Leader)   │  │  Manager    │  │  Learner    ││       │
│  │  └─────────────┘  └─────────────┘  └─────────────┘│       │
│  └────────────────────────────────────────────────────┘       │
│                             │                                   │
│                    ┌────────▼────────┐                          │
│                    │  SKILL REGISTRY │                          │
│                    │  (SKILL.md)     │                          │
│                    └─────────────────┘                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 A2A Protocol (adaptado de Hermes)

#### 3.2.1 Agent Card

Cada agente expone su "Agent Card" para descubrimiento:

```json
{
  "name": "research-agent",
  "description": "Agente de investigación y análisis",
  "url": "http://localhost:3030/agents/research",
  "capabilities": ["web_search", "data_analysis", "report_generation"],
  "version": "1.0.0",
  "provider": "canvas-ai",
  "skills": ["research-skill", "data-analysis"]
}
```

#### 3.2.2 JSON-RPC Methods

| Método | Descripción | Equivalente GrokBot |
|---|---|---|
| `message/send` | Enviar tarea a agente | "Message a Bot" |
| `message/stream` | Streaming SSE | Respuesta en tiempo real |
| `tasks/get` | Obtener estado de tarea | "Check Bot progress" |
| `tasks/list` | Listar tareas activas | "See all Bots" |
| `tasks/cancel` | Cancelar tarea | "Stop Bot" |

#### 3.2.3 Task Lifecycle

```
SUBMITTED → WORKING → COMPLETED
              ↓
           FAILED
              ↓
           CANCELED
```

### 3.3 Group Chat Pattern (de GrokBot)

#### 3.3.1 Concepción

En GrokBot, los Bots se colocan en un "group chat" donde coordinan trabajo:
- Pasan trabajo entre ellos
- Asignan ownership
- Solo traen al humano para decisiones de juicio

#### 3.3.2 Implementación en Canvas AI

```rust
// Estructura para Group Chat
pub struct GroupChat {
    pub id: String,
    pub agents: Vec<AgentId>,
    pub messages: Vec<ChatMessage>,
    pub shared_context: SharedContext,
    pub coordinator: AgentId,  // Chief of Staff
}

pub struct ChatMessage {
    pub from: AgentId,
    pub to: Option<AgentId>,  // None = broadcast
    pub content: String,
    pub message_type: MessageType,
    pub timestamp: DateTime<Utc>,
}

pub enum MessageType {
    TaskDelegation,      // "Haz esto"
    TaskResult,          // "Terminé esto"
    Question,            // "¿Qué hago con esto?"
    StatusUpdate,        // "Voy en 50%"
    Handoff,             // "Paso esto a @agent-b"
    ApprovalRequired,    // "Necesito aprobación"
}
```

#### 3.3.3 Flujo de Group Chat

```
1. Usuario envía tarea al Group Chat
2. Chief of Staff analiza y descompone
3. Chief of Staff delega a especialistas
4. Especialistas trabajan en paralelo
5. Especialistas se pasan trabajo entre sí
6. Chief of Staff sintetiza resultados
7. Chief of Staff reporta a usuario
```

### 3.4 Chief of Staff Pattern (de GrokBot)

#### 3.4.1 Concepción

En GrokBot internamente:
> "A chief of staff sits on top, with a specialist for each lane: inbox management, expenses, recruiting, bug fixes, or operations."

#### 3.4.2 Implementación en Canvas AI

```rust
// Chief of Staff = Orchestrator
pub struct ChiefOfStaff {
    pub agent_id: AgentId,
    pub specialists: HashMap<SpecialistRole, AgentId>,
    pub active_tasks: Vec<TaskId>,
    pub completed_tasks: Vec<TaskResult>,
}

pub enum SpecialistRole {
    Researcher,
    Coder,
    Reviewer,
    Tester,
    DevOps,
    Writer,
    // Extensible...
}

impl ChiefOfStaff {
    pub fn decompose_task(&self, task: &Task) -> Vec<SubTask> {
        // LLM analiza tarea y genera sub-tareas
        // Cada sub-tarea asignada al especialista correcto
    }
    
    pub fn coordinate(&self, subtasks: Vec<SubTask>) -> Vec<Delegation> {
        // Determina dependencias y paralelismo
        // Devuelve delegaciones optimizadas
    }
}
```

### 3.5 Routine Learning (de GrokBot)

#### 3.5.1 Concepción

En GrokBot:
> "The best way for a Bot to learn your workflow is to ask it to follow along the next time you do a job. It watches the steps and remembers how you like the work done. It saves your workflow as a routine."

#### 3.5.2 Implementación en Canvas AI

**Fase 1: Observación**
```rust
pub struct WorkflowObserver {
    pub observed_steps: Vec<WorkflowStep>,
    pub context: WorkflowContext,
}

pub struct WorkflowStep {
    pub action: String,
    pub tool_used: String,
    pub parameters: HashMap<String, Value>,
    pub result: Value,
    pub timestamp: DateTime<Utc>,
}
```

**Fase 2: Generalización**
```rust
pub struct WorkflowGeneralizer {
    pub patterns: Vec<WorkflowPattern>,
}

pub struct WorkflowPattern {
    pub name: String,
    pub steps: Vec<StepTemplate>,
    pub variables: Vec<Variable>,
    pub triggers: Vec<Trigger>,
}
```

**Fase 3: SKILL.md Auto-generado**
```markdown
---
name: auto-generated-workflow
description: "Workflow aprendido de observación humana"
version: 1.0.0
source: "routine_learning"
observed_from: "user-workflow"
---

# Workflow: [Nombre detectado]

## Pasos
1. [Paso 1 con variables]
2. [Paso 2 con variables]
...

## Variables
- ${input_file}: Archivo de entrada
- ${output_format}: Formato de salida

## Triggers
- Cuando usuario dice "haz X"
- Cuando detecta condición Y
```

### 3.6 Proactive Behavior (de GrokBot)

#### 3.6.1 Concepción

En GrokBot:
> "Over time they become more proactive, picking up work before you need to ask and knowing when something needs your attention."

#### 3.6.2 Implementación en Canvas AI

```rust
pub struct ProactiveEngine {
    pub triggers: Vec<ProactiveTrigger>,
    pub watched_patterns: Vec<WatchedPattern>,
}

pub enum ProactiveTrigger {
    // Temporales
    Scheduled(String),           // "Cada lunes a las 9am"
    Interval(Duration),          // "Cada 30 minutos"
    
    // Basados en eventos
    FileChanged(PathBuf),        // "Cuando cambie este archivo"
    GitCommit(String),           // "Cuando hagan commit en main"
    ErrorDetected(String),       // "Cuando haya un error en logs"
    
    // Basados en contexto
    StaleData(Duration),         // "Cuando datos tengan >24h sin actualizar"
    ThresholdExceeded(f64),      // "Cuando metrica supere umbral"
    PatternDetected(String),     // "Cuando detecte patron X"
}

impl ProactiveEngine {
    pub fn check_triggers(&self, context: &Context) -> Vec<ProactiveAction> {
        let mut actions = Vec::new();
        for trigger in &self.triggers {
            if trigger.should_fire(context) {
                actions.push(trigger.create_action(context));
            }
        }
        actions
    }
}
```

---

## 4. SKILL.md Format (estándar portable)

### 4.1 Formato Hermes (referencia)

```markdown
---
name: skill-name
description: "Descripción corta"
version: 1.0.0
author: "Autor"
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [tag1, tag2]
    related_skills: [other-skill]
---

# Skill Title

## When to Use
...

## Prerequisites
...

## How to Run
...

## Procedure
...

## Verification
...
```

### 4.2 Formato Canvas AI (adaptado)

```markdown
---
name: skill-name
description: "Descripción corta"
version: 1.0.0
author: "Autor"
license: MIT
platforms: [linux, macos, windows]
source: "manual|routine_learning|imported"
metadata:
  empresa:
    tags: [tag1, tag2]
    related_skills: [other-skill]
    difficulty: "beginner|intermediate|advanced"
    estimated_time: "5min"
    cost_estimate: "$0.02"
---

# Skill Title

## When to Use
...

## Prerequisites
...

## How to Run
...

## Procedure
...

## Verification
...

## Cost Estimate
- Tokens: ~1000
- Time: ~30s
- Provider: deepseek
```

### 4.3 Diferencias clave con Hermes

| Campo | Hermes | Canvas AI |
|---|---|---|
| `source` | No tiene | `manual\|routine_learning\|imported` |
| `difficulty` | No tiene | `beginner\|intermediate\|advanced` |
| `estimated_time` | No tiene | Tiempo estimado |
| `cost_estimate` | No tiene | Costo estimado en tokens/$ |

---

## 5. Subagent Lifecycle (adaptado de Hermes)

### 5.1 Estados del Subagente

```rust
pub enum SubagentState {
    Pending,      // Creado, esperando start
    Starting,     // Inicializando
    Running,      // Ejecutando
    Succeeded,    // Completado exitosamente
    Failed,       // Falló
    Interrupted,  // Interrumpido por usuario
    CancelRequested, // Cancelación solicitada
    Cancelled,    // Cancelado
    Unknown,      // Estado desconocido
}
```

### 5.2 Handle del Subagente

```rust
pub struct SubagentHandle {
    pub contract_version: u32,
    pub subagent_id: String,
    pub parent_session_id: Option<String>,
    pub correlation_id: Option<String>,
    pub created_at: f64,
    pub provider: Option<String>,
    pub model: Option<String>,
    pub role: String,
    pub depth: u32,
    pub capability: String,
}
```

### 5.3 Registry (thread-safe)

```rust
pub struct SubagentRegistry {
    records: HashMap<String, SubagentRecord>,
    correlations: HashMap<(Option<String>, String), String>,
}

pub struct SubagentRecord {
    pub handle: SubagentHandle,
    pub state: SubagentState,
    pub updated_at: f64,
    pub result: Option<SubagentResult>,
}
```

---

## 6. Orchestration Patterns (de Microsoft Agent Framework)

### 6.1 Sequential Pattern

```
Agent A → Agent B → Agent C → Result
```

**Uso**: Pipelines donde cada paso depende del anterior.

### 6.2 Concurrent Pattern

```
Agent A ─┐
Agent B ─┼→ Aggregate → Result
Agent C ─┘
```

**Uso**: Tareas paralelas que se combinan.

### 6.3 Handoff Pattern

```
Agent A → (decide) → Agent B → (decide) → Agent C → Result
```

**Uso**: Delegación dinámica según contexto.

### 6.4 Group Chat Pattern

```
Agent A ←→ Agent B
  ↕           ↕
Agent C ←→ Agent D → Coordinator → Result
```

**Uso**: Discusión colaborativa entre agentes.

---

## 7. Integración con Planes Existentes

### 7.1 Inserciones en Planes

| Plan | Inserción | Qué se agrega |
|---|---|---|
| **Plan N (Empresas Autonomas)** | N.N7 | A2A Protocol para comunicación entre empresas |
| **Plan N** | N.N8 | Chief of Staff pattern para PM agentes |
| **Plan G (Skills Lab)** | G.G6 | SKILL.md format estándar + routine learning |
| **Plan G** | G.G7 | Proactive triggers para skills |
| **Plan I (Revisión)** | I.I5 | Cross-agent review via A2A |
| **Plan C (Reasonix)** | C.C8 | A2A provider para multi-agent |

### 7.2 Dependencias

```
SDD-012 (este documento)
  ├── SDD-011 (Hermes Integration)
  │     ├── T.SEC (Security patterns)
  │     ├── G.1 (SKILL.md format)
  │     └── D.D5 (Learning graph)
  ├── Plan N (Empresas Autonomas)
  │     └── N.N1 (Subagentes reasonix)
  ├── Plan G (Skills Lab)
  │     └── G.2 (Tool-gating)
  └── Plan C (Reasonix)
        └── C.1 (Provider system)
```

---

## 8. Estimación de Esfuerzo

| Componente | Días | Dependencias |
|---|---|---|
| A2A Protocol (Rust) | 3d | Ninguna |
| Group Chat Manager | 2d | A2A Protocol |
| Chief of Staff Pattern | 1.5d | Group Chat |
| Routine Learning Engine | 2d | SKILL.md format |
| Proactive Triggers | 1.5d | Watchdog existente |
| SKILL.md Format Extension | 0.5d | Hermes reference |
| Subagent Registry | 1d | Lifecycle states |
| Integration + Tests | 2d | Todos |
| **Total** | **13.5d** | |

---

## 9. Riesgos y Mitigaciones

| Riesgo | Impacto | Mitigación |
|---|---|---|
| A2A complejo de implementar | Alto | Empezar con subset mínimo, expandir gradualmente |
| Group Chat overhead | Medio | Límite de agentes por chat (max 8) |
| Routine learning inexacto | Medio | Requiere aprobación humana para skills críticos |
| Proactive behavior molesto | Bajo | Configurable por usuario, fail-open |
| Incompatibilidad con Hermes A2A | Bajo | Seguir estándar v1.0, testear interop |

---

## 10. Métricas de Éxito

| Métrica | Target |
|---|---|
| Latencia A2A (local) | < 100ms |
| Group Chat coordination | < 500ms overhead |
| Routine learning accuracy | > 80% (humano aprueba) |
| Proactive trigger false positives | < 5% |
| Interop con Hermes A2A | 100% (test suite) |

---

## 11. Referencias

| Fuente | URL | Qué aporta |
|---|---|---|
| GrokBot Announcement | x.ai/news/introducing-grok-bot | Group Chat, Chief of Staff, Routine Learning |
| Grok Multi-Agent API | docs.x.ai/developers/model-capabilities/text/multi-agent | Leader agent, 4/16 agents, encrypted sub-agent state |
| Hermes A2A Adapter | reference/hermes-agent/plugins/platforms/a2a/ | A2A v1.0 protocol, Agent Card, JSON-RPC |
| Hermes Skills | reference/hermes-agent/skills/ | SKILL.md format, progressive disclosure |
| MS Agent Framework | github.com/microsoft/agent-framework | Orchestration patterns, Skills design |
| Semantic Kernel Multi-Agent | devblogs.microsoft.com/agent-framework/semantic-kernel-multi-agent-orchestration | Sequential, concurrent, handoff, group, magentic patterns |

---

## 12. Próximos Pasos

1. **Aprobar SDD-012** → crear ramas de implementación
2. **Implementar A2A Protocol** → empezar con Agent Card + message/send
3. **Implementar Group Chat** → sobre base A2A
4. **Implementar Routine Learning** → extender Plan G
5. **Testing de interop** → test suite contra Hermes A2A
