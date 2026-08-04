import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { streamSSE } from 'hono/streaming'
import { serveStatic } from '@hono/node-server/serve-static'
import { serve } from '@hono/node-server'
import type { ChatChunk } from './types.js'

const app = new Hono()

app.use('*', cors({ origin: '*' }))

app.get('/api/health', (c) => c.json({ status: 'ok', uptime: process.uptime() }))

app.post('/api/chat', (c) => {
  const id = crypto.randomUUID()
  const reply = 'hola desde Hono'
  return streamSSE(c, async (stream) => {
    const chunk: ChatChunk = { id, content: reply }
    await stream.writeSSE({ data: JSON.stringify(chunk) })
    await stream.writeSSE({ data: '[DONE]' })
  })
})

// Servir el build del frontend (apps/web/dist) en producción
const webDist = process.env.WEB_DIST ?? new URL('../../web/dist/', import.meta.url).pathname
app.use('*', serveStatic({ root: webDist }))
app.use('*', serveStatic({ root: webDist, path: 'index.html' }))

const port = Number(process.env.PORT) || 7688

export default app

if (process.env.NODE_ENV !== 'test') {
  console.log(`[server] listening on http://localhost:${port}`)
  serve({ fetch: app.fetch, port })
}

