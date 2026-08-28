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
      // A.3: si hay provider BYOK, /chat responde user+assistant reales;
      // sin provider → 400 → fallback: persiste solo el mensaje del usuario.
      const turn = await chatApi.chat(sessionId, content);
      if (turn) return [turn.user_message, turn.assistant_message];
      const m = await chatApi.sendMessage(sessionId, content);
      if (!m) throw new Error('gateway');
      return [m];
    },
    onSuccess: (msgs: MessageInfo[]) => {
      if (msgs[0]) qc.invalidateQueries({ queryKey: sessionKeys.messages(msgs[0].session_id) });
    },
  });
}
