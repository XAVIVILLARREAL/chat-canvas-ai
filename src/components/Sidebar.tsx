import React, { useState } from 'react';
import { 
  Bot, Zap, Plug, Play, Settings,
  Plus, Search, Edit, Trash2, Play as PlayIcon, Pause, RotateCcw,
  ExternalLink, Eye,
} from 'lucide-react';
import { 
  useCanvasStore 
} from '../stores/canvas-store';
import { useI18n, SUPPORTED_LOCALES, type Locale } from '../i18n';
import { useTheme } from '../theme';
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
    addAgent,
  } = useCanvasStore();

  const { t } = useI18n();
  const [searchQuery, setSearchQuery] = useState('');
  const [modalAgente, setModalAgente] = useState(false);
  const [nombreAgente, setNombreAgente] = useState('');
  const [rolAgente, setRolAgente] = useState<AgentRole>('executor');

  const guardarAgente = () => {
    const nombre = nombreAgente.trim() || 'Agente';
    const now = Date.now();
    const agente: Agent = {
      id: crypto.randomUUID(),
      name: nombre,
      description: '',
      role: rolAgente,
      status: 'idle',
      skills: [],
      mcpServers: [],
      config: { model: 'stealth/ox-alpha', temperature: 0.7, maxTokens: 4096, systemPrompt: '', maxConcurrentTasks: 1, autoImproveSkills: false, learningEnabled: false },
      memory: { shortTerm: [], longTerm: [], episodic: [], skillKnowledge: {} },
      metrics: { tasksCompleted: 0, tasksFailed: 0, skillsExecuted: 0, totalCostUsd: 0, avgTaskDurationMs: 0, uptimePercentage: 100 },
      createdAt: now,
      updatedAt: now,
      createdBy: 'local',
    };
    addAgent(agente);
    setSelectedAgent(agente.id);
    setModalAgente(false);
    setNombreAgente('');
  };

  const tabs = [
    { id: 'skills', label: t('sidebar.skills'), icon: Zap, count: skills.length },
    { id: 'agents', label: t('sidebar.agents'), icon: Bot, count: agents.length },
    { id: 'mcp', label: t('sidebar.mcp'), icon: Plug, count: mcpServers.length },
    { id: 'execution', label: t('sidebar.executions'), icon: Play, count: executions.length },
    { id: 'settings', label: t('sidebar.settings'), icon: Settings, count: 0 },
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
        <input type="text" placeholder={t("sidebar.search")} value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} />
        <Search width={14} height={14} />
      </div>

      <div className="sidebar-content">
        {activeTab === 'skills' && <SkillList skills={filteredSkills} selectedId={selectedSkillId} onSelect={setSelectedSkill} onAdd={() => {}} onRemove={removeSkill} />}
        {activeTab === 'agents' && <AgentList agents={filteredAgents} selectedId={selectedAgentId} onSelect={setSelectedAgent} onAdd={() => setModalAgente(true)} onRemove={removeAgent} />}
        {activeTab === 'mcp' && <McpServerList servers={filteredMcpServers} selectedId={selectedMcpServerId} onSelect={setSelectedMcpServer} onAdd={() => {}} onRemove={removeMcpServer} />}
        {activeTab === 'execution' && <ExecutionList executions={filteredExecutions} currentExecutionId={currentExecutionId} onSelect={setCurrentExecution} />}
        {activeTab === 'settings' && <SettingsPanel />}
      </div>

      {modalAgente && (
        <div className="modal-overlay" onClick={() => setModalAgente(false)}>
          <div className="glass-deep modal-agente" role="dialog" aria-modal="true" aria-label={t("sidebar.newAgent")} onClick={(e) => e.stopPropagation()}>
            <h3>{t("sidebar.newAgent")}</h3>
            <form onSubmit={(e) => { e.preventDefault(); guardarAgente(); }}>
              <input
                autoFocus
                type="text"
                placeholder={t("sidebar.createAgent")}
                value={nombreAgente}
                onChange={(e) => setNombreAgente(e.target.value)}
                aria-label={t("sidebar.agentName")}
              />
              <select value={String(rolAgente)} onChange={(e) => setRolAgente(e.target.value as AgentRole)} aria-label={t("sidebar.agentRole")}>
                <option value="executor">executor</option>
                <option value="reviewer">reviewer</option>
                <option value="planner">planner</option>
                <option value="coordinator">coordinator</option>
                <option value="specialist">specialist</option>
              </select>
              <div className="modal-actions">
                <button type="button" onClick={() => setModalAgente(false)}>{t("sidebar.cancel")}</button>
                <button type="submit" className="btn-primary">{t("sidebar.save")}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

const SkillList: React.FC<{ skills: Skill[]; selectedId: string | null; onSelect: (id: string | null) => void; onAdd: () => void; onRemove: (id: string) => void }> = ({ skills, selectedId, onSelect, onAdd, onRemove }) => {
  const { t, formatNumber } = useI18n();
  return (
  <div className="sidebar-list">
    <div className="list-header"><h3>{t("sidebar.skills")}</h3><button className="add-btn" onClick={onAdd} title={t("sidebar.newSkill")}><Plus width={14} height={14} /></button></div>
    {skills.length === 0 ? <div className="empty-state"><p>{t("sidebar.noSkills")}</p><button className="btn-primary" onClick={onAdd}><Plus width={14} height={14} /> {t("sidebar.createSkill")}</button></div> : <ul className="item-list stagger">{skills.map(skill => (<li tabIndex={0} key={skill.id} className={`item ${selectedId === skill.id ? 'selected' : ''}`} onClick={() => onSelect(skill.id)}><div className="item-main"><span className="item-icon" style={{ color: '#10b981' }}><Zap width={14} height={14} /></span><div className="item-info"><span className="item-name">{skill.name}</span><span className="item-meta">v{skill.version} · {formatNumber(skill.metadata.usageCount)} {t("sidebar.uses")} · {formatNumber(skill.metadata.successRate * 100, { maximumFractionDigits: 0 })}%</span></div></div><div className="item-actions"><button className="item-action" onClick={(e) => { e.stopPropagation(); onSelect(null); }} title="Probar"><PlayIcon width={12} height={12} /></button><button className="item-action" onClick={(e) => { e.stopPropagation(); onSelect(skill.id); }} title="Editar"><Edit width={12} height={12} /></button><button className="item-action danger" onClick={(e) => { e.stopPropagation(); onRemove(skill.id); }} title="Eliminar"><Trash2 width={12} height={12} /></button></div></li>))}</ul>}
  </div>
  );
};

const AgentList: React.FC<{ agents: Agent[]; selectedId: string | null; onSelect: (id: string | null) => void; onAdd: () => void; onRemove: (id: string) => void }> = ({ agents, selectedId, onSelect, onAdd, onRemove }) => {
  const { t, formatNumber } = useI18n();
  const getStatusColor = (status: AgentStatus) => AGENT_STATUS_COLORS[status] || '#64748b';
  const getRoleColor = (role: AgentRole) => { if (typeof role === 'string') return AGENT_ROLE_COLORS[role] || '#6366f1'; return AGENT_ROLE_COLORS['custom'] || '#6366f1'; };
  return (
    <div className="sidebar-list"><div className="list-header"><h3>{t("sidebar.agents")}</h3><button className="add-btn" onClick={onAdd} title={t("sidebar.newAgent")}><Plus width={14} height={14} /></button></div>
    {agents.length === 0 ? <div className="empty-state"><p>{t("sidebar.noAgents")}</p><button className="btn-primary" onClick={onAdd}><Plus width={14} height={14} /> {t("sidebar.createAgent")}</button></div> : <ul className="item-list stagger">{agents.map(agent => (<li tabIndex={0} key={agent.id} className={`item ${selectedId === agent.id ? 'selected' : ''}`} onClick={() => onSelect(agent.id)}><div className="item-main"><div className={`agent-avatar${agent.status === 'working' ? ' agent-alive' : ''}`} style={{ backgroundColor: `${getRoleColor(agent.role)}20` }}><Bot width={16} height={16} style={{ color: getRoleColor(agent.role) }} /></div><div className="item-info"><div className="item-name-row"><span className="item-name">{agent.name}</span><span className="status-dot" style={{ backgroundColor: getStatusColor(agent.status) }} /></div><span className="item-meta">{typeof agent.role === 'string' ? agent.role : 'Custom'} · {formatNumber(agent.skills.length)} skills</span></div></div><div className="item-actions"><button className="item-action" onClick={(e) => { e.stopPropagation(); onSelect(agent.id); }} title="Chat"><ExternalLink width={12} height={12} /></button><button className="item-action" onClick={(e) => { e.stopPropagation(); onSelect(agent.id); }} title="Editar"><Edit width={12} height={12} /></button><button className="item-action danger" onClick={(e) => { e.stopPropagation(); onRemove(agent.id); }} title="Eliminar"><Trash2 width={12} height={12} /></button></div></li>))}</ul>}
  </div>
  );
};

const McpServerList: React.FC<{ servers: MCPServer[]; selectedId: string | null; onSelect: (id: string | null) => void; onAdd: () => void; onRemove: (id: string) => void }> = ({ servers, selectedId, onSelect, onAdd, onRemove }) => {
  const { t, formatNumber } = useI18n();
  const getStatusColor = (status: MCPServer['status']) => { switch (status) { case 'connected': return '#22c55e'; case 'connecting': return '#f59e0b'; case 'error': return '#ef4444'; case 'unauthorized': return '#ec4899'; default: return '#64748b'; }};
  return (
    <div className="sidebar-list"><div className="list-header"><h3>MCP</h3><button className="add-btn" onClick={onAdd} title={t("sidebar.newServer")}><Plus width={14} height={14} /></button></div>
    {servers.length === 0 ? <div className="empty-state"><p>{t("sidebar.noServers")}</p><button className="btn-primary" onClick={onAdd}><Plus width={14} height={14} /> {t("sidebar.addServer")}</button></div> : <ul className="item-list stagger">{servers.map(server => (<li tabIndex={0} key={server.id} className={`item ${selectedId === server.id ? 'selected' : ''}`} onClick={() => onSelect(server.id)}><div className="item-main"><span className="item-icon" style={{ color: '#06b6d4' }}><Plug width={14} height={14} /></span><div className="item-info"><div className="item-name-row"><span className="item-name">{server.name}</span><span className="status-dot" style={{ backgroundColor: getStatusColor(server.status) }} /></div><span className="item-meta">{formatNumber(server.tools.length)} tools · {server.transport}</span></div></div><div className="item-actions"><button className="item-action" onClick={(e) => { e.stopPropagation(); }} title="Conectar/Desconectar">{server.status === 'connected' ? <Pause width={12} height={12} /> : <PlayIcon width={12} height={12} />}</button><button className="item-action" onClick={(e) => { e.stopPropagation(); onSelect(server.id); }} title="Editar"><Edit width={12} height={12} /></button><button className="item-action danger" onClick={(e) => { e.stopPropagation(); onRemove(server.id); }} title="Eliminar"><Trash2 width={12} height={12} /></button></div></li>))}</ul>}
  </div>
  );
};

const ExecutionList: React.FC<{ executions: ExecutionContext[]; currentExecutionId: string | null; onSelect: (id: string | null) => void }> = ({ executions, currentExecutionId, onSelect }) => {
  const { t } = useI18n();
  const getStatusColor = (status: ExecutionContext['status']) => { switch (status) { case 'completed': return '#22c55e'; case 'running': return '#3b82f6'; case 'failed': return '#ef4444'; case 'cancelled': return '#f59e0b'; case 'waitingForHuman': return '#ec4899'; default: return '#64748b'; }};
  const formatTime = (ms?: number) => { if (!ms) return '0ms'; if (ms < 1000) return `${ms}ms`; return `${(ms / 1000).toFixed(1)}s`; };
  return (
    <div className="sidebar-list"><div className="list-header"><h3>{t("sidebar.executions")}</h3></div>
    {executions.length === 0 ? <div className="empty-state"><p>{t("sidebar.noExecutions")}</p></div> : <ul className="item-list stagger">{executions.map(exec => (<li tabIndex={0} key={exec.executionId} className={`item ${currentExecutionId === exec.executionId ? 'selected' : ''}`} onClick={() => onSelect(exec.executionId)}><div className="item-main"><div className="item-info"><div className="item-name-row"><span className="item-name">{exec.executionId.slice(0, 8)}</span><span className="status-dot" style={{ backgroundColor: getStatusColor(exec.status) }} /></div><span className="item-meta">Canvas: {exec.canvasId.slice(0, 8)} · {formatTime(exec.totalDurationMs)}</span></div></div><div className="item-actions"><button className="item-action" onClick={(e) => { e.stopPropagation(); }} title="Ver detalles"><Eye width={12} height={12} /></button><button className="item-action" onClick={(e) => { e.stopPropagation(); }} title="Reintentar"><RotateCcw width={12} height={12} /></button></div></li>))}</ul>}
  </div>
  );
};

const ThemeSelect: React.FC = () => {
  const { theme, setTheme } = useTheme();
  const { t } = useI18n();
  return (
    <select value={theme} onChange={(e) => setTheme(e.target.value as 'dark' | 'light' | 'system')} aria-label={t("header.theme")}>
      <option value="dark">{t("theme.dark")}</option>
      <option value="light">{t("theme.light")}</option>
      <option value="system">{t("theme.system")}</option>
    </select>
  );
};

const LangSelect: React.FC = () => {
  const { locale, setLocale: setL, t } = useI18n();
  return (
    <select value={locale} onChange={(e) => setL(e.target.value as Locale)} aria-label={t("header.language")}>
      {SUPPORTED_LOCALES.map((l: Locale) => <option key={l} value={l}>{l.toUpperCase()}</option>)}
    </select>
  );
};

const SettingsPanel: React.FC = () => {
  const { t } = useI18n();
  return (
    <div className="sidebar-list">
      <div className="list-header"><h3>{t("sidebar.settings")}</h3></div>
      <div className="settings-section"><h4>Canvas</h4><div className="setting-item"><label><input type="checkbox" defaultChecked /> {t("sidebar.autoSave")}</label></div><div className="setting-item"><label>{t("sidebar.executionMode")}<select defaultValue="dag"><option value="dag">DAG</option><option value="sequential">{t("sidebar.sequential")}</option><option value="parallel">{t("sidebar.parallel")}</option></select></label></div></div>
      <div className="settings-section"><h4>Apariencia</h4><div className="setting-item"><label>{t("header.theme")}: <ThemeSelect /></label></div><div className="setting-item"><label>{t("header.language")}: <LangSelect /></label></div></div>
    </div>
  );
};

export default Sidebar;
