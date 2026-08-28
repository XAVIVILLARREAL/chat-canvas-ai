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
  /** Ramas (A.9): grupo de variantes (ancla = id del original) y camino activo. */
  variant_group?: string | null;
  active?: number;
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

/** Dónde se quedó la sesión (A.8 — card de resume). */
export interface SessionResumeInfo {
  session_id: string;
  total_messages: number;
  total_tokens: number;
  total_cost_usd: number;
  last_activity_at: number;
  unanswered: boolean;
  last_user_message: string | null;
  last_assistant_message: string | null;
}

/** Resultado de /compact (A.8). */
export interface CompactResult {
  compacted: boolean;
  removed: number;
  summary_message_id: string | null;
  reason: string | null;
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

export const API = (import.meta.env.VITE_API_BASE ?? '').replace(/\/api\/?$/, '');

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

/**
 * Resultado del chat con provider BYOK (A.1/A.9):
 * - ok: user+assistant persistidos.
 * - persisted: el gateway YA persistió el mensaje del usuario pero no hubo
 *   respuesta (sin provider o provider caído) — NO re-persistir (duplicaría).
 * - failed: nada se persistió (gateway caído, sesión inexistente).
 */
export type ChatFallback =
  | { kind: 'ok'; turn: ChatTurn }
  | { kind: 'persisted' }
  | { kind: 'failed' };

export const chatApi = {
  /** Chat con provider BYOK. Sin provider → `persisted` (el mensaje del
   *  usuario ya quedó guardado); gateway caído → `failed`. */
  chat: async (sessionId: string, content: string): Promise<ChatFallback> => {
    try {
      const res = await fetch(`${API}/api/sessions/${sessionId}/chat`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ content }),
      });
      if (res.ok) return { kind: 'ok', turn: (await res.json()) as ChatTurn };
      // 400 (sin provider) y 5xx (provider caído): el handler persiste el
      // mensaje del usuario ANTES de intentar el provider
      if (res.status === 400 || res.status >= 500) return { kind: 'persisted' };
      return { kind: 'failed' }; // 404 etc.
    } catch {
      return { kind: 'failed' }; // red/gateway caído
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
  /** Dónde se quedó la sesión (A.8). `null` si falla (fail-open). */
  resume: (sessionId: string) => apiFetch<SessionResumeInfo>(`/api/sessions/${sessionId}/resume`),
  /** Comprime el historial viejo en un resumen (A.8). `null` si falla (p.ej. sin provider). */
  compact: (sessionId: string, keep?: number) =>
    apiFetch<CompactResult>(`/api/sessions/${sessionId}/compact`, {
      method: 'POST',
      body: JSON.stringify({ keep: keep ?? 4 }),
    }),
  /** Edita un mensaje → crea variante hermana activa (A.9). */
  editMessage: (id: string, content: string) =>
    apiFetch<MessageInfo>(`/api/messages/${id}`, {
      method: 'PUT',
      body: JSON.stringify({ content }),
    }),
  /** Activa una variante del grupo (flechas ‹/›) → devuelve el grupo completo. */
  activateVariant: (id: string) =>
    apiFetch<MessageInfo[]>(`/api/messages/${id}/activate`, { method: 'POST' }),
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
