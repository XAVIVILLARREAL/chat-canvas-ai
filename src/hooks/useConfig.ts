/**
 * Hooks del Centro de Configuración (A.6). Server data → React Query;
 * escribir un override invalida la vista efectiva (y el medidor de contexto
 * cuando toca `context_max_tokens`).
 */
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { configApi, type ConfigScope, type EffectiveSettings, type AgentInfo } from '../lib/configApi';
import { projectsApi, UI_KEYS } from '../lib/projectsApi';

export const configKeys = {
  effective: (projectId: string, sessionId: string | null) =>
    ['config', 'effective', projectId, sessionId ?? '-'] as const,
  agents: ['config', 'agents'] as const,
  activeProject: ['config', 'activeProject'] as const,
};

/** Proyecto activo (persistido en settings globales por el ProjectSwitcher). */
export function useActiveProjectId() {
  return useQuery<string>({
    queryKey: configKeys.activeProject,
    queryFn: async () => {
      const s = await projectsApi.globalSettings();
      const saved = s?.[UI_KEYS.activeProject];
      return typeof saved === 'string' ? saved : 'local-default';
    },
    staleTime: 60_000,
  });
}

export function useEffectiveSettings(projectId: string, sessionId: string | null) {
  return useQuery<EffectiveSettings | null>({
    queryKey: configKeys.effective(projectId, sessionId),
    queryFn: async () => await configApi.effective(projectId, sessionId),
    staleTime: 5_000,
  });
}

export function useAgents() {
  return useQuery<AgentInfo[] | null>({
    queryKey: configKeys.agents,
    queryFn: async () => await configApi.listAgents(),
    staleTime: 30_000,
  });
}

export interface WriteConfigArgs {
  scope: ConfigScope;
  projectId: string;
  sessionId: string | null;
  agent: AgentInfo | null;
  key: string;
  value: unknown;
}

/** Escribe el override en el scope elegido → invalida la vista efectiva. */
export function useWriteConfig(sessionId: string | null) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ scope, projectId, sessionId, agent, key, value }: WriteConfigArgs) => {
      let r: { ok?: boolean } | AgentInfo | null = null;
      if (scope === 'global') r = await configApi.putGlobal(key, value);
      else if (scope === 'project') r = await configApi.putProject(projectId, key, value);
      else if (scope === 'session' && sessionId) r = await configApi.putSession(sessionId, key, value);
      else if (scope === 'agent' && agent) r = await configApi.putAgent(agent, key, value);
      if (!r) throw new Error(`no se pudo escribir ${key} en ${scope}`);
    },
    onSuccess: (_d, vars) => {
      qc.invalidateQueries({ queryKey: configKeys.effective(vars.projectId, sessionId) });
      if (vars.key === 'context_max_tokens') {
        qc.invalidateQueries({ queryKey: ['sessions', sessionId, 'context'] });
      }
    },
  });
}
