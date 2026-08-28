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
  created_at: number;
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
  sendMessage: (sessionId: string, content: string) =>
    apiFetch<MessageInfo>(`/api/sessions/${sessionId}/messages`, {
      method: 'POST',
      body: JSON.stringify({ role: 'user', content }),
    }),
};
