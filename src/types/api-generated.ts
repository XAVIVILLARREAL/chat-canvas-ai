// AUTO-GENERADO: cargo run -p canvas-ai-server --bin export-openapi — NO editar a mano.
// Fuente única: structs Rust del server/core (docs/openapi.json).

export type A2AArtifact = {
  description: string;
  id: string;
  metadata?: Record<string, unknown>;
  name: string;
  parts: A2APart[];
};

export type A2AAuth = {
  credentials: Record<string, unknown>;
  schemes: string[];
};

export type A2ACapabilities = {
  push_notifications: boolean;
  state_transition_history: boolean;
  streaming: boolean;
};

export type A2AMessage = {
  id: string;
  metadata?: Record<string, unknown>;
  parts: A2APart[];
  role: A2ARole;
};

export type A2APart = {
  content: string;
  metadata?: Record<string, unknown>;
  part_type: A2APartType;
};

export type A2APartType = "text" | "file" | "data" | "form";

export type A2ARole = "user" | "agent" | "system";

export type A2ASkill = {
  description: string;
  examples: string[];
  id: string;
  input_modes: string[];
  name: string;
  output_modes: string[];
  tags: string[];
};

export type A2ATaskStatus = "submitted" | "working" | "input_required" | "completed" | "failed" | "cancelled" | "rejected" | "auth_failed";

export type AgentConfig = {
  auto_improve_skills: boolean;
  budget_usd_per_day?: Record<string, unknown>;
  learning_enabled: boolean;
  max_concurrent_tasks: number;
  max_tokens: number;
  model: string;
  system_prompt: string;
  temperature: number;
};

export type AgentMemory = {
  episodic: EpisodicMemory[];
  long_term: MemoryEntry[];
  short_term: MemoryEntry[];
  skill_knowledge: Record<string, SkillKnowledge>;
};

export type AgentMetrics = {
  avg_task_duration_ms: number;
  skills_executed: number;
  tasks_completed: number;
  tasks_failed: number;
  total_cost_usd: number;
  uptime_percentage: number;
};

export type AgentRole = Record<string, unknown>;

export type AgentStatus = "idle" | "working" | "blocked" | "error" | "offline" | "learning";

export type CanvasEdge = {
  condition?: Record<string, unknown>;
  edge_type: EdgeType;
  id: string;
  source: string;
  source_port: string;
  target: string;
  target_port: string;
};

export type CanvasNode = {
  config: NodeConfig;
  id: string;
  inputs: Port[];
  metadata: NodeMetadata;
  node_type: NodeType;
  outputs: Port[];
  position: Position;
};

export type CanvasSettings = {
  auto_save: boolean;
  execution_mode: ExecutionMode;
  parallel_execution: boolean;
  retry_policy: RetryPolicy;
  timeout_ms: number;
};

export type CodeLanguage = "typescript" | "python" | "rust" | "javascript";

export type DataType = "string" | "number" | "boolean" | "object" | "array" | "any" | "agent" | "skill" | "m_c_p_tool" | "canvas" | "file" | "image" | "audio";

export type Dependency = {
  name: string;
  source: DependencySource;
  version: string;
};

export type DependencySource = "n_p_m" | "py_p_i" | "cargo" | "local" | "git";

export type EdgeType = "data" | "control" | "conditional" | "error";

export type EpisodicMemory = {
  canvas_id?: Record<string, unknown>;
  created_at: number;
  id: string;
  lessons_learned: string[];
  outcome: TaskOutcome;
  summary: string;
  task_id: string;
};

export type ExecutionMode = "sequential" | "parallel" | "d_a_g";

export type ExecutionResult = {
  cost_usd: number;
  error?: Record<string, unknown>;
  node_results: Record<string, NodeExecutionState>;
  outputs: Record<string, never>;
  success: boolean;
  total_duration_ms: number;
};

export type ExecutionStatus = "pending" | "running" | "paused" | "completed" | "failed" | "cancelled" | "waiting_for_human";

export type ExecutionTrigger = {
  payload: Record<string, unknown>;
  trigger_type: TriggerType;
  triggered_by: string;
};

export type ImplementationKind = "function" | "class" | "canvas" | "m_c_p_wrapper" | "a2_a_delegate";

export type ImprovementTrigger = "test_failure" | "performance_regression" | "user_feedback" | "new_requirement" | "a_i_optimization";

export type LoopConfig = {
  collection_expr?: Record<string, unknown>;
  condition_expr?: Record<string, unknown>;
  loop_type: LoopType;
  max_iterations: number;
};

export type LoopType = "for_each" | "while" | "times";

export type MCPAuth = {
  auth_type: MCPAuthType;
  config: Record<string, unknown>;
};

export type MCPAuthType = Record<string, unknown>;

export type MCPCapabilities = {
  completions: boolean;
  logging: boolean;
  prompts: boolean;
  resources: boolean;
  tools: boolean;
};

export type MCPServerStatus = "disconnected" | "connecting" | "connected" | "error" | "unauthorized";

export type MCPTool = {
  annotations?: MCPToolAnnotations | null;
  description: string;
  input_schema: Record<string, unknown>;
  name: string;
  output_schema?: Record<string, unknown>;
};

export type MCPToolAnnotations = {
  destructive?: Record<string, unknown>;
  idempotent?: Record<string, unknown>;
  open_world?: Record<string, unknown>;
  read_only?: Record<string, unknown>;
  title?: Record<string, unknown>;
};

export type MCPTransport = "stdio" | "s_s_e" | "streamable_h_t_t_p" | "web_socket";

export type MemoryEntry = {
  access_count: number;
  accessed_at: number;
  content: string;
  created_at: number;
  embedding?: Record<string, unknown>;
  id: string;
  importance: number;
};

export type NodeCategory = "trigger" | "action" | "logic" | "data" | "a_i" | "m_c_p" | "agent" | "human" | "output";

export type NodeConfig = {
  code?: Record<string, unknown>;
  condition?: Record<string, unknown>;
  continue_on_error: boolean;
  imports: string[];
  language?: CodeLanguage | null;
  loop_config?: LoopConfig | null;
  max_tokens?: Record<string, unknown>;
  mcp_args_schema?: Record<string, unknown>;
  mcp_server_id?: Record<string, unknown>;
  mcp_tool_name?: Record<string, unknown>;
  model?: Record<string, unknown>;
  prompt_template?: Record<string, unknown>;
  response_schema?: Record<string, unknown>;
  retries?: Record<string, unknown>;
  skill_id?: Record<string, unknown>;
  skill_version?: Record<string, unknown>;
  sub_canvas_id?: Record<string, unknown>;
  temperature?: Record<string, unknown>;
  timeout_ms?: Record<string, unknown>;
  trigger_config?: TriggerConfig | null;
};

export type NodeExecutionState = {
  completed_at?: Record<string, unknown>;
  error?: Record<string, unknown>;
  inputs: Record<string, never>;
  node_id: string;
  outputs: Record<string, never>;
  retry_count: number;
  started_at?: Record<string, unknown>;
  status: NodeExecutionStatus;
};

export type NodeExecutionStatus = "pending" | "running" | "completed" | "failed" | "skipped" | "waiting_for_input";

export type NodeMetadata = {
  ai_generation_prompt?: Record<string, unknown>;
  category: NodeCategory;
  color: string;
  description: string;
  icon: string;
  is_ai_generated: boolean;
  label: string;
  last_test_result?: TestResult | null;
  test_cases: TestCase[];
};

export type NodeType = "code" | "l_l_m_call" | "m_c_p_call" | "a2_a_message" | "skill_invoke" | "sub_canvas" | "human_input" | "conditional" | "loop" | "parallel" | "trigger" | "output" | "transform" | "aggregate";

export type OptimizationGoal = "minimize_cost" | "minimize_latency" | "maximize_success_rate" | "maximize_accuracy" | "balanced";

export type Port = {
  data_type: DataType;
  default_value?: Record<string, unknown>;
  id: string;
  name: string;
  required: boolean;
};

export type Position = {
  x: number;
  y: number;
};

export type RetryPolicy = {
  backoff_ms: number;
  max_retries: number;
  retry_on: string[];
};

export type SkillCategory = "automation" | "data_processing" | "communication" | "analysis" | "generation" | "integration" | "custom";

export type SkillImplementation = {
  code: string;
  dependencies: Dependency[];
  entry_point: string;
  kind: ImplementationKind;
  language: CodeLanguage;
  schema: SkillSchema;
};

export type SkillImprovement = {
  after_metrics: SkillMetrics;
  before_metrics: SkillMetrics;
  description: string;
  improved_at: number;
  trigger: ImprovementTrigger;
  version: string;
};

export type SkillKnowledge = {
  failure_patterns: string[];
  last_used: number;
  optimal_params: Record<string, never>;
  proficiency: number;
  skill_id: string;
  successful_patterns: string[];
};

export type SkillMetadata = {
  avg_duration_ms: number;
  improvement_history: SkillImprovement[];
  is_auto_generated: boolean;
  last_improved_at?: Record<string, unknown>;
  parent_skill_id?: Record<string, unknown>;
  success_rate: number;
  tags: string[];
  usage_count: number;
};

export type SkillMetrics = {
  avg_duration_ms: number;
  cost_per_execution: number;
  error_rate: number;
  success_rate: number;
};

export type SkillPermissions = {
  allowed_domains: string[];
  allowed_files: string[];
  allowed_mcp_servers: string[];
  filesystem_access: boolean;
  max_execution_time_ms: number;
  max_memory_mb: number;
  network_access: boolean;
};

export type SkillSchema = {
  input: Record<string, unknown>;
  output: Record<string, unknown>;
};

export type SkillTrigger = {
  conditions: string[];
  pattern?: Record<string, unknown>;
  trigger_type: TriggerType;
};

export type TaskOutcome = "success" | "partial_success" | "failure" | "cancelled";

export type TestCase = {
  created_by: string;
  expected_outputs: Record<string, never>;
  id: string;
  inputs: Record<string, never>;
  name: string;
};

export type TestResult = {
  duration_ms: number;
  error?: Record<string, unknown>;
  outputs: Record<string, never>;
  passed: boolean;
  tested_at: number;
};

export type TriggerConfig = {
  cron_expression?: Record<string, unknown>;
  event_filters: string[];
  trigger_type: TriggerType;
  webhook_path?: Record<string, unknown>;
};

export type TriggerType = "manual" | "cron" | "webhook" | "event" | "m_c_p_notification";

export type Viewport = {
  x: number;
  y: number;
  zoom: number;
};

export type A2AAgentCard = {
  auth?: A2AAuth | null;
  capabilities: A2ACapabilities;
  description: string;
  name: string;
  skills: A2ASkill[];
  url: string;
  version: string;
};

export type A2AMessageRequest = {
  message: A2AMessage;
  target_agent_url: string;
};

export type A2ATask = {
  artifacts: A2AArtifact[];
  history: A2AMessage[];
  id: string;
  message: A2AMessage;
  status: A2ATaskStatus;
};

export type AIGenerateCanvasRequest = {
  created_by: string;
  description: string;
  name: string;
  prompt: string;
};

export type AIGenerateNodeRequest = {
  description: string;
  label: string;
  node_type: NodeType;
  position: Position;
  prompt: string;
};

export type AIGenerateSkillRequest = {
  category: SkillCategory;
  created_by: string;
  description: string;
  name: string;
  prompt: string;
};

export type AIOptimizeCanvasRequest = {
  canvas_id: string;
  generations: number;
  optimization_goal: OptimizationGoal;
};

export type AITestGenerationRequest = {
  node_config: NodeConfig;
  node_id: string;
  num_cases: number;
};

export type Agent = {
  avatar?: Record<string, unknown>;
  config: AgentConfig;
  created_at: number;
  created_by: string;
  description: string;
  id: string;
  mcp_servers: string[];
  memory: AgentMemory;
  metrics: AgentMetrics;
  name: string;
  role: AgentRole;
  skills: string[];
  status: AgentStatus;
  updated_at: number;
};

export type AssignMCPRequest = {
  mcp_server_id: string;
};

export type AssignSkillRequest = {
  skill_id: string;
};

export type CallMCPToolRequest = {
  arguments: Record<string, unknown>;
  tool_name: string;
};

export type Canvas = {
  created_at: number;
  created_by: string;
  description: string;
  edges: CanvasEdge[];
  id: string;
  name: string;
  nodes: CanvasNode[];
  settings: CanvasSettings;
  updated_at: number;
  version: number;
  viewport: Viewport;
};

export type ChatRequest = {
  context?: Record<string, never>;
  message: string;
};

export type ChatResponse = {
  cost_usd: number;
  message: string;
  used_skills: string[];
};

export type CreateAgentRequest = {
  created_by: string;
  description: string;
  name: string;
  role: AgentRole;
};

export type CreateCanvasRequest = {
  created_by: string;
  description: string;
  name: string;
};

export type CreateMCPServerRequest = {
  description: string;
  name: string;
  transport: MCPTransport;
};

export type CreateProviderRequest = {
  api_key: string;
  base_url: string;
  name: string;
  provider_type: string;
  validate?: Record<string, unknown>;
};

export type CreateSkillRequest = {
  category: SkillCategory;
  created_by: string;
  description: string;
  name: string;
};

export type ExecuteCanvasRequest = {
  canvas_id: string;
  trigger: ExecutionTrigger;
};

export type ExecutionContext = {
  canvas_id: string;
  completed_at?: Record<string, unknown>;
  execution_id: string;
  node_states: Record<string, NodeExecutionState>;
  result?: ExecutionResult | null;
  started_at: number;
  status: ExecutionStatus;
  trigger: ExecutionTrigger;
  variables: Record<string, never>;
};

export type MCPServer = {
  auth?: MCPAuth | null;
  capabilities: MCPCapabilities;
  created_at: number;
  description: string;
  id: string;
  name: string;
  status: MCPServerStatus;
  tools: MCPTool[];
  transport: MCPTransport;
  updated_at: number;
};

export type Provider = {
  base_url?: Record<string, unknown>;
  created_at: number;
  enabled: boolean;
  id: string;
  key_ref?: Record<string, unknown>;
  model_tier?: Record<string, unknown>;
  name: string;
  project_id: string;
  provider_type: string;
  updated_at: number;
};

export type ProviderTestResponse = {
  connected: boolean;
  error?: Record<string, unknown>;
};

export type Skill = {
  category: SkillCategory;
  created_at: number;
  created_by: string;
  description: string;
  id: string;
  implementation: SkillImplementation;
  is_auto_generated: boolean;
  metadata: SkillMetadata;
  name: string;
  permissions: SkillPermissions;
  triggers: SkillTrigger[];
  updated_at: number;
  version: string;
};

export type SkillImprovementRequest = {
  description: string;
  implementation?: SkillImplementation | null;
  improved_by: string;
  is_auto_generated: boolean;
  trigger: ImprovementTrigger;
};

export type StreamEvent = {
  actor_id?: Record<string, unknown>;
  actor_type?: Record<string, unknown>;
  cost_usd?: Record<string, unknown>;
  created_at: number;
  event_type: string;
  id: number;
  lines_added?: Record<string, unknown>;
  lines_deleted?: Record<string, unknown>;
  model_used?: Record<string, unknown>;
  payload?: Record<string, unknown>;
  session_id: string;
  summary: string;
  tokens_used?: Record<string, unknown>;
};

export type TestNodeInputs = Record<string, never>;

export type TestNodeRequest = {
  inputs: Record<string, never>;
  node: CanvasNode;
};

export type UpdateCanvasRequest = {
  description?: Record<string, unknown>;
  edges?: Record<string, unknown>;
  name?: Record<string, unknown>;
  nodes?: Record<string, unknown>;
  settings?: CanvasSettings | null;
  viewport?: Viewport | null;
};

export type ValidationResult = {
  errors: string[];
  valid: boolean;
  warnings: string[];
};

export type VersionInfo = {
  app: string;
  version: string;
};

export type ViewPort = {
  x: number;
  y: number;
  zoom: number;
};

