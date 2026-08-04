import { useCallback, useState } from 'react'
import {
  ReactFlow,
  Background,
  Controls,
  MiniMap,
  type NodeTypes,
  type OnNodesChange,
  type OnEdgesChange,
  type NodeChange,
  type EdgeChange,
  applyNodeChanges,
  applyEdgeChanges,
  type Connection,
  addEdge,
} from '@xyflow/react'
import { useCanvaStore } from './store/canva'
import CajaNode from './nodes/CajaNode'
import VentanitaNode from './nodes/VentanitaNode'
import Toolbar from './components/Toolbar'
import ChatWindow from './components/ChatWindow'
import KanbanPanel from './components/KanbanPanel'

const nodeTypes: NodeTypes = {
  caja: CajaNode,
  ventanita: VentanitaNode,
}

export default function App() {
  const nodes = useCanvaStore((s) => s.nodes)
  const edges = useCanvaStore((s) => s.edges)
  const setNodes = useCanvaStore((s) => s.setNodes)
  const setEdges = useCanvaStore((s) => s.setEdges)
  const [kanbanOpen, setKanbanOpen] = useState(false)

  const onNodesChange = useCallback<OnNodesChange>(
    (changes: NodeChange[]) => setNodes(applyNodeChanges(changes, nodes)),
    [nodes, setNodes],
  )

  const onEdgesChange = useCallback<OnEdgesChange>(
    (changes: EdgeChange[]) => setEdges(applyEdgeChanges(changes, edges)),
    [edges, setEdges],
  )

  const onConnect = useCallback(
    (conn: Connection) => setEdges(addEdge(conn, edges)),
    [edges, setEdges],
  )

  return (
    <div className="relative h-full w-full">
      <ReactFlow
        nodes={nodes}
        edges={edges}
        nodeTypes={nodeTypes}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        fitView
        minZoom={0.2}
        maxZoom={2.5}
        proOptions={{ hideAttribution: true }}
      >
        <Background gap={20} size={1} color="#1e293b" />
        <Controls />
        <MiniMap
          nodeColor="#334155"
          maskColor="rgba(15,23,42,0.7)"
          className="!bottom-4 !right-4"
        />
      </ReactFlow>

      <Toolbar />
      <ChatWindow />
      {kanbanOpen ? <KanbanPanel /> : null}
      <button
        onClick={() => setKanbanOpen((v) => !v)}
        className="pointer-events-auto absolute bottom-4 left-4 z-20 rounded-xl border border-slate-800 bg-slate-900/95 px-3 py-2 text-sm text-slate-200 shadow-2xl backdrop-blur hover:bg-slate-800"
        title="Tablero de la empresa"
      >
        📋 {kanbanOpen ? 'Cerrar' : 'Empresa'}
      </button>
    </div>
  )
}
