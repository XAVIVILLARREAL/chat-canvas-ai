import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';
import type { 
  Canvas, 
  CanvasNode, 
  CanvasEdge, 
  Skill, 
  Agent, 
  MCPServer,
  ExecutionContext,
  Viewport,
  Position,
  NodeType,
} from '../types';
import { NODE_TYPE_CONFIG } from '../types';

interface CanvasState {
  currentCanvas: Canvas | null;
  canvases: Canvas[];
  selectedNodeIds: string[];
  selectedEdgeIds: string[];
  viewport: Viewport;
  sidebarOpen: boolean;
  sidebarTab: 'nodes' | 'skills' | 'agents' | 'mcp' | 'settings' | 'execution';
  nodePanelOpen: boolean;
  nodePanelNodeId: string | null;
  skills: Skill[];
  selectedSkillId: string | null;
  agents: Agent[];
  selectedAgentId: string | null;
  mcpServers: MCPServer[];
  selectedMcpServerId: string | null;
  executions: ExecutionContext[];
  currentExecutionId: string | null;
  toasts: Toast[];
  loading: boolean;
  saving: boolean;
  history: CanvasHistoryEntry[];
  historyIndex: number;
  setCanvases: (canvases: Canvas[]) => void;
  setSkills: (skills: Skill[]) => void;
  setAgents: (agents: Agent[]) => void;
  setMcpServers: (servers: MCPServer[]) => void;
  setExecutions: (executions: ExecutionContext[]) => void;
  setLoading: (loading: boolean) => void;
  setSaving: (saving: boolean) => void;
  fetchCanvases: () => Promise<void>;
  fetchSkills: () => Promise<void>;
  fetchAgents: () => Promise<void>;
  fetchMcpServers: () => Promise<void>;
  fetchExecutions: () => Promise<void>;
  setCurrentCanvas: (canvas: Canvas) => void;
  createCanvas: (name?: string) => void;
  deleteCanvas: (id: string) => void;
  updateCanvas: (updates: Partial<Canvas>) => void;
  addNode: (node: CanvasNode) => void;
  removeNode: (nodeId: string) => void;
  updateNode: (nodeId: string, updates: Partial<CanvasNode>) => void;
  updateNodePosition: (nodeId: string, position: Position) => void;
  updateNodeConfig: (nodeId: string, config: Partial<CanvasNode['config']>) => void;
  duplicateNode: (nodeId: string) => void;
  addEdge: (edge: CanvasEdge) => void;
  removeEdge: (edgeId: string) => void;
  updateEdge: (edgeId: string, updates: Partial<CanvasEdge>) => void;
  selectNode: (nodeId: string, multi?: boolean) => void;
  selectEdge: (edgeId: string, multi?: boolean) => void;
  clearSelection: () => void;
  selectAll: () => void;
  setViewport: (viewport: Viewport) => void;
  panViewport: (deltaX: number, deltaY: number) => void;
  zoomViewport: (zoom: number, centerX?: number, centerY?: number) => void;
  fitView: () => void;
  toggleSidebar: () => void;
  setSidebarTab: (tab: CanvasState['sidebarTab']) => void;
  openNodePanel: (nodeId: string) => void;
  closeNodePanel: () => void;
  addSkill: (skill: Skill) => void;
  updateSkill: (skill: Skill) => void;
  removeSkill: (id: string) => void;
  setSelectedSkill: (id: string | null) => void;
  addAgent: (agent: Agent) => void;
  updateAgent: (agent: Agent) => void;
  removeAgent: (id: string) => void;
  setSelectedAgent: (id: string | null) => void;
  addMcpServer: (server: MCPServer) => void;
  updateMcpServer: (server: MCPServer) => void;
  removeMcpServer: (id: string) => void;
  setSelectedMcpServer: (id: string | null) => void;
  addExecution: (execution: ExecutionContext) => void;
  updateExecution: (executionId: string, updates: Partial<ExecutionContext>) => void;
  setCurrentExecution: (id: string | null) => void;
  addToast: (toast: Omit<Toast, 'id'>) => void;
  removeToast: (id: string) => void;
  undo: () => void;
  redo: () => void;
  canUndo: () => boolean;
  canRedo: () => boolean;
  exportCanvas: () => string | null;
  importCanvas: (json: string) => boolean;
  createNodeFromType: (nodeType: NodeType, position: Position) => CanvasNode;
}

interface Toast {
  id: string;
  type: 'success' | 'error' | 'warning' | 'info';
  message: string;
  duration?: number;
}

interface CanvasHistoryEntry {
  nodes: CanvasNode[];
  edges: CanvasEdge[];
  viewport: Viewport;
  timestamp: number;
}

const DEFAULT_VIEWPORT: Viewport = { x: 0, y: 0, zoom: 1 };

const createEmptyCanvas = (name: string = 'Nuevo Canvas'): Canvas => ({
  id: crypto.randomUUID(),
  name,
  description: '',
  version: 1,
  nodes: [],
  edges: [],
  viewport: DEFAULT_VIEWPORT,
  settings: {
    autoSave: true,
    executionMode: 'dag',
    timeoutMs: 300000,
    retryPolicy: { maxRetries: 3, backoffMs: 1000, retryOn: ['timeout', 'network_error'] },
    parallelExecution: true,
  },
  createdAt: Date.now(),
  updatedAt: Date.now(),
  createdBy: 'user',
});

export const useCanvasStore = create<CanvasState>()(
  immer((set, get) => ({
    currentCanvas: createEmptyCanvas(),
    canvases: [createEmptyCanvas()],
    selectedNodeIds: [],
    selectedEdgeIds: [],
    viewport: DEFAULT_VIEWPORT,
    sidebarOpen: true,
    sidebarTab: 'nodes',
    nodePanelOpen: false,
    nodePanelNodeId: null,
    skills: [],
    selectedSkillId: null,
    agents: [],
    selectedAgentId: null,
    mcpServers: [],
    selectedMcpServerId: null,
    executions: [],
    currentExecutionId: null,
    toasts: [],
    loading: false,
    saving: false,
    history: [],
    historyIndex: -1,

    setCurrentCanvas: (canvas: Canvas) => set((state: CanvasState) => {
      state.currentCanvas = canvas;
      state.selectedNodeIds = [];
      state.selectedEdgeIds = [];
      state.viewport = canvas.viewport;
    }),

    createCanvas: (name?: string) => set((state: CanvasState) => {
      const canvas = createEmptyCanvas(name);
      state.canvases.push(canvas);
      state.currentCanvas = canvas;
      state.selectedNodeIds = [];
      state.selectedEdgeIds = [];
      state.viewport = DEFAULT_VIEWPORT;
    }),

    deleteCanvas: (id: string) => set((state: CanvasState) => {
      state.canvases = state.canvases.filter((c: Canvas) => c.id !== id);
      if (state.currentCanvas?.id === id) {
        state.currentCanvas = state.canvases[0] || createEmptyCanvas();
      }
    }),

    updateCanvas: (updates: Partial<Canvas>) => set((state: CanvasState) => {
      if (state.currentCanvas) {
        state.currentCanvas = { ...state.currentCanvas, ...updates, updatedAt: Date.now() };
        const idx = state.canvases.findIndex((c: Canvas) => c.id === state.currentCanvas!.id);
        if (idx >= 0) state.canvases[idx] = state.currentCanvas;
      }
    }),

    addNode: (node: CanvasNode) => set((state: CanvasState) => {
      if (state.currentCanvas) {
        pushHistory(state);
        state.currentCanvas.nodes.push(node);
        state.currentCanvas.updatedAt = Date.now();
      }
    }),

    removeNode: (nodeId: string) => set((state: CanvasState) => {
      if (state.currentCanvas) {
        pushHistory(state);
        state.currentCanvas.nodes = state.currentCanvas.nodes.filter((n: CanvasNode) => n.id !== nodeId);
        state.currentCanvas.edges = state.currentCanvas.edges.filter((e: CanvasEdge) => e.source !== nodeId && e.target !== nodeId);
        state.selectedNodeIds = state.selectedNodeIds.filter((id: string) => id !== nodeId);
        state.currentCanvas.updatedAt = Date.now();
      }
    }),

    updateNode: (nodeId: string, updates: Partial<CanvasNode>) => set((state: CanvasState) => {
      if (state.currentCanvas) {
        pushHistory(state);
        const node = state.currentCanvas.nodes.find((n: CanvasNode) => n.id === nodeId);
        if (node) { Object.assign(node, updates); state.currentCanvas.updatedAt = Date.now(); }
      }
    }),

    updateNodePosition: (nodeId: string, position: Position) => set((state: CanvasState) => {
      if (state.currentCanvas) {
        const node = state.currentCanvas.nodes.find((n: CanvasNode) => n.id === nodeId);
        if (node) { node.position = position; state.currentCanvas.updatedAt = Date.now(); }
      }
    }),

    updateNodeConfig: (nodeId: string, config: Partial<CanvasNode['config']>) => set((state: CanvasState) => {
      if (state.currentCanvas) {
        pushHistory(state);
        const node = state.currentCanvas.nodes.find((n: CanvasNode) => n.id === nodeId);
        if (node) { node.config = { ...node.config, ...config }; state.currentCanvas.updatedAt = Date.now(); }
      }
    }),

    duplicateNode: (nodeId: string) => set((state: CanvasState) => {
      if (state.currentCanvas) {
        pushHistory(state);
        const node = state.currentCanvas.nodes.find((n: CanvasNode) => n.id === nodeId);
        if (node) {
          const newNode: CanvasNode = { ...node, id: crypto.randomUUID(), position: { x: node.position.x + 20, y: node.position.y + 20 } };
          state.currentCanvas.nodes.push(newNode);
          state.currentCanvas.updatedAt = Date.now();
        }
      }
    }),

    addEdge: (edge: CanvasEdge) => set((state: CanvasState) => {
      if (state.currentCanvas) {
        pushHistory(state);
        state.currentCanvas.edges.push(edge);
        state.currentCanvas.updatedAt = Date.now();
      }
    }),

    removeEdge: (edgeId: string) => set((state: CanvasState) => {
      if (state.currentCanvas) {
        pushHistory(state);
        state.currentCanvas.edges = state.currentCanvas.edges.filter((e: CanvasEdge) => e.id !== edgeId);
        state.selectedEdgeIds = state.selectedEdgeIds.filter((id: string) => id !== edgeId);
        state.currentCanvas.updatedAt = Date.now();
      }
    }),

    updateEdge: (edgeId: string, updates: Partial<CanvasEdge>) => set((state: CanvasState) => {
      if (state.currentCanvas) {
        pushHistory(state);
        const edge = state.currentCanvas.edges.find((e: CanvasEdge) => e.id === edgeId);
        if (edge) { Object.assign(edge, updates); state.currentCanvas.updatedAt = Date.now(); }
      }
    }),

    selectNode: (nodeId: string, multi = false) => set((state: CanvasState) => {
      if (multi) {
        if (state.selectedNodeIds.includes(nodeId)) state.selectedNodeIds = state.selectedNodeIds.filter((id: string) => id !== nodeId);
        else state.selectedNodeIds.push(nodeId);
      } else { state.selectedNodeIds = [nodeId]; }
      state.selectedEdgeIds = [];
    }),

    selectEdge: (edgeId: string, multi = false) => set((state: CanvasState) => {
      if (multi) {
        if (state.selectedEdgeIds.includes(edgeId)) state.selectedEdgeIds = state.selectedEdgeIds.filter((id: string) => id !== edgeId);
        else state.selectedEdgeIds.push(edgeId);
      } else { state.selectedEdgeIds = [edgeId]; }
      state.selectedNodeIds = [];
    }),

    clearSelection: () => set((state: CanvasState) => { state.selectedNodeIds = []; state.selectedEdgeIds = []; }),
    selectAll: () => set((state: CanvasState) => { if (state.currentCanvas) { state.selectedNodeIds = state.currentCanvas.nodes.map((n: CanvasNode) => n.id); state.selectedEdgeIds = state.currentCanvas.edges.map((e: CanvasEdge) => e.id); } }),

    setViewport: (viewport: Viewport) => set((state: CanvasState) => { state.viewport = viewport; if (state.currentCanvas) state.currentCanvas.viewport = viewport; }),
    panViewport: (deltaX: number, deltaY: number) => set((state: CanvasState) => { state.viewport.x += deltaX / state.viewport.zoom; state.viewport.y += deltaY / state.viewport.zoom; if (state.currentCanvas) state.currentCanvas.viewport = state.viewport; }),
    zoomViewport: (zoom: number, centerX?: number, centerY?: number) => set((state: CanvasState) => { const oldZoom = state.viewport.zoom; state.viewport.zoom = Math.max(0.1, Math.min(3, zoom)); if (centerX !== undefined && centerY !== undefined) { const factor = state.viewport.zoom / oldZoom; state.viewport.x = centerX - (centerX - state.viewport.x) * factor; state.viewport.y = centerY - (centerY - state.viewport.y) * factor; } if (state.currentCanvas) state.currentCanvas.viewport = state.viewport; }),
    fitView: () => set((state: CanvasState) => { if (!state.currentCanvas || state.currentCanvas.nodes.length === 0) return; const nodes = state.currentCanvas.nodes; let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity; nodes.forEach((node: CanvasNode) => { minX = Math.min(minX, node.position.x); minY = Math.min(minY, node.position.y); maxX = Math.max(maxX, node.position.x + 200); maxY = Math.max(maxY, node.position.y + 100); }); const padding = 100; const canvasWidth = window.innerWidth - 320; const canvasHeight = window.innerHeight - 100; const contentWidth = maxX - minX + padding * 2; const contentHeight = maxY - minY + padding * 2; const zoomVal = Math.min(canvasWidth / contentWidth, canvasHeight / contentHeight, 1); state.viewport = { x: minX - padding, y: minY - padding, zoom: zoomVal }; if (state.currentCanvas) state.currentCanvas.viewport = state.viewport; }),

    toggleSidebar: () => set((state: CanvasState) => { state.sidebarOpen = !state.sidebarOpen; }),
    setSidebarTab: (tab: CanvasState['sidebarTab']) => set((state: CanvasState) => { state.sidebarTab = tab; }),
    openNodePanel: (nodeId: string) => set((state: CanvasState) => { state.nodePanelOpen = true; state.nodePanelNodeId = nodeId; }),
    closeNodePanel: () => set((state: CanvasState) => { state.nodePanelOpen = false; state.nodePanelNodeId = null; }),

    setCanvases: (canvases: Canvas[]) => set((state: CanvasState) => { state.canvases = canvases; }),
    setSkills: (skills: Skill[]) => set((state: CanvasState) => { state.skills = skills; }),
    setAgents: (agents: Agent[]) => set((state: CanvasState) => { state.agents = agents; }),
    setMcpServers: (servers: MCPServer[]) => set((state: CanvasState) => { state.mcpServers = servers; }),
    setExecutions: (executions: ExecutionContext[]) => set((state: CanvasState) => { state.executions = executions; }),
    setLoading: (loading: boolean) => set((state: CanvasState) => { state.loading = loading; }),
    setSaving: (saving: boolean) => set((state: CanvasState) => { state.saving = saving; }),

    fetchCanvases: async () => { try { const response = await fetch('/api/canvases'); if (response.ok) { const canvases = await response.json(); get().setCanvases(canvases); } } catch (error) { console.error('Failed to fetch canvases:', error); } },
    fetchSkills: async () => { try { const response = await fetch('/api/skills'); if (response.ok) { const skills = await response.json(); get().setSkills(skills); } } catch (error) { console.error('Failed to fetch skills:', error); } },
    fetchAgents: async () => { try { const response = await fetch('/api/agents'); if (response.ok) { const agents = await response.json(); get().setAgents(agents); } } catch (error) { console.error('Failed to fetch agents:', error); } },
    fetchMcpServers: async () => { try { const response = await fetch('/api/mcp/servers'); if (response.ok) { const servers = await response.json(); get().setMcpServers(servers); } } catch (error) { console.error('Failed to fetch MCP servers:', error); } },
    fetchExecutions: async () => { try { const response = await fetch('/api/executions'); if (response.ok) { const executions = await response.json(); get().setExecutions(executions); } } catch (error) { console.error('Failed to fetch executions:', error); } },

    addSkill: (skill: Skill) => set((state: CanvasState) => { state.skills.push(skill); }),
    updateSkill: (skill: Skill) => set((state: CanvasState) => { const idx = state.skills.findIndex((s: Skill) => s.id === skill.id); if (idx >= 0) state.skills[idx] = skill; }),
    removeSkill: (id: string) => set((state: CanvasState) => { state.skills = state.skills.filter((s: Skill) => s.id !== id); if (state.selectedSkillId === id) state.selectedSkillId = null; }),
    setSelectedSkill: (id: string | null) => set((state: CanvasState) => { state.selectedSkillId = id; }),

    addAgent: (agent: Agent) => set((state: CanvasState) => { state.agents.push(agent); }),
    updateAgent: (agent: Agent) => set((state: CanvasState) => { const idx = state.agents.findIndex((a: Agent) => a.id === agent.id); if (idx >= 0) state.agents[idx] = agent; }),
    removeAgent: (id: string) => set((state: CanvasState) => { state.agents = state.agents.filter((a: Agent) => a.id !== id); if (state.selectedAgentId === id) state.selectedAgentId = null; }),
    setSelectedAgent: (id: string | null) => set((state: CanvasState) => { state.selectedAgentId = id; }),

    addMcpServer: (server: MCPServer) => set((state: CanvasState) => { state.mcpServers.push(server); }),
    updateMcpServer: (server: MCPServer) => set((state: CanvasState) => { const idx = state.mcpServers.findIndex((s: MCPServer) => s.id === server.id); if (idx >= 0) state.mcpServers[idx] = server; }),
    removeMcpServer: (id: string) => set((state: CanvasState) => { state.mcpServers = state.mcpServers.filter((s: MCPServer) => s.id !== id); if (state.selectedMcpServerId === id) state.selectedMcpServerId = null; }),
    setSelectedMcpServer: (id: string | null) => set((state: CanvasState) => { state.selectedMcpServerId = id; }),

    addExecution: (execution: ExecutionContext) => set((state: CanvasState) => { state.executions.unshift(execution); state.currentExecutionId = execution.executionId; }),
    updateExecution: (executionId: string, updates: Partial<ExecutionContext>) => set((state: CanvasState) => { const exec = state.executions.find((e: ExecutionContext) => e.executionId === executionId); if (exec) Object.assign(exec, updates); }),
    setCurrentExecution: (id: string | null) => set((state: CanvasState) => { state.currentExecutionId = id; }),

    addToast: (toast: Omit<Toast, 'id'>) => set((state: CanvasState) => { state.toasts.push({ ...toast, id: crypto.randomUUID() }); }),
    removeToast: (id: string) => set((state: CanvasState) => { state.toasts = state.toasts.filter((t: Toast) => t.id !== id); }),

    undo: () => set((state: CanvasState) => { if (state.historyIndex > 0) { state.historyIndex--; const entry = state.history[state.historyIndex]; if (state.currentCanvas) { state.currentCanvas.nodes = entry.nodes; state.currentCanvas.edges = entry.edges; state.currentCanvas.viewport = entry.viewport; state.currentCanvas.updatedAt = Date.now(); } } }),
    redo: () => set((state: CanvasState) => { if (state.historyIndex < state.history.length - 1) { state.historyIndex++; const entry = state.history[state.historyIndex]; if (state.currentCanvas) { state.currentCanvas.nodes = entry.nodes; state.currentCanvas.edges = entry.edges; state.currentCanvas.viewport = entry.viewport; state.currentCanvas.updatedAt = Date.now(); } } }),
    canUndo: () => get().historyIndex > 0,
    canRedo: () => get().historyIndex < get().history.length - 1,

    exportCanvas: () => { const canvas = get().currentCanvas; if (!canvas) return null; return JSON.stringify(canvas, null, 2); },
    importCanvas: (json: string) => { try { const canvas = JSON.parse(json) as Canvas; get().setCurrentCanvas(canvas); get().setCanvases([canvas]); get().clearSelection(); get().setViewport(canvas.viewport); get().setCanvases([canvas]); return true; } catch { return false; } },

    createNodeFromType: (nodeType: NodeType, position: Position) => {
      const config = NODE_TYPE_CONFIG[nodeType];
      const node: CanvasNode = { id: crypto.randomUUID(), nodeType, position, config: config.defaultConfig as CanvasNode['config'], inputs: config.defaultInputs, outputs: config.defaultOutputs, metadata: { label: config.label, description: config.description, color: config.color, icon: nodeType, category: config.category, isAiGenerated: false, testCases: [] } };
      get().addNode(node);
      return node;
    },
  }))
);

function pushHistory(state: CanvasState) {
  if (!state.currentCanvas) return;
  state.history = state.history.slice(0, state.historyIndex + 1);
  state.history.push({ nodes: JSON.parse(JSON.stringify(state.currentCanvas.nodes)), edges: JSON.parse(JSON.stringify(state.currentCanvas.edges)), viewport: { ...state.currentCanvas.viewport }, timestamp: Date.now() });
  state.historyIndex = state.history.length - 1;
  if (state.history.length > 50) { state.history.shift(); state.historyIndex--; }
}
