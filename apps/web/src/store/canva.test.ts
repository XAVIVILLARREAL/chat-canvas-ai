import { describe, expect, it } from 'vitest'
import { useCanvaStore } from './canva'

describe('canva store', () => {
  it('adds a ventanita node', () => {
    const s = useCanvaStore.getState()
    const before = s.nodes.length
    s.addNode({
      id: 'n1',
      type: 'ventanita',
      position: { x: 0, y: 0 },
      data: { titulo: 'Agente', status: 'idle' },
    })
    const after = useCanvaStore.getState().nodes
    expect(after.length).toBe(before + 1)
    expect(after[after.length - 1]?.id).toBe('n1')
  })

  it('opens and closes a ventanita', () => {
    const s = useCanvaStore.getState()
    s.openVentanita('n1')
    expect(useCanvaStore.getState().selectedVentanitaId).toBe('n1')
    s.closeVentanita()
    expect(useCanvaStore.getState().selectedVentanitaId).toBeNull()
  })
})
