import React, { useState } from 'react';
import { 
  Bot, Zap, Plug, Play, Settings,
  Plus, Search, Edit, Trash2, Play as PlayIcon, Pause, RotateCcw,
  ExternalLink, Eye,
} from 'lucide-react';
import { 
  useCanvasStore 
} from '../stores/canvas-store';
import type { 
  Skill, Agent, MCPServer, ExecutionContext,
  AgentStatus, AgentRole 
} from '../types';
import { AGENT_STATUS_COLORS, AGENT_ROLE_COLORS } from '../types';
import './Sidebar.css';

interface SidebarProps {
  activeTab: 'nodes' | 'skills' | 'agents' | 'mcp' | 'settings' | 'execution';
  onTabChange: (tab: SidebarProps['activeTab']) => void;
  skills: Skill[];
  agents: Agent[];
  mcpServers: MCPServer[];
  executions: ExecutionContext[];
}

export const Sidebar: React.FC<SidebarProps> = ({
  activeTab,
  onTabChange,
  skills,
  agents,
  mcpServers,
  executions,
}) => {
  const {
    selectedSkillId,
    setSelectedSkill,
    selectedAgentId,
    setSelectedAgent,
    selectedMcpServerId,
    setSelectedMcpServer,
    currentExecutionId,
    setCurrentExecution,
    removeSkill,
    removeAgent,
    removeMcpServer,
  } = useCanvasStore();

  const [searchQuery, setSearchQuery] = useState('');

  const tabs = [
    { id: 'skills', label: 'Skills', icon: Zap, count: skills.length },
    { id: 'agents', label: 'Agentes', icon: Bot, count: agents.length },
    { id: 'mcp', label: 'MCP', icon: Plug, count: mcpServers.length },
    { id: 'execution', label: 'Ejecuciones', icon: Play, count: executions.length },
    { id: 'settings', label: 'Config', icon: Settings, count: 0 },
  ];

  const filteredSkills = skills.filter(s => s.name.toLowerCase().includes(searchQuery.toLowerCase()) || s.description.toLowerCase().includes(searchQuery.toLowerCase()));
  const filteredAgents = agents.filter(a => a.name.toLowerCase().includes(searchQuery.toLowerCase()) || a.description.toLowerCase().includes(searchQuery.toLowerCase()));
  const filteredMcpServers = mcpServers.filter(s => s.name.toLowerCase().includes(searchQuery.toLowerCase()) || s.description.toLowerCase().includes(searchQuery.toLowerCase()));
  const filteredExecutions = executions.filter(e => e.executionId.toLowerCase().includes(searchQuery.toLowerCase()) || e.canvasId.toLowerCase().includes(searchQuery.toLowerCase()));

  return (
    <div className="sidebar">
      <div className="sidebar-tabs">
        {tabs.map(tab => (
          <button key={tab.id} className={`sidebar-tab ${activeTab === tab.id ? 'active' : ''}`} onClick={() => onTabChange(tab.id as any)} title={tab.label}>
            <tab.icon width={16} height={16} />
            <span>{tab.label}</span>
            {tab.count > 0 && <span className="tab-badge">{tab.count}</span>}
          </button>
        ))}
      </div>

      <div className="sidebar-search">
        <input type="text" placeholder="Buscar..." value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} />
        <Search width={14} height={14} />
      </div>

      <div className="sidebar-content">
        {activeTab === 'skills' && <SkillList skills={filteredSkills} selectedId={selectedSkillId} onSelect={setSelectedSkill} onAdd={() => {}} onRemove={removeSkill} />}
        {activeTab === 'agents' && <AgentList agents={filteredAgents} selectedId={selectedAgentId} onSelect={setSelectedAgent} onAdd={() => {}} onRemove={removeAgent} />}
        {activeTab === 'mcp' && <McpServerList servers={filteredMcpServers} selectedId={selectedMcpServerId} onSelect={setSelectedMcpServer} onAdd={() => {}} onRemove={removeMcpServer} />}
        {activeTab === 'execution' && <ExecutionList executions={filteredExecutions} currentExecutionId={currentExecutionId} onSelect={setCurrentExecution} />}
        {activeTab === 'settings' && <SettingsPanel />}
      </div>
    </div>
  );
};

const SkillList: React.FC<{ skills: Skill[]; selectedId: string | null; onSelect: (id: string | null) => void; onAdd: () => void; onRemove: (id: string) => void }> = ({ skills, selectedId, onSelect, onAdd, onRemove }) => (
  <div className="sidebar-list">
    <div className="list-header"><h3>Skills</h3><button className="add-btn" onClick={onAdd} title="Nueva Skill"><Plus width={14} height={14} /></button></div>
    {skills.length === 0 ? <div className="empty-state"><p>No hay skills</p><button className="btn-primary" onClick={onAdd}><Plus width={14} height={14} /> Crear Skill</button></div> : <ul className="item-list stagger">{skills.map(skill => (<li key={skill.id} className={`item ${selectedId === skill.id ? 'selected' : ''}`} onClick={() => onSelect(skill.id)}><div className="item-main"><span className="item-icon" style={{ color: '#10b981' }}><Zap width={14} height={14} /></span><div className="item-info"><span className="item-name">{skill.name}</span><span className="item-meta">v{skill.version} · {skill.metadata.usageCount} usos · {(skill.metadata.successRate * 100).toFixed(0)}%</span></div></div><div className="item-actions"><button className="item-action" onClick={(e) => { e.stopPropagation(); onSelect(null); }} title="Probar"><PlayIcon width={12} height={12} /></button><button className="item-action" onClick={(e) => { e.stopPropagation(); onSelect(skill.id); }} title="Editar"><Edit width={12} height={12} /></button><button className="item-action danger" onClick={(e) => { e.stopPropagation(); onRemove(skill.id); }} title="Eliminar"><Trash2 width={12} height={12} /></button></div></li>))}</ul>}
  </div>
);

const AgentList: React.FC<{ agents: Agent[]; selectedId: string | null; onSelect: (id: string | null) => void; onAdd: () => void; onRemove: (id: string) => void }> = ({ agents, selectedId, onSelect, onAdd, onRemove }) => {
  const getStatusColor = (status: AgentStatus) => AGENT_STATUS_COLORS[status] || '#64748b';
  const getRoleColor = (role: AgentRole) => { if (typeof role === 'string') return AGENT_ROLE_COLORS[role] || '#6366f1'; return AGENT_ROLE_COLORS['custom'] || '#6366f1'; };
  return (
    <div className="sidebar-list"><div className="list-header"><h3>Agentes</h3><button className="add-btn" onClick={onAdd} title="Nuevo Agente"><Plus width={14} height={14} /></button></div>
    {agents.length === 0 ? <div className="empty-state"><p>No hay agentes</p><button className="btn-primary" onClick={onAdd}><Plus width={14} height={14} /> Crear Agente</button></div> : <ul className="item-list stagger">{agents.map(agent => (<li key={agent.id} className={`item ${selectedId === agent.id ? 'selected' : ''}`} onClick={() => onSelect(agent.id)}><div className="item-main"><div className={`agent-avatar${agent.status === 'working' ? ' agent-alive' : ''}`} style={{ backgroundColor: `${getRoleColor(agent.role)}20` }}><Bot width={16} height={16} style={{ color: getRoleColor(agent.role) }} /></div><div className="item-info"><div className="item-name-row"><span className="item-name">{agent.name}</span><span className="status-dot" style={{ backgroundColor: getStatusColor(agent.status) }} /></div><span className="item-meta">{typeof agent.role === 'string' ? agent.role : 'Custom'} · {agent.skills.length} skills</span></div></div><div className="item-actions"><button className="item-action" onClick={(e) => { e.stopPropagation(); onSelect(agent.id); }} title="Chat"><ExternalLink width={12} height={12} /></button><button className="item-action" onClick={(e) => { e.stopPropagation(); onSelect(agent.id); }} title="Editar"><Edit width={12} height={12} /></button><button className="item-action danger" onClick={(e) => { e.stopPropagation(); onRemove(agent.id); }} title="Eliminar"><Trash2 width={12} height={12} /></button></div></li>))}</ul>}
  </div>
  );
};

const McpServerList: React.FC<{ servers: MCPServer[]; selectedId: string | null; onSelect: (id: string | null) => void; onAdd: () => void; onRemove: (id: string) => void }> = ({ servers, selectedId, onSelect, onAdd, onRemove }) => {
  const getStatusColor = (status: MCPServer['status']) => { switch (status) { case 'connected': return '#22c55e'; case 'connecting': return '#f59e0b'; case 'error': return '#ef4444'; case 'unauthorized': return '#ec4899'; default: return '#64748b'; }};
  return (
    <div className="sidebar-list"><div className="list-header"><h3>MCP Servers</h3><button className="add-btn" onClick={onAdd} title="Nuevo MCP Server"><Plus width={14} height={14} /></button></div>
    {servers.length === 0 ? <div className="empty-state"><p>No hay servidores MCP</p><button className="btn-primary" onClick={onAdd}><Plus width={14} height={14} /> Agregar Servidor</button></div> : <ul className="item-list stagger">{servers.map(server => (<li key={server.id} className={`item ${selectedId === server.id ? 'selected' : ''}`} onClick={() => onSelect(server.id)}><div className="item-main"><span className="item-icon" style={{ color: '#06b6d4' }}><Plug width={14} height={14} /></span><div className="item-info"><div className="item-name-row"><span className="item-name">{server.name}</span><span className="status-dot" style={{ backgroundColor: getStatusColor(server.status) }} /></div><span className="item-meta">{server.tools.length} tools · {server.transport}</span></div></div><div className="item-actions"><button className="item-action" onClick={(e) => { e.stopPropagation(); }} title="Conectar/Desconectar">{server.status === 'connected' ? <Pause width={12} height={12} /> : <PlayIcon width={12} height={12} />}</button><button className="item-action" onClick={(e) => { e.stopPropagation(); onSelect(server.id); }} title="Editar"><Edit width={12} height={12} /></button><button className="item-action danger" onClick={(e) => { e.stopPropagation(); onRemove(server.id); }} title="Eliminar"><Trash2 width={12} height={12} /></button></div></li>))}</ul>}
  </div>
  );
};

const ExecutionList: React.FC<{ executions: ExecutionContext[]; currentExecutionId: string | null; onSelect: (id: string | null) => void }> = ({ executions, currentExecutionId, onSelect }) => {
  const getStatusColor = (status: ExecutionContext['status']) => { switch (status) { case 'completed': return '#22c55e'; case 'running': return '#3b82f6'; case 'failed': return '#ef4444'; case 'cancelled': return '#f59e0b'; case 'waitingForHuman': return '#ec4899'; default: return '#64748b'; }};
  const formatTime = (ms?: number) => { if (!ms) return '0ms'; if (ms < 1000) return `${ms}ms`; return `${(ms / 1000).toFixed(1)}s`; };
  return (
    <div className="sidebar-list"><div className="list-header"><h3>Ejecuciones</h3></div>
    {executions.length === 0 ? <div className="empty-state"><p>No hay ejecuciones</p></div> : <ul className="item-list stagger">{executions.map(exec => (<li key={exec.executionId} className={`item ${currentExecutionId === exec.executionId ? 'selected' : ''}`} onClick={() => onSelect(exec.executionId)}><div className="item-main"><div className="item-info"><div className="item-name-row"><span className="item-name">{exec.executionId.slice(0, 8)}</span><span className="status-dot" style={{ backgroundColor: getStatusColor(exec.status) }} /></div><span className="item-meta">Canvas: {exec.canvasId.slice(0, 8)} · {formatTime(exec.totalDurationMs)}</span></div></div><div className="item-actions"><button className="item-action" onClick={(e) => { e.stopPropagation(); }} title="Ver detalles"><Eye width={12} height={12} /></button><button className="item-action" onClick={(e) => { e.stopPropagation(); }} title="Reintentar"><RotateCcw width={12} height={12} /></button></div></li>))}</ul>}
  </div>
  );
};

const SettingsPanel: React.FC = () => (
  <div className="sidebar-list">
    <div className="list-header"><h3>Configuración</h3></div>
    <div className="settings-section"><h4>Canvas</h4><div className="setting-item"><label><input type="checkbox" defaultChecked /> Auto-guardar</label></div><div className="setting-item"><label><input type="checkbox" defaultChecked /> Ejecución paralela</label></div><div className="setting-item"><label>Modo de ejecución:<select defaultValue="dag"><option value="dag">DAG (Topológico)</option><option value="sequential">Secuencial</option><option value="parallel">Paralelo</option></select></label></div></div>
    <div className="settings-section"><h4>IA</h4><div className="setting-item"><label>Modelo por defecto:<select defaultValue="gpt-4o"><option value="gpt-4o">GPT-4o</option><option value="gpt-4o-mini">GPT-4o Mini</option><option value="claude-3-5-sonnet">Claude 3.5 Sonnet</option></select></label></div><div className="setting-item"><label>Temperatura:<input type="range" min="0" max="2" step="0.1" defaultValue="0.7" /></label></div></div>
    <div className="settings-section"><h4>Apariencia</h4><div className="setting-item"><label><input type="checkbox" defaultChecked /> Grid</label></div><div className="setting-item"><label><input type="checkbox" defaultChecked /> Snap to grid</label></div><div className="setting-item"><label>Tema:<select defaultValue="dark"><option value="dark">Oscuro</option><option value="light">Claro</option><option value="system">Sistema</option></select></label></div></div>
  </div>
);

export default Sidebar;
