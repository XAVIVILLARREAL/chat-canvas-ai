// Voz: TTS (Edge TTS via server) + STT (Web Speech API del navegador)

let audioEl: HTMLAudioElement | null = null

export async function speak(text: string): Promise<void> {
  try {
    const res = await fetch('/api/tts', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text }),
    })
    if (!res.ok) throw new Error(`tts ${res.status}`)
    const blob = await res.blob()
    const url = URL.createObjectURL(blob)
    audioEl?.pause()
    audioEl = new Audio(url)
    await audioEl.play()
    await new Promise<void>((resolve) => {
      audioEl!.onended = () => resolve()
      audioEl!.onerror = () => resolve()
    })
  } catch (err) {
    console.error('[voz] tts error:', err)
    throw err
  }
}

export function stopSpeaking() {
  audioEl?.pause()
}

// STT — Web Speech API (navegador, gratis). No está en lib.dom estándar,
// así que tipamos de forma pragmática.
type SR = {
  lang: string
  continuous: boolean
  interimResults: boolean
  onresult: ((e: { results: ArrayLike<{ isFinal: boolean; [j: number]: { transcript: string } }> }) => void) | null
  onerror: ((e: { error: string }) => void) | null
  onend: (() => void) | null
  start: () => void
  stop: () => void
  abort: () => void
}

function getCtor(): (new () => SR) | null {
  if (typeof window === 'undefined') return null
  const w = window as unknown as Record<string, unknown>
  return (w.SpeechRecognition as (new () => SR) | undefined) ??
    (w.webkitSpeechRecognition as (new () => SR) | undefined) ??
    null
}

export function browserSpeechSupported(): boolean {
  return getCtor() !== null
}

export type ListenCallbacks = {
  onTranscript: (finalText: string) => void
  onInterim?: (text: string) => void
  onEnd?: () => void
  onError?: (err: string) => void
}

let recognition: SR | null = null

export function startListening(cbs: ListenCallbacks, lang = 'es-MX'): boolean {
  const Ctor = getCtor()
  if (!Ctor) return false

  recognition?.abort()
  recognition = new Ctor()
  recognition.lang = lang
  recognition.continuous = false
  recognition.interimResults = true

  recognition.onresult = (e) => {
    let interim = ''
    let final = ''
    const n = e.results.length
    for (let i = 0; i < n; i++) {
      const r = e.results[i]
      if (!r) continue
      const transcript = r[0]?.transcript ?? ''
      if (r.isFinal) final += transcript
      else interim += transcript
    }
    if (final) cbs.onTranscript(final)
    else if (interim && cbs.onInterim) cbs.onInterim(interim)
  }
  recognition.onerror = (e) => {
    if (cbs.onError) cbs.onError(e.error)
    if (cbs.onEnd) cbs.onEnd()
  }
  recognition.onend = () => {
    if (cbs.onEnd) cbs.onEnd()
  }
  recognition.start()
  return true
}

export function stopListening() {
  try {
    recognition?.stop()
  } catch {
    // ignore
  }
}
