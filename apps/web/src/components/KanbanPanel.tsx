import { useEffect, useState } from 'react'

type Job = { id: string; status: string }
type JobDetail = { status: string; result?: { plan?: string; implementation?: string; verification?: string; review?: string; error?: string } }

const STATUS_LABEL: Record<string, string> = {
  pending: 'Backlog',
  planning: 'Planificando',
  implementing: 'Implementando',
  verifying: 'Verificando',
  reviewing: 'Revisión',
  done: 'Listo',
  failed: 'Falló',
}

const STATUS_COLOR: Record<string, string> = {
  pending: 'bg-slate-500',
  planning: 'bg-sky-500',
  implementing: 'bg-amber-500',
  verifying: 'bg-violet-500',
  reviewing: 'bg-fuchsia-500',
  done: 'bg-emerald-500',
  failed: 'bg-rose-500',
}

export default function KanbanPanel() {
  const [jobs, setJobs] = useState<Job[]>([])
  const [detail, setDetail] = useState<Record<string, JobDetail>>({})
  const [selected, setSelected] = useState<string | null>(null)
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [creating, setCreating] = useState(false)

  const refresh = async () => {
    try {
      const r = await fetch('/api/jobs')
      const list = (await r.json()) as Job[]
      setJobs(list)
      for (const j of list) {
        const d = await fetch(`/api/jobs/${j.id}`)
        const dj = (await d.json()) as JobDetail
        setDetail((prev) => ({ ...prev, [j.id]: dj }))
      }
    } catch {
      // ignore
    }
  }

  useEffect(() => {
    void refresh()
    const t = setInterval(refresh, 5000)
    return () => clearInterval(t)
  }, [])

  async function createJob() {
    if (!title.trim()) return
    setCreating(true)
    try {
      await fetch('/api/jobs', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title, description, directory: '/opt/empresa-desarrollo-autonoma' }),
      })
      setTitle('')
      setDescription('')
      await refresh()
    } finally {
      setCreating(false)
    }
  }

  const statuses = ['pending', 'planning', 'implementing', 'verifying', 'reviewing', 'done', 'failed']

  return (
    <div className="pointer-events-auto absolute right-4 top-4 z-20 flex max-h-[calc(100%-2rem)] w-[360px] flex-col rounded-2xl border border-slate-800 bg-slate-900/95 shadow-2xl backdrop-blur">
      <div className="flex items-center justify-between border-b border-slate-800 px-4 py-3">
        <div className="text-sm font-semibold text-slate-100">📋 Empresa — Tickets</div>
        <span className="rounded-full bg-slate-800 px-2 py-0.5 text-[10px] text-slate-400">
          {jobs.length} jobs
        </span>
      </div>

      {/* Crear ticket */}
      <div className="border-b border-slate-800 px-3 py-3">
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && void createJob()}
          placeholder="Nuevo ticket (ej. 'haz X')…"
          className="w-full rounded-lg border border-slate-700 bg-slate-800 px-2 py-1.5 text-xs text-slate-100 placeholder:text-slate-500 focus:border-sky-500 focus:outline-none"
        />
        <textarea
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Descripción…"
          rows={2}
          className="mt-2 w-full resize-none rounded-lg border border-slate-700 bg-slate-800 px-2 py-1.5 text-xs text-slate-100 placeholder:text-slate-500 focus:border-sky-500 focus:outline-none"
        />
        <button
          onClick={() => void createJob()}
          disabled={!title.trim() || creating}
          className="mt-2 w-full rounded-lg bg-sky-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-sky-500 disabled:opacity-40"
        >
          {creating ? 'Creando…' : '▶ Lanzar ticket'}
        </button>
      </div>

      {/* Columnas */}
      <div className="flex-1 space-y-3 overflow-y-auto px-3 py-3">
        {statuses.map((st) => {
          const inCol = jobs.filter((j) => (detail[j.id]?.status ?? j.status) === st)
          if (inCol.length === 0) return null
          return (
            <div key={st}>
              <div className="mb-1 flex items-center gap-2">
                <span className={`h-2 w-2 rounded-full ${STATUS_COLOR[st]}`} />
                <span className="text-[10px] font-semibold uppercase tracking-wider text-slate-400">
                  {STATUS_LABEL[st] ?? st}
                </span>
                <span className="text-[10px] text-slate-500">{inCol.length}</span>
              </div>
              {inCol.map((j) => (
                <button
                  key={j.id}
                  onClick={() => setSelected(j.id === selected ? null : j.id)}
                  className="mb-1 block w-full rounded-lg border border-slate-800 bg-slate-800/60 px-2 py-1.5 text-left text-xs text-slate-200 hover:border-slate-600"
                >
                  {j.id}
                </button>
              ))}
            </div>
          )
        })}
        {jobs.length === 0 && (
          <div className="py-6 text-center text-xs text-slate-500">Sin tickets. Crea uno arriba.</div>
        )}
      </div>

      {/* Detalle */}
      {selected && detail[selected] ? (
        <div className="max-h-64 overflow-y-auto border-t border-slate-800 px-4 py-3">
          <div className="mb-2 flex items-center gap-2">
            <span className={`h-2 w-2 rounded-full ${STATUS_COLOR[detail[selected]?.status ?? 'pending']}`} />
            <span className="text-xs font-semibold text-slate-200">{selected}</span>
          </div>
          {(['plan', 'implementation', 'verification', 'review'] as const).map((k) =>
            detail[selected]?.result?.[k] ? (
              <details key={k} className="mb-2 rounded-lg border border-slate-800 bg-slate-900 px-2 py-1.5">
                <summary className="cursor-pointer text-[11px] text-slate-300">{k}</summary>
                <pre className="mt-1 max-h-40 overflow-auto whitespace-pre-wrap text-[10px] text-slate-400">
                  {detail[selected]?.result?.[k]}
                </pre>
              </details>
            ) : null,
          )}
          {detail[selected]?.result?.error ? (
            <div className="text-[11px] text-rose-400">{detail[selected]?.result?.error}</div>
          ) : null}
        </div>
      ) : null}
    </div>
  )
}
