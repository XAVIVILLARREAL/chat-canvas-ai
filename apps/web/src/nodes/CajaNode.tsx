import { memo } from 'react'
import { Handle, Position, type NodeProps } from '@xyflow/react'

export type CajaNodeData = { label: string; color?: string }

function CajaNode({ data, selected }: NodeProps) {
  const d = data as CajaNodeData
  return (
    <div
      className="min-w-[160px] max-w-[280px] rounded-xl border bg-slate-900/90 px-4 py-3 text-sm shadow-lg backdrop-blur"
      style={{
        borderColor: selected ? '#38bdf8' : (d.color ?? '#334155'),
        boxShadow: selected ? '0 0 0 2px rgba(56,189,248,0.3)' : undefined,
      }}
    >
      <Handle type="target" position={Position.Top} className="!bg-slate-500" />
      <div className="font-medium text-slate-200">{d.label || 'Caja'}</div>
      <Handle type="source" position={Position.Bottom} className="!bg-slate-500" />
    </div>
  )
}

export default memo(CajaNode)
