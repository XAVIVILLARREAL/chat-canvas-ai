import { useCallback, useState } from 'react';
import { useCanvasStore } from '../stores/canvas-store';
import type { 
  Canvas, Skill, Agent, MCPServer, ExecutionContext,
  CreateCanvasRequest, CreateSkillRequest, CreateAgentRequest,
  CreateMCPServerRequest, ExecuteCanvasRequest,
  AIGenerateNodeRequest, AIGenerateCanvasRequest, AIGenerateSkillRequest,
} from '../types';

const API_BASE = '/api';

interface ApiError extends Error {
  status?: number;
}

async function apiRequest<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const response = await fetch(`${API_BASE}${endpoint}`, {
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
    ...options,
  });

  if (!response.ok) {
    const error: ApiError = new Error(`API Error: ${response.status}`);
    error.status = response.status;
    throw error;
  }

  if (response.status === 204) {
    return undefined as T;
  }

  return response.json();
}

export const useApi = () => {
  const [loading, setLoading] = useState(false);

  const request = useCallback(async <T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> => {
    setLoading(true);
    try {
      return await apiRequest<T>(endpoint, options);
    } finally {
      setLoading(false);
    }
  }, []);

  // ============================================
  // CANVAS API
  // ============================================

  const fetchCanvases = useCallback(async (): Promise<Canvas[]> => {
    return request<Canvas[]>('/canvases');
  }, [request]);

  const createCanvas = useCallback(async (data: CreateCanvasRequest): Promise<Canvas> => {
    return request<Canvas>('/canvases', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }, [request]);

  const fetchCanvas = useCallback(async (id: string): Promise<Canvas> => {
    return request<Canvas>(`/canvases/${id}`);
  }, [request]);

  const updateCanvas = useCallback(async (id: string, data: Partial<Canvas>): Promise<Canvas> => {
    return request<Canvas>(`/canvases/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }, [request]);

  const deleteCanvas = useCallback(async (id: string): Promise<void> => {
    return request<void>(`/canvases/${id}`, { method: 'DELETE' });
  }, [request]);

  const executeCanvas = useCallback(async (id: string, trigger: ExecuteCanvasRequest['trigger']): Promise<ExecutionContext> => {
    return request<ExecutionContext>(`/canvases/${id}/execute`, {
      method: 'POST',
      body: JSON.stringify({ trigger }),
    });
  }, [request]);

  const testCanvas = useCallback(async (id: string, node: any, inputs: any): Promise<any> => {
    return request<any>(`/canvases/${id}/test`, {
      method: 'POST',
      body: JSON.stringify({ node, inputs }),
    });
  }, [request]);

  const validateCanvas = useCallback(async (id: string): Promise<any> => {
    return request<any>(`/canvases/${id}/validate`, { method: 'POST' });
  }, [request]);

  // ============================================
  // SKILLS API
  // ============================================

  const fetchSkills = useCallback(async (): Promise<Skill[]> => {
    return request<Skill[]>('/skills');
  }, [request]);

  const createSkill = useCallback(async (data: CreateSkillRequest): Promise<Skill> => {
    return request<Skill>('/skills', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }, [request]);

  const fetchSkill = useCallback(async (id: string): Promise<Skill> => {
    return request<Skill>(`/skills/${id}`);
  }, [request]);

  const updateSkill = useCallback(async (id: string, data: Partial<Skill>): Promise<Skill> => {
    return request<Skill>(`/skills/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }, [request]);

  const deleteSkill = useCallback(async (id: string): Promise<void> => {
    return request<void>(`/skills/${id}`, { method: 'DELETE' });
  }, [request]);

  const testSkill = useCallback(async (id: string, inputs: any): Promise<any> => {
    return request<any>(`/skills/${id}/test`, {
      method: 'POST',
      body: JSON.stringify(inputs),
    });
  }, [request]);

  const improveSkill = useCallback(async (id: string, data: any): Promise<Skill> => {
    return request<Skill>(`/skills/${id}/improve`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }, [request]);

  // ============================================
  // AGENTS API
  // ============================================

  const fetchAgents = useCallback(async (): Promise<Agent[]> => {
    return request<Agent[]>('/agents');
  }, [request]);

  const createAgent = useCallback(async (data: CreateAgentRequest): Promise<Agent> => {
    return request<Agent>('/agents', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }, [request]);

  const fetchAgent = useCallback(async (id: string): Promise<Agent> => {
    return request<Agent>(`/agents/${id}`);
  }, [request]);

  const updateAgent = useCallback(async (id: string, data: Partial<Agent>): Promise<Agent> => {
    return request<Agent>(`/agents/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }, [request]);

  const deleteAgent = useCallback(async (id: string): Promise<void> => {
    return request<void>(`/agents/${id}`, { method: 'DELETE' });
  }, [request]);

  const assignSkillToAgent = useCallback(async (agentId: string, skillId: string): Promise<Agent> => {
    return request<Agent>(`/agents/${agentId}/skills`, {
      method: 'POST',
      body: JSON.stringify({ skill_id: skillId }),
    });
  }, [request]);

  const removeSkillFromAgent = useCallback(async (agentId: string, skillId: string): Promise<Agent> => {
    return request<Agent>(`/agents/${agentId}/skills?skill_id=${skillId}`, {
      method: 'DELETE',
    });
  }, [request]);

  const chatWithAgent = useCallback(async (agentId: string, message: string, context?: any): Promise<any> => {
    return request<any>(`/agents/${agentId}/chat`, {
      method: 'POST',
      body: JSON.stringify({ message, context }),
    });
  }, [request]);

  // ============================================
  // MCP SERVERS API
  // ============================================

  const fetchMcpServers = useCallback(async (): Promise<MCPServer[]> => {
    return request<MCPServer[]>('/mcp/servers');
  }, [request]);

  const createMcpServer = useCallback(async (data: CreateMCPServerRequest): Promise<MCPServer> => {
    return request<MCPServer>('/mcp/servers', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }, [request]);

  const fetchMcpServer = useCallback(async (id: string): Promise<MCPServer> => {
    return request<MCPServer>(`/mcp/servers/${id}`);
  }, [request]);

  const updateMcpServer = useCallback(async (id: string, data: Partial<MCPServer>): Promise<MCPServer> => {
    return request<MCPServer>(`/mcp/servers/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }, [request]);

  const deleteMcpServer = useCallback(async (id: string): Promise<void> => {
    return request<void>(`/mcp/servers/${id}`, { method: 'DELETE' });
  }, [request]);

  const connectMcpServer = useCallback(async (id: string): Promise<MCPServer> => {
    return request<MCPServer>(`/mcp/servers/${id}/connect`, { method: 'POST' });
  }, [request]);

  const disconnectMcpServer = useCallback(async (id: string): Promise<MCPServer> => {
    return request<MCPServer>(`/mcp/servers/${id}/disconnect`, { method: 'POST' });
  }, [request]);

  const listMcpTools = useCallback(async (id: string): Promise<any[]> => {
    return request<any[]>(`/mcp/servers/${id}/tools`);
  }, [request]);

  const callMcpTool = useCallback(async (id: string, toolName: string, args: any): Promise<any> => {
    return request<any>(`/mcp/servers/${id}/call`, {
      method: 'POST',
      body: JSON.stringify({ tool_name: toolName, arguments: args }),
    });
  }, [request]);

  // ============================================
  // EXECUTIONS API
  // ============================================

  const fetchExecutions = useCallback(async (): Promise<ExecutionContext[]> => {
    return request<ExecutionContext[]>('/executions');
  }, [request]);

  const fetchExecution = useCallback(async (id: string): Promise<ExecutionContext> => {
    return request<ExecutionContext>(`/executions/${id}`);
  }, [request]);

  const cancelExecution = useCallback(async (id: string): Promise<ExecutionContext> => {
    return request<ExecutionContext>(`/executions/${id}/cancel`, { method: 'POST' });
  }, [request]);

  const retryExecution = useCallback(async (id: string): Promise<ExecutionContext> => {
    return request<ExecutionContext>(`/executions/${id}/retry`, { method: 'POST' });
  }, [request]);

  // ============================================
  // AI GENERATION API
  // ============================================

  const aiGenerateNode = useCallback(async (data: AIGenerateNodeRequest): Promise<any> => {
    return request<any>('/ai/generate-node', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }, [request]);

  const aiGenerateCanvas = useCallback(async (data: AIGenerateCanvasRequest): Promise<Canvas> => {
    return request<Canvas>('/ai/generate-canvas', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }, [request]);

  const aiGenerateSkill = useCallback(async (data: AIGenerateSkillRequest): Promise<Skill> => {
    return request<Skill>('/ai/generate-skill', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }, [request]);

  const aiOptimizeCanvas = useCallback(async (canvasId: string, goal: string, generations: number): Promise<Canvas> => {
    return request<Canvas>('/ai/optimize-canvas', {
      method: 'POST',
      body: JSON.stringify({ canvas_id: canvasId, optimization_goal: goal, generations }),
    });
  }, [request]);

  // ============================================
  // SYNC WITH STORE
  // ============================================

  const syncCanvases = useCallback(async () => {
    try {
      const canvases = await fetchCanvases();
      useCanvasStore.getState().setCanvases(canvases);
    } catch (error) {
      console.error('Failed to sync canvases:', error);
    }
  }, [fetchCanvases]);

  const syncSkills = useCallback(async () => {
    try {
      const skills = await fetchSkills();
      useCanvasStore.getState().setSkills(skills);
    } catch (error) {
      console.error('Failed to sync skills:', error);
    }
  }, [fetchSkills]);

  const syncAgents = useCallback(async () => {
    try {
      const agents = await fetchAgents();
      useCanvasStore.getState().setAgents(agents);
    } catch (error) {
      console.error('Failed to sync agents:', error);
    }
  }, [fetchAgents]);

  const syncMcpServers = useCallback(async () => {
    try {
      const servers = await fetchMcpServers();
      useCanvasStore.getState().setMcpServers(servers);
    } catch (error) {
      console.error('Failed to sync MCP servers:', error);
    }
  }, [fetchMcpServers]);

  const syncExecutions = useCallback(async () => {
    try {
      const executions = await fetchExecutions();
      useCanvasStore.getState().setExecutions(executions);
    } catch (error) {
      console.error('Failed to sync executions:', error);
    }
  }, [fetchExecutions]);

  return {
    loading,
    // Canvas
    fetchCanvases,
    createCanvas,
    fetchCanvas,
    updateCanvas,
    deleteCanvas,
    executeCanvas,
    testCanvas,
    validateCanvas,
    // Skills
    fetchSkills,
    createSkill,
    fetchSkill,
    updateSkill,
    deleteSkill,
    testSkill,
    improveSkill,
    // Agents
    fetchAgents,
    createAgent,
    fetchAgent,
    updateAgent,
    deleteAgent,
    assignSkillToAgent,
    removeSkillFromAgent,
    chatWithAgent,
    // MCP
    fetchMcpServers,
    createMcpServer,
    fetchMcpServer,
    updateMcpServer,
    deleteMcpServer,
    connectMcpServer,
    disconnectMcpServer,
    listMcpTools,
    callMcpTool,
    // Executions
    fetchExecutions,
    fetchExecution,
    cancelExecution,
    retryExecution,
    // AI
    aiGenerateNode,
    aiGenerateCanvas,
    aiGenerateSkill,
    aiOptimizeCanvas,
    // Sync
    syncCanvases,
    syncSkills,
    syncAgents,
    syncMcpServers,
    syncExecutions,
  };
};

// Add setCanvases, setSkills, etc. to the store
// We'll need to update the canvas-store.ts to include these setters