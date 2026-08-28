/**
 * UI state del chat (A.1). Server data vive en React Query — aquí solo UI:
 * vista activa (canvas|chat) y sesión seleccionada.
 */
import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';

export type AppView = 'canvas' | 'chat';

interface ChatUiState {
  view: AppView;
  activeSessionId: string | null;
  setView: (v: AppView) => void;
  setActiveSession: (id: string | null) => void;
}

export const useChatUiStore = create<ChatUiState>()(
  immer((set) => ({
    view: 'canvas',
    activeSessionId: null,
    setView: (view) =>
      set((s) => {
        s.view = view;
      }),
    setActiveSession: (id) =>
      set((s) => {
        s.activeSessionId = id;
      }),
  }))
);
