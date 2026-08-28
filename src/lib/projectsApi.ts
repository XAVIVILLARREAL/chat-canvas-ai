/**
 * Cliente del gateway para proyectos + settings con scopes (A.0).
 * Fail-open: si el gateway no está (dev local sin server), la UI degrada
 * a un único proyecto por defecto sin romper nada.
 */

export interface ProjectInfo {
  id: string;
  name: string;
}

const API = import.meta.env.VITE_API_BASE ?? '';
// VITE_API_BASE puede ser '/api' (proxy de dev): evita doble prefijo /api/api
const BASE = API.replace(/\/api\/?$/, '');

async function apiFetch<T>(path: string, init?: RequestInit): Promise<T | null> {
  try {
    const res = await fetch(`${BASE}${path}`, {
      headers: { 'content-type': 'application/json' },
      ...init,
    });
    if (!res.ok) return null;
    return (await res.json()) as T;
  } catch {
    return null; // fail-open: gateway ausente
  }
}

export const projectsApi = {
  list: () => apiFetch<ProjectInfo[]>('/api/projects'),
  create: (name: string) =>
    apiFetch<ProjectInfo>('/api/projects', { method: 'POST', body: JSON.stringify({ name }) }),
  remove: (id: string) => apiFetch<null>(`/api/projects/${id}`, { method: 'DELETE' }),

  /** Settings resueltas del proyecto (override local + herencia global). */
  settings: (projectId: string) => apiFetch<Record<string, unknown>>(`/api/settings/${projectId}`),
  globalSettings: () => apiFetch<Record<string, unknown>>('/api/settings'),
  putSetting: (projectId: string, key: string, value: unknown) =>
    apiFetch<{ ok: boolean }>(`/api/settings/${projectId}`, {
      method: 'PUT',
      body: JSON.stringify({ key, value }),
    }),
  putGlobalSetting: (key: string, value: unknown) =>
    apiFetch<{ ok: boolean }>('/api/settings', { method: 'PUT', body: JSON.stringify({ key, value }) }),
};

/** Estado UI persistido en settings del gateway (tabs activas, proyecto activo). */
export const UI_KEYS = {
  tabs: 'ui.tabs',
  activeProject: 'ui.active_project',
} as const;
