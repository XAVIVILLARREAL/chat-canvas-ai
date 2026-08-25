//! Servidor central de AI Canvas — APIs para Canvas, Skills, Agents, MCP, Teams
//!
//! Expone el mismo dominio `canvas-ai-core` via HTTP (Axum).
//! Compatible con Tauri (IPC) y clientes web.

use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::Json,
    routing::{get, post, put, delete},
    Router,
};
use canvas_ai_core::domain::*;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::{info, error};
use uuid::Uuid;

// ============================================================================
// APP STATE
// ============================================================================

#[derive(Clone)]
pub struct AppState {
    pub canvases: Arc<RwLock<HashMap<String, Canvas>>>,
    pub skills: Arc<RwLock<HashMap<String, Skill>>>,
    pub agents: Arc<RwLock<HashMap<String, Agent>>>,
    pub teams: Arc<RwLock<HashMap<String, AgentTeam>>>,
    pub mcp_servers: Arc<RwLock<HashMap<String, MCPServer>>>,
    pub executions: Arc<RwLock<HashMap<String, ExecutionContext>>>,
}

impl Default for AppState {
    fn default() -> Self {
        Self {
            canvases: Arc::new(RwLock::new(HashMap::new())),
            skills: Arc::new(RwLock::new(HashMap::new())),
            agents: Arc::new(RwLock::new(HashMap::new())),
            teams: Arc::new(RwLock::new(HashMap::new())),
            mcp_servers: Arc::new(RwLock::new(HashMap::new())),
            executions: Arc::new(RwLock::new(HashMap::new())),
        }
    }
}

// ============================================================================
// REQUEST/RESPONSE TYPES
// ============================================================================

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct CreateCanvasRequest {
    pub name: String,
    pub description: String,
    pub created_by: String,
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct UpdateCanvasRequest {
    pub name: Option<String>,
    pub description: Option<String>,
    pub nodes: Option<Vec<CanvasNode>>,
    pub edges: Option<Vec<CanvasEdge>>,
    pub viewport: Option<Viewport>,
    pub settings: Option<CanvasSettings>,
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct CreateSkillRequest {
    pub name: String,
    pub description: String,
    pub category: SkillCategory,
    pub created_by: String,
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct CreateAgentRequest {
    pub name: String,
    pub description: String,
    pub role: AgentRole,
    pub created_by: String,
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct CreateTeamRequest {
    pub name: String,
    pub description: String,
    pub leader_id: String,
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct CreateMCPServerRequest {
    pub name: String,
    pub description: String,
    pub transport: MCPTransport,
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct ExecuteCanvasRequest {
    pub canvas_id: String,
    pub trigger: ExecutionTrigger,
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct TestNodeRequest {
    pub node: CanvasNode,
    pub inputs: HashMap<String, serde_json::Value>,
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct A2AMessageRequest {
    pub target_agent_url: String,
    pub message: A2AMessage,
}

// ============================================================================
// ROUTES
// ============================================================================

pub fn create_router(state: AppState) -> Router {
    Router::new()
        // Health
        .route("/healthz", get(healthz))
        .route("/api/version", get(version))
        
        // Canvas CRUD
        .route("/api/canvases", get(list_canvases).post(create_canvas))
        .route("/api/canvases/:id", get(get_canvas).put(update_canvas).delete(delete_canvas))
        .route("/api/canvases/:id/execute", post(execute_canvas))
        .route("/api/canvases/:id/test", post(test_canvas))
        .route("/api/canvases/:id/validate", post(validate_canvas))
        
        // Skills CRUD
        .route("/api/skills", get(list_skills).post(create_skill))
        .route("/api/skills/:id", get(get_skill).put(update_skill).delete(delete_skill))
        .route("/api/skills/:id/test", post(test_skill))
        .route("/api/skills/:id/improve", post(improve_skill))
        .route("/api/skills/:id/versions", get(list_skill_versions))
        
        // Agents CRUD
        .route("/api/agents", get(list_agents).post(create_agent))
        .route("/api/agents/:id", get(get_agent).put(update_agent).delete(delete_agent))
        .route("/api/agents/:id/skills", post(assign_skill_to_agent).delete(remove_skill_from_agent))
        .route("/api/agents/:id/mcp", post(assign_mcp_to_agent).delete(remove_mcp_from_agent))
        .route("/api/agents/:id/chat", post(chat_with_agent))
        .route("/api/agents/:id/memory", get(get_agent_memory).post(update_agent_memory))
        
        // Teams CRUD
        .route("/api/teams", get(list_teams).post(create_team))
        .route("/api/teams/:id", get(get_team).put(update_team).delete(delete_team))
        .route("/api/teams/:id/members", post(add_team_member).delete(remove_team_member))
        .route("/api/teams/:id/canvas", post(set_team_canvas))
        .route("/api/teams/:id/execute", post(execute_team_canvas))
        
        // MCP Servers
        .route("/api/mcp/servers", get(list_mcp_servers).post(create_mcp_server))
        .route("/api/mcp/servers/:id", get(get_mcp_server).put(update_mcp_server).delete(delete_mcp_server))
        .route("/api/mcp/servers/:id/connect", post(connect_mcp_server))
        .route("/api/mcp/servers/:id/disconnect", post(disconnect_mcp_server))
        .route("/api/mcp/servers/:id/tools", get(list_mcp_tools))
        .route("/api/mcp/servers/:id/call", post(call_mcp_tool))
        
        // A2A Protocol
        .route("/api/a2a/agent-card", get(get_agent_card))
        .route("/api/a2a/message/send", post(send_a2a_message))
        .route("/api/a2a/tasks/:id", get(get_a2a_task))
        .route("/api/a2a/tasks/:id/cancel", post(cancel_a2a_task))
        
        // Executions
        .route("/api/executions", get(list_executions))
        .route("/api/executions/:id", get(get_execution))
        .route("/api/executions/:id/cancel", post(cancel_execution))
        .route("/api/executions/:id/retry", post(retry_execution))
        
        // AI Generation endpoints
        .route("/api/ai/generate-node", post(ai_generate_node))
        .route("/api/ai/generate-canvas", post(ai_generate_canvas))
        .route("/api/ai/generate-skill", post(ai_generate_skill))
        .route("/api/ai/optimize-canvas", post(ai_optimize_canvas))
        .route("/api/ai/test-generation", post(ai_test_generation))
        
        .with_state(state)
}

// ============================================================================
// HANDLERS - HEALTH & VERSION
// ============================================================================

async fn healthz() -> &'static str {
    "ok"
}

async fn version() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "app": env!("CARGO_PKG_NAME"),
        "version": env!("CARGO_PKG_VERSION"),
    }))
}

// ============================================================================
// HANDLERS - CANVAS
// ============================================================================

async fn list_canvases(State(state): State<AppState>) -> Json<Vec<Canvas>> {
    let canvases = state.canvases.read().await;
    Json(canvases.values().cloned().collect())
}

async fn create_canvas(
    State(state): State<AppState>,
    Json(req): Json<CreateCanvasRequest>,
) -> Result<Json<Canvas>, (StatusCode, String)> {
    let id = Uuid::new_v4().to_string();
    let canvas = Canvas::new(id, req.name, req.created_by);
    let mut canvas = canvas;
    canvas.description = req.description;
    
    state.canvases.write().await.insert(canvas.id.clone(), canvas.clone());
    info!("Created canvas: {}", canvas.id);
    Ok(Json(canvas))
}

async fn get_canvas(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<Canvas>, (StatusCode, String)> {
    let canvases = state.canvases.read().await;
    canvases.get(&id)
        .cloned()
        .map(Json)
        .ok_or((StatusCode::NOT_FOUND, "Canvas not found".into()))
}

async fn update_canvas(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(req): Json<UpdateCanvasRequest>,
) -> Result<Json<Canvas>, (StatusCode, String)> {
    let mut canvases = state.canvases.write().await;
    let mut canvas = canvases.get(&id)
        .cloned()
        .ok_or((StatusCode::NOT_FOUND, "Canvas not found".into()))?;
    
    if let Some(name) = req.name { canvas.name = name; }
    if let Some(description) = req.description { canvas.description = description; }
    if let Some(nodes) = req.nodes { canvas.nodes = nodes; }
    if let Some(edges) = req.edges { canvas.edges = edges; }
    if let Some(viewport) = req.viewport { canvas.viewport = viewport; }
    if let Some(settings) = req.settings { canvas.settings = settings; }
    
    canvas.version += 1;
    canvas.updated_at = chrono::Utc::now().timestamp_millis();
    
    canvases.insert(id, canvas.clone());
    info!("Updated canvas: {}", canvas.id);
    Ok(Json(canvas))
}

async fn delete_canvas(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<StatusCode, (StatusCode, String)> {
    state.canvases.write().await.remove(&id)
        .ok_or((StatusCode::NOT_FOUND, "Canvas not found".into()))?;
    info!("Deleted canvas: {}", id);
    Ok(StatusCode::NO_CONTENT)
}

async fn execute_canvas(
    State(state): State<AppState>,
    Path(canvas_id): Path<String>,
    Json(req): Json<ExecuteCanvasRequest>,
) -> Result<Json<ExecutionContext>, (StatusCode, String)> {
    let canvas = {
        let canvases = state.canvases.read().await;
        canvases.get(&canvas_id)
            .cloned()
            .ok_or((StatusCode::NOT_FOUND, "Canvas not found".into()))?
    };
    
    let execution_id = Uuid::new_v4().to_string();
    let now = chrono::Utc::now().timestamp_millis();
    
    let execution = ExecutionContext {
        execution_id: execution_id.clone(),
        canvas_id: canvas_id.clone(),
        trigger: req.trigger,
        variables: HashMap::new(),
        node_states: HashMap::new(),
        started_at: now,
        completed_at: None,
        status: ExecutionStatus::Pending,
        result: None,
    };
    
    state.executions.write().await.insert(execution_id.clone(), execution.clone());
    
    // Spawn execution task
    let state_clone = state.clone();
    let exec_id = execution_id.clone();
    let canvas_id_for_log = canvas_id.clone();
    tokio::spawn(async move {
        execute_canvas_internal(state_clone, exec_id, canvas).await;
    });
    
    info!("Started execution: {} for canvas: {}", execution_id, canvas_id_for_log);
    Ok(Json(execution))
}

async fn execute_canvas_internal(
    state: AppState,
    execution_id: String,
    canvas: Canvas,
) {
    // Update status to running
    {
        let mut executions = state.executions.write().await;
        if let Some(exec) = executions.get_mut(&execution_id) {
            exec.status = ExecutionStatus::Running;
        }
    }
    
    // TODO: Implement actual canvas execution logic
    // This would:
    // 1. Topologically sort nodes based on edges
    // 2. Execute nodes in order (respecting parallel/sequential)
    // 3. Handle MCP calls, LLM calls, code execution, etc.
    // 4. Update node states and execution result
    
    // For now, simulate completion
    tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
    
    let mut executions = state.executions.write().await;
    if let Some(exec) = executions.get_mut(&execution_id) {
        exec.status = ExecutionStatus::Completed;
        exec.completed_at = Some(chrono::Utc::now().timestamp_millis());
        exec.result = Some(ExecutionResult {
            success: true,
            outputs: HashMap::new(),
            error: None,
            node_results: HashMap::new(),
            total_duration_ms: 100,
            cost_usd: 0.0,
        });
    }
}

async fn test_canvas(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(req): Json<TestNodeRequest>,
) -> Result<Json<TestResult>, (StatusCode, String)> {
    // TODO: Implement node testing with sandboxed execution
    Ok(Json(TestResult {
        passed: true,
        outputs: HashMap::new(),
        error: None,
        duration_ms: 50,
        tested_at: chrono::Utc::now().timestamp_millis(),
    }))
}

async fn validate_canvas(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<ValidationResult>, (StatusCode, String)> {
    let canvas = {
        let canvases = state.canvases.read().await;
        canvases.get(&id)
            .cloned()
            .ok_or((StatusCode::NOT_FOUND, "Canvas not found".into()))?
    };
    
    let mut errors = Vec::new();
    let mut warnings = Vec::new();
    
    // Validate: at least one trigger node
    let has_trigger = canvas.nodes.iter().any(|n| n.node_type == NodeType::Trigger);
    if !has_trigger {
        errors.push("Canvas must have at least one Trigger node".into());
    }
    
    // Validate: no cycles (for DAG execution)
    if canvas.settings.execution_mode == ExecutionMode::DAG {
        if has_cycle(&canvas.nodes, &canvas.edges) {
            errors.push("Canvas has cycles - not valid for DAG execution".into());
        }
    }
    
    // Validate: all edges reference valid nodes/ports
    let node_ids: std::collections::HashSet<_> = canvas.nodes.iter().map(|n| n.id.clone()).collect();
    for edge in &canvas.edges {
        if !node_ids.contains(&edge.source) {
            errors.push(format!("Edge {} references non-existent source node {}", edge.id, edge.source));
        }
        if !node_ids.contains(&edge.target) {
            errors.push(format!("Edge {} references non-existent target node {}", edge.id, edge.target));
        }
    }
    
    Ok(Json(ValidationResult {
        valid: errors.is_empty(),
        errors,
        warnings,
    }))
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct ValidationResult {
    pub valid: bool,
    pub errors: Vec<String>,
    pub warnings: Vec<String>,
}

fn has_cycle(nodes: &[CanvasNode], edges: &[CanvasEdge]) -> bool {
    use std::collections::{HashMap, HashSet, VecDeque};
    
    let mut adj: HashMap<String, Vec<String>> = HashMap::new();
    let mut in_degree: HashMap<String, usize> = HashMap::new();
    
    for node in nodes {
        adj.insert(node.id.clone(), Vec::new());
        in_degree.insert(node.id.clone(), 0);
    }
    
    for edge in edges {
        if let Some(neighbors) = adj.get_mut(&edge.source) {
            neighbors.push(edge.target.clone());
        }
        *in_degree.get_mut(&edge.target).unwrap_or(&mut 0) += 1;
    }
    
    let mut queue = VecDeque::new();
    for (node_id, &degree) in &in_degree {
        if degree == 0 {
            queue.push_back(node_id.clone());
        }
    }
    
    let mut visited = 0;
    while let Some(node_id) = queue.pop_front() {
        visited += 1;
        if let Some(neighbors) = adj.get(&node_id) {
            for neighbor in neighbors {
                let degree = in_degree.get_mut(neighbor).unwrap();
                *degree -= 1;
                if *degree == 0 {
                    queue.push_back(neighbor.clone());
                }
            }
        }
    }
    
    visited != nodes.len()
}

// ============================================================================
// HANDLERS - SKILLS
// ============================================================================

async fn list_skills(State(state): State<AppState>) -> Json<Vec<Skill>> {
    let skills = state.skills.read().await;
    Json(skills.values().cloned().collect())
}

async fn create_skill(
    State(state): State<AppState>,
    Json(req): Json<CreateSkillRequest>,
) -> Result<Json<Skill>, (StatusCode, String)> {
    let id = Uuid::new_v4().to_string();
    let skill = Skill::new(id, req.name, req.category, req.created_by);
    let mut skill = skill;
    skill.description = req.description;
    
    state.skills.write().await.insert(skill.id.clone(), skill.clone());
    info!("Created skill: {}", skill.id);
    Ok(Json(skill))
}

async fn get_skill(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<Skill>, (StatusCode, String)> {
    let skills = state.skills.read().await;
    skills.get(&id)
        .cloned()
        .map(Json)
        .ok_or((StatusCode::NOT_FOUND, "Skill not found".into()))
}

async fn update_skill(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(mut skill): Json<Skill>,
) -> Result<Json<Skill>, (StatusCode, String)> {
    let mut skills = state.skills.write().await;
    let existing = skills.get(&id)
        .ok_or((StatusCode::NOT_FOUND, "Skill not found".into()))?;
    
    skill.id = id.clone();
    skill.updated_at = chrono::Utc::now().timestamp_millis();
    skill.version = increment_version(&existing.version);
    
    skills.insert(id, skill.clone());
    info!("Updated skill: {}", skill.id);
    Ok(Json(skill))
}

async fn delete_skill(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<StatusCode, (StatusCode, String)> {
    state.skills.write().await.remove(&id)
        .ok_or((StatusCode::NOT_FOUND, "Skill not found".into()))?;
    info!("Deleted skill: {}", id);
    Ok(StatusCode::NO_CONTENT)
}

async fn test_skill(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(inputs): Json<HashMap<String, serde_json::Value>>,
) -> Result<Json<TestResult>, (StatusCode, String)> {
    let skill = {
        let skills = state.skills.read().await;
        skills.get(&id)
            .cloned()
            .ok_or((StatusCode::NOT_FOUND, "Skill not found".into()))?
    };
    
    // TODO: Execute skill in sandbox with inputs
    // For now return mock result
    Ok(Json(TestResult {
        passed: true,
        outputs: HashMap::from([("result".into(), serde_json::json!({"status": "success"}))]),
        error: None,
        duration_ms: 100,
        tested_at: chrono::Utc::now().timestamp_millis(),
    }))
}

async fn improve_skill(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(req): Json<SkillImprovementRequest>,
) -> Result<Json<Skill>, (StatusCode, String)> {
    let mut skills = state.skills.write().await;
    let mut skill = skills.get(&id)
        .cloned()
        .ok_or((StatusCode::NOT_FOUND, "Skill not found".into()))?;
    
    // Create improved version
    let improved_skill = Skill {
        id: Uuid::new_v4().to_string(),
        name: skill.name.clone(),
        description: skill.description.clone(),
        version: increment_version(&skill.version),
        category: skill.category.clone(),
        triggers: skill.triggers.clone(),
        implementation: req.implementation.unwrap_or(skill.implementation.clone()),
        permissions: skill.permissions.clone(),
        metadata: SkillMetadata {
            tags: skill.metadata.tags.clone(),
            usage_count: skill.metadata.usage_count,
            success_rate: skill.metadata.success_rate,
            avg_duration_ms: skill.metadata.avg_duration_ms,
            last_improved_at: Some(chrono::Utc::now().timestamp_millis()),
            improvement_history: {
                let mut history = skill.metadata.improvement_history.clone();
                history.push(SkillImprovement {
                    version: increment_version(&skill.version),
                    description: req.description,
                    trigger: req.trigger,
                    before_metrics: SkillMetrics {
                        success_rate: skill.metadata.success_rate,
                        avg_duration_ms: skill.metadata.avg_duration_ms,
                        error_rate: 1.0 - skill.metadata.success_rate,
                        cost_per_execution: 0.0,
                    },
                    after_metrics: SkillMetrics {
                        success_rate: 1.0,
                        avg_duration_ms: skill.metadata.avg_duration_ms,
                        error_rate: 0.0,
                        cost_per_execution: 0.0,
                    },
                    improved_at: chrono::Utc::now().timestamp_millis(),
                });
                history
            },
            is_auto_generated: req.is_auto_generated,
            parent_skill_id: Some(skill.id.clone()),
        },
        created_at: chrono::Utc::now().timestamp_millis(),
        updated_at: chrono::Utc::now().timestamp_millis(),
        created_by: req.improved_by,
        is_auto_generated: req.is_auto_generated,
    };
    
    skills.insert(improved_skill.id.clone(), improved_skill.clone());
    info!("Improved skill: {} -> {}", id, improved_skill.id);
    Ok(Json(improved_skill))
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct SkillImprovementRequest {
    pub description: String,
    pub trigger: ImprovementTrigger,
    pub implementation: Option<SkillImplementation>,
    pub is_auto_generated: bool,
    pub improved_by: String,
}

async fn list_skill_versions(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<Vec<Skill>>, (StatusCode, String)> {
    let skills = state.skills.read().await;
    let versions: Vec<Skill> = skills.values()
        .filter(|s| s.id == id || s.metadata.parent_skill_id.as_ref() == Some(&id))
        .cloned()
        .collect();
    Ok(Json(versions))
}

fn increment_version(version: &str) -> String {
    let parts: Vec<&str> = version.split('.').collect();
    if parts.len() == 3 {
        let major: u32 = parts[0].parse().unwrap_or(1);
        let minor: u32 = parts[1].parse().unwrap_or(0);
        let patch: u32 = parts[2].parse().unwrap_or(0) + 1;
        format!("{}.{}.{}", major, minor, patch)
    } else {
        "1.0.1".into()
    }
}

// ============================================================================
// HANDLERS - AGENTS
// ============================================================================

async fn list_agents(State(state): State<AppState>) -> Json<Vec<Agent>> {
    let agents = state.agents.read().await;
    Json(agents.values().cloned().collect())
}

async fn create_agent(
    State(state): State<AppState>,
    Json(req): Json<CreateAgentRequest>,
) -> Result<Json<Agent>, (StatusCode, String)> {
    let id = Uuid::new_v4().to_string();
    let agent = Agent::new(id, req.name, req.role, req.created_by);
    let mut agent = agent;
    agent.description = req.description;
    
    state.agents.write().await.insert(agent.id.clone(), agent.clone());
    info!("Created agent: {}", agent.id);
    Ok(Json(agent))
}

async fn get_agent(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<Agent>, (StatusCode, String)> {
    let agents = state.agents.read().await;
    agents.get(&id)
        .cloned()
        .map(Json)
        .ok_or((StatusCode::NOT_FOUND, "Agent not found".into()))
}

async fn update_agent(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(mut agent): Json<Agent>,
) -> Result<Json<Agent>, (StatusCode, String)> {
    let mut agents = state.agents.write().await;
    let _ = agents.get(&id)
        .ok_or((StatusCode::NOT_FOUND, "Agent not found".into()))?;
    
    agent.id = id.clone();
    agent.updated_at = chrono::Utc::now().timestamp_millis();
    
    agents.insert(id, agent.clone());
    info!("Updated agent: {}", agent.id);
    Ok(Json(agent))
}

async fn delete_agent(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<StatusCode, (StatusCode, String)> {
    state.agents.write().await.remove(&id)
        .ok_or((StatusCode::NOT_FOUND, "Agent not found".into()))?;
    info!("Deleted agent: {}", id);
    Ok(StatusCode::NO_CONTENT)
}

async fn assign_skill_to_agent(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(req): Json<AssignSkillRequest>,
) -> Result<Json<Agent>, (StatusCode, String)> {
    let mut agents = state.agents.write().await;
    let mut agent = agents.get(&id)
        .cloned()
        .ok_or((StatusCode::NOT_FOUND, "Agent not found".into()))?;
    
    if !agent.skills.contains(&req.skill_id) {
        agent.skills.push(req.skill_id);
        agent.updated_at = chrono::Utc::now().timestamp_millis();
        agents.insert(id, agent.clone());
    }
    Ok(Json(agent))
}

async fn remove_skill_from_agent(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Query(req): Query<RemoveSkillQuery>,
) -> Result<Json<Agent>, (StatusCode, String)> {
    let mut agents = state.agents.write().await;
    let mut agent = agents.get(&id)
        .cloned()
        .ok_or((StatusCode::NOT_FOUND, "Agent not found".into()))?;
    
    agent.skills.retain(|s| s != &req.skill_id);
    agent.updated_at = chrono::Utc::now().timestamp_millis();
    agents.insert(id, agent.clone());
    Ok(Json(agent))
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct AssignSkillRequest {
    pub skill_id: String,
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct RemoveSkillQuery {
    pub skill_id: String,
}

async fn assign_mcp_to_agent(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(req): Json<AssignMCPRequest>,
) -> Result<Json<Agent>, (StatusCode, String)> {
    let mut agents = state.agents.write().await;
    let mut agent = agents.get(&id)
        .cloned()
        .ok_or((StatusCode::NOT_FOUND, "Agent not found".into()))?;
    
    if !agent.mcp_servers.contains(&req.mcp_server_id) {
        agent.mcp_servers.push(req.mcp_server_id);
        agent.updated_at = chrono::Utc::now().timestamp_millis();
        agents.insert(id, agent.clone());
    }
    Ok(Json(agent))
}

async fn remove_mcp_from_agent(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Query(req): Query<RemoveMCPQuery>,
) -> Result<Json<Agent>, (StatusCode, String)> {
    let mut agents = state.agents.write().await;
    let mut agent = agents.get(&id)
        .cloned()
        .ok_or((StatusCode::NOT_FOUND, "Agent not found".into()))?;
    
    agent.mcp_servers.retain(|s| s != &req.mcp_server_id);
    agent.updated_at = chrono::Utc::now().timestamp_millis();
    agents.insert(id, agent.clone());
    Ok(Json(agent))
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct AssignMCPRequest {
    pub mcp_server_id: String,
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct RemoveMCPQuery {
    pub mcp_server_id: String,
}

async fn chat_with_agent(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(req): Json<ChatRequest>,
) -> Result<Json<ChatResponse>, (StatusCode, String)> {
    let _agent = {
        let agents = state.agents.read().await;
        agents.get(&id)
            .cloned()
            .ok_or((StatusCode::NOT_FOUND, "Agent not found".into()))?
    };
    
    // TODO: Implement actual agent chat with LLM, skills, MCP, memory
    Ok(Json(ChatResponse {
        message: format!("Agent response to: {}", req.message),
        used_skills: vec![],
        cost_usd: 0.001,
    }))
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct ChatRequest {
    pub message: String,
    pub context: Option<HashMap<String, serde_json::Value>>,
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct ChatResponse {
    pub message: String,
    pub used_skills: Vec<String>,
    pub cost_usd: f64,
}

async fn get_agent_memory(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<AgentMemory>, (StatusCode, String)> {
    let agents = state.agents.read().await;
    agents.get(&id)
        .map(|a| Json(a.memory.clone()))
        .ok_or((StatusCode::NOT_FOUND, "Agent not found".into()))
}

async fn update_agent_memory(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(memory): Json<AgentMemory>,
) -> Result<Json<Agent>, (StatusCode, String)> {
    let mut agents = state.agents.write().await;
    let mut agent = agents.get(&id)
        .cloned()
        .ok_or((StatusCode::NOT_FOUND, "Agent not found".into()))?;
    
    agent.memory = memory;
    agent.updated_at = chrono::Utc::now().timestamp_millis();
    agents.insert(id, agent.clone());
    Ok(Json(agent))
}

// ============================================================================
// HANDLERS - TEAMS
// ============================================================================

async fn list_teams(State(state): State<AppState>) -> Json<Vec<AgentTeam>> {
    let teams = state.teams.read().await;
    Json(teams.values().cloned().collect())
}

async fn create_team(
    State(state): State<AppState>,
    Json(req): Json<CreateTeamRequest>,
) -> Result<Json<AgentTeam>, (StatusCode, String)> {
    let id = Uuid::new_v4().to_string();
    let team = AgentTeam::new(id, req.name, req.leader_id);
    let mut team = team;
    team.description = req.description;
    
    state.teams.write().await.insert(team.id.clone(), team.clone());
    info!("Created team: {}", team.id);
    Ok(Json(team))
}

async fn get_team(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<AgentTeam>, (StatusCode, String)> {
    let teams = state.teams.read().await;
    teams.get(&id)
        .cloned()
        .map(Json)
        .ok_or((StatusCode::NOT_FOUND, "Team not found".into()))
}

async fn update_team(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(mut team): Json<AgentTeam>,
) -> Result<Json<AgentTeam>, (StatusCode, String)> {
    let mut teams = state.teams.write().await;
    let _ = teams.get(&id)
        .ok_or((StatusCode::NOT_FOUND, "Team not found".into()))?;
    
    team.id = id.clone();
    team.updated_at = chrono::Utc::now().timestamp_millis();
    teams.insert(id, team.clone());
    Ok(Json(team))
}

async fn delete_team(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<StatusCode, (StatusCode, String)> {
    state.teams.write().await.remove(&id)
        .ok_or((StatusCode::NOT_FOUND, "Team not found".into()))?;
    info!("Deleted team: {}", id);
    Ok(StatusCode::NO_CONTENT)
}

async fn add_team_member(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(member): Json<TeamMember>,
) -> Result<Json<AgentTeam>, (StatusCode, String)> {
    let mut teams = state.teams.write().await;
    let mut team = teams.get(&id)
        .cloned()
        .ok_or((StatusCode::NOT_FOUND, "Team not found".into()))?;
    
    if !team.members.iter().any(|m| m.agent_id == member.agent_id) {
        team.members.push(member);
        team.updated_at = chrono::Utc::now().timestamp_millis();
        teams.insert(id, team.clone());
    }
    Ok(Json(team))
}

async fn remove_team_member(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Query(req): Query<RemoveMemberQuery>,
) -> Result<Json<AgentTeam>, (StatusCode, String)> {
    let mut teams = state.teams.write().await;
    let mut team = teams.get(&id)
        .cloned()
        .ok_or((StatusCode::NOT_FOUND, "Team not found".into()))?;
    
    team.members.retain(|m| m.agent_id != req.agent_id);
    team.updated_at = chrono::Utc::now().timestamp_millis();
    teams.insert(id, team.clone());
    Ok(Json(team))
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct RemoveMemberQuery {
    pub agent_id: String,
}

async fn set_team_canvas(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(req): Json<SetTeamCanvasRequest>,
) -> Result<Json<AgentTeam>, (StatusCode, String)> {
    let mut teams = state.teams.write().await;
    let mut team = teams.get(&id)
        .cloned()
        .ok_or((StatusCode::NOT_FOUND, "Team not found".into()))?;
    
    team.shared_canvas_id = Some(req.canvas_id);
    team.updated_at = chrono::Utc::now().timestamp_millis();
    teams.insert(id, team.clone());
    Ok(Json(team))
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct SetTeamCanvasRequest {
    pub canvas_id: String,
}

async fn execute_team_canvas(
    State(state): State<AppState>,
    Path(team_id): Path<String>,
    Json(req): Json<ExecuteCanvasRequest>,
) -> Result<Json<ExecutionContext>, (StatusCode, String)> {
    let team = {
        let teams = state.teams.read().await;
        teams.get(&team_id)
            .cloned()
            .ok_or((StatusCode::NOT_FOUND, "Team not found".into()))?
    };
    
    let canvas_id = team.shared_canvas_id
        .ok_or((StatusCode::BAD_REQUEST, "Team has no shared canvas".into()))?;
    
    // Execute with team context
    let mut trigger = req.trigger;
    trigger.payload = serde_json::json!({
        "team_id": team_id,
        "team_members": team.members.iter().map(|m| m.agent_id.clone()).collect::<Vec<_>>(),
        "payload": trigger.payload,
    });
    
    // Call execute_canvas by constructing the request directly
    let execution_id = Uuid::new_v4().to_string();
    let now = chrono::Utc::now().timestamp_millis();
    
    let canvas = {
        let canvases = state.canvases.read().await;
        canvases.get(&canvas_id)
            .cloned()
            .ok_or((StatusCode::NOT_FOUND, "Canvas not found".into()))?
    };
    
    let execution = ExecutionContext {
        execution_id: execution_id.clone(),
        canvas_id: canvas_id.clone(),
        trigger,
        variables: HashMap::new(),
        node_states: HashMap::new(),
        started_at: now,
        completed_at: None,
        status: ExecutionStatus::Pending,
        result: None,
    };
    
    state.executions.write().await.insert(execution_id.clone(), execution.clone());
    
    let state_clone = state.clone();
    let exec_id = execution_id.clone();
    let canvas_id_for_spawn = canvas_id.clone();
    tokio::spawn(async move {
        execute_canvas_internal(state_clone, exec_id, canvas).await;
    });
    
    info!("Started team execution: {} for canvas: {}", execution_id, canvas_id_for_spawn);
    Ok(Json(execution))
}

// ============================================================================
// HANDLERS - MCP SERVERS
// ============================================================================

async fn list_mcp_servers(State(state): State<AppState>) -> Json<Vec<MCPServer>> {
    let servers = state.mcp_servers.read().await;
    Json(servers.values().cloned().collect())
}

async fn create_mcp_server(
    State(state): State<AppState>,
    Json(req): Json<CreateMCPServerRequest>,
) -> Result<Json<MCPServer>, (StatusCode, String)> {
    let id = Uuid::new_v4().to_string();
    let server = MCPServer::new(id, req.name, req.transport);
    let mut server = server;
    server.description = req.description;
    
    state.mcp_servers.write().await.insert(server.id.clone(), server.clone());
    info!("Created MCP server: {}", server.id);
    Ok(Json(server))
}

async fn get_mcp_server(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<MCPServer>, (StatusCode, String)> {
    let servers = state.mcp_servers.read().await;
    servers.get(&id)
        .cloned()
        .map(Json)
        .ok_or((StatusCode::NOT_FOUND, "MCP server not found".into()))
}

async fn update_mcp_server(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(mut server): Json<MCPServer>,
) -> Result<Json<MCPServer>, (StatusCode, String)> {
    let mut servers = state.mcp_servers.write().await;
    let _ = servers.get(&id)
        .ok_or((StatusCode::NOT_FOUND, "MCP server not found".into()))?;
    
    server.id = id.clone();
    server.updated_at = chrono::Utc::now().timestamp_millis();
    servers.insert(id, server.clone());
    Ok(Json(server))
}

async fn delete_mcp_server(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<StatusCode, (StatusCode, String)> {
    state.mcp_servers.write().await.remove(&id)
        .ok_or((StatusCode::NOT_FOUND, "MCP server not found".into()))?;
    info!("Deleted MCP server: {}", id);
    Ok(StatusCode::NO_CONTENT)
}

async fn connect_mcp_server(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<MCPServer>, (StatusCode, String)> {
    let mut servers = state.mcp_servers.write().await;
    let mut server = servers.get(&id)
        .cloned()
        .ok_or((StatusCode::NOT_FOUND, "MCP server not found".into()))?;
    
    // TODO: Actual MCP connection using rmcp
    server.status = MCPServerStatus::Connected;
    server.tools = vec![
        MCPTool {
            name: "example_tool".into(),
            description: "Example tool from MCP server".into(),
            input_schema: serde_json::json!({"type": "object", "properties": {}}),
            output_schema: None,
            annotations: None,
        }
    ];
    server.updated_at = chrono::Utc::now().timestamp_millis();
    
    servers.insert(id, server.clone());
    info!("Connected MCP server: {}", server.id);
    Ok(Json(server))
}

async fn disconnect_mcp_server(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<MCPServer>, (StatusCode, String)> {
    let mut servers = state.mcp_servers.write().await;
    let mut server = servers.get(&id)
        .cloned()
        .ok_or((StatusCode::NOT_FOUND, "MCP server not found".into()))?;
    
    server.status = MCPServerStatus::Disconnected;
    server.updated_at = chrono::Utc::now().timestamp_millis();
    servers.insert(id, server.clone());
    Ok(Json(server))
}

async fn list_mcp_tools(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<Vec<MCPTool>>, (StatusCode, String)> {
    let servers = state.mcp_servers.read().await;
    servers.get(&id)
        .map(|s| Json(s.tools.clone()))
        .ok_or((StatusCode::NOT_FOUND, "MCP server not found".into()))
}

async fn call_mcp_tool(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(_req): Json<CallMCPToolRequest>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    let server_exists = {
        let servers = state.mcp_servers.read().await;
        servers.contains_key(&id)
    };
    
    if !server_exists {
        return Err((StatusCode::NOT_FOUND, "MCP server not found".into()));
    }
    
    // TODO: Actual MCP tool call using rmcp
    Ok(Json(serde_json::json!({"result": "success", "data": {}})))
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct CallMCPToolRequest {
    pub tool_name: String,
    pub arguments: serde_json::Value,
}

// ============================================================================
// HANDLERS - A2A PROTOCOL
// ============================================================================

async fn get_agent_card(
    State(state): State<AppState>,
    Query(req): Query<GetAgentCardQuery>,
) -> Result<Json<A2AAgentCard>, (StatusCode, String)> {
    let agents = state.agents.read().await;
    let agent = agents.get(&req.agent_id)
        .ok_or((StatusCode::NOT_FOUND, "Agent not found".into()))?;
    
    Ok(Json(A2AAgentCard {
        name: agent.name.clone(),
        description: agent.description.clone(),
        version: "1.0.0".into(),
        url: format!("http://localhost:3030/api/a2a/agent/{}", agent.id),
        capabilities: A2ACapabilities {
            streaming: true,
            push_notifications: true,
            state_transition_history: true,
        },
        skills: agent.skills.iter().map(|skill_id| A2ASkill {
            id: skill_id.clone(),
            name: skill_id.clone(),
            description: format!("Skill: {}", skill_id),
            tags: vec![],
            examples: vec![],
            input_modes: vec!["text".into()],
            output_modes: vec!["text".into()],
        }).collect(),
        auth: None,
    }))
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct GetAgentCardQuery {
    pub agent_id: String,
}

async fn send_a2a_message(
    State(_state): State<AppState>,
    Json(req): Json<A2AMessageRequest>,
) -> Result<Json<A2ATask>, (StatusCode, String)> {
    // TODO: Implement actual A2A protocol communication
    Ok(Json(A2ATask {
        id: Uuid::new_v4().to_string(),
        status: A2ATaskStatus::Submitted,
        message: req.message,
        artifacts: vec![],
        history: vec![],
    }))
}

async fn get_a2a_task(
    State(_state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<A2ATask>, (StatusCode, String)> {
    // TODO: Implement task tracking
    Ok(Json(A2ATask {
        id,
        status: A2ATaskStatus::Completed,
        message: A2AMessage {
            id: Uuid::new_v4().to_string(),
            role: A2ARole::Agent,
            parts: vec![A2APart {
                part_type: A2APartType::Text,
                content: "Task completed".into(),
                metadata: None,
            }],
            metadata: None,
        },
        artifacts: vec![],
        history: vec![],
    }))
}

async fn cancel_a2a_task(
    State(_state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<A2ATask>, (StatusCode, String)> {
    Ok(Json(A2ATask {
        id,
        status: A2ATaskStatus::Cancelled,
        message: A2AMessage {
            id: Uuid::new_v4().to_string(),
            role: A2ARole::System,
            parts: vec![A2APart {
                part_type: A2APartType::Text,
                content: "Task cancelled".into(),
                metadata: None,
            }],
            metadata: None,
        },
        artifacts: vec![],
        history: vec![],
    }))
}

// ============================================================================
// HANDLERS - EXECUTIONS
// ============================================================================

async fn list_executions(State(state): State<AppState>) -> Json<Vec<ExecutionContext>> {
    let executions = state.executions.read().await;
    Json(executions.values().cloned().collect())
}

async fn get_execution(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<ExecutionContext>, (StatusCode, String)> {
    let executions = state.executions.read().await;
    executions.get(&id)
        .cloned()
        .map(Json)
        .ok_or((StatusCode::NOT_FOUND, "Execution not found".into()))
}

async fn cancel_execution(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<ExecutionContext>, (StatusCode, String)> {
    let mut executions = state.executions.write().await;
    let mut exec = executions.get(&id)
        .cloned()
        .ok_or((StatusCode::NOT_FOUND, "Execution not found".into()))?;
    
    exec.status = ExecutionStatus::Cancelled;
    exec.completed_at = Some(chrono::Utc::now().timestamp_millis());
    executions.insert(id, exec.clone());
    Ok(Json(exec))
}

async fn retry_execution(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<ExecutionContext>, (StatusCode, String)> {
    let exec = {
        let executions = state.executions.read().await;
        executions.get(&id)
            .cloned()
            .ok_or((StatusCode::NOT_FOUND, "Execution not found".into()))?
    };
    
    let canvas = {
        let canvases = state.canvases.read().await;
        canvases.get(&exec.canvas_id)
            .cloned()
            .ok_or((StatusCode::NOT_FOUND, "Canvas not found".into()))?
    };
    
    let new_execution_id = Uuid::new_v4().to_string();
    let now = chrono::Utc::now().timestamp_millis();
    
    let new_exec = ExecutionContext {
        execution_id: new_execution_id.clone(),
        canvas_id: exec.canvas_id,
        trigger: exec.trigger,
        variables: HashMap::new(),
        node_states: HashMap::new(),
        started_at: now,
        completed_at: None,
        status: ExecutionStatus::Pending,
        result: None,
    };
    
    state.executions.write().await.insert(new_execution_id.clone(), new_exec.clone());
    
    let state_clone = state.clone();
    tokio::spawn(async move {
        execute_canvas_internal(state_clone, new_execution_id, canvas).await;
    });
    
    Ok(Json(new_exec))
}

// ============================================================================
// HANDLERS - AI GENERATION
// ============================================================================

async fn ai_generate_node(
    State(_state): State<AppState>,
    Json(req): Json<AIGenerateNodeRequest>,
) -> Result<Json<CanvasNode>, (StatusCode, String)> {
    // TODO: Implement AI node generation using LLM
    // This would call an LLM with the user's intent and generate a complete node
    let node = CanvasNode {
        id: Uuid::new_v4().to_string(),
        node_type: req.node_type,
        position: req.position,
        config: NodeConfig {
            code: Some("// AI generated code\nasync function execute(inputs) {\n  return { result: 'hello' };\n}".to_string()),
            language: Some(CodeLanguage::TypeScript),
            imports: vec![],
            ..NodeConfig::default()
        },
        inputs: vec![],
        outputs: vec![Port {
            id: "output".into(),
            name: "result".into(),
            data_type: DataType::Any,
            required: false,
            default_value: None,
        }],
        metadata: NodeMetadata {
            label: req.label,
            description: req.description,
            color: "#6366f1".into(),
            icon: "code".into(),
            category: NodeCategory::Action,
            is_ai_generated: true,
            ai_generation_prompt: Some(req.prompt),
            test_cases: vec![],
            last_test_result: None,
        },
    };
    Ok(Json(node))
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct AIGenerateNodeRequest {
    pub prompt: String,
    pub node_type: NodeType,
    pub position: Position,
    pub label: String,
    pub description: String,
}

async fn ai_generate_canvas(
    State(_state): State<AppState>,
    Json(req): Json<AIGenerateCanvasRequest>,
) -> Result<Json<Canvas>, (StatusCode, String)> {
    // TODO: Implement AI canvas generation - full flow from natural language
    let canvas = Canvas::new(Uuid::new_v4().to_string(), req.name, req.created_by);
    let mut canvas = canvas;
    canvas.description = req.description;
    // AI would generate nodes, edges, etc.
    Ok(Json(canvas))
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct AIGenerateCanvasRequest {
    pub name: String,
    pub description: String,
    pub prompt: String,
    pub created_by: String,
}

async fn ai_generate_skill(
    State(_state): State<AppState>,
    Json(req): Json<AIGenerateSkillRequest>,
) -> Result<Json<Skill>, (StatusCode, String)> {
    // TODO: Implement AI skill generation
    let skill = Skill::new(Uuid::new_v4().to_string(), req.name, req.category, req.created_by);
    let mut skill = skill;
    skill.description = req.description;
    skill.is_auto_generated = true;
    Ok(Json(skill))
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct AIGenerateSkillRequest {
    pub name: String,
    pub description: String,
    pub category: SkillCategory,
    pub prompt: String,
    pub created_by: String,
}

async fn ai_optimize_canvas(
    State(state): State<AppState>,
    Json(req): Json<AIOptimizeCanvasRequest>,
) -> Result<Json<Canvas>, (StatusCode, String)> {
    // TODO: Implement AI canvas optimization (A/B testing, genetic algorithms, etc.)
    let canvases = state.canvases.read().await;
    let canvas = canvases.get(&req.canvas_id)
        .cloned()
        .ok_or((StatusCode::NOT_FOUND, "Canvas not found".into()))?;
    Ok(Json(canvas))
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct AIOptimizeCanvasRequest {
    pub canvas_id: String,
    pub optimization_goal: OptimizationGoal,
    pub generations: u32,
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum OptimizationGoal {
    MinimizeCost,
    MinimizeLatency,
    MaximizeSuccessRate,
    MaximizeAccuracy,
    Balanced,
}

async fn ai_test_generation(
    State(_state): State<AppState>,
    Json(req): Json<AITestGenerationRequest>,
) -> Result<Json<Vec<TestCase>>, (StatusCode, String)> {
    // TODO: Implement AI test case generation
    Ok(Json(vec![TestCase {
        id: Uuid::new_v4().to_string(),
        name: "AI generated test".into(),
        inputs: HashMap::new(),
        expected_outputs: HashMap::new(),
        created_by: "ai".into(),
    }]))
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct AITestGenerationRequest {
    pub node_id: String,
    pub node_config: NodeConfig,
    pub num_cases: u32,
}

// ============================================================================
// MAIN
// ============================================================================

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .json()
        .init();
    
    let state = AppState::default();
    let app = create_router(state);
    
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3030").await?;
    info!("AI Canvas Server listening on http://0.0.0.0:3030");
    
    axum::serve(listener, app).await?;
    Ok(())
}