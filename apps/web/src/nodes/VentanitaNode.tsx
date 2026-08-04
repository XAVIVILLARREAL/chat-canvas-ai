import { memo } from 'react'
import { Handle, Position, type NodeProps } from '@xyflow/react'
import type { VentanitaNodeData } from '../types'
import { useCanvaStore } from '../store/canva'

const STATUS_DOT: Record<VentanitaNodeData['status'], string> = {
  idle: 'bg-slate-400',
  thinking: 'bg-amber-400 animate-pulse',
  listo: 'bg-emerald-400',
  error: 'bg-rose-500',
}

const STATUS_TEXT: Record<VentanitaNodeData['status'], string> = {
  idle: 'listo',
  thinking: 'pensando…',
  listo: 'listo',
  error: 'error',
}

function VentanitaNode({ id, data, selected }: NodeProps) {
  const d = data as VentanitaNodeData
  const openVentanita = useCanvaStore((s) => s.openVentanita)

  return (
    <div
      onClick={() => openVentanita(id)}
      className="w-56 cursor-pointer select-none rounded-2xl border bg-slate-900/95 p-3 shadow-xl backdrop-blur transition-transform hover:-translate-y-0.5"
      style={{
        borderColor: selected ? '#38bdf8' : d.status === 'thinking' ? '#fbbf24' : '#334155',
      }}
    >
      <Handle type="target" position={Position.Top} className="!bg-slate-500" />
      <div className="flex items-center gap-2">
        <span className={`h-2.5 w-2.5 rounded-full ${STATUS_DOT[d.status]}`} />
        <span className="flex-1 truncate text-sm font-semibold text-slate-100">
          {d.titulo || 'Agente'}
        </span>
        <span className="text-[10px] uppercase tracking-wide text-slate-500">
          {STATUS_TEXT[d.status]}
        </span>
      </div>
      {d.proyecto ? (
        <div className="mt-1 text-xs text-slate-400">{d.proyecto}</div>
      ) : null}
      {d.ultimaEvidencia ? (
        <div className="mt-2 overflow-hidden rounded-lg border border-slate-700/60">
          <img
            src={d.ultimaEvidencia}
            alt="evidencia"
            className="h-16 w-full object-cover"
          />
        </div>
      ) : (
        <div className="mt-2 rounded-lg border border-dashed border-slate-700/60 px-2 py-3 text-center text-[11px] text-slate-500">
          clic para abrir la sesión
        </div>
      )}
      <div className="mt-2 flex items-center justify-between text-[11px] text-slate-500">
        <span>🔊 voz</span>
        <span>📷 evidencia</span>
      </div>
      <Handle type="source" position={Position.Bottom} className="!bg-slate-500" />
    </div>
  )
}

export default memo(VentanitaNode)
