/**
 * Tipos canónicos del API del gateway — derivados de los structs Rust.
 * FUENTE: src/types/api-generated.ts (auto-generado, NO editar).
 * Regenerar: cargo run -p canvas-ai-server --bin export-openapi
 * (slice 0.6 — packages/shared-types queda deprecado por este archivo)
 */

import type {
  Agent,
  Canvas,
  ExecutionContext,
  Provider,
  Skill,
  StreamEvent,
  MCPServer,
} from './api-generated';

export type {
  Agent,
  A2AAgentCard,
  A2ATask,
  Canvas,
  CanvasNode,
  CanvasEdge,
  CreateCanvasRequest,
  CreateProviderRequest,
  CreateSkillRequest,
  CreateAgentRequest,
  CreateMCPServerRequest,
  ExecutionContext,
  ExecutionStatus,
  MCPServer,
  MCPTool,
  Provider,
  ProviderTestResponse,
  Skill,
  StreamEvent,
  TestCase,
  TestResult,
} from './api-generated';

/** Los tipos generados son la fuente; estos aliases son atajos de lectura. */
export type ApiCanvas = Canvas;
export type ApiSkill = Skill;
export type ApiAgent = Agent;
export type ApiExecution = ExecutionContext;
export type ApiProvider = Provider;
export type ApiMcpServer = MCPServer;
export type ApiEvent = StreamEvent;

/** Verificación compile-time: el contrato generado expone las entidades core. */
export type _ContractCheck = [
  Canvas,
  Skill,
  Agent,
  ExecutionContext,
  Provider,
  StreamEvent,
];
