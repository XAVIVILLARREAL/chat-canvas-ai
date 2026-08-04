import { useCallback } from 'react'
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

const nodeTypes: NodeTypes = {
  caja: CajaNode,
  ventanita: VentanitaNode,
}

export default function App() {
  const nodes = useCanvaStore((s) => s.nodes)
  const edges = useCanvaStore((s) => s.edges)
  const setNodes = useCanvaStore((s) => s.setNodes)
  const setEdges = useCanvaStore((s) => s.setEdges)

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
    </div>
  )
}
