import React, { useCallback, useEffect, useState } from 'react';
import {
  ReactFlow,
  Connection,
  NodeTypes,
  EdgeTypes,
  useNodesState,
  useEdgesState,
  useReactFlow,
  Background,
  Controls,
  MiniMap,
  Panel,
  OnNodesChange,
  OnEdgesChange,
  OnConnect,
  OnConnectStart,
  OnConnectEnd,
  Handle,
  Position as HandlePosition,
  Node,
  Edge,
  Viewport as RFViewport,
  type PanelPosition,
  ConnectionMode,
} from '@xyflow/react';
import { 
  X, ChevronLeft,
  ZoomIn, ZoomOut, RotateCcw, Undo2, Redo2,
  AlignCenter, AlignHorizontalDistributeCenter,
  CheckCircle, Loader2,
} from 'lucide-react';
import { useCanvasStore } from '../stores/canvas-store';
import { 
  NODE_TYPE_CONFIG, 
  EDGE_TYPE_COLORS, 
  type CanvasNode, 
  type CanvasEdge, 
  type NodeType,
} from '../types';
import '@xyflow/react/dist/style.css';
import './Canvas.css';

type CanvasNodeData = { canvasNode: CanvasNode } & Record<string, unknown>;
type RFNode = Node<CanvasNodeData>;
type RFEdge = Edge;

function canvasNodeToRFNode(canvasNode: CanvasNode): RFNode {
  return {
    id: canvasNode.id,
    type: 'custom',
    position: canvasNode.position,
    data: { canvasNode },
    sourcePosition: HandlePosition.Right,
    targetPosition: HandlePosition.Left,
  };
}

function canvasEdgeToRFEdge(canvasEdge: CanvasEdge): RFEdge {
  return {
    id: canvasEdge.id,
    source: canvasEdge.source,
    target: canvasEdge.target,
    sourceHandle: canvasEdge.sourcePort,
    targetHandle: canvasEdge.targetPort,
    type: 'custom',
    data: { edgeType: canvasEdge.edgeType, condition: canvasEdge.condition },
    style: { stroke: EDGE_TYPE_COLORS[canvasEdge.edgeType] || '#6366f1' },
  };
}

const CustomNode: React.FC<{ data: CanvasNodeData; selected?: boolean }> = ({ data, selected }) => {
  const { canvasNode } = data;
  const config = NODE_TYPE_CONFIG[canvasNode.nodeType];
  const { removeNode, duplicateNode } = useCanvasStore.getState();
  
  const handleDelete = useCallback(() => removeNode(canvasNode.id), [removeNode, canvasNode.id]);
  const handleDuplicate = useCallback(() => duplicateNode(canvasNode.id), [duplicateNode, canvasNode.id]);
  
  return (
    <div 
      className={`custom-node ${selected ? 'selected' : ''} category-${canvasNode.metadata.category}`}
      style={{ 
        width: 240,
        borderColor: selected ? config.color : 'transparent',
        boxShadow: selected ? `0 0 0 2px ${config.color}40, 0 8px 32px ${config.color}20` : undefined,
      }}
    >
      <div className="node-header" style={{ borderTopColor: config.color }}>
        <div className="node-icon" style={{ backgroundColor: `${config.color}20`, color: config.color }}>
          <config.icon width={14} height={14} />
        </div>
        <div className="node-title-area">
          <span className="node-label">{canvasNode.metadata.label}</span>
          <span className="node-type-badge" style={{ backgroundColor: `${config.color}20`, color: config.color }}>
            {config.label}
          </span>
        </div>
        <div className="node-actions">
          <button className="node-action-btn" onClick={() => console.log('Test:', canvasNode.id)} title="Test">
            <CheckCircle width={12} height={12} />
          </button>
          <button className="node-action-btn" onClick={handleDuplicate} title="Duplicate">
            <svg width={12} height={12} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>
          </button>
          <button className="node-action-btn danger" onClick={handleDelete} title="Delete">
            <svg width={12} height={12} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg>
          </button>
        </div>
      </div>
      <div className="node-body">
        <div className="node-ports inputs">
          {canvasNode.inputs.map((port) => (
            <div key={port.id} className="port-wrapper">
              <Handle id={port.id} type="target" position={HandlePosition.Left} className={`port-handle ${port.required ? 'required' : ''}`}>
                <div className="port-indicator" style={{ backgroundColor: port.required ? '#ef4444' : '#64748b' }} />
              </Handle>
              <span className="port-label" title={`${port.name} (${port.dataType})${port.required ? ' *' : ''}`}>{port.name}</span>
            </div>
          ))}
        </div>
        <div className="node-content">
          <div className="node-description">{canvasNode.metadata.description}</div>
          {canvasNode.config.code && <div className="node-code-preview"><span className="code-label">Code:</span><pre>{canvasNode.config.code.slice(0, 100)}...</pre></div>}
          {canvasNode.config.promptTemplate && <div className="node-prompt-preview"><span className="code-label">Prompt:</span><pre>{canvasNode.config.promptTemplate.slice(0, 100)}...</pre></div>}
          {canvasNode.config.mcpServerId && <div className="node-mcp-info"><svg width={12} height={12} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}><path d="M18.36 6.64A9 9 0 0 1 20.77 15"></path><path d="M6.16 6.16a9 9 0 0 0-4.5 16.5"></path><path d="M12 12h.01"></path></svg><span>MCP: {canvasNode.config.mcpToolName || canvasNode.config.mcpServerId}</span></div>}
          {canvasNode.config.skillId && <div className="node-skill-info"><svg width={12} height={12} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon></svg><span>Skill: {canvasNode.config.skillId}</span></div>}
        </div>
        <div className="node-ports outputs">
          {canvasNode.outputs.map((port) => (
            <div key={port.id} className="port-wrapper">
              <span className="port-label" title={`${port.name} (${port.dataType})`}>{port.name}</span>
              <Handle id={port.id} type="source" position={HandlePosition.Right} className="port-handle">
                <div className="port-indicator" style={{ backgroundColor: '#64748b' }} />
              </Handle>
            </div>
          ))}
        </div>
      </div>
      <div className="node-footer"><span className="node-id">{canvasNode.id.slice(0, 8)}</span></div>
    </div>
  );
};

const CustomEdge: React.FC<{ data?: { edgeType?: string; condition?: string }; style?: React.CSSProperties }> = ({ data, style }) => {
  const edgeType = data?.edgeType || 'data';
  const condition = data?.condition;
  const color = EDGE_TYPE_COLORS[edgeType as keyof typeof EDGE_TYPE_COLORS] || '#6366f1';
  const dashArray = edgeType === 'conditional' ? '5,5' : edgeType === 'error' ? '2,4' : 'none';
  return (
    <>
      <path className="custom-edge-path" style={{ ...style, stroke: color, strokeWidth: 2, strokeDasharray: dashArray, markerEnd: edgeType === 'data' || edgeType === 'control' ? `url(#arrowhead-${color.replace('#', '')})` : undefined }} />
      {condition && <text className="edge-condition-label" x="50%" y="-10" textAnchor="middle" fill={color} fontSize="10">{condition}</text>}
    </>
  );
};

const nodeTypes: NodeTypes = { custom: CustomNode };
const edgeTypes: EdgeTypes = { custom: CustomEdge };

const miniMapNodeColor = ({ data }: { data: Record<string, unknown> }) => {
  const canvasNode = (data as CanvasNodeData)?.canvasNode;
  return canvasNode ? NODE_TYPE_CONFIG[canvasNode.nodeType]?.color || '#6366f1' : '#6366f1';
};

export const Canvas: React.FC = () => {
  const {
    currentCanvas,
    selectedNodeIds,
    selectedEdgeIds,
    viewport,
    nodePanelOpen,
    nodePanelNodeId,
    removeNode,
    updateNodePosition,
    addEdge,
    removeEdge,
    clearSelection,
    setViewport,
    fitView,
    undo,
    redo,
    canUndo,
    canRedo,
    createNodeFromType,
    loading,
  } = useCanvasStore();

  const [nodes, setNodes, onNodesChange] = useNodesState<RFNode>(currentCanvas?.nodes.map(canvasNodeToRFNode) || []);
  const [edges, setEdges, onEdgesChange] = useEdgesState<RFEdge>(currentCanvas?.edges.map(canvasEdgeToRFEdge) || []);
  const reactFlowInstance = useReactFlow();
  
  const [showGrid, setShowGrid] = useState(true);
  const [snapToGrid, setSnapToGrid] = useState(true);
  const [connectionMode, setConnectionMode] = useState<'loose' | 'strict'>('strict');
  const [miniMapOpen] = useState(true);
  const [contextMenu, setContextMenu] = useState<{ x: number; y: number } | null>(null);

  useEffect(() => {
    if (currentCanvas) {
      setNodes(currentCanvas.nodes.map(canvasNodeToRFNode));
      setEdges(currentCanvas.edges.map(canvasEdgeToRFEdge));
      if (reactFlowInstance) {
        reactFlowInstance.setViewport({ x: currentCanvas.viewport.x, y: currentCanvas.viewport.y, zoom: currentCanvas.viewport.zoom }, { duration: 0 });
      }
    }
  }, [currentCanvas?.id, setNodes, setEdges, reactFlowInstance]);

  const onViewportChange = useCallback((newViewport: RFViewport) => setViewport({ x: newViewport.x, y: newViewport.y, zoom: newViewport.zoom }), [setViewport]);

  const handleNodesChange: OnNodesChange<RFNode> = useCallback((changes) => {
    onNodesChange(changes);
    changes.forEach(change => { if (change.type === 'position' && change.position) updateNodePosition(change.id, change.position); });
  }, [onNodesChange, updateNodePosition]);

  const handleEdgesChange: OnEdgesChange = useCallback((changes) => onEdgesChange(changes), [onEdgesChange]);

  const handleConnect: OnConnect = useCallback((connection: Connection) => {
    if (connection.source && connection.target && connection.sourceHandle && connection.targetHandle) {
      addEdge({ id: `edge-${connection.source}-${connection.sourceHandle}-${connection.target}-${connection.targetHandle}`, source: connection.source, sourcePort: connection.sourceHandle, target: connection.target, targetPort: connection.targetHandle, edgeType: 'data' });
    }
  }, [addEdge]);

  const handleConnectStart: OnConnectStart = useCallback(() => setConnectionMode('loose'), []);
  const handleConnectEnd: OnConnectEnd = useCallback(() => setConnectionMode('strict'), []);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return;
      if ((e.metaKey || e.ctrlKey) && e.key === 'z') { e.preventDefault(); e.shiftKey ? redo() : undo(); }
      if ((e.metaKey || e.ctrlKey) && e.key === 'y') { e.preventDefault(); redo(); }
      if (e.key === 'Delete' || e.key === 'Backspace') { selectedNodeIds.forEach(removeNode); selectedEdgeIds.forEach(removeEdge); }
      if (e.key === 'Escape') { clearSelection(); setContextMenu(null); }
      if (e.key === 'f') fitView();
      if (e.key === 'g') setShowGrid(!showGrid);
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [selectedNodeIds, selectedEdgeIds, removeNode, removeEdge, clearSelection, undo, redo, fitView, showGrid]);

  const handleContextMenu = (e: React.MouseEvent) => { e.preventDefault(); if (e.target === e.currentTarget) setContextMenu({ x: e.clientX, y: e.clientY }); };
  const closeContextMenu = () => setContextMenu(null);
  const handleAddNodeFromMenu = (nodeType: NodeType) => { if (contextMenu && reactFlowInstance) { createNodeFromType(nodeType, reactFlowInstance.screenToFlowPosition({ x: contextMenu.x, y: contextMenu.y })); } closeContextMenu(); };

  if (!currentCanvas) return <div className="canvas-loading">Loading canvas...</div>;

  return (
    <div className="canvas-container" onContextMenu={handleContextMenu}>
      <div className="canvas-toolbar">
        <div className="toolbar-group">
          <button className="toolbar-btn" onClick={undo} disabled={!canUndo()} title="Undo (Ctrl+Z)"><Undo2 width={16} height={16} /></button>
          <button className="toolbar-btn" onClick={redo} disabled={!canRedo()} title="Redo (Ctrl+Y)"><Redo2 width={16} height={16} /></button>
        </div>
        <div className="toolbar-divider" />
        <div className="toolbar-group">
          <button className="toolbar-btn" onClick={() => reactFlowInstance?.setViewport({ x: 0, y: 0, zoom: 1 }, { duration: 300 })} title="Fit View (F)"><AlignCenter width={16} height={16} /></button>
          <button className="toolbar-btn" onClick={() => reactFlowInstance?.setViewport({ x: 0, y: 0, zoom: reactFlowInstance.getZoom() }, { duration: 300 })} title="Center View"><AlignHorizontalDistributeCenter width={16} height={16} /></button>
        </div>
        <div className="toolbar-divider" />
        <div className="toolbar-group">
          <button className="toolbar-btn" onClick={() => reactFlowInstance?.setViewport({ x: reactFlowInstance.getViewport().x, y: reactFlowInstance.getViewport().y, zoom: Math.min(3, reactFlowInstance.getZoom() + 0.1) })} title="Zoom In (+)"><ZoomIn width={16} height={16} /></button>
          <button className="toolbar-btn" onClick={() => reactFlowInstance?.setViewport({ x: reactFlowInstance.getViewport().x, y: reactFlowInstance.getViewport().y, zoom: Math.max(0.1, reactFlowInstance.getZoom() - 0.1) })} title="Zoom Out (-)"><ZoomOut width={16} height={16} /></button>
          <button className="toolbar-btn" onClick={() => reactFlowInstance?.setViewport({ x: reactFlowInstance.getViewport().x, y: reactFlowInstance.getViewport().y, zoom: 1 })} title="Reset Zoom (1)"><RotateCcw width={16} height={16} /></button>
        </div>
        <div className="toolbar-divider" />
        <div className="toolbar-group">
          <label className="toolbar-toggle" title="Toggle Grid (G)"><input type="checkbox" checked={showGrid} onChange={(e) => setShowGrid(e.target.checked)} /><span>Grid</span></label>
          <label className="toolbar-toggle" title="Snap to Grid"><input type="checkbox" checked={snapToGrid} onChange={(e) => setSnapToGrid(e.target.checked)} /><span>Snap</span></label>
        </div>
        <div className="toolbar-spacer" />
        <div className="toolbar-group"><span className="viewport-info">{Math.round(viewport.zoom * 100)}% • {Math.round(viewport.x)}, {Math.round(viewport.y)}</span></div>
      </div>

      <ReactFlow
        nodes={nodes} edges={edges}
        onNodesChange={handleNodesChange} onEdgesChange={handleEdgesChange}
        onConnect={handleConnect} onConnectStart={handleConnectStart} onConnectEnd={handleConnectEnd}
        onViewportChange={onViewportChange}
        nodeTypes={nodeTypes} edgeTypes={edgeTypes}
        connectionMode={connectionMode as ConnectionMode}
        defaultViewport={{ x: viewport.x, y: viewport.y, zoom: viewport.zoom }}
        snapToGrid={snapToGrid} snapGrid={[20, 20]}
        nodesDraggable={true} nodesConnectable={true} elementsSelectable={true}
        selectNodesOnDrag={true}
        panOnScroll={true} panOnScrollSpeed={0.5}
        zoomOnScroll={true} zoomOnPinch={true}
        minZoom={0.1} maxZoom={3}
        onlyRenderVisibleElements={true} attributionPosition="bottom-right"
      >
        <Background color="#64748b" gap={20} size={1} style={{ opacity: showGrid ? 0.15 : 0 }} />
        <Controls showZoom={false} showFitView={false} showInteractive={false} />
        {miniMapOpen && <MiniMap nodeColor={miniMapNodeColor} maskColor="oklch(0.08 0.01 260 / 0.8)" />}
      </ReactFlow>

      <Panel position={"left" as PanelPosition} className="node-palette-panel">
        <div className="palette-header"><h3>Nodos</h3><button className="palette-close" onClick={() => useCanvasStore.getState().setSidebarTab('nodes')}><ChevronLeft width={16} height={16} /></button></div>
        <div className="palette-search"><input type="text" placeholder="Buscar nodos..." /></div>
        <div className="palette-categories">
          {['trigger', 'action', 'logic', 'data', 'ai', 'mcp', 'agent', 'human', 'output'].map(category => (
            <details key={category} className="palette-category" open>
              <summary className="palette-category-title">{category}</summary>
              <div className="palette-nodes">
                {Object.entries(NODE_TYPE_CONFIG).filter(([, config]) => config.category === category).map(([type, config]) => (
                  <button key={type} className="palette-node-btn" onClick={() => handleAddNodeFromMenu(type as NodeType)} draggable onDragStart={(e) => { e.dataTransfer.setData('application/x-node-type', type); e.dataTransfer.effectAllowed = 'copy'; }}>
                    <config.icon className="palette-node-icon" style={{ color: config.color }} width={18} height={18} />
                    <span>{config.label}</span>
                  </button>
                ))}
              </div>
            </details>
          ))}
        </div>
      </Panel>

      <Panel position={"right" as PanelPosition} className="properties-panel" style={{ width: nodePanelOpen ? 360 : 0 }}>
        {nodePanelOpen && nodePanelNodeId && <NodePropertiesPanel nodeId={nodePanelNodeId} onClose={() => useCanvasStore.getState().closeNodePanel()} />}
      </Panel>

      {contextMenu && (
        <div className="context-menu" style={{ left: contextMenu.x, top: contextMenu.y }} onClick={closeContextMenu}>
          <div className="context-menu-section"><h4>Agregar Nodo</h4>{Object.entries(NODE_TYPE_CONFIG).map(([type, config]) => (<button key={type} className="context-menu-item" onClick={() => handleAddNodeFromMenu(type as NodeType)}><config.icon width={14} height={14} style={{ color: config.color }} />{config.label}</button>))}</div>
          <div className="context-menu-divider" />
          <button className="context-menu-item" onClick={fitView}><AlignCenter width={14} height={14} /> Ajustar Vista</button>
          <button className="context-menu-item" onClick={() => reactFlowInstance?.setViewport({ x: 0, y: 0, zoom: 1 }, { duration: 300 })}><AlignHorizontalDistributeCenter width={14} height={14} /> Centrar</button>
        </div>
      )}

      <div className="canvas-status-bar">
        <div className="status-item"><span>{nodes.length} nodos</span></div>
        <div className="status-item"><span>{edges.length} conexiones</span></div>
        <div className="status-item"><span>{selectedNodeIds.length} seleccionados</span></div>
        {loading && <div className="status-item loading"><Loader2 width={14} height={14} className="spinning" /> Ejecutando...</div>}
      </div>
    </div>
  );
};

const NodePropertiesPanel: React.FC<{ nodeId: string; onClose: () => void }> = ({ nodeId, onClose }) => {
  const { currentCanvas, updateNode, updateNodeConfig, closeNodePanel } = useCanvasStore();
  const node = currentCanvas?.nodes.find(n => n.id === nodeId);
  if (!node) return null;
  const config = NODE_TYPE_CONFIG[node.nodeType];
  return (
    <div className="properties-panel-content">
      <div className="properties-header"><div className="node-type-badge" style={{ backgroundColor: `${config.color}20`, color: config.color }}><config.icon width={16} height={16} /> {config.label}</div><button className="close-btn" onClick={onClose}><X width={16} height={16} /></button></div>
      <div className="properties-section"><h4>Configuración Básica</h4><div className="form-group"><label>Etiqueta</label><input value={node.metadata.label} onChange={(e) => updateNode(nodeId, { metadata: { ...node.metadata, label: e.target.value } })} /></div><div className="form-group"><label>Descripción</label><textarea value={node.metadata.description} onChange={(e) => updateNode(nodeId, { metadata: { ...node.metadata, description: e.target.value } })} rows={3} /></div><div className="form-group"><label>Color</label><input type="color" value={node.metadata.color} onChange={(e) => updateNode(nodeId, { metadata: { ...node.metadata, color: e.target.value } })} /></div></div>
      <div className="properties-section"><h4>Configuración del Nodo</h4>{node.nodeType === 'code' && <div className="form-group"><label>Código (TypeScript)</label><textarea value={node.config.code || ''} onChange={(e) => updateNodeConfig(nodeId, { code: e.target.value })} rows={10} className="code-editor" spellCheck={false} /></div>}{node.nodeType === 'llmCall' && (<><div className="form-group"><label>Modelo</label><select value={node.config.model || 'gpt-4o'} onChange={(e) => updateNodeConfig(nodeId, { model: e.target.value })}><option value="gpt-4o">GPT-4o</option><option value="gpt-4o-mini">GPT-4o Mini</option><option value="claude-3-5-sonnet">Claude 3.5 Sonnet</option><option value="gemini-1.5-pro">Gemini 1.5 Pro</option></select></div><div className="form-group"><label>Temperatura: {node.config.temperature || 0.7}</label><input type="range" min="0" max="2" step="0.1" value={node.config.temperature || 0.7} onChange={(e) => updateNodeConfig(nodeId, { temperature: parseFloat(e.target.value) })} /></div><div className="form-group"><label>Max Tokens</label><input type="number" value={node.config.maxTokens || 4096} onChange={(e) => updateNodeConfig(nodeId, { maxTokens: parseInt(e.target.value) })} /></div><div className="form-group"><label>Prompt Template</label><textarea value={node.config.promptTemplate || ''} onChange={(e) => updateNodeConfig(nodeId, { promptTemplate: e.target.value })} rows={8} className="code-editor" /></div></>)} {node.nodeType === 'mcpCall' && (<><div className="form-group"><label>MCP Server</label><input value={node.config.mcpServerId || ''} onChange={(e) => updateNodeConfig(nodeId, { mcpServerId: e.target.value })} placeholder="Seleccionar servidor MCP..." /></div><div className="form-group"><label>Herramienta</label><input value={node.config.mcpToolName || ''} onChange={(e) => updateNodeConfig(nodeId, { mcpToolName: e.target.value })} placeholder="Nombre de la herramienta" /></div></>)} {node.nodeType === 'skillInvoke' && <div className="form-group"><label>Skill ID</label><input value={node.config.skillId || ''} onChange={(e) => updateNodeConfig(nodeId, { skillId: e.target.value })} placeholder="ID de la skill" /></div>} {node.nodeType === 'conditional' && <div className="form-group"><label>Condición (expresión JS)</label><textarea value={node.config.condition || ''} onChange={(e) => updateNodeConfig(nodeId, { condition: e.target.value })} rows={3} className="code-editor" placeholder="return inputs.value > 10;" /></div>} {node.nodeType === 'loop' && (<><div className="form-group"><label>Tipo de Bucle</label><select value={node.config.loopConfig?.loopType || 'forEach'} onChange={(e) => updateNodeConfig(nodeId, { loopConfig: { ...node.config.loopConfig!, loopType: e.target.value as any } })}><option value="forEach">For Each</option><option value="while">While</option><option value="times">Times</option></select></div><div className="form-group"><label>Max Iteraciones</label><input type="number" value={node.config.loopConfig?.maxIterations || 100} onChange={(e) => updateNodeConfig(nodeId, { loopConfig: { ...node.config.loopConfig!, maxIterations: parseInt(e.target.value) } })} /></div></>)} {node.nodeType === 'trigger' && (<><div className="form-group"><label>Tipo de Trigger</label><select value={node.config.triggerConfig?.triggerType || 'manual'} onChange={(e) => updateNodeConfig(nodeId, { triggerConfig: { ...node.config.triggerConfig!, triggerType: e.target.value as any } })}><option value="manual">Manual</option><option value="cron">Cron</option><option value="webhook">Webhook</option><option value="event">Evento</option><option value="mcpNotification">Notificación MCP</option></select></div>{node.config.triggerConfig?.triggerType === 'cron' && <div className="form-group"><label>Expresión Cron</label><input value={node.config.triggerConfig?.cronExpression || ''} onChange={(e) => updateNodeConfig(nodeId, { triggerConfig: { ...node.config.triggerConfig!, cronExpression: e.target.value } })} placeholder="0 0 * * *" /></div>}</>)}</div>
      <div className="properties-section"><h4>Puertos de Entrada</h4>{node.inputs.map(port => (<div key={port.id} className="port-config"><span className="port-name">{port.name}</span><span className="port-type">{port.dataType}</span>{port.required && <span className="required-badge">*</span>}</div>))}</div>
      <div className="properties-section"><h4>Puertos de Salida</h4>{node.outputs.map(port => (<div key={port.id} className="port-config"><span className="port-name">{port.name}</span><span className="port-type">{port.dataType}</span></div>))}</div>
      <div className="properties-actions"><button className="btn-secondary"><svg width={14} height={14} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}><polygon points="5 3 19 12 5 21 5 3"></polygon></svg> Probar Nodo</button><button className="btn-danger" onClick={() => { useCanvasStore.getState().removeNode(nodeId); closeNodePanel(); }}><svg width={14} height={14} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg> Eliminar</button></div>
    </div>
  );
};

export default Canvas;
