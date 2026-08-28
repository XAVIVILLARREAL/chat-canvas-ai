/**
 * Cliente del gateway para sesiones/mensajes (A.1 — chat con sesiones).
 * Fail-open: sin gateway las listas quedan vacías y la UI no rompe.
 */

export interface SessionInfo {
  id: string;
  title: string;
  status: string;
  created_at: number;
  total_tokens: number;
  total_cost_usd: number;
}

export interface MessageInfo {
  id: string;
  session_id: string;
  role: 'user' | 'assistant' | 'system' | 'tool';
  content: string;
  model: string | null;
  tokens_prompt?: number | null;
  tokens_completion?: number | null;
  created_at: number;
}

export interface ContextSource {
  source: string; // system|historial|knowledge|tools|archivos
  tokens: number;
}

/** Medidor de contexto (A.5) — desglose por fuente + límite + truncado. */
export interface ContextInfo {
  session_id: string;
  project_id: string;
  sources: ContextSource[];
  total_tokens: number;
  limit_tokens: number;
  sent_tokens: number;
}

/** Callback por evento SSE del stream de chat. */
export interface StreamHandlers {
  onDelta: (delta: string) => void;
  onDone: (meta: {
    message_id: string;
    model: string;
    usage?: { prompt_tokens: number; completion_tokens: number };
    context?: ContextInfo;
  }) => void;
}

/**
 * POST /chat/stream con parse SSE en vivo (A.4).
 * Devuelve true si el stream arrancó (200); false si falló antes (fallback local).
 */
export async function streamChat(
  sessionId: string,
  content: string,
  h: StreamHandlers,
): Promise<boolean> {
  let res: Response;
  try {
    res = await fetch(`${API}/api/sessions/${sessionId}/chat/stream`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ content }),
    });
  } catch {
    return false;
  }
  if (!res.ok || !res.body) return false;

  const reader = res.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });
    let idx: number;
    while ((idx = buffer.indexOf('\n\n')) !== -1) {
      const event = buffer.slice(0, idx);
      buffer = buffer.slice(idx + 2);
      for (const line of event.split('\n')) {
        if (!line.startsWith('data: ')) continue;
        try {
          const v = JSON.parse(line.slice(6));
          if (v.delta) h.onDelta(v.delta as string);
          if (v.done && v.message_id) {
            h.onDone({
              message_id: v.message_id,
              model: v.model ?? '',
              usage: v.usage,
            });
          }
        } catch {
          // evento no-JSON ignorado (keep-alive)
        }
      }
    }
  }
  return true;
}

const API = (import.meta.env.VITE_API_BASE ?? '').replace(/\/api\/?$/, '');

async function apiFetch<T>(path: string, init?: RequestInit): Promise<T | null> {
  try {
    const res = await fetch(`${API}${path}`, {
      headers: { 'content-type': 'application/json' },
      ...init,
    });
    if (!res.ok) return null;
    return (await res.json()) as T;
  } catch {
    return null; // fail-open
  }
}

export interface ChatTurn {
  user_message: MessageInfo;
  assistant_message: MessageInfo;
  provider: string;
}

export const chatApi = {
  /** Chat con provider BYOK (persiste user+assistant). `null` si no hay provider (400). */
  chat: async (sessionId: string, content: string): Promise<ChatTurn | null> => {
    try {
      const res = await fetch(`${API}/api/sessions/${sessionId}/chat`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ content }),
      });
      if (res.status === 400) return null; // sin provider → fallback local
      if (!res.ok) return null;
      return (await res.json()) as ChatTurn;
    } catch {
      return null;
    }
  },
  listSessions: () => apiFetch<SessionInfo[]>('/api/sessions'),
  createSession: (title: string) =>
    apiFetch<SessionInfo>('/api/sessions', { method: 'POST', body: JSON.stringify({ title }) }),
  deleteSession: (id: string) =>
    apiFetch<SessionInfo>(`/api/sessions/${id}`, { method: 'DELETE' }),
  listMessages: (sessionId: string) => apiFetch<MessageInfo[]>(`/api/sessions/${sessionId}/messages`),
  /** Medidor de contexto de la sesión (A.5). `null` si falla (fail-open). */
  context: (sessionId: string) => apiFetch<ContextInfo>(`/api/sessions/${sessionId}/context`),
  /** Escribe el límite de contexto como override de proyecto (hereda si se borra). */
  setContextLimit: (projectId: string, limit: number) =>
    apiFetch<{ ok: boolean }>(`/api/settings/${projectId}`, {
      method: 'PUT',
      body: JSON.stringify({ key: 'context_max_tokens', value: limit }),
    }),
  sendMessage: (sessionId: string, content: string) =>
    apiFetch<MessageInfo>(`/api/sessions/${sessionId}/messages`, {
      method: 'POST',
      body: JSON.stringify({ role: 'user', content }),
    }),
};
