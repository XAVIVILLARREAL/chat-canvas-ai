import { useEffect, useRef, useState } from 'react'
import type { VentanitaNodeData } from '../types'
import { useCanvaStore } from '../store/canva'
import { speak, startListening, stopListening, browserSpeechSupported } from '../lib/voice'

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
  const [sessionId, setSessionId] = useState<string | null>(null)
  const [status, setStatus] = useState<'idle' | 'streaming' | 'error'>('idle')
  const [listening, setListening] = useState(false)
  const [autoSpeak, setAutoSpeak] = useState(true)
  const scrollRef = useRef<HTMLDivElement>(null)
  const canSpeak = browserSpeechSupported()

  // Al abrir una ventanita, crear una sesión de agente real en opencode
  useEffect(() => {
    let cancelled = false
    setMessages([])
    setStatus('idle')
    setSessionId(null)
    if (selectedId) {
      setVentanitaStatus(selectedId, 'thinking')
      fetch('/api/sessions', { method: 'POST' })
        .then((r) => r.json())
        .then((s) => {
          if (!cancelled) setSessionId(s.id)
        })
        .catch(() => {
          if (!cancelled) setStatus('error')
        })
        .finally(() => {
          if (!cancelled && selectedId) setVentanitaStatus(selectedId, 'idle')
        })
    }
    return () => {
      cancelled = true
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedId])

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: 'smooth' })
  }, [messages, status])

  async function send() {
    const msg = input.trim()
    if (!msg || status === 'streaming' || !sessionId) return
    setInput('')
    setMessages((m) => [...m, { role: 'user', content: msg }])
    setStatus('streaming')
    if (selectedId) setVentanitaStatus(selectedId, 'thinking')

    try {
      const res = await fetch(`/api/sessions/${sessionId}/message`, {
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
              const chunk = JSON.parse(line.slice(6)) as { content?: string }
              if (chunk.content) {
                setMessages((m) => {
                  const last = m[m.length - 1]
                  if (last?.role === 'assistant') {
                    return [...m.slice(0, -1), { role: 'assistant', content: (last.content ?? '') + chunk.content }]
                  }
                  return [...m, { role: 'assistant', content: chunk.content ?? '' }]
                })
              }
            } catch {
              // ignora líneas no JSON
            }
          }
        }
      }
      setStatus('idle')
      if (selectedId) setVentanitaStatus(selectedId, 'listo')
      if (autoSpeak) {
        const lastMsg = messages[messages.length - 1]
        if (lastMsg?.role === 'assistant') void speak(lastMsg.content)
      }
    } catch (err) {
      console.error('[chat] error:', err)
      setStatus('error')
      if (selectedId) setVentanitaStatus(selectedId, 'error')
    }
  }

  function toggleListening() {
    if (listening) {
      stopListening()
      setListening(false)
      return
    }
    const ok = startListening({
      onTranscript: (finalText) => {
        setInput(finalText)
        void send()
      },
      onInterim: setInput,
      onEnd: () => setListening(false),
      onError: () => setListening(false),
    })
    if (!ok) {
      setInput('')
      return
    }
    setListening(true)
  }

  function speakMessage(content: string) {
    if (autoSpeak) setAutoSpeak(false)
    void speak(content)
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
            <div className="text-xs text-slate-500">
              {sessionId ? `sesión ${sessionId.slice(0, 8)}` : 'conectando…'} · opencode
            </div>
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
              {status === 'error' ? 'No pude conectar con el agente.' : 'Escribe un mensaje para empezar…'}
            </div>
          ) : null}
          {messages.map((m, i) => (
            <div
              key={i}
              className={`group flex max-w-[80%] items-end gap-2 ${
                m.role === 'user' ? 'ml-auto' : 'mr-auto'
              }`}
            >
              <div
                className={`whitespace-pre-wrap rounded-2xl px-3 py-2 text-sm ${
                  m.role === 'user' ? 'bg-sky-600 text-white' : 'bg-slate-800 text-slate-100'
                }`}
              >
                {m.content}
              </div>
              {m.role === 'assistant' ? (
                <button
                  onClick={() => speakMessage(m.content)}
                  title="Escuchar"
                  className="mb-1 rounded-lg p-1.5 text-slate-500 opacity-0 transition hover:bg-slate-700 hover:text-white group-hover:opacity-100"
                >
                  🔊
                </button>
              ) : null}
            </div>
          ))}
          {status === 'streaming' && (
            <div className="flex items-center gap-2 text-xs text-slate-500">
              <span className="animate-pulse">●</span> agente trabajando…
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
            disabled={!sessionId || status === 'streaming'}
            className="flex-1 rounded-xl border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-slate-100 placeholder:text-slate-500 focus:border-sky-500 focus:outline-none disabled:opacity-50"
          />
          <button
            onClick={() => void send()}
            disabled={!input.trim() || status === 'streaming' || !sessionId}
            className="rounded-xl bg-sky-600 px-4 py-2 text-sm font-semibold text-white hover:bg-sky-500 disabled:opacity-40"
          >
            ➜
          </button>
          <button
            onClick={toggleListening}
            disabled={!canSpeak}
            title={canSpeak ? (listening ? 'Deja de escuchar' : 'Habla con el agente') : 'Voz no soportada'}
            className={`rounded-xl border px-3 py-2 text-sm transition ${
              listening
                ? 'animate-pulse border-rose-500 bg-rose-500/20 text-rose-300'
                : 'border-slate-700 text-slate-300 hover:bg-slate-800'
            } disabled:opacity-40`}
          >
            {listening ? '⏺' : '🎤'}
          </button>
          <button
            onClick={() => setAutoSpeak((v) => !v)}
            title={autoSpeak ? 'Respuestas por voz: activado' : 'Respuestas por voz: desactivado'}
            className={`rounded-xl border px-3 py-2 text-sm transition ${
              autoSpeak
                ? 'border-emerald-600/60 bg-emerald-600/10 text-emerald-300'
                : 'border-slate-700 text-slate-400 hover:bg-slate-800'
            }`}
          >
            {autoSpeak ? '🔊' : '🔇'}
          </button>
        </div>
      </div>
    </div>
  )
}
