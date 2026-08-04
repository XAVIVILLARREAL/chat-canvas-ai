import { memo, useEffect, useState } from 'react'
import { Handle, Position, type NodeProps } from '@xyflow/react'
import type { VentanitaNodeData } from '../types'
import { useCanvaStore } from '../store/canva'
import { speak, startListening, stopListening, browserSpeechSupported } from '../lib/voice'

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
  const setStatus = useCanvaStore((s) => s.setVentanitaStatus)
  const setSession = useCanvaStore((s) => s.setVentanitaSession)
  const setReply = useCanvaStore((s) => s.setVentanitaReply)
  const [listening, setListening] = useState(false)
  const [voiceErr, setVoiceErr] = useState<string | null>(null)
  const canVoice = browserSpeechSupported()

  // Mini-estado en vivo: si la sesión tiene actividad reciente, marcar "pensando"
  useEffect(() => {
    if (!d.sessionId) return
    let cancelled = false
    const poll = async () => {
      try {
        const r = await fetch(`/api/sessions/${d.sessionId}`)
        if (!r.ok) return
        const s = (await r.json()) as { updated?: number | null }
        const now = Date.now()
        const last = s.updated ?? 0
        if (now - last < 8000 && !cancelled) setStatus(id, 'thinking')
      } catch {
        // ignore
      }
    }
    const t = setInterval(poll, 6000)
    return () => {
      cancelled = true
      clearInterval(t)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [d.sessionId, id])

  async function ensureSession(): Promise<string | null> {
    if (d.sessionId) return d.sessionId
    try {
      const r = await fetch('/api/sessions', { method: 'POST' })
      const s = (await r.json()) as { id: string }
      setSession(id, s.id)
      return s.id
    } catch {
      return null
    }
  }

  async function sendVoice(text: string) {
    setStatus(id, 'thinking')
    const sid = await ensureSession()
    if (!sid) {
      setStatus(id, 'error')
      setVoiceErr('sin sesión')
      return
    }
    try {
      const r = await fetch(`/api/sessions/${sid}/message`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: text }),
      })
      const reader = r.body?.getReader()
      let reply = ''
      if (reader) {
        const decoder = new TextDecoder()
        let buf = ''
        // eslint-disable-next-line no-constant-condition
        while (true) {
          const { done, value } = await reader.read()
          if (done) break
          buf += decoder.decode(value, { stream: true })
          for (const line of buf.split('\n')) {
            if (line.startsWith('data: ') && line !== 'data: [DONE]') {
              try {
                const chunk = JSON.parse(line.slice(6)) as { content?: string }
                if (chunk.content) reply += chunk.content
              } catch {
                // ignore
              }
            }
          }
        }
      }
      setStatus(id, 'listo')
      setReply(id, reply)
      if (reply) void speak(reply)
    } catch {
      setStatus(id, 'error')
      setVoiceErr('error de voz')
    }
  }

  function onMic() {
    if (listening) {
      stopListening()
      setListening(false)
      return
    }
    setVoiceErr(null)
    const ok = startListening({
      onTranscript: (finalText) => {
        setListening(false)
        void sendVoice(finalText)
      },
      onEnd: () => setListening(false),
      onError: () => {
        setListening(false)
        setVoiceErr('no pude oírte')
      },
    })
    if (!ok) {
      setVoiceErr('voz no soportada')
      return
    }
    setListening(true)
  }

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
          <img src={d.ultimaEvidencia} alt="evidencia" className="h-16 w-full object-cover" />
        </div>
      ) : (
        <div className="mt-2 rounded-lg border border-dashed border-slate-700/60 px-2 py-2 text-center text-[11px] text-slate-500">
          clic para abrir la sesión
        </div>
      )}
      {d.ultimaRespuesta ? (
        <div className="mt-2 line-clamp-2 text-[11px] text-slate-400">{d.ultimaRespuesta}</div>
      ) : null}
      {voiceErr ? <div className="mt-1 text-[10px] text-rose-400">{voiceErr}</div> : null}
      <div
        className="mt-2 flex items-center justify-between gap-1 text-[11px] text-slate-500"
        onClick={(e) => e.stopPropagation()}
      >
        <button
          onClick={onMic}
          disabled={!canVoice}
          title={listening ? 'Deja de escuchar' : 'Hablar con el agente (sin abrir)'}
          className={`rounded-lg px-2 py-1 transition disabled:opacity-40 ${
            listening
              ? 'animate-pulse bg-rose-500/20 text-rose-300'
              : 'hover:bg-slate-800 hover:text-white'
          }`}
        >
          {listening ? '⏺' : '🎤'}
        </button>
        <button
          onClick={() => d.ultimaRespuesta && void speak(d.ultimaRespuesta)}
          disabled={!d.ultimaRespuesta}
          title="Repetir respuesta por voz"
          className="rounded-lg px-2 py-1 transition hover:bg-slate-800 hover:text-white disabled:opacity-30"
        >
          🔊
        </button>
        <span className="px-1 opacity-60">{d.sessionId ? 'sesión activa' : 'sin sesión'}</span>
      </div>
      <Handle type="source" position={Position.Bottom} className="!bg-slate-500" />
    </div>
  )
}

export default memo(VentanitaNode)
