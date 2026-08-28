/**
 * Hooks de encargos (A.7). Mientras haya encargos en curso, polling cada 2s;
 * cuando terminan, polling se apaga (cero costo en reposo).
 */
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { encargosApi, type EncargoInfo } from '../lib/encargosApi';

export const encargosKeys = {
  all: ['encargos'] as const,
};

export function useEncargos() {
  return useQuery<EncargoInfo[]>({
    queryKey: encargosKeys.all,
    queryFn: async () => (await encargosApi.list()) ?? [],
    // polling solo si hay trabajo en curso (pending/running)
    refetchInterval: (query) => {
      const data = query.state.data as EncargoInfo[] | undefined;
      return data?.some((e) => e.status === 'pending' || e.status === 'running')
        ? 2_000
        : false;
    },
    staleTime: 0,
  });
}

export function useCreateEncargo(sessionId: string | null) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ title, criteria }: { title: string; criteria: string }) => {
      const e = await encargosApi.create(title, criteria, sessionId);
      if (!e) throw new Error('gateway');
      return e;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: encargosKeys.all }),
  });
}
