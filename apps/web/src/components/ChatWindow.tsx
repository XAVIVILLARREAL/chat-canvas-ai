import { useEffect, useRef, useState } from 'react'
import type { ChatChunk, VentanitaNodeData } from '../types'
import { useCanvaStore } from '../store/canva'

type ChatMessage = { role: 'user' | 'assistant'; content: string }

export default function ChatWindow() {
  const selectedId = useCanvaStore((s) => s.selectedVentanitaId)
  const closeVentanita = useCanvaStore((s) => s.closeVentanita)
  const nodes = useCanvaStore((s) => s.nodes)
  const setVentanitaStatus = useCanvaStore((s) => s.setVentanitaStatus)

  const ventanita = nodes.find((n) => n.id === selectedId)
  const data = ventanita?.data as VentanitaNodeData | undefined

  const [input, setInput] = useState('')
  const [messages, setMessages] = useState<ChatMessage[]>([])
  const [status, setStatus] = useState<'idle' | 'streaming' | 'error'>('idle')
  const scrollRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    setMessages([])
    setStatus('idle')
  }, [selectedId])

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: 'smooth' })
  }, [messages, status])

  async function send() {
    const msg = input.trim()
    if (!msg || status === 'streaming') return
    setInput('')
    setMessages((m) => [...m, { role: 'user', content: msg }])
    setStatus('streaming')
    if (selectedId) setVentanitaStatus(selectedId, 'thinking')

    try {
      const res = await fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: msg }),
      })
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      const reader = res.body?.getReader()
      if (!reader) throw new Error('sin stream')

      const decoder = new TextDecoder()
      let buffer = ''
      // eslint-disable-next-line no-constant-condition
      while (true) {
        const { done, value } = await reader.read()
        if (done) break
        buffer += decoder.decode(value, { stream: true })
        for (const line of buffer.split('\n')) {
          if (line.startsWith('data: ') && line !== 'data: [DONE]') {
            try {
              const chunk = JSON.parse(line.slice(6)) as ChatChunk
              setMessages((m) => {
                const last = m[m.length - 1]
                if (last?.role === 'assistant') {
                  return [...m.slice(0, -1), { role: 'assistant', content: last.content + chunk.content }]
                }
                return [...m, { role: 'assistant', content: chunk.content }]
              })
            } catch {
              // ignora líneas no JSON
            }
          }
        }
      }
      setStatus('idle')
      if (selectedId) setVentanitaStatus(selectedId, 'listo')
    } catch (err) {
      console.error('[chat] error:', err)
      setStatus('error')
      if (selectedId) setVentanitaStatus(selectedId, 'error')
    }
  }

  if (!selectedId) return null

  return (
    <div className="fixed inset-0 z-50 flex flex-col bg-slate-950/80 p-0 backdrop-blur-sm sm:p-6">
      <div className="flex h-full flex-col overflow-hidden border-slate-800 bg-slate-900 shadow-2xl sm:rounded-2xl sm:border">
        {/* Header */}
        <div className="flex items-center gap-3 border-b border-slate-800 px-4 py-3">
          <span
            className={`h-2.5 w-2.5 rounded-full ${
              data?.status === 'thinking' ? 'animate-pulse bg-amber-400' : 'bg-emerald-400'
            }`}
          />
          <div className="flex-1">
            <div className="text-sm font-semibold text-slate-100">{data?.titulo ?? 'Agente'}</div>
            {data?.proyecto ? (
              <div className="text-xs text-slate-500">{data.proyecto}</div>
            ) : null}
          </div>
          <button
            onClick={closeVentanita}
            className="rounded-lg px-2 py-1 text-slate-400 hover:bg-slate-800 hover:text-white"
            aria-label="cerrar"
          >
            ✕
          </button>
        </div>

        {/* Messages */}
        <div ref={scrollRef} className="flex-1 space-y-3 overflow-y-auto px-4 py-4">
          {messages.length === 0 && status !== 'streaming' ? (
            <div className="flex h-full items-center justify-center text-sm text-slate-500">
              Escribe un mensaje para empezar…
            </div>
          ) : null}
          {messages.map((m, i) => (
            <div
              key={i}
              className={`max-w-[80%] whitespace-pre-wrap rounded-2xl px-3 py-2 text-sm ${
                m.role === 'user'
                  ? 'ml-auto bg-sky-600 text-white'
                  : 'bg-slate-800 text-slate-100'
              }`}
            >
              {m.content}
            </div>
          ))}
          {status === 'streaming' && (
            <div className="flex items-center gap-2 text-xs text-slate-500">
              <span className="animate-pulse">●</span> agente escribiendo…
            </div>
          )}
          {status === 'error' && (
            <div className="rounded-2xl border border-rose-500/40 bg-rose-500/10 px-3 py-2 text-sm text-rose-300">
              No pude conectar con el agente.{' '}
              <button onClick={() => void send()} className="underline">
                Reintentar
              </button>
            </div>
          )}
        </div>

        {/* Input */}
        <div className="flex items-center gap-2 border-t border-slate-800 px-3 py-3">
          <input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && void send()}
            placeholder="Mensaje al agente…"
            className="flex-1 rounded-xl border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-slate-100 placeholder:text-slate-500 focus:border-sky-500 focus:outline-none"
          />
          <button
            onClick={() => void send()}
            disabled={!input.trim() || status === 'streaming'}
            className="rounded-xl bg-sky-600 px-4 py-2 text-sm font-semibold text-white hover:bg-sky-500 disabled:opacity-40"
          >
            ➜
          </button>
          <button
            className="rounded-xl border border-slate-700 px-3 py-2 text-sm text-slate-300 hover:bg-slate-800"
            title="voz (próximamente)"
          >
            🎤
          </button>
        </div>
      </div>
    </div>
  )
}
