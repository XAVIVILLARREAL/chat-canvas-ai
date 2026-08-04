import type { Node } from '@xyflow/react'
import { useCanvaStore } from '../store/canva'
import type { VentanitaNodeData } from '../types'

export type ToolKind = 'caja' | 'ventanita'

const TOOLS: { kind: ToolKind; label: string; icon: string; hint: string }[] = [
  { kind: 'ventanita', label: 'Agente', icon: '🤖', hint: 'Sesión de agente (click para hablar)' },
  { kind: 'caja', label: 'Caja', icon: '▭', hint: 'Caja de texto libre' },
]

export default function Toolbar() {
  const addNode = useCanvaStore((s) => s.addNode)

  function add(kind: ToolKind) {
    const pos = { x: 120 + Math.random() * 120, y: 120 + Math.random() * 120 }
    const node: Node =
      kind === 'ventanita'
        ? {
            id: crypto.randomUUID(),
            type: 'ventanita',
            position: pos,
            data: { titulo: 'Agente', proyecto: 'proyecto', status: 'idle' } satisfies VentanitaNodeData,
          }
        : {
            id: crypto.randomUUID(),
            type: 'caja',
            position: pos,
            data: { label: 'Nueva caja' },
          }
    addNode(node)
  }

  return (
    <div className="pointer-events-auto absolute left-4 top-4 z-20 flex flex-col gap-2 rounded-2xl border border-slate-800 bg-slate-900/95 p-2 shadow-2xl backdrop-blur">
      <div className="px-2 pb-1 text-[10px] font-semibold uppercase tracking-wider text-slate-500">
        Insertar
      </div>
      {TOOLS.map((t) => (
        <button
          key={t.kind}
          onClick={() => add(t.kind)}
          title={t.hint}
          className="flex items-center gap-2 rounded-xl px-3 py-2 text-sm text-slate-200 transition hover:bg-slate-800 hover:text-white"
        >
          <span className="text-base">{t.icon}</span>
          {t.label}
        </button>
      ))}
    </div>
  )
}
