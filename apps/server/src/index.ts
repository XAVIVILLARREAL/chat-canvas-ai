import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { streamSSE } from 'hono/streaming'
import { serveStatic } from '@hono/node-server/serve-static'
import { serve } from '@hono/node-server'
import { MsEdgeTTS, OUTPUT_FORMAT } from 'msedge-tts'
import { buildGraph, type Runner, type Ticket } from '@empresa/orchestrator'
import { mkdirSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'

const OPENCODE_URL = process.env.OPENCODE_URL ?? 'http://127.0.0.1:7699'
const MODEL = process.env.OPENCODE_MODEL ?? 'deepseek/deepseek-v4-flash'
const TTS_VOICE = process.env.TTS_VOICE ?? 'es-MX-DaliaNeural'
const EVIDENCE_DIR = process.env.EVIDENCE_DIR ?? '/opt/empresa-desarrollo-autonoma/data/evidence'

mkdirSync(EVIDENCE_DIR, { recursive: true })

const app = new Hono()

app.use('*', cors({ origin: '*' }))

app.get('/api/health', (c) => c.json({ status: 'ok', uptime: process.uptime() }))

// Crear una sesión de agente en opencode
app.post('/api/sessions', async (c) => {
  const res = await fetch(`${OPENCODE_URL}/session`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({}),
  })
  const data = (await res.json()) as { id: string }
  return c.json({ id: data.id })
})

// Estado de una sesión (para mini-estado en vivo en las ventanitas)
app.get('/api/sessions/:id', async (c) => {
  const sessionId = c.req.param('id')
  const res = await fetch(`${OPENCODE_URL}/session/${sessionId}`)
  if (!res.ok) return c.json({ error: 'not found' }, 404)
  const data = (await res.json()) as { info?: { time?: { created?: number; updated?: number } } }
  return c.json({ id: sessionId, updated: data.info?.time?.updated ?? null })
})

// Servir evidencias (screenshots) guardadas
app.get('/api/evidence/:file', (c) => {
  const file = c.req.param('file')
  // solo nombres seguros
  if (!/^[a-zA-Z0-9._-]+$/.test(file)) return c.text('invalid', 400)
  const p = join(EVIDENCE_DIR, file)
  const buf = readFileSafe(p)
  if (!buf) return c.text('not found', 404)
  const type = file.endsWith('.png') ? 'image/png' : 'image/jpeg'
  const body = new Uint8Array(buf.buffer, buf.byteOffset, buf.byteLength)
  return new Response(body, {
    status: 200,
    headers: { 'Content-Type': type, 'Cache-Control': 'public, max-age=31536000, immutable' },
  })
})

function readFileSafe(p: string): Buffer | null {
  try {
    const { readFileSync } = require('node:fs') as typeof import('node:fs')
    return readFileSync(p)
  } catch {
    return null
  }
}

// Enviar un mensaje al agente y transmitir la respuesta en streaming (SSE).
// Flujo correcto de opencode: POST /session/{id}/message dispara el turno;
// GET /event entrega los eventos en vivo (text, tool, screenshots, idle).
app.post('/api/sessions/:id/message', (c) => {
  const sessionId = c.req.param('id')
  return streamSSE(c, async (stream) => {
    let body: { message: string } | undefined
    try {
      const raw = await c.req.text()
      body = JSON.parse(raw) as { message: string }
    } catch {
      body = { message: 'hola' }
    }
    const text = body?.message ?? 'hola'

    // 1. Abrir el stream de eventos de opencode ANTES de disparar el mensaje
    const eventRes = await fetch(`${OPENCODE_URL}/event`, {
      headers: { Accept: 'text/event-stream' },
    })
    if (!eventRes.ok || !eventRes.body) {
      await stream.writeSSE({ data: JSON.stringify({ error: 'no event stream' }) })
      await stream.writeSSE({ data: '[DONE]' })
      return
    }

    const evReader = eventRes.body.getReader()
    const evDecoder = new TextDecoder()
    let evBuffer = ''

    const handleEvent = async (event: Record<string, unknown>) => {
      const type = event.type as string
      const props = (event.properties as Record<string, unknown>) ?? {}
      const sid = props.sessionID as string | undefined
      if (sid && sid !== sessionId) return
      const part = props.part as
        | { type?: string; text?: string; tool?: string; state?: { output?: unknown } }
        | undefined

      if (type === 'message.part.delta' && part?.type === 'text' && part.text) {
        await stream.writeSSE({ data: JSON.stringify({ type: 'text', content: part.text }) })
      }

      if (type === 'message.part.updated' && part?.type === 'tool') {
        const output = part.state?.output
        const extractions = extractImages(output)
        for (const img of extractions) {
          const filename = `${sessionId.slice(0, 8)}-${Date.now().toString(36)}.png`
          writeFileSync(join(EVIDENCE_DIR, filename), Buffer.from(img.b64, 'base64'))
          await stream.writeSSE({
            data: JSON.stringify({ type: 'evidence', url: `/api/evidence/${filename}`, caption: part.tool }),
          })
        }
        await stream.writeSSE({
          data: JSON.stringify({ type: 'tool', tool: part.tool, output: stringifyOutput(output).slice(0, 2000) }),
        })
      }
    }

    // 2. Disparar el mensaje en paralelo (opencode POST espera al turno completo,
    //    los eventos van llegando por /event mientras tanto)
    const postPromise = fetch(`${OPENCODE_URL}/session/${sessionId}/message`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ providerID: 'deepseek', modelID: MODEL, parts: [{ type: 'text', text }] }),
    })

    // 3. Consumir eventos mientras el POST del turno corre; el POST resuelve
    //    cuando opencode termina el turno.
    const deadline = Date.now() + 180_000
    let upstreamError: string | null = null
    let turnFinished = false
    const turnResult = postPromise
      .then((res) => {
        if (!res.ok) upstreamError = `upstream ${res.status}`
      })
      .catch(() => {
        upstreamError = 'upstream error'
      })
      .finally(() => {
        turnFinished = true
      })

    // eslint-disable-next-line no-constant-condition
    while (Date.now() < deadline) {
      const evDonePromise = evReader.read()
      const finishSignal = new Promise<void>((resolve) => {
        const check = () => {
          if (turnFinished) resolve()
          else setTimeout(check, 50)
        }
        check()
      })
      const outcome = await Promise.race([
        evDonePromise.then((r) => ({ kind: 'event', value: r })),
        finishSignal.then(() => ({ kind: 'finish', value: null as never })),
      ])

      if (outcome.kind === 'event') {
        const { done: evDone, value } = outcome.value
        if (evDone) break
        evBuffer += evDecoder.decode(value, { stream: true })
      } else {
        break
      }

      // Procesar bloques completos
      const blocks = evBuffer.split('\n\n')
      evBuffer = blocks.pop() ?? ''
      for (const block of blocks) {
        const dataLine = block.split('\n').find((l) => l.startsWith('data:'))
        if (!dataLine) continue
        const json = dataLine.slice(5).trim()
        if (!json || json === '[DONE]') continue
        try {
          const event = JSON.parse(json) as Record<string, unknown>
          const props = (event.properties as Record<string, unknown>) ?? {}
          const sid = props.sessionID as string | undefined
          if (sid && sid !== sessionId) continue
          await handleEvent(event)
        } catch {
          // ignorar
        }
      }
    }
    try {
      evReader.cancel()
    } catch {
      // ignore
    }
    if (upstreamError) {
      await stream.writeSSE({ data: JSON.stringify({ error: upstreamError }) })
    }
    await stream.writeSSE({ data: '[DONE]' })
  })
})

// ===== Orquestador (Fase 2: LangGraph — la empresa) =====
const activeJobs = new Map<string, { status: string; result: unknown }>()

// Runner: ejecuta prompts con opencode en un directorio (multi-directorio)
const runner: Runner = {
  async runPrompt(directory, prompt) {
    const sid = await createOpencodeSession(directory)
    const res = await fetch(`${OPENCODE_URL}/session/${sid}/message`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ providerID: 'deepseek', modelID: MODEL, parts: [{ type: 'text', text: prompt }] }),
    })
    const data = (await res.json()) as { parts?: { type: string; text?: string }[] }
    const texts = (data.parts ?? [])
      .filter((p) => p.type === 'text' && p.text)
      .map((p) => p.text)
    return texts.join('\n') || '(sin respuesta)'
  },
  async runUITest(directory, url) {
    // Fase 3: verificación con Chrome headless (Playwright) + captura como evidencia
    try {
      const { chromium } = await import('playwright-core')
      const CHROME =
        process.env.CHROME_PATH ?? '/root/.cache/ms-playwright/chromium-1228/chrome-linux64/chrome'
      const browser = await chromium.launch({ executablePath: CHROME, headless: true, args: ['--no-sandbox'] })
      const page = await browser.newPage({ viewport: { width: 1280, height: 800 } })
      const consoleErrors: string[] = []
      page.on('console', (m) => {
        if (m.type() === 'error') consoleErrors.push(m.text().slice(0, 200))
      })
      try {
        await page.goto(url, { waitUntil: 'networkidle', timeout: 20000 })
        await page.waitForTimeout(1000)
      } catch (e) {
        consoleErrors.push(`goto: ${String(e).slice(0, 200)}`)
      }
      const screenshotPath = join(EVIDENCE_DIR, `uitest-${Date.now().toString(36)}.png`)
      await page.screenshot({ path: screenshotPath })
      const title = await page.title().catch(() => '')
      await browser.close()
      return `UI visitada OK. Titulo: ${title}. Errores de consola: ${consoleErrors.length ? consoleErrors.join(' | ') : 'ninguno'}. Evidencia: /api/evidence/${screenshotPath.split('/').pop()}`
    } catch (e) {
      return `UI test fallo: ${String(e).slice(0, 300)}`
    }
  },
}

async function createOpencodeSession(directory?: string): Promise<string> {
  const res = await fetch(`${OPENCODE_URL}/session`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(directory ? { directory } : {}),
  })
  const data = (await res.json()) as { id: string }
  return data.id
}

app.post('/api/jobs', async (c) => {
  const body = (await c.req.json()) as { title?: string; description?: string; directory?: string }
  const ticket: Ticket = {
    id: `t_${Date.now().toString(36)}`,
    title: body.title ?? 'Ticket sin título',
    description: body.description ?? '',
    directory: body.directory ?? '/opt/empresa-desarrollo-autonoma',
  }
  const graph = buildGraph(runner)
  const jobId = `job_${Date.now().toString(36)}`
  activeJobs.set(jobId, { status: 'pending', result: null })

  graph
    .run(ticket)
    .then((result) => {
      activeJobs.set(jobId, { status: result.status, result })
    })
    .catch((err) => {
      activeJobs.set(jobId, { status: 'failed', result: { error: String(err) } })
    })

  return c.json({ jobId, ticket })
})

app.get('/api/jobs/:id', (c) => {
  const job = activeJobs.get(c.req.param('id'))
  if (!job) return c.json({ error: 'not found' }, 404)
  return c.json(job)
})

app.get('/api/jobs', (c) => {
  const list = [...activeJobs.entries()].map(([id, j]) => ({ id, status: j.status }))
  return c.json(list)
})

// Text-to-Speech con Edge TTS (Microsoft Read Aloud) — voz natural en español
app.post('/api/tts', async (c) => {
  let text = ''
  try {
    const body = (await c.req.json()) as { text?: string }
    text = body.text ?? ''
  } catch {
    text = ''
  }
  const sanitized = text.replace(/[<>&"']/g, '').slice(0, 2000)

  const tts = new MsEdgeTTS()
  await tts.setMetadata(TTS_VOICE, OUTPUT_FORMAT.AUDIO_24KHZ_48KBITRATE_MONO_MP3)
  const { audioStream } = tts.toStream(sanitized || 'Hola')

  const chunks: Buffer[] = []
  for await (const chunk of audioStream as AsyncIterable<Buffer>) {
    chunks.push(Buffer.from(chunk))
  }
  const audio = Buffer.concat(chunks)

  return c.body(audio, 200, {
    'Content-Type': 'audio/mpeg',
    'Content-Length': String(audio.length),
    'Cache-Control': 'no-cache',
  })
})

// Servir el build del frontend (apps/web/dist) en producción
const webDist = process.env.WEB_DIST ?? new URL('../../web/dist/', import.meta.url).pathname
app.use('*', serveStatic({ root: webDist }))
app.use('*', serveStatic({ root: webDist, path: 'index.html' }))

const port = Number(process.env.PORT) || 7688

export default app

if (process.env.NODE_ENV !== 'test') {
  console.log(`[server] listening on http://localhost:${port} -> opencode ${OPENCODE_URL}`)
  serve({ fetch: app.fetch, port })
}

// Helpers

function extractImages(output: unknown): { b64: string }[] {
  const found: { b64: string }[] = []
  const walk = (o: unknown): void => {
    if (!o || typeof o !== 'object') return
    if (Array.isArray(o)) {
      o.forEach(walk)
      return
    }
    const rec = o as Record<string, unknown>
    for (const v of Object.values(rec)) {
      if (typeof v === 'string' && v.startsWith('data:image/')) {
        const m = /^data:image\/[a-z+]+;base64,([A-Za-z0-9+/=]+)$/.exec(v)
        if (m && m[1]) found.push({ b64: m[1] })
      } else {
        walk(v)
      }
    }
  }
  walk(output)
  return found
}

function stringifyOutput(o: unknown): string {
  if (typeof o === 'string') return o
  try {
    return JSON.stringify(o)
  } catch {
    return String(o)
  }
}
