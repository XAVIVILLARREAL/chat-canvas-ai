//! Tipos de dominio para AI Canvas — Automatizaciones con IA nativa.
//!
//! Regla dura (ADR-005 D1): este crate NO depende de Tauri, HTTP ni I/O.
//! Aquí viven los tipos de dominio y las reglas de negocio puras que
//! comparten el shell Tauri (local) y el binario servidor (nube).

use serde::{Deserialize, Serialize};
use specta::Type;
use schemars::JsonSchema;
use std::collections::HashMap;

/// ============================================================================
/// CANVAS — El grafo de automatización visual
/// ============================================================================

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct Canvas {
    pub id: String,
    pub name: String,
    pub description: String,
    pub version: u32,
    pub nodes: Vec<CanvasNode>,
    pub edges: Vec<CanvasEdge>,
    pub viewport: Viewport,
    pub settings: CanvasSettings,
    pub created_at: i64,
    pub updated_at: i64,
    pub created_by: String, // user_id or agent_id
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct Viewport {
    pub x: f64,
    pub y: f64,
    pub zoom: f64,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct CanvasSettings {
    pub auto_save: bool,
    pub execution_mode: ExecutionMode,
    pub timeout_ms: u64,
    pub retry_policy: RetryPolicy,
    pub parallel_execution: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum ExecutionMode {
    Sequential,
    Parallel,
    DAG, // Directed Acyclic Graph - topological order
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct RetryPolicy {
    pub max_retries: u32,
    pub backoff_ms: u64,
    pub retry_on: Vec<String>, // error codes to retry
}

/// ============================================================================
/// NODOS — Unidades de ejecución (AI diseña, no conectores predefinidos)
/// ============================================================================

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct CanvasNode {
    pub id: String,
    pub node_type: NodeType,
    pub position: Position,
    pub config: NodeConfig,
    pub inputs: Vec<Port>,
    pub outputs: Vec<Port>,
    pub metadata: NodeMetadata,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum NodeType {
    // Nodos de código puro (AI genera el código)
    Code,           // Ejecuta código TypeScript/Python/Rust arbitrario
    LLMCall,        // Llamada a LLM con prompt estructurado
    MCPCall,        // Llamada a herramienta MCP
    A2AMessage,     // Envía mensaje a otro agente (A2A protocol)
    SkillInvoke,    // Invoca una Skill registrada
    SubCanvas,      // Canvas anidado (composición)
    HumanInput,     // Pide input al humano (HITL)
    Conditional,    // Rama condicional
    Loop,           // Bucle for/while
    Parallel,       // Ejecución en paralelo de sub-nodos
    Trigger,        // Inicio del flujo (webhook, cron, manual)
    Output,         // Resultado final
    // Nodos de datos
    Transform,      // Transformación de datos (map, filter, reduce)
    Aggregate,      // Agregación de resultados
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct Position {
    pub x: f64,
    pub y: f64,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct Port {
    pub id: String,
    pub name: String,
    pub data_type: DataType,
    pub required: bool,
    pub default_value: Option<serde_json::Value>,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum DataType {
    String,
    Number,
    Boolean,
    Object,
    Array,
    Any,
    // Tipos específicos de dominio
    Agent,
    Skill,
    MCPTool,
    Canvas,
    File,
    Image,
    Audio,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, Default)]
pub struct NodeConfig {
    // Para Code node
    pub code: Option<String>,           // TypeScript/Python/Rust code
    pub language: Option<CodeLanguage>,
    pub imports: Vec<String>,           // Imports permitidos
    // Para LLMCall
    pub prompt_template: Option<String>,
    pub model: Option<String>,
    pub temperature: Option<f32>,
    pub max_tokens: Option<u32>,
    pub response_schema: Option<serde_json::Value>, // JSON Schema
    // Para MCPCall
    pub mcp_server_id: Option<String>,
    pub mcp_tool_name: Option<String>,
    pub mcp_args_schema: Option<serde_json::Value>,
    // Para SkillInvoke
    pub skill_id: Option<String>,
    pub skill_version: Option<String>,
    // Para SubCanvas
    pub sub_canvas_id: Option<String>,
    // Para Conditional
    pub condition: Option<String>, // Expresión JS que evalúa a boolean
    // Para Loop
    pub loop_config: Option<LoopConfig>,
    // Para Trigger
    pub trigger_config: Option<TriggerConfig>,
    // Config común
    pub timeout_ms: Option<u64>,
    pub retries: Option<u32>,
    pub continue_on_error: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum CodeLanguage {
    TypeScript,
    Python,
    Rust,
    JavaScript,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct LoopConfig {
    pub loop_type: LoopType,
    pub collection_expr: Option<String>, // Para for-each
    pub condition_expr: Option<String>,  // Para while
    pub max_iterations: u32,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum LoopType {
    ForEach,
    While,
    Times,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct TriggerConfig {
    pub trigger_type: TriggerType,
    pub cron_expression: Option<String>,
    pub webhook_path: Option<String>,
    pub event_filters: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum TriggerType {
    Manual,
    Cron,
    Webhook,
    Event,
    MCPNotification,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct NodeMetadata {
    pub label: String,
    pub description: String,
    pub color: String,
    pub icon: String,
    pub category: NodeCategory,
    pub is_ai_generated: bool,
    pub ai_generation_prompt: Option<String>,
    pub test_cases: Vec<TestCase>,
    pub last_test_result: Option<TestResult>,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum NodeCategory {
    Trigger,
    Action,
    Logic,
    Data,
    AI,
    MCP,
    Agent,
    Human,
    Output,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct TestCase {
    pub id: String,
    pub name: String,
    pub inputs: HashMap<String, serde_json::Value>,
    pub expected_outputs: HashMap<String, serde_json::Value>,
    pub created_by: String, // "ai" | "human"
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct TestResult {
    pub passed: bool,
    pub outputs: HashMap<String, serde_json::Value>,
    pub error: Option<String>,
    pub duration_ms: u64,
    pub tested_at: i64,
}

/// ============================================================================
/// EDGES — Conexiones entre nodos
/// ============================================================================

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct CanvasEdge {
    pub id: String,
    pub source: String, // node_id
    pub source_port: String,
    pub target: String, // node_id
    pub target_port: String,
    pub edge_type: EdgeType,
    pub condition: Option<String>, // Para edges condicionales
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum EdgeType {
    Data,      // Flujo de datos normal
    Control,   // Flujo de control (siguiente nodo)
    Conditional, // Solo si se cumple condición
    Error,     // Manejo de errores
}

/// ============================================================================
/// SKILLS — Capacidades reutilizables, auto-mejorables (estilo Hermes)
/// ============================================================================

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct Skill {
    pub id: String,
    pub name: String,
    pub description: String,
    pub version: String,
    pub category: SkillCategory,
    pub triggers: Vec<SkillTrigger>,
    pub implementation: SkillImplementation,
    pub permissions: SkillPermissions,
    pub metadata: SkillMetadata,
    pub created_at: i64,
    pub updated_at: i64,
    pub created_by: String,
    pub is_auto_generated: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum SkillCategory {
    Automation,
    DataProcessing,
    Communication,
    Analysis,
    Generation,
    Integration,
    Custom,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct SkillTrigger {
    pub trigger_type: TriggerType,
    pub pattern: Option<String>, // regex o keyword
    pub conditions: Vec<String>, // expresiones JS
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct SkillImplementation {
    pub kind: ImplementationKind,
    pub code: String, // Código principal
    pub language: CodeLanguage,
    pub dependencies: Vec<Dependency>,
    pub entry_point: String, // función principal
    pub schema: SkillSchema, // Input/Output schema
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum ImplementationKind {
    Function,      // Función pura
    Class,         // Clase con estado
    Canvas,        // Sub-canvas
    MCPWrapper,    // Wrapper de herramienta MCP
    A2ADelegate,   // Delegación a otro agente
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct Dependency {
    pub name: String,
    pub version: String,
    pub source: DependencySource,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum DependencySource {
    NPM,
    PyPI,
    Cargo,
    Local,
    Git,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct SkillSchema {
    pub input: serde_json::Value,  // JSON Schema
    pub output: serde_json::Value, // JSON Schema
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct SkillPermissions {
    pub allowed_mcp_servers: Vec<String>, // "*" para todos
    pub allowed_domains: Vec<String>,     // dominios HTTP permitidos
    pub allowed_files: Vec<String>,       // paths de archivos permitidos
    pub max_execution_time_ms: u64,
    pub max_memory_mb: u32,
    pub network_access: bool,
    pub filesystem_access: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct SkillMetadata {
    pub tags: Vec<String>,
    pub usage_count: u64,
    pub success_rate: f32,
    pub avg_duration_ms: u64,
    pub last_improved_at: Option<i64>,
    pub improvement_history: Vec<SkillImprovement>,
    pub is_auto_generated: bool,
    pub parent_skill_id: Option<String>, // Para tracking de evolución
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct SkillImprovement {
    pub version: String,
    pub description: String,
    pub trigger: ImprovementTrigger,
    pub before_metrics: SkillMetrics,
    pub after_metrics: SkillMetrics,
    pub improved_at: i64,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum ImprovementTrigger {
    TestFailure,
    PerformanceRegression,
    UserFeedback,
    NewRequirement,
    AIOptimization,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct SkillMetrics {
    pub success_rate: f32,
    pub avg_duration_ms: u64,
    pub error_rate: f32,
    pub cost_per_execution: f64,
}

/// ============================================================================
/// AGENTES — Agentes basados en Skills con identidad propia
/// ============================================================================

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct Agent {
    pub id: String,
    pub name: String,
    pub description: String,
    pub avatar: Option<String>,
    pub role: AgentRole,
    pub status: AgentStatus,
    pub skills: Vec<String>, // skill_ids
    pub mcp_servers: Vec<String>, // mcp_server_ids
    pub config: AgentConfig,
    pub memory: AgentMemory,
    pub metrics: AgentMetrics,
    pub created_at: i64,
    pub updated_at: i64,
    pub created_by: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum AgentRole {
    Coordinator,  // Orquesta a otros agentes
    Specialist,   // Ejecuta skills específicas
    Reviewer,     // Revisa/calidad
    Planner,      // Planifica tareas complejas
    Executor,     // Ejecuta tareas operativas
    Custom(String),
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum AgentStatus {
    Idle,
    Working,
    Blocked,
    Error,
    Offline,
    Learning, // En proceso de mejorar skills
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct AgentConfig {
    pub model: String,
    pub temperature: f32,
    pub max_tokens: u32,
    pub system_prompt: String,
    pub max_concurrent_tasks: u32,
    pub auto_improve_skills: bool,
    pub learning_enabled: bool,
    pub budget_usd_per_day: Option<f64>,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct AgentMemory {
    pub short_term: Vec<MemoryEntry>, // Contexto actual
    pub long_term: Vec<MemoryEntry>,  // Conocimiento persistente
    pub episodic: Vec<EpisodicMemory>, // Experiencias pasadas
    pub skill_knowledge: HashMap<String, SkillKnowledge>, // Por skill
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct MemoryEntry {
    pub id: String,
    pub content: String,
    pub embedding: Option<Vec<f32>>, // Para búsqueda semántica
    pub importance: f32,
    pub created_at: i64,
    pub accessed_at: i64,
    pub access_count: u32,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct EpisodicMemory {
    pub id: String,
    pub task_id: String,
    pub canvas_id: Option<String>,
    pub summary: String,
    pub outcome: TaskOutcome,
    pub lessons_learned: Vec<String>,
    pub created_at: i64,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum TaskOutcome {
    Success,
    PartialSuccess,
    Failure,
    Cancelled,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct SkillKnowledge {
    pub skill_id: String,
    pub proficiency: f32, // 0.0 - 1.0
    pub successful_patterns: Vec<String>,
    pub failure_patterns: Vec<String>,
    pub optimal_params: HashMap<String, serde_json::Value>,
    pub last_used: i64,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct AgentMetrics {
    pub tasks_completed: u64,
    pub tasks_failed: u64,
    pub skills_executed: u64,
    pub total_cost_usd: f64,
    pub avg_task_duration_ms: u64,
    pub uptime_percentage: f32,
}

/// ============================================================================
/// MCP — Model Context Protocol Integration
/// ============================================================================

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct MCPServer {
    pub id: String,
    pub name: String,
    pub description: String,
    pub transport: MCPTransport,
    pub capabilities: MCPCapabilities,
    pub auth: Option<MCPAuth>,
    pub status: MCPServerStatus,
    pub tools: Vec<MCPTool>,
    pub created_at: i64,
    pub updated_at: i64,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum MCPTransport {
    Stdio,
    SSE,
    StreamableHTTP,
    WebSocket,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct MCPCapabilities {
    pub tools: bool,
    pub resources: bool,
    pub prompts: bool,
    pub logging: bool,
    pub completions: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct MCPAuth {
    pub auth_type: MCPAuthType,
    pub config: serde_json::Value,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum MCPAuthType {
    None,
    BearerToken,
    APIKey,
    OAuth2,
    Custom(String),
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum MCPServerStatus {
    Disconnected,
    Connecting,
    Connected,
    Error,
    Unauthorized,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct MCPTool {
    pub name: String,
    pub description: String,
    pub input_schema: serde_json::Value,
    pub output_schema: Option<serde_json::Value>,
    pub annotations: Option<MCPToolAnnotations>,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct MCPToolAnnotations {
    pub title: Option<String>,
    pub read_only: Option<bool>,
    pub destructive: Option<bool>,
    pub idempotent: Option<bool>,
    pub open_world: Option<bool>,
}

/// ============================================================================
/// EJECUCIÓN Y TESTING
/// ============================================================================

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct ExecutionContext {
    pub execution_id: String,
    pub canvas_id: String,
    pub trigger: ExecutionTrigger,
    pub variables: HashMap<String, serde_json::Value>,
    pub node_states: HashMap<String, NodeExecutionState>,
    pub started_at: i64,
    pub completed_at: Option<i64>,
    pub status: ExecutionStatus,
    pub result: Option<ExecutionResult>,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct ExecutionTrigger {
    pub trigger_type: TriggerType,
    pub payload: serde_json::Value,
    pub triggered_by: String, // user_id, agent_id, cron, webhook
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum ExecutionStatus {
    Pending,
    Running,
    Paused,
    Completed,
    Failed,
    Cancelled,
    WaitingForHuman,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct NodeExecutionState {
    pub node_id: String,
    pub status: NodeExecutionStatus,
    pub inputs: HashMap<String, serde_json::Value>,
    pub outputs: HashMap<String, serde_json::Value>,
    pub error: Option<String>,
    pub started_at: Option<i64>,
    pub completed_at: Option<i64>,
    pub retry_count: u32,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum NodeExecutionStatus {
    Pending,
    Running,
    Completed,
    Failed,
    Skipped,
    WaitingForInput,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct ExecutionResult {
    pub success: bool,
    pub outputs: HashMap<String, serde_json::Value>,
    pub error: Option<String>,
    pub node_results: HashMap<String, NodeExecutionState>,
    pub total_duration_ms: u64,
    pub cost_usd: f64,
}

/// ============================================================================
/// A2A PROTOCOL — Agent-to-Agent Communication
/// ============================================================================

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct A2AAgentCard {
    pub name: String,
    pub description: String,
    pub version: String,
    pub url: String,
    pub capabilities: A2ACapabilities,
    pub skills: Vec<A2ASkill>,
    pub auth: Option<A2AAuth>,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct A2ACapabilities {
    pub streaming: bool,
    pub push_notifications: bool,
    pub state_transition_history: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct A2ASkill {
    pub id: String,
    pub name: String,
    pub description: String,
    pub tags: Vec<String>,
    pub examples: Vec<String>,
    pub input_modes: Vec<String>,
    pub output_modes: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct A2AAuth {
    pub schemes: Vec<String>,
    pub credentials: serde_json::Value,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct A2AMessage {
    pub id: String,
    pub role: A2ARole,
    pub parts: Vec<A2APart>,
    pub metadata: Option<serde_json::Value>,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum A2ARole {
    User,
    Agent,
    System,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct A2APart {
    pub part_type: A2APartType,
    pub content: String,
    pub metadata: Option<serde_json::Value>,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum A2APartType {
    Text,
    File,
    Data,
    Form,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct A2ATask {
    pub id: String,
    pub status: A2ATaskStatus,
    pub message: A2AMessage,
    pub artifacts: Vec<A2AArtifact>,
    pub history: Vec<A2AMessage>,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum A2ATaskStatus {
    Submitted,
    Working,
    InputRequired,
    Completed,
    Failed,
    Cancelled,
    Rejected,
    AuthFailed,
}

#[derive(Debug, Serialize, Deserialize, Clone, Type, JsonSchema)]
pub struct A2AArtifact {
    pub id: String,
    pub name: String,
    pub description: String,
    pub parts: Vec<A2APart>,
    pub metadata: Option<serde_json::Value>,
}

/// ============================================================================
/// FACTORY FUNCTIONS
/// ============================================================================

impl Canvas {
    pub fn new(id: String, name: String, created_by: String) -> Self {
        let now = chrono::Utc::now().timestamp_millis();
        Self {
            id,
            name,
            description: String::new(),
            version: 1,
            nodes: vec![],
            edges: vec![],
            viewport: Viewport { x: 0.0, y: 0.0, zoom: 1.0 },
            settings: CanvasSettings {
                auto_save: true,
                execution_mode: ExecutionMode::DAG,
                timeout_ms: 300_000,
                retry_policy: RetryPolicy {
                    max_retries: 3,
                    backoff_ms: 1000,
                    retry_on: vec!["timeout".into(), "network_error".into()],
                },
                parallel_execution: true,
            },
            created_at: now,
            updated_at: now,
            created_by,
        }
    }
}

impl Agent {
    pub fn new(id: String, name: String, role: AgentRole, created_by: String) -> Self {
        let now = chrono::Utc::now().timestamp_millis();
        Self {
            id,
            name,
            description: String::new(),
            avatar: None,
            role,
            status: AgentStatus::Idle,
            skills: vec![],
            mcp_servers: vec![],
            config: AgentConfig {
                model: "gpt-4o".into(),
                temperature: 0.7,
                max_tokens: 4096,
                system_prompt: "Eres un agente autónomo en un equipo de IA. Colabora, aprende y mejora continuamente.".into(),
                max_concurrent_tasks: 3,
                auto_improve_skills: true,
                learning_enabled: true,
                budget_usd_per_day: Some(10.0),
            },
            memory: AgentMemory {
                short_term: vec![],
                long_term: vec![],
                episodic: vec![],
                skill_knowledge: HashMap::new(),
            },
            metrics: AgentMetrics {
                tasks_completed: 0,
                tasks_failed: 0,
                skills_executed: 0,
                total_cost_usd: 0.0,
                avg_task_duration_ms: 0,
                uptime_percentage: 100.0,
            },
            created_at: now,
            updated_at: now,
            created_by,
        }
    }
}

impl Skill {
    pub fn new(id: String, name: String, category: SkillCategory, created_by: String) -> Self {
        let now = chrono::Utc::now().timestamp_millis();
        Self {
            id,
            name,
            description: String::new(),
            version: "1.0.0".into(),
            category,
            triggers: vec![],
            implementation: SkillImplementation {
                kind: ImplementationKind::Function,
                code: String::new(),
                language: CodeLanguage::TypeScript,
                dependencies: vec![],
                entry_point: "execute".into(),
                schema: SkillSchema {
                    input: serde_json::json!({"type": "object", "properties": {}}),
                    output: serde_json::json!({"type": "object", "properties": {}}),
                },
            },
            permissions: SkillPermissions {
                allowed_mcp_servers: vec!["*".into()],
                allowed_domains: vec!["*".into()],
                allowed_files: vec!["*".into()],
                max_execution_time_ms: 60_000,
                max_memory_mb: 512,
                network_access: true,
                filesystem_access: true,
            },
            metadata: SkillMetadata {
                tags: vec![],
                usage_count: 0,
                success_rate: 1.0,
                avg_duration_ms: 0,
                last_improved_at: None,
                improvement_history: vec![],
                is_auto_generated: false,
                parent_skill_id: None,
            },
            created_at: now,
            updated_at: now,
            created_by,
            is_auto_generated: false,
        }
    }
}

impl MCPServer {
    pub fn new(id: String, name: String, transport: MCPTransport) -> Self {
        let now = chrono::Utc::now().timestamp_millis();
        Self {
            id,
            name,
            description: String::new(),
            transport,
            capabilities: MCPCapabilities {
                tools: true,
                resources: false,
                prompts: false,
                logging: false,
                completions: false,
            },
            auth: None,
            status: MCPServerStatus::Disconnected,
            tools: vec![],
            created_at: now,
            updated_at: now,
        }
    }
}

