export type VentanitaStatus = 'idle' | 'thinking' | 'listo' | 'error'

export type VentanitaNodeData = {
  titulo: string
  proyecto?: string
  status: VentanitaStatus
  ultimaEvidencia?: string | null
}

export type ChatChunk = {
  id: string
  content: string
}
