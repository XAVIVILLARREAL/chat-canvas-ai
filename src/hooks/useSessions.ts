/**
 * Hooks React Query para sesiones/mensajes (A.1). Server data → React Query;
 * invalidación tras mutaciones. Fail-open: error → listas vacías.
 */
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  chatApi, type CompactResult, type ContextInfo, type MessageInfo,
  type SessionInfo, type SessionResumeInfo,
} from '../lib/chatApi';

export const sessionKeys = {
  all: ['sessions'] as const,
  messages: (id: string | null) => ['sessions', id, 'messages'] as const,
  context: (id: string | null) => ['sessions', id, 'context'] as const,
  resume: (id: string | null) => ['sessions', id, 'resume'] as const,
};

export function useSessions() {
  return useQuery<SessionInfo[]>({
    queryKey: sessionKeys.all,
    queryFn: async () => (await chatApi.listSessions()) ?? [],
    staleTime: 10_000,
  });
}

export function useMessages(sessionId: string | null) {
  return useQuery<MessageInfo[]>({
    queryKey: sessionKeys.messages(sessionId),
    queryFn: async () => (sessionId ? (await chatApi.listMessages(sessionId)) ?? [] : []),
    enabled: !!sessionId,
    staleTime: 5_000,
  });
}

/** Dónde se quedó la sesión (A.8) — card de resume al reabrir. */
export function useSessionResume(sessionId: string | null) {
  return useQuery<SessionResumeInfo | null>({
    queryKey: sessionKeys.resume(sessionId),
    queryFn: async () => (sessionId ? (await chatApi.resume(sessionId)) ?? null : null),
    enabled: !!sessionId,
    staleTime: 30_000,
  });
}

/** /compact — comprime el historial viejo (A.8). Invalida mensajes+contexto. */
export function useCompact(sessionId: string | null) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (keep?: number): Promise<CompactResult> => {
      if (!sessionId) throw new Error('sin sesión');
      const r = await chatApi.compact(sessionId, keep);
      if (!r) throw new Error('compact falló (¿sin provider?)');
      return r;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: sessionKeys.messages(sessionId) });
      qc.invalidateQueries({ queryKey: sessionKeys.context(sessionId) });
    },
  });
}

/** Edita un mensaje → variante hermana activa (A.9). Nada se pierde. */
export function useEditMessage(sessionId: string | null) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, content }: { id: string; content: string }) => {
      const m = await chatApi.editMessage(id, content);
      if (!m) throw new Error('edit falló');
      return m;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: sessionKeys.messages(sessionId) });
      qc.invalidateQueries({ queryKey: sessionKeys.context(sessionId) });
    },
  });
}

/** Flechas ‹/› (A.9): activa la variante elegida del grupo. */
export function useActivateVariant(sessionId: string | null) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      const g = await chatApi.activateVariant(id);
      if (!g) throw new Error('activate falló');
      return g;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: sessionKeys.messages(sessionId) });
      qc.invalidateQueries({ queryKey: sessionKeys.context(sessionId) });
    },
  });
}

/** Medidor de contexto de la sesión (A.5) — en vivo, refresco tras cada mensaje. */
export function useContextInfo(sessionId: string | null) {
  return useQuery<ContextInfo | null>({
    queryKey: sessionKeys.context(sessionId),
    queryFn: async () => (sessionId ? (await chatApi.context(sessionId)) ?? null : null),
    enabled: !!sessionId,
    staleTime: 5_000,
  });
}

/** Ajusta el límite de contexto (override de proyecto) → el siguiente request lo refleja. */
export function useSetContextLimit(sessionId: string | null) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ projectId, limit }: { projectId: string; limit: number }) => {
      const r = await chatApi.setContextLimit(projectId, limit);
      if (!r) throw new Error('gateway');
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: sessionKeys.context(sessionId) }),
  });
}

export function useCreateSession() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (title: string) => {
      const s = await chatApi.createSession(title);
      if (!s) throw new Error('gateway');
      return s;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: sessionKeys.all }),
  });
}

export function useSendMessage(sessionId: string | null) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (content: string) => {
      if (!sessionId) throw new Error('sin sesión');
      // A.3: /chat persiste user+assistant con provider BYOK. Sin provider o
      // con provider caído, el handler YA persistió el mensaje del usuario
      // ('persisted') — re-persistirlo duplicaría (bug raíz corregido en A.9).
      const r = await chatApi.chat(sessionId, content);
      if (r.kind === 'ok') return [r.turn.user_message, r.turn.assistant_message];
      if (r.kind === 'persisted') return [];
      throw new Error('gateway caído');
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: sessionKeys.messages(sessionId) });
      qc.invalidateQueries({ queryKey: sessionKeys.context(sessionId) });
    },
  });
}
