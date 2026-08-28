/**
 * Cliente de encargos (A.7 — modo ENCARGO). Fail-open: sin gateway, listas
 * vacías y creaciones null (la UI no rompe).
 */
import { API } from './chatApi';

export interface EncargoInfo {
  id: string;
  project_id: string;
  title: string;
  criteria: string;
  status: 'pending' | 'running' | 'completed' | 'failed';
  session_id: string | null;
  agent_id: string | null;
  result: string | null;
  error: string | null;
  model: string | null;
  tokens: number;
  duration_ms: number | null;
  created_at: number;
  updated_at: number;
  completed_at: number | null;
}

async function fetchJson<T>(path: string, init?: RequestInit): Promise<T | null> {
  try {
    const res = await fetch(`${API}${path}`, {
      headers: { 'content-type': 'application/json' },
      ...init,
    });
    if (!res.ok) return null;
    return (await res.json()) as T;
  } catch {
    return null;
  }
}

export const encargosApi = {
  list: () => fetchJson<EncargoInfo[]>('/api/encargos'),
  get: (id: string) => fetchJson<EncargoInfo>(`/api/encargos/${id}`),
  create: (title: string, criteria: string, sessionId?: string | null) =>
    fetchJson<EncargoInfo>('/api/encargos', {
      method: 'POST',
      body: JSON.stringify({ title, criteria, session_id: sessionId ?? null }),
    }),
};
