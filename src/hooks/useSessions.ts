/**
 * Hooks React Query para sesiones/mensajes (A.1). Server data → React Query;
 * invalidación tras mutaciones. Fail-open: error → listas vacías.
 */
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { chatApi, type MessageInfo, type SessionInfo } from '../lib/chatApi';

export const sessionKeys = {
  all: ['sessions'] as const,
  messages: (id: string | null) => ['sessions', id, 'messages'] as const,
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
      const m = await chatApi.sendMessage(sessionId, content);
      if (!m) throw new Error('gateway');
      return m;
    },
    onSuccess: (m: MessageInfo) => qc.invalidateQueries({ queryKey: sessionKeys.messages(m.session_id) }),
  });
}
