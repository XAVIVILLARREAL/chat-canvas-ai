//! Servidor central de Canvas AI — APIs para Canvas, Skills, Agents, MCP, Executions
//!
//! Expone el mismo dominio `canvas-ai-core` via HTTP (Axum).
//! Persistencia: SQLite vía `canvas-ai-core::repo` (slice 0.1, ADR-007) —
//! la data sobrevive reinicios. Postgres+RLS llega en slice 0.2.

use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::Json,
    routing::{get, post},
    Router,
};
use canvas_ai_core::{domain::*, repo, vault};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use tracing::{info, error};
use uuid::Uuid;

// ============================================================================
// APP STATE — persistido en SQLite (ADR-007), no en memoria
// ============================================================================

/// Workspace local por defecto (multi-tenant real con nube/RLS en slice 0.2).
pub const DEFAULT_PROJECT_ID: &str = "local-default";

#[derive(Clone)]
pub struct AppState {
    pub db: repo::Db,
    pub project_id: String,
    /// KEK del vault BYOK (env CANVAS_KEK, base64 32B — THREAT-MODEL §3).
    pub vault_ks: std::sync::Arc<dyn vault::KeyStore>,
}

impl AppState {
    /// Conecta a SQLite, aplica migraciones y asegura el proyecto default.
    /// La KEK del vault se lee de `CANVAS_KEK` (tests la setean antes de llamar).
    pub async fn connect(url: &str) -> anyhow::Result<Self> {
        let db = repo::connect(url).await?;
        if repo::project_get(&db, DEFAULT_PROJECT_ID).await?.is_none() {
            repo::project_create(&db, DEFAULT_PROJECT_ID, "Canvas AI (local)").await?;
            info!("Proyecto default creado: {}", DEFAULT_PROJECT_ID);
        }
        Ok(Self {
            db,
            project_id: DEFAULT_PROJECT_ID.into(),
            vault_ks: std::sync::Arc::new(vault::EnvKeyStore::from_env("CANVAS_KEK")),
        })
    }
}

type ApiResult<T> = Result<Json<T>, (StatusCode, String)>;

fn not_found(que: &str) -> (StatusCode, String) {
    (StatusCode::NOT_FOUND, format!("{} not found", que))
}

fn vault_err(e: canvas_ai_core::vault::VaultError) -> (StatusCode, String) {
    error!("vault error: {}", e);
    (StatusCode::INTERNAL_SERVER_ERROR, format!("vault error: {e}"))
}

fn db_err(e: sqlx::Error) -> (StatusCode, String) {
    error!("DB error: {}", e);
    (StatusCode::INTERNAL_SERVER_ERROR, format!("db error: {e}"))
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
        
        // Providers BYOK (la key NUNCA en respuestas — solo key_ref)
        .route("/api/providers", get(list_providers).post(create_provider))
        .route("/api/providers/:id", get(get_provider).delete(delete_provider))
        .route("/api/providers/:id/test", post(test_provider))
        
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
// HANDLERS - CANVAS (persistido: canvases.data JSON, ADR-007)
// ============================================================================

async fn list_canvases(State(state): State<AppState>) -> ApiResult<Vec<Canvas>> {
    repo::canvas_list(&state.db, &state.project_id).await
        .map(Json).map_err(|e| db_err(e))
}

async fn create_canvas(
    State(state): State<AppState>,
    Json(req): Json<CreateCanvasRequest>,
) -> ApiResult<Canvas> {
    let id = Uuid::new_v4().to_string();
    let mut canvas = Canvas::new(id, req.name, req.created_by);
    canvas.description = req.description;
    repo::canvas_put(&state.db, &state.project_id, &canvas).await.map_err(|e| db_err(e))?;
    info!("Created canvas: {}", canvas.id);
    Ok(Json(canvas))
}

async fn get_canvas(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> ApiResult<Canvas> {
    repo::canvas_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .map(Json)
        .ok_or_else(|| not_found("Canvas"))
}

async fn update_canvas(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(req): Json<UpdateCanvasRequest>,
) -> ApiResult<Canvas> {
    let mut canvas = repo::canvas_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .ok_or_else(|| not_found("Canvas"))?;
    
    if let Some(name) = req.name { canvas.name = name; }
    if let Some(description) = req.description { canvas.description = description; }
    if let Some(nodes) = req.nodes { canvas.nodes = nodes; }
    if let Some(edges) = req.edges { canvas.edges = edges; }
    if let Some(viewport) = req.viewport { canvas.viewport = viewport; }
    if let Some(settings) = req.settings { canvas.settings = settings; }
    
    canvas.version += 1;
    canvas.updated_at = chrono::Utc::now().timestamp_millis();
    
    repo::canvas_put(&state.db, &state.project_id, &canvas).await.map_err(|e| db_err(e))?;
    info!("Updated canvas: {}", canvas.id);
    Ok(Json(canvas))
}

async fn delete_canvas(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<StatusCode, (StatusCode, String)> {
    let affected = repo::canvas_delete(&state.db, &id).await.map_err(|e| db_err(e))?;
    if affected == 0 { return Err(not_found("Canvas")); }
    info!("Deleted canvas: {}", id);
    Ok(StatusCode::NO_CONTENT)
}

async fn execute_canvas(
    State(state): State<AppState>,
    Path(canvas_id): Path<String>,
    Json(req): Json<ExecuteCanvasRequest>,
) -> ApiResult<ExecutionContext> {
    let canvas = repo::canvas_get(&state.db, &canvas_id).await
        .map_err(|e| db_err(e))?
        .ok_or_else(|| not_found("Canvas"))?;
    
    let now = chrono::Utc::now().timestamp_millis();
    let execution = ExecutionContext {
        execution_id: Uuid::new_v4().to_string(),
        canvas_id: canvas_id.clone(),
        trigger: req.trigger,
        variables: HashMap::new(),
        node_states: HashMap::new(),
        started_at: now,
        completed_at: None,
        status: ExecutionStatus::Pending,
        result: None,
    };
    repo::execution_domain_create(&state.db, &execution).await.map_err(|e| db_err(e))?;
    
    // Spawn execution task
    let state_clone = state.clone();
    let exec_id = execution.execution_id.clone();
    let canvas_id_for_log = canvas_id.clone();
    tokio::spawn(async move {
        execute_canvas_internal(state_clone, exec_id, canvas).await;
    });
    
    info!("Started execution: {} for canvas: {}", execution.execution_id, canvas_id_for_log);
    Ok(Json(execution))
}

async fn execute_canvas_internal(
    state: AppState,
    execution_id: String,
    _canvas: Canvas,
) {
    // Update status to running
    let mut ctx = match repo::execution_domain_get(&state.db, &execution_id).await {
        Ok(Some(c)) => c,
        Ok(None) => { error!("Execution {} desapareció", execution_id); return; }
        Err(e) => { error!("DB error al leer execution: {e}"); return; }
    };
    ctx.status = ExecutionStatus::Running;
    if let Err(e) = repo::execution_domain_update(&state.db, &ctx).await {
        error!("DB error al marcar running: {e}"); return;
    }
    
    // TODO: Implement actual canvas execution logic
    // This would:
    // 1. Topologically sort nodes based on edges
    // 2. Execute nodes in order (respecting parallel/sequential)
    // 3. Handle MCP calls, LLM calls, code execution, etc.
    // 4. Update node states and execution result
    
    // For now, simulate completion
    tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
    
    ctx.status = ExecutionStatus::Completed;
    ctx.completed_at = Some(chrono::Utc::now().timestamp_millis());
    ctx.result = Some(ExecutionResult {
        success: true,
        outputs: HashMap::new(),
        error: None,
        node_results: HashMap::new(),
        total_duration_ms: 100,
        cost_usd: 0.0,
    });
    if let Err(e) = repo::execution_domain_update(&state.db, &ctx).await {
        error!("DB error al completar execution: {e}");
    }
}

async fn test_canvas(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(req): Json<TestNodeRequest>,
) -> ApiResult<TestResult> {
    // el canvas debe existir (validación barata contra la DB)
    if repo::canvas_get(&state.db, &id).await.map_err(|e| db_err(e))?.is_none() {
        return Err(not_found("Canvas"));
    }
    // TODO: Implement node testing with sandboxed execution
    let _ = req;
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
) -> ApiResult<ValidationResult> {
    let canvas = repo::canvas_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .ok_or_else(|| not_found("Canvas"))?;
    
    let mut errors = Vec::new();
    let warnings = Vec::new();
    
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
    use std::collections::{HashMap, VecDeque};
    
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
// HANDLERS - PROVIDERS BYOK (secretos en vault, THREAT-MODEL §3)
// ============================================================================

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct CreateProviderRequest {
    pub provider_type: String,   // openai|anthropic|openrouter|deepseek|ollama|generic
    pub name: String,
    pub base_url: String,
    pub api_key: String,         // ENTRADA únicamente; jamás se devuelve
    pub validate: Option<bool>,  // default true: roundtrip mínimo antes de guardar
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct ProviderTestResponse {
    pub connected: bool,
    pub error: Option<String>,
}

async fn create_provider(
    State(state): State<AppState>,
    Json(req): Json<CreateProviderRequest>,
) -> ApiResult<repo::Provider> {
    // validación roundtrip mínima antes de guardar (default: on)
    if req.validate.unwrap_or(true) {
        vault::validate_provider_key(&req.provider_type, &req.base_url, &req.api_key)
            .await
            .map_err(|e| (StatusCode::BAD_REQUEST, format!("provider inválido: {e}")))?;
    }
    // secreto al vault; key_ref al registro — la key nunca vuelve a verse
    let key_ref = vault::store_secret(&state.db, &state.project_id, state.vault_ks.as_ref(), &req.api_key)
        .await
        .map_err(vault_err)?;
    let id = Uuid::new_v4().to_string();
    let provider = repo::provider_create(
        &state.db, &id, &state.project_id, &req.provider_type, &req.name,
        Some(&req.base_url), Some(&key_ref),
    ).await.map_err(|e| db_err(e))?;
    info!("Provider creado ({}): key_ref={}", req.provider_type, key_ref);
    Ok(Json(provider))
}

async fn list_providers(State(state): State<AppState>) -> ApiResult<Vec<repo::Provider>> {
    repo::provider_list_by_project(&state.db, &state.project_id)
        .await.map(Json).map_err(|e| db_err(e))
}

async fn get_provider(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> ApiResult<repo::Provider> {
    repo::provider_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .map(Json)
        .ok_or_else(|| not_found("Provider"))
}

/// Roundtrip de salud con la key almacenada (revela SOLO en memoria del server).
async fn test_provider(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> ApiResult<ProviderTestResponse> {
    let provider = repo::provider_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .ok_or_else(|| not_found("Provider"))?;
    let key_ref = provider.key_ref.clone()
        .ok_or_else(|| (StatusCode::BAD_REQUEST, "provider sin key".into()))?;
    match vault::reveal_secret(&state.db, &key_ref, state.vault_ks.as_ref()).await {
        Ok(key) => {
            match vault::validate_provider_key(&provider.provider_type,
                provider.base_url.as_deref().unwrap_or(""), &key).await {
                Ok(()) => Ok(Json(ProviderTestResponse { connected: true, error: None })),
                Err(e) => Ok(Json(ProviderTestResponse { connected: false, error: Some(e.to_string()) })),
            }
        }
        Err(e) => Ok(Json(ProviderTestResponse { connected: false, error: Some(e.to_string()) })),
    }
}

async fn delete_provider(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<StatusCode, (StatusCode, String)> {
    let provider = repo::provider_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .ok_or_else(|| not_found("Provider"))?;
    if let Some(key_ref) = &provider.key_ref {
        vault::delete_secret(&state.db, key_ref).await.map_err(vault_err)?;
    }
    repo::provider_delete(&state.db, &id).await.map_err(|e| db_err(e))?;
    info!("Provider eliminado: {}", id);
    Ok(StatusCode::NO_CONTENT)
}

// ============================================================================
// HANDLERS - SKILLS (persistido: skills.manifest JSON + skill_versions, ADR-007)
// ============================================================================

async fn list_skills(State(state): State<AppState>) -> ApiResult<Vec<Skill>> {
    repo::skill_domain_list(&state.db, &state.project_id).await
        .map(Json).map_err(|e| db_err(e))
}

async fn create_skill(
    State(state): State<AppState>,
    Json(req): Json<CreateSkillRequest>,
) -> ApiResult<Skill> {
    let id = Uuid::new_v4().to_string();
    let mut skill = Skill::new(id, req.name, req.category, req.created_by);
    skill.description = req.description;
    repo::skill_domain_create(&state.db, &state.project_id, &skill, None).await.map_err(|e| db_err(e))?;
    info!("Created skill: {}", skill.id);
    Ok(Json(skill))
}

async fn get_skill(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> ApiResult<Skill> {
    repo::skill_domain_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .map(Json)
        .ok_or_else(|| not_found("Skill"))
}

async fn update_skill(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(mut skill): Json<Skill>,
) -> ApiResult<Skill> {
    let existing = repo::skill_domain_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .ok_or_else(|| not_found("Skill"))?;
    
    skill.id = id.clone();
    skill.updated_at = chrono::Utc::now().timestamp_millis();
    skill.version = increment_version(&existing.version);
    
    // snapshot en skill_versions + manifest actualizado
    repo::skill_domain_update(&state.db, &skill).await.map_err(|e| db_err(e))?;
    info!("Updated skill: {}", skill.id);
    Ok(Json(skill))
}

async fn delete_skill(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<StatusCode, (StatusCode, String)> {
    let affected = repo::skill_soft_delete(&state.db, &id).await.map_err(|e| db_err(e))?;
    if affected == 0 { return Err(not_found("Skill")); }
    info!("Deleted skill: {}", id);
    Ok(StatusCode::NO_CONTENT)
}

async fn test_skill(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(inputs): Json<HashMap<String, serde_json::Value>>,
) -> ApiResult<TestResult> {
    if repo::skill_domain_get(&state.db, &id).await.map_err(|e| db_err(e))?.is_none() {
        return Err(not_found("Skill"));
    }
    let _ = inputs;
    // TODO: Execute skill in sandbox with inputs
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
) -> ApiResult<Skill> {
    let skill = repo::skill_domain_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .ok_or_else(|| not_found("Skill"))?;
    
    // Create improved version (skill nuevo, como antes)
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
    
    repo::skill_domain_create(&state.db, &state.project_id, &improved_skill, None).await.map_err(|e| db_err(e))?;
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
) -> ApiResult<Vec<Skill>> {
    // historial real desde skill_versions (snapshots del manifest)
    repo::skill_domain_versions(&state.db, &id).await.map(Json).map_err(|e| db_err(e))
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
// HANDLERS - AGENTS (persistido: agents.data JSON, ADR-007)
// ============================================================================

async fn list_agents(State(state): State<AppState>) -> ApiResult<Vec<Agent>> {
    repo::agent_list(&state.db, &state.project_id).await
        .map(Json).map_err(|e| db_err(e))
}

async fn create_agent(
    State(state): State<AppState>,
    Json(req): Json<CreateAgentRequest>,
) -> ApiResult<Agent> {
    let id = Uuid::new_v4().to_string();
    let mut agent = Agent::new(id, req.name, req.role, req.created_by);
    agent.description = req.description;
    repo::agent_put(&state.db, &state.project_id, &agent).await.map_err(|e| db_err(e))?;
    info!("Created agent: {}", agent.id);
    Ok(Json(agent))
}

async fn get_agent(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> ApiResult<Agent> {
    repo::agent_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .map(Json)
        .ok_or_else(|| not_found("Agent"))
}

async fn update_agent(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(mut agent): Json<Agent>,
) -> ApiResult<Agent> {
    if repo::agent_get(&state.db, &id).await.map_err(|e| db_err(e))?.is_none() {
        return Err(not_found("Agent"));
    }
    agent.id = id.clone();
    agent.updated_at = chrono::Utc::now().timestamp_millis();
    repo::agent_put(&state.db, &state.project_id, &agent).await.map_err(|e| db_err(e))?;
    info!("Updated agent: {}", agent.id);
    Ok(Json(agent))
}

async fn delete_agent(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<StatusCode, (StatusCode, String)> {
    let affected = repo::agent_delete(&state.db, &id).await.map_err(|e| db_err(e))?;
    if affected == 0 { return Err(not_found("Agent")); }
    info!("Deleted agent: {}", id);
    Ok(StatusCode::NO_CONTENT)
}

async fn assign_skill_to_agent(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(req): Json<AssignSkillRequest>,
) -> ApiResult<Agent> {
    let mut agent = repo::agent_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .ok_or_else(|| not_found("Agent"))?;
    
    if !agent.skills.contains(&req.skill_id) {
        agent.skills.push(req.skill_id);
        agent.updated_at = chrono::Utc::now().timestamp_millis();
        repo::agent_put(&state.db, &state.project_id, &agent).await.map_err(|e| db_err(e))?;
    }
    Ok(Json(agent))
}

async fn remove_skill_from_agent(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Query(req): Query<RemoveSkillQuery>,
) -> ApiResult<Agent> {
    let mut agent = repo::agent_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .ok_or_else(|| not_found("Agent"))?;
    
    agent.skills.retain(|s| s != &req.skill_id);
    agent.updated_at = chrono::Utc::now().timestamp_millis();
    repo::agent_put(&state.db, &state.project_id, &agent).await.map_err(|e| db_err(e))?;
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
) -> ApiResult<Agent> {
    let mut agent = repo::agent_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .ok_or_else(|| not_found("Agent"))?;
    
    if !agent.mcp_servers.contains(&req.mcp_server_id) {
        agent.mcp_servers.push(req.mcp_server_id);
        agent.updated_at = chrono::Utc::now().timestamp_millis();
        repo::agent_put(&state.db, &state.project_id, &agent).await.map_err(|e| db_err(e))?;
    }
    Ok(Json(agent))
}

async fn remove_mcp_from_agent(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Query(req): Query<RemoveMCPQuery>,
) -> ApiResult<Agent> {
    let mut agent = repo::agent_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .ok_or_else(|| not_found("Agent"))?;
    
    agent.mcp_servers.retain(|s| s != &req.mcp_server_id);
    agent.updated_at = chrono::Utc::now().timestamp_millis();
    repo::agent_put(&state.db, &state.project_id, &agent).await.map_err(|e| db_err(e))?;
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
) -> ApiResult<ChatResponse> {
    if repo::agent_get(&state.db, &id).await.map_err(|e| db_err(e))?.is_none() {
        return Err(not_found("Agent"));
    }
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
) -> ApiResult<AgentMemory> {
    repo::agent_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .map(|a| Json(a.memory))
        .ok_or_else(|| not_found("Agent"))
}

async fn update_agent_memory(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(memory): Json<AgentMemory>,
) -> ApiResult<Agent> {
    let mut agent = repo::agent_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .ok_or_else(|| not_found("Agent"))?;
    
    agent.memory = memory;
    agent.updated_at = chrono::Utc::now().timestamp_millis();
    repo::agent_put(&state.db, &state.project_id, &agent).await.map_err(|e| db_err(e))?;
    Ok(Json(agent))
}

// ============================================================================
// HANDLERS - MCP SERVERS (persistido: mcp_servers.data JSON, ADR-007)
// ============================================================================

async fn list_mcp_servers(State(state): State<AppState>) -> ApiResult<Vec<MCPServer>> {
    repo::mcp_list(&state.db, &state.project_id).await
        .map(Json).map_err(|e| db_err(e))
}

async fn create_mcp_server(
    State(state): State<AppState>,
    Json(req): Json<CreateMCPServerRequest>,
) -> ApiResult<MCPServer> {
    let id = Uuid::new_v4().to_string();
    let mut server = MCPServer::new(id, req.name, req.transport);
    server.description = req.description;
    repo::mcp_put(&state.db, &state.project_id, &server).await.map_err(|e| db_err(e))?;
    info!("Created MCP server: {}", server.id);
    Ok(Json(server))
}

async fn get_mcp_server(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> ApiResult<MCPServer> {
    repo::mcp_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .map(Json)
        .ok_or_else(|| not_found("MCP server"))
}

async fn update_mcp_server(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(mut server): Json<MCPServer>,
) -> ApiResult<MCPServer> {
    if repo::mcp_get(&state.db, &id).await.map_err(|e| db_err(e))?.is_none() {
        return Err(not_found("MCP server"));
    }
    server.id = id.clone();
    server.updated_at = chrono::Utc::now().timestamp_millis();
    repo::mcp_put(&state.db, &state.project_id, &server).await.map_err(|e| db_err(e))?;
    Ok(Json(server))
}

async fn delete_mcp_server(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<StatusCode, (StatusCode, String)> {
    let affected = repo::mcp_delete(&state.db, &id).await.map_err(|e| db_err(e))?;
    if affected == 0 { return Err(not_found("MCP server")); }
    info!("Deleted MCP server: {}", id);
    Ok(StatusCode::NO_CONTENT)
}

async fn connect_mcp_server(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> ApiResult<MCPServer> {
    let mut server = repo::mcp_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .ok_or_else(|| not_found("MCP server"))?;
    
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
    
    repo::mcp_put(&state.db, &state.project_id, &server).await.map_err(|e| db_err(e))?;
    info!("Connected MCP server: {}", server.id);
    Ok(Json(server))
}

async fn disconnect_mcp_server(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> ApiResult<MCPServer> {
    let mut server = repo::mcp_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .ok_or_else(|| not_found("MCP server"))?;
    
    server.status = MCPServerStatus::Disconnected;
    server.updated_at = chrono::Utc::now().timestamp_millis();
    repo::mcp_put(&state.db, &state.project_id, &server).await.map_err(|e| db_err(e))?;
    Ok(Json(server))
}

async fn list_mcp_tools(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> ApiResult<Vec<MCPTool>> {
    repo::mcp_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .map(|s| Json(s.tools))
        .ok_or_else(|| not_found("MCP server"))
}

async fn call_mcp_tool(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(_req): Json<CallMCPToolRequest>,
) -> ApiResult<serde_json::Value> {
    if repo::mcp_get(&state.db, &id).await.map_err(|e| db_err(e))?.is_none() {
        return Err(not_found("MCP server"));
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
) -> ApiResult<A2AAgentCard> {
    let agent = repo::agent_get(&state.db, &req.agent_id).await
        .map_err(|e| db_err(e))?
        .ok_or_else(|| not_found("Agent"))?;
    
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
) -> ApiResult<A2ATask> {
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
) -> ApiResult<A2ATask> {
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
) -> ApiResult<A2ATask> {
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
// HANDLERS - EXECUTIONS (persistido: executions columnas tipadas, ADR-007)
// ============================================================================

async fn list_executions(State(state): State<AppState>) -> ApiResult<Vec<ExecutionContext>> {
    repo::execution_domain_list(&state.db).await
        .map(Json).map_err(|e| db_err(e))
}

async fn get_execution(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> ApiResult<ExecutionContext> {
    repo::execution_domain_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .map(Json)
        .ok_or_else(|| not_found("Execution"))
}

async fn cancel_execution(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> ApiResult<ExecutionContext> {
    let mut exec = repo::execution_domain_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .ok_or_else(|| not_found("Execution"))?;
    
    exec.status = ExecutionStatus::Cancelled;
    exec.completed_at = Some(chrono::Utc::now().timestamp_millis());
    repo::execution_domain_update(&state.db, &exec).await.map_err(|e| db_err(e))?;
    Ok(Json(exec))
}

async fn retry_execution(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> ApiResult<ExecutionContext> {
    let exec = repo::execution_domain_get(&state.db, &id).await
        .map_err(|e| db_err(e))?
        .ok_or_else(|| not_found("Execution"))?;
    
    let canvas = repo::canvas_get(&state.db, &exec.canvas_id).await
        .map_err(|e| db_err(e))?
        .ok_or_else(|| not_found("Canvas"))?;
    
    let now = chrono::Utc::now().timestamp_millis();
    let new_exec = ExecutionContext {
        execution_id: Uuid::new_v4().to_string(),
        canvas_id: exec.canvas_id,
        trigger: exec.trigger,
        variables: HashMap::new(),
        node_states: HashMap::new(),
        started_at: now,
        completed_at: None,
        status: ExecutionStatus::Pending,
        result: None,
    };
    repo::execution_domain_create(&state.db, &new_exec).await.map_err(|e| db_err(e))?;
    
    let state_clone = state.clone();
    let new_id = new_exec.execution_id.clone();
    tokio::spawn(async move {
        execute_canvas_internal(state_clone, new_id, canvas).await;
    });
    
    Ok(Json(new_exec))
}

// ============================================================================
// HANDLERS - AI GENERATION
// ============================================================================

async fn ai_generate_node(
    State(_state): State<AppState>,
    Json(req): Json<AIGenerateNodeRequest>,
) -> ApiResult<CanvasNode> {
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
    State(state): State<AppState>,
    Json(req): Json<AIGenerateCanvasRequest>,
) -> ApiResult<Canvas> {
    // TODO: Implement AI canvas generation - full flow from natural language
    let id = Uuid::new_v4().to_string();
    let mut canvas = Canvas::new(id, req.name, req.created_by);
    canvas.description = req.description;
    // AI would generate nodes, edges, etc. — persistido para que no se pierda
    repo::canvas_put(&state.db, &state.project_id, &canvas).await.map_err(|e| db_err(e))?;
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
    State(state): State<AppState>,
    Json(req): Json<AIGenerateSkillRequest>,
) -> ApiResult<Skill> {
    // TODO: Implement AI skill generation
    let id = Uuid::new_v4().to_string();
    let mut skill = Skill::new(id, req.name, req.category, req.created_by);
    skill.description = req.description;
    skill.is_auto_generated = true;
    repo::skill_domain_create(&state.db, &state.project_id, &skill, None).await.map_err(|e| db_err(e))?;
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
) -> ApiResult<Canvas> {
    // TODO: Implement AI canvas optimization (A/B testing, genetic algorithms, etc.)
    repo::canvas_get(&state.db, &req.canvas_id).await
        .map_err(|e| db_err(e))?
        .map(Json)
        .ok_or_else(|| not_found("Canvas"))
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
) -> ApiResult<Vec<TestCase>> {
    // TODO: Implement AI test case generation
    let _ = req;
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
// SERVE
// ============================================================================

/// Arranca el servidor HTTP en :3030 con SQLite persistente.
pub async fn serve() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .json()
        .init();
    
    // Persistencia real: SQLite (slice 0.1, ADR-007). Override con CANVAS_AI_DB.
    let db_url = std::env::var("CANVAS_AI_DB").unwrap_or_else(|_| "sqlite://canvas-ai.db".into());
    let state = AppState::connect(&db_url).await?;
    tracing::info!("SQLite listo: {}", db_url);
    
    let app = create_router(state);
    
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3030").await?;
    tracing::info!("AI Canvas Server listening on http://0.0.0.0:3030");
    
    axum::serve(listener, app).await?;
    Ok(())
}
