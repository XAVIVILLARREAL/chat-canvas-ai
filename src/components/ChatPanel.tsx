/**
 * Panel de Chat (A.1) — sesiones + mensajes + input + memory rail placeholder.
 * Sin proveedor aún (A.3): enviar persiste el mensaje del usuario; el hint
 * indica que los proveedores BYOK llegan después (sin datos inventados).
 */
import { useEffect, useRef, useState } from 'react';
import { Send, Brain } from 'lucide-react';
import { useI18n } from '../i18n';
import { useChatUiStore } from '../stores/chat-ui-store';
import { useSessions, useMessages, useSendMessage } from '../hooks/useSessions';

export function ChatPanel() {
  const { t } = useI18n();
  const activeSessionId = useChatUiStore((s) => s.activeSessionId);
  const { data: sessions = [] } = useSessions();
  const { data: messages = [] } = useMessages(activeSessionId);
  const send = useSendMessage(activeSessionId);
  const [draft, setDraft] = useState('');
  const bottomRef = useRef<HTMLDivElement>(null);

  const active = sessions.find((s) => s.id === activeSessionId) ?? null;

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages.length]);

  const handleSend = async () => {
    const content = draft.trim();
    if (!content || !activeSessionId || send.isPending) return;
    setDraft('');
    try {
      await send.mutateAsync(content);
    } catch {
      setDraft(content); // devolver el texto si el gateway falló (fail-open)
    }
  };

  return (
    <div className="chat-shell" data-testid="chat-panel" style={{ display: 'flex', height: '100%', minHeight: 0 }}>
      {/* columna principal de conversación */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        <div className="chat-header" style={{ padding: '10px 16px', borderBottom: '1px solid rgba(148,163,184,0.2)', fontWeight: 600 }}>
          {active ? active.title : t('sessions.none')}
        </div>

        <div className="chat-messages" style={{ flex: 1, overflowY: 'auto', padding: 16, display: 'flex', flexDirection: 'column', gap: 10 }}>
          {messages.length === 0 && (
            <p style={{ opacity: 0.6, textAlign: 'center', marginTop: 40 }} data-testid="chat-empty">
              {t('chat.empty')}
            </p>
          )}
          {messages.map((m) => (
            <div
              key={m.id}
              data-testid={`msg-${m.role}`}
              style={{
                alignSelf: m.role === 'user' ? 'flex-end' : 'flex-start',
                maxWidth: '75%',
                padding: '8px 12px',
                borderRadius: 12,
                background: m.role === 'user' ? 'rgba(99,102,241,0.25)' : 'rgba(148,163,184,0.15)',
                whiteSpace: 'pre-wrap',
                wordBreak: 'break-word',
              }}
            >
              {m.content}
              {m.model && <div style={{ fontSize: 11, opacity: 0.55, marginTop: 4 }}>{m.model}</div>}
            </div>
          ))}
          <div ref={bottomRef} />
        </div>

        <div className="chat-input-row" style={{ display: 'flex', gap: 8, padding: 12, borderTop: '1px solid rgba(148,163,184,0.2)' }}>
          <input
            data-testid="chat-input"
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSend()}
            placeholder={active ? t('chat.placeholder') : t('sessions.pickFirst')}
            disabled={!active}
            style={{ flex: 1, background: 'rgba(15,23,42,0.5)', border: '1px solid rgba(148,163,184,0.25)', borderRadius: 10, padding: '10px 12px', color: 'inherit' }}
          />
          <button
            className="btn-primary"
            data-testid="chat-send"
            onClick={handleSend}
            disabled={!active || !draft.trim() || send.isPending}
            style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '10px 14px', borderRadius: 10, cursor: 'pointer' }}
          >
            <Send width={15} height={15} /> {t('chat.send')}
          </button>
        </div>
        <div style={{ fontSize: 11, opacity: 0.5, padding: '0 12px 8px' }}>{t('chat.providerNote')}</div>
      </div>

      {/* memory rail — placeholder (Etapa D) */}
      <aside
        className="memory-rail"
        data-testid="memory-rail"
        style={{
          width: 220,
          borderInlineStart: '1px solid rgba(148,163,184,0.2)',
          padding: 14,
          display: 'flex',
          flexDirection: 'column',
          gap: 8,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontWeight: 600 }}>
          <Brain width={16} height={16} /> {t('chat.memoryTitle')}
        </div>
        <p style={{ fontSize: 12, opacity: 0.6 }}>{t('chat.memorySoon')}</p>
      </aside>
    </div>
  );
}
