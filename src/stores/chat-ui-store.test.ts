import { describe, it, expect, beforeEach } from 'vitest';
import { useChatUiStore } from './chat-ui-store';

// A.1 — store de UI del chat: vista activa + sesión seleccionada (Zustand+immer)

describe('chat-ui-store', () => {
  beforeEach(() => {
    useChatUiStore.setState({ view: 'canvas', activeSessionId: null });
  });

  it('arranca en canvas sin sesión activa', () => {
    const s = useChatUiStore.getState();
    expect(s.view).toBe('canvas');
    expect(s.activeSessionId).toBeNull();
  });

  it('setView alterna canvas↔chat (inmutabilidad por immer)', () => {
    const before = useChatUiStore.getState();
    useChatUiStore.getState().setView('chat');
    const after = useChatUiStore.getState();
    expect(after.view).toBe('chat');
    expect(before.view).toBe('canvas'); // el snapshot viejo no muta
    useChatUiStore.getState().setView('canvas');
    expect(useChatUiStore.getState().view).toBe('canvas');
  });

  it('setActiveSession selecciona y limpia', () => {
    useChatUiStore.getState().setActiveSession('s1');
    expect(useChatUiStore.getState().activeSessionId).toBe('s1');
    useChatUiStore.getState().setActiveSession(null);
    expect(useChatUiStore.getState().activeSessionId).toBeNull();
  });
});
