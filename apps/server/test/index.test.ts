import { describe, expect, it } from 'vitest'
import app from '../src/index.js'

describe('server', () => {
  it('GET /api/health returns ok', async () => {
    const res = await app.request('/api/health')
    expect(res.status).toBe(200)
    const body = (await res.json()) as { status: string }
    expect(body.status).toBe('ok')
  })

  it('POST /api/chat streams a hola chunk', async () => {
    const res = await app.request('/api/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: 'hola' }),
    })
    expect(res.status).toBe(200)
    const text = await res.text()
    expect(text).toContain('hola desde Hono')
    expect(text).toContain('[DONE]')
  })
})
