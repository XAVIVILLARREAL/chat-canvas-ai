import type React from 'react';
import {
  Code, Brain, Plug, MessageSquare, Zap, Layers, User,
  GitBranch, Repeat, GitFork, Play, Square, ArrowRightLeft, Calculator,
} from 'lucide-react';

// Tipos del frontend - sincronizados con el core Rust via specta/tauri

export type NodeType = 
  | 'code' 
  | 'llmCall' 
  | 'mcpCall' 
  | 'a2aMessage' 
  | 'skillInvoke' 
  | 'subCanvas' 
  | 'humanInput' 
  | 'conditional' 
  | 'loop' 
  | 'parallel' 
  | 'trigger' 
  | 'output' 
  | 'transform' 
  | 'aggregate';

export type ExecutionMode = 'sequential' | 'parallel' | 'dag';
export type LoopType = 'forEach' | 'while' | 'times';
export type TriggerType = 'manual' | 'cron' | 'webhook' | 'event' | 'mcpNotification';
export type EdgeType = 'data' | 'control' | 'conditional' | 'error';
export type DataType = 'string' | 'number' | 'boolean' | 'object' | 'array' | 'any' | 'agent' | 'skill' | 'mcpTool' | 'canvas' | 'file' | 'image' | 'audio';
export type NodeCategory = 'trigger' | 'action' | 'logic' | 'data' | 'ai' | 'mcp' | 'agent' | 'human' | 'output';
export type CodeLanguage = 'typescript' | 'python' | 'rust' | 'javascript';
export type SkillCategory = 'automation' | 'dataProcessing' | 'communication' | 'analysis' | 'generation' | 'integration' | 'custom';
export type ImplementationKind = 'function' | 'class' | 'canvas' | 'mcpWrapper' | 'a2aDelegate';
export type DependencySource = 'npm' | 'pypi' | 'cargo' | 'local' | 'git';
export type ImprovementTrigger = 'testFailure' | 'performanceRegression' | 'userFeedback' | 'newRequirement' | 'aiOptimization';
export type AgentRole = 'coordinator' | 'specialist' | 'reviewer' | 'planner' | 'executor' | { custom: string };
export type AgentStatus = 'idle' | 'working' | 'blocked' | 'error' | 'offline' | 'learning';
export type MCPTransport = 'stdio' | 'sse' | 'streamableHttp' | 'websocket';
export type MCPAuthType = 'none' | 'bearerToken' | 'apiKey' | 'oauth2' | { custom: string };
export type MCPServerStatus = 'disconnected' | 'connecting' | 'connected' | 'error' | 'unauthorized';
export type ExecutionStatus = 'pending' | 'running' | 'paused' | 'completed' | 'failed' | 'cancelled' | 'waitingForHuman';
export type NodeExecutionStatus = 'pending' | 'running' | 'completed' | 'failed' | 'skipped' | 'waitingForInput';
export type A2ARole = 'user' | 'agent' | 'system';
export type A2APartType = 'text' | 'file' | 'data' | 'form';
export type A2ATaskStatus = 'submitted' | 'working' | 'inputRequired' | 'completed' | 'failed' | 'cancelled' | 'rejected' | 'authFailed';
export type TaskStatus = 'pending' | 'in_progress' | 'completed' | 'failed' | 'cancelled';

export interface Task {
  id: string;
  name: string;
  description: string;
  status: TaskStatus;
  assignedAgentId: string | null;
  createdAt: number;
  updatedAt: number;
}

export interface Position { x: number; y: number; }
export interface Viewport { x: number; y: number; zoom: number; }

export interface RetryPolicy {
  maxRetries: number;
  backoffMs: number;
  retryOn: string[];
}

export interface CanvasSettings {
  autoSave: boolean;
  executionMode: ExecutionMode;
  timeoutMs: number;
  retryPolicy: RetryPolicy;
  parallelExecution: boolean;
}

export interface Port {
  id: string;
  name: string;
  dataType: DataType;
  required: boolean;
  defaultValue?: any;
}

export interface LoopConfig {
  loopType: LoopType;
  collectionExpr?: string;
  conditionExpr?: string;
  maxIterations: number;
}

export interface TriggerConfig {
  triggerType: TriggerType;
  cronExpression?: string;
  webhookPath?: string;
  eventFilters: string[];
}

export interface NodeConfig {
  code?: string;
  language?: CodeLanguage;
  imports: string[];
  promptTemplate?: string;
  model?: string;
  temperature?: number;
  maxTokens?: number;
  responseSchema?: any;
  mcpServerId?: string;
  mcpToolName?: string;
  mcpArgsSchema?: any;
  skillId?: string;
  skillVersion?: string;
  subCanvasId?: string;
  condition?: string;
  loopConfig?: LoopConfig;
  triggerConfig?: TriggerConfig;
  timeoutMs?: number;
  retries?: number;
  continueOnError: boolean;
}

export interface TestCase {
  id: string;
  name: string;
  inputs: Record<string, any>;
  expectedOutputs: Record<string, any>;
  createdBy: 'ai' | 'human';
}

export interface TestResult {
  passed: boolean;
  outputs: Record<string, any>;
  error?: string;
  durationMs: number;
  testedAt: number;
}

export interface NodeMetadata {
  label: string;
  description: string;
  color: string;
  icon: string;
  category: NodeCategory;
  isAiGenerated: boolean;
  aiGenerationPrompt?: string;
  testCases: TestCase[];
  lastTestResult?: TestResult;
}

export interface CanvasNode {
  id: string;
  nodeType: NodeType;
  position: Position;
  config: NodeConfig;
  inputs: Port[];
  outputs: Port[];
  metadata: NodeMetadata;
}

export interface CanvasEdge {
  id: string;
  source: string;
  sourcePort: string;
  target: string;
  targetPort: string;
  edgeType: EdgeType;
  condition?: string;
}

export interface Canvas {
  id: string;
  name: string;
  description: string;
  version: number;
  nodes: CanvasNode[];
  edges: CanvasEdge[];
  viewport: Viewport;
  settings: CanvasSettings;
  createdAt: number;
  updatedAt: number;
  createdBy: string;
}

export interface SkillSchema {
  input: any;
  output: any;
}

export interface Dependency {
  name: string;
  version: string;
  source: DependencySource;
}

export interface SkillImplementation {
  kind: ImplementationKind;
  code: string;
  language: CodeLanguage;
  dependencies: Dependency[];
  entryPoint: string;
  schema: SkillSchema;
}

export interface SkillPermissions {
  allowedMcpServers: string[];
  allowedDomains: string[];
  allowedFiles: string[];
  maxExecutionTimeMs: number;
  maxMemoryMb: number;
  networkAccess: boolean;
  filesystemAccess: boolean;
}

export interface SkillMetrics {
  successRate: number;
  avgDurationMs: number;
  errorRate: number;
  costPerExecution: number;
}

export interface SkillImprovement {
  version: string;
  description: string;
  trigger: ImprovementTrigger;
  beforeMetrics: SkillMetrics;
  afterMetrics: SkillMetrics;
  improvedAt: number;
}

export interface SkillMetadata {
  tags: string[];
  usageCount: number;
  successRate: number;
  avgDurationMs: number;
  lastImprovedAt?: number;
  improvementHistory: SkillImprovement[];
  isAutoGenerated: boolean;
  parentSkillId?: string;
}

export interface Skill {
  id: string;
  name: string;
  description: string;
  version: string;
  category: SkillCategory;
  triggers: SkillTrigger[];
  implementation: SkillImplementation;
  permissions: SkillPermissions;
  metadata: SkillMetadata;
  createdAt: number;
  updatedAt: number;
  createdBy: string;
  isAutoGenerated: boolean;
}

export interface SkillTrigger {
  triggerType: TriggerType;
  pattern?: string;
  conditions: string[];
}

export interface AgentConfig {
  model: string;
  temperature: number;
  maxTokens: number;
  systemPrompt: string;
  maxConcurrentTasks: number;
  autoImproveSkills: boolean;
  learningEnabled: boolean;
  budgetUsdPerDay?: number;
}

export interface MemoryEntry {
  id: string;
  content: string;
  embedding?: number[];
  importance: number;
  createdAt: number;
  accessedAt: number;
  accessCount: number;
}

export interface EpisodicMemory {
  id: string;
  taskId: string;
  canvasId?: string;
  summary: string;
  outcome: 'success' | 'partialSuccess' | 'failure' | 'cancelled';
  lessonsLearned: string[];
  createdAt: number;
}

export interface SkillKnowledge {
  skillId: string;
  proficiency: number;
  successfulPatterns: string[];
  failurePatterns: string[];
  optimalParams: Record<string, any>;
  lastUsed: number;
}

export interface AgentMemory {
  shortTerm: MemoryEntry[];
  longTerm: MemoryEntry[];
  episodic: EpisodicMemory[];
  skillKnowledge: Record<string, SkillKnowledge>;
}

export interface AgentMetrics {
  tasksCompleted: number;
  tasksFailed: number;
  skillsExecuted: number;
  totalCostUsd: number;
  avgTaskDurationMs: number;
  uptimePercentage: number;
}

export interface Agent {
  id: string;
  name: string;
  description: string;
  avatar?: string;
  role: AgentRole;
  status: AgentStatus;
  skills: string[];
  mcpServers: string[];
  config: AgentConfig;
  memory: AgentMemory;
  metrics: AgentMetrics;
  createdAt: number;
  updatedAt: number;
  createdBy: string;
}

export interface MCPCapabilities {
  tools: boolean;
  resources: boolean;
  prompts: boolean;
  logging: boolean;
  completions: boolean;
}

export interface MCPAuth {
  authType: MCPAuthType;
  config: any;
}

export interface MCPToolAnnotations {
  title?: string;
  readOnly?: boolean;
  destructive?: boolean;
  idempotent?: boolean;
  openWorld?: boolean;
}

export interface MCPTool {
  name: string;
  description: string;
  inputSchema: any;
  outputSchema?: any;
  annotations?: MCPToolAnnotations;
}

export interface MCPServer {
  id: string;
  name: string;
  description: string;
  transport: MCPTransport;
  capabilities: MCPCapabilities;
  auth?: MCPAuth;
  status: MCPServerStatus;
  tools: MCPTool[];
  createdAt: number;
  updatedAt: number;
}

export interface ExecutionTrigger {
  triggerType: TriggerType;
  payload: any;
  triggeredBy: string;
}

export interface NodeExecutionState {
  nodeId: string;
  status: NodeExecutionStatus;
  inputs: Record<string, any>;
  outputs: Record<string, any>;
  error?: string;
  startedAt?: number;
  completedAt?: number;
  retryCount: number;
}

export interface ExecutionResult {
  success: boolean;
  outputs: Record<string, any>;
  error?: string;
  nodeResults: Record<string, NodeExecutionState>;
  totalDurationMs: number;
  costUsd: number;
}

export interface ExecutionContext {
  executionId: string;
  canvasId: string;
  trigger: ExecutionTrigger;
  variables: Record<string, any>;
  nodeStates: Record<string, NodeExecutionState>;
  startedAt: number;
  completedAt?: number;
  status: ExecutionStatus;
  result?: ExecutionResult;
  totalDurationMs?: number;
}

export interface A2ACapabilities {
  streaming: boolean;
  pushNotifications: boolean;
  stateTransitionHistory: boolean;
}

export interface A2ASkill {
  id: string;
  name: string;
  description: string;
  tags: string[];
  examples: string[];
  inputModes: string[];
  outputModes: string[];
}

export interface A2AAuth {
  schemes: string[];
  credentials: any;
}

export interface A2AAgentCard {
  name: string;
  description: string;
  version: string;
  url: string;
  capabilities: A2ACapabilities;
  skills: A2ASkill[];
  auth?: A2AAuth;
}

export interface A2APart {
  partType: A2APartType;
  content: string;
  metadata?: any;
}

export interface A2AMessage {
  id: string;
  role: A2ARole;
  parts: A2APart[];
  metadata?: any;
}

export interface A2AArtifact {
  id: string;
  name: string;
  description: string;
  parts: A2APart[];
  metadata?: any;
}

export interface A2ATask {
  id: string;
  status: A2ATaskStatus;
  message: A2AMessage;
  artifacts: A2AArtifact[];
  history: A2AMessage[];
}

export interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}

export interface ChatRequest {
  message: string;
  context?: Record<string, any>;
}

export interface ChatResponse {
  message: string;
  usedSkills: string[];
  costUsd: number;
}

// ============================================
// NODOS PREDEFINIDOS PARA EL CANVAS
// ============================================

export const NODE_TYPE_CONFIG: Record<NodeType, { 
  label: string; 
  description: string; 
  color: string; 
  icon: React.ComponentType<{ width?: number; height?: number; style?: React.CSSProperties; className?: string }>;
  category: NodeCategory;
  defaultInputs: Port[];
  defaultOutputs: Port[];
  defaultConfig: Partial<NodeConfig>;
}> = {
  code: {
    label: 'Código',
    description: 'Ejecuta código TypeScript/Python/Rust arbitrario',
    color: '#6366f1',
    icon: Code,
    category: 'action',
    defaultInputs: [{ id: 'input', name: 'input', dataType: 'any', required: false, defaultValue: {} }],
    defaultOutputs: [{ id: 'output', name: 'output', dataType: 'any', required: false }],
    defaultConfig: { language: 'typescript', timeoutMs: 30000, retries: 0, continueOnError: false },
  },
  llmCall: {
    label: 'LLM Call',
    description: 'Llamada a LLM con prompt estructurado',
    color: '#8b5cf6',
    icon: Brain,
    category: 'ai',
    defaultInputs: [
      { id: 'prompt', name: 'prompt', dataType: 'string', required: true },
      { id: 'context', name: 'context', dataType: 'object', required: false },
    ],
    defaultOutputs: [
      { id: 'response', name: 'response', dataType: 'any', required: false },
      { id: 'tokens', name: 'tokens', dataType: 'number', required: false },
    ],
    defaultConfig: { model: 'gpt-4o', temperature: 0.7, maxTokens: 4096, timeoutMs: 60000, retries: 2, continueOnError: false },
  },
  mcpCall: {
    label: 'MCP Call',
    description: 'Llamada a herramienta MCP',
    color: '#06b6d4',
    icon: Plug,
    category: 'mcp',
    defaultInputs: [{ id: 'args', name: 'arguments', dataType: 'object', required: true }],
    defaultOutputs: [{ id: 'result', name: 'result', dataType: 'any', required: false }],
    defaultConfig: { timeoutMs: 30000, retries: 1, continueOnError: false },
  },
  a2aMessage: {
    label: 'A2A Message',
    description: 'Envía mensaje a otro agente (protocolo A2A)',
    color: '#ec4899',
    icon: MessageSquare,
    category: 'agent',
    defaultInputs: [
      { id: 'targetAgentUrl', name: 'targetAgentUrl', dataType: 'string', required: true },
      { id: 'message', name: 'message', dataType: 'object', required: true },
    ],
    defaultOutputs: [{ id: 'response', name: 'response', dataType: 'object', required: false }],
    defaultConfig: { timeoutMs: 60000, retries: 1, continueOnError: false },
  },
  skillInvoke: {
    label: 'Skill Invoke',
    description: 'Invoca una Skill registrada',
    color: '#10b981',
    icon: Zap,
    category: 'action',
    defaultInputs: [{ id: 'input', name: 'input', dataType: 'object', required: true }],
    defaultOutputs: [{ id: 'output', name: 'output', dataType: 'any', required: false }],
    defaultConfig: { timeoutMs: 60000, retries: 1, continueOnError: false },
  },
  subCanvas: {
    label: 'Sub-Canvas',
    description: 'Canvas anidado (composición)',
    color: '#f59e0b',
    icon: Layers,
    category: 'logic',
    defaultInputs: [{ id: 'input', name: 'input', dataType: 'object', required: true }],
    defaultOutputs: [{ id: 'output', name: 'output', dataType: 'any', required: false }],
    defaultConfig: { timeoutMs: 120000, retries: 0, continueOnError: false },
  },
  humanInput: {
    label: 'Human Input',
    description: 'Pide input al humano (HITL)',
    color: '#f97316',
    icon: User,
    category: 'human',
    defaultInputs: [],
    defaultOutputs: [{ id: 'response', name: 'response', dataType: 'any', required: true }],
    defaultConfig: { timeoutMs: 3600000, retries: 0, continueOnError: false },
  },
  conditional: {
    label: 'Condicional',
    description: 'Rama condicional',
    color: '#84cc16',
    icon: GitBranch,
    category: 'logic',
    defaultInputs: [{ id: 'condition', name: 'condition', dataType: 'boolean', required: true }],
    defaultOutputs: [
      { id: 'true', name: 'true', dataType: 'any', required: false },
      { id: 'false', name: 'false', dataType: 'any', required: false },
    ],
    defaultConfig: { timeoutMs: 5000, retries: 0, continueOnError: false },
  },
  loop: {
    label: 'Bucle',
    description: 'Bucle for/while',
    color: '#6366f1',
    icon: Repeat,
    category: 'logic',
    defaultInputs: [{ id: 'collection', name: 'collection', dataType: 'array', required: true }],
    defaultOutputs: [{ id: 'item', name: 'item', dataType: 'any', required: false }],
    defaultConfig: { 
      loopConfig: { loopType: 'forEach', maxIterations: 100 },
      timeoutMs: 120000, 
      retries: 0, 
      continueOnError: false 
    },
  },
  parallel: {
    label: 'Paralelo',
    description: 'Ejecución en paralelo de sub-nodos',
    color: '#0ea5e9',
    icon: GitFork,
    category: 'logic',
    defaultInputs: [{ id: 'input', name: 'input', dataType: 'object', required: true }],
    defaultOutputs: [{ id: 'results', name: 'results', dataType: 'array', required: false }],
    defaultConfig: { timeoutMs: 120000, retries: 0, continueOnError: false },
  },
  trigger: {
    label: 'Trigger',
    description: 'Inicio del flujo (webhook, cron, manual)',
    color: '#22c55e',
    icon: Play,
    category: 'trigger',
    defaultInputs: [],
    defaultOutputs: [{ id: 'payload', name: 'payload', dataType: 'any', required: false }],
    defaultConfig: { 
      triggerConfig: { triggerType: 'manual', eventFilters: [] },
      timeoutMs: 5000, 
      retries: 0, 
      continueOnError: false 
    },
  },
  output: {
    label: 'Output',
    description: 'Resultado final',
    color: '#64748b',
    icon: Square,
    category: 'output',
    defaultInputs: [{ id: 'result', name: 'result', dataType: 'any', required: true }],
    defaultOutputs: [],
    defaultConfig: { timeoutMs: 5000, retries: 0, continueOnError: false },
  },
  transform: {
    label: 'Transform',
    description: 'Transformación de datos (map, filter, reduce)',
    color: '#a855f7',
    icon: ArrowRightLeft,
    category: 'data',
    defaultInputs: [{ id: 'input', name: 'input', dataType: 'array', required: true }],
    defaultOutputs: [{ id: 'output', name: 'output', dataType: 'array', required: false }],
    defaultConfig: { timeoutMs: 10000, retries: 0, continueOnError: false },
  },
  aggregate: {
    label: 'Aggregate',
    description: 'Agregación de resultados',
    color: '#d946ef',
    icon: Calculator,
    category: 'data',
    defaultInputs: [{ id: 'items', name: 'items', dataType: 'array', required: true }],
    defaultOutputs: [{ id: 'result', name: 'result', dataType: 'object', required: false }],
    defaultConfig: { timeoutMs: 10000, retries: 0, continueOnError: false },
  },
};

export const EDGE_TYPE_COLORS: Record<EdgeType, string> = {
  data: '#6366f1',
  control: '#22c55e',
  conditional: '#f59e0b',
  error: '#ef4444',
};

export const AGENT_ROLE_COLORS: Record<string, string> = {
  coordinator: '#8b5cf6',
  specialist: '#10b981',
  reviewer: '#f59e0b',
  planner: '#06b6d4',
  executor: '#ef4444',
};

export const AGENT_STATUS_COLORS: Record<AgentStatus, string> = {
  idle: '#64748b',
  working: '#22c55e',
  blocked: '#f59e0b',
  error: '#ef4444',
  offline: '#374151',
  learning: '#8b5cf6',
};

// ============================================
// API REQUEST/RESPONSE TYPES
// ============================================

export interface CreateCanvasRequest {
  name: string;
  description: string;
  created_by: string;
}

export interface CreateSkillRequest {
  name: string;
  description: string;
  category: SkillCategory;
  created_by: string;
}

export interface CreateAgentRequest {
  name: string;
  description: string;
  role: AgentRole;
  created_by: string;
}

export interface CreateMCPServerRequest {
  name: string;
  description: string;
  transport: MCPTransport;
}

export interface ExecuteCanvasRequest {
  canvas_id: string;
  trigger: ExecutionTrigger;
}

export interface AIGenerateNodeRequest {
  prompt: string;
  node_type: NodeType;
  position: Position;
  label: string;
  description: string;
}

export interface AIGenerateCanvasRequest {
  name: string;
  description: string;
  prompt: string;
  created_by: string;
}

export interface AIGenerateSkillRequest {
  name: string;
  description: string;
  category: SkillCategory;
  prompt: string;
  created_by: string;
}

export interface AIOptimizeCanvasRequest {
  canvas_id: string;
  optimization_goal: 'minimize_cost' | 'minimize_latency' | 'maximize_success_rate' | 'maximize_accuracy' | 'balanced';
  generations: number;
}

export interface AITestGenerationRequest {
  node_id: string;
  node_config: NodeConfig;
  num_cases: number;
}

export interface SkillImprovementRequest {
  description: string;
  trigger: ImprovementTrigger;
  implementation?: SkillImplementation;
  is_auto_generated: boolean;
  improved_by: string;
}

export interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}

export interface ChatRequest {
  message: string;
  context?: Record<string, any>;
}

export interface ChatResponse {
  message: string;
  used_skills: string[];
  cost_usd: number;
}

export interface AssignSkillRequest {
  skill_id: string;
}

export interface AssignMCPRequest {
  mcp_server_id: string;
}

export interface SetTeamCanvasRequest {
  canvas_id: string;
}

export interface CallMCPToolRequest {
  tool_name: string;
  arguments: any;
}

export interface GetAgentCardQuery {
  agent_id: string;
}

export interface RemoveSkillQuery {
  skill_id: string;
}

export interface RemoveMCPQuery {
  mcp_server_id: string;
}

export interface RemoveMemberQuery {
  agent_id: string;
}

export interface A2AMessageRequest {
  target_agent_url: string;
  message: A2AMessage;
}