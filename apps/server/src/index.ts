import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { streamSSE } from 'hono/streaming'
import { serveStatic } from '@hono/node-server/serve-static'
import { serve } from '@hono/node-server'
import { MsEdgeTTS, OUTPUT_FORMAT } from 'msedge-tts'

const OPENCODE_URL = process.env.OPENCODE_URL ?? 'http://127.0.0.1:7699'
const MODEL = process.env.OPENCODE_MODEL ?? 'deepseek/deepseek-chat'
const TTS_VOICE = process.env.TTS_VOICE ?? 'es-MX-DaliaNeural'

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

// Enviar un mensaje al agente y transmitir la respuesta en streaming (SSE)
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

    const controller = new AbortController()
    const upstream = await fetch(`${OPENCODE_URL}/session/${sessionId}/message`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        providerID: 'deepseek',
        modelID: MODEL,
        parts: [{ type: 'text', text }],
      }),
      signal: controller.signal,
    })

    if (!upstream.ok || !upstream.body) {
      await stream.writeSSE({ data: JSON.stringify({ error: `upstream ${upstream.status}` }) })
      await stream.writeSSE({ data: '[DONE]' })
      return
    }

    // Leer el stream NDJSON del agente y reenviarlo
    const reader = upstream.body.getReader()
    const decoder = new TextDecoder()
    let buffer = ''
    try {
      // eslint-disable-next-line no-constant-condition
      while (true) {
        const { done, value } = await reader.read()
        if (done) break
        buffer += decoder.decode(value, { stream: true })
        const lines = buffer.split('\n')
        buffer = lines.pop() ?? ''
        for (const line of lines) {
          const trimmed = line.trim()
          if (!trimmed) continue
          try {
            const event = JSON.parse(trimmed) as { type?: string; text?: string }
            if (event.type === 'text' && event.text) {
              await stream.writeSSE({ data: JSON.stringify({ content: event.text }) })
            }
          } catch {
            // línea no JSON: ignorar
          }
        }
      }
    } finally {
      controller.abort()
    }
    await stream.writeSSE({ data: '[DONE]' })
  })
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
