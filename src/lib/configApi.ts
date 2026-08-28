/**
 * Cliente del Centro de Configuración (A.6) — settings por scope con valor
 * efectivo y origen. Fail-open: sin gateway las lecturas devuelven null.
 */
import { API } from './chatApi';

export type ConfigScope = 'global' | 'project' | 'session' | 'agent';

export interface SettingEntry {
  key: string;
  value: unknown;
  origin: ConfigScope; // global|project|session|agent
}

export interface EffectiveSettings {
  items: SettingEntry[];
  resolved: Record<string, unknown>;
}

export interface AgentInfo {
  id: string;
  name: string;
  config: { model: string; temperature: number; max_tokens: number; [k: string]: unknown };
  [k: string]: unknown;
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

export const configApi = {
  /** Valor efectivo + origen por clave (Agente > Sesión > Proyecto > Global). */
  effective: (projectId: string, sessionId?: string | null, agentId?: string | null) => {
    const qs = new URLSearchParams();
    if (sessionId) qs.set('session_id', sessionId);
    if (agentId) qs.set('agent_id', agentId);
    const q = qs.toString();
    return fetchJson<EffectiveSettings>(
      `/api/settings/${projectId}/effective${q ? `?${q}` : ''}`,
    );
  },

  putGlobal: (key: string, value: unknown) =>
    fetchJson<{ ok: boolean }>('/api/settings', {
      method: 'PUT',
      body: JSON.stringify({ key, value }),
    }),

  putProject: (projectId: string, key: string, value: unknown) =>
    fetchJson<{ ok: boolean }>(`/api/settings/${projectId}`, {
      method: 'PUT',
      body: JSON.stringify({ key, value }),
    }),

  putSession: (sessionId: string, key: string, value: unknown) =>
    fetchJson<{ ok: boolean }>(`/api/sessions/${sessionId}/settings`, {
      method: 'PUT',
      body: JSON.stringify({ key, value }),
    }),

  /** Scope agente: escribe el campo del AgentConfig vía update completo. */
  putAgent: (agent: AgentInfo, key: string, value: unknown) => {
    const body = {
      ...agent,
      config: { ...agent.config, [key]: value },
    };
    return fetchJson<AgentInfo>(`/api/agents/${agent.id}`, {
      method: 'PUT',
      body: JSON.stringify(body),
    });
  },

  listAgents: () => fetchJson<AgentInfo[]>('/api/agents'),
};
