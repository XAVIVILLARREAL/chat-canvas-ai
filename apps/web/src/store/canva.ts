import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { Node, Edge } from '@xyflow/react'
import type { VentanitaNodeData } from '../types'

const STORAGE_KEY = 'empresa-canva-v1'

export type CanvaState = {
  nodes: Node[]
  edges: Edge[]
  selectedVentanitaId: string | null
  setNodes: (nodes: Node[]) => void
  setEdges: (edges: Edge[]) => void
  addNode: (node: Node) => void
  openVentanita: (id: string) => void
  closeVentanita: () => void
  setVentanitaStatus: (id: string, status: VentanitaNodeData['status']) => void
  setVentanitaSession: (id: string, sessionId: string) => void
  setVentanitaReply: (id: string, text: string) => void
}

let idCounter = 0
const nextId = () => `n${Date.now().toString(36)}${(idCounter++).toString(36)}`

export const useCanvaStore = create<CanvaState>()(
  persist(
    (set, get) => ({
      nodes: [],
      edges: [],
      selectedVentanitaId: null,

      setNodes: (nodes) => set({ nodes }),
      setEdges: (edges) => set({ edges }),

      addNode: (node) =>
        set({
          nodes: [...get().nodes, { ...node, id: node.id ?? nextId() }],
        }),

      openVentanita: (id) => set({ selectedVentanitaId: id }),
      closeVentanita: () => set({ selectedVentanitaId: null }),

      setVentanitaStatus: (id, status) =>
        set({
          nodes: get().nodes.map((n) =>
            n.id === id && n.type === 'ventanita'
              ? { ...n, data: { ...(n.data as VentanitaNodeData), status } }
              : n,
          ),
        }),

      setVentanitaSession: (id, sessionId) =>
        set({
          nodes: get().nodes.map((n) =>
            n.id === id && n.type === 'ventanita'
              ? { ...n, data: { ...(n.data as VentanitaNodeData), sessionId } }
              : n,
          ),
        }),

      setVentanitaReply: (id, text) =>
        set({
          nodes: get().nodes.map((n) =>
            n.id === id && n.type === 'ventanita'
              ? { ...n, data: { ...(n.data as VentanitaNodeData), ultimaRespuesta: text } }
              : n,
          ),
        }),
    }),
    {
      name: STORAGE_KEY,
      partialize: (s) => ({ nodes: s.nodes, edges: s.edges }),
    },
  ),
)
