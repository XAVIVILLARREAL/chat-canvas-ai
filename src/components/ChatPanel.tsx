/**
 * Panel de Chat (A.1) — sesiones + mensajes + input + memory rail placeholder.
 * Sin proveedor aún (A.3): enviar persiste el mensaje del usuario; el hint
 * indica que los proveedores BYOK llegan después (sin datos inventados).
 */
import { useEffect, useRef, useState } from 'react';
import { Send, Brain } from 'lucide-react';
import { useI18n } from '../i18n';
import { useChatUiStore } from '../stores/chat-ui-store';
import { useQueryClient } from '@tanstack/react-query';
import {
  useSessions, useMessages, useSendMessage, sessionKeys,
} from '../hooks/useSessions';
import { streamChat } from '../lib/chatApi';
import { ContextMeter } from './ContextMeter';

export function ChatPanel() {
  const { t } = useI18n();
  const activeSessionId = useChatUiStore((s) => s.activeSessionId);
  const { data: sessions = [] } = useSessions();
  const { data: messages = [] } = useMessages(activeSessionId);
  const send = useSendMessage(activeSessionId);
  const [draft, setDraft] = useState('');
  const [streaming, setStreaming] = useState<string | null>(null); // texto en vivo
  const [notice, setNotice] = useState<string | null>(null);       // notas /help etc.
  const qc = useQueryClient();
  const bottomRef = useRef<HTMLDivElement>(null);

  const active = sessions.find((s) => s.id === activeSessionId) ?? null;

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages.length, streaming]);

  const handleSend = async () => {
    const content = draft.trim();
    if (!content || !activeSessionId || send.isPending || streaming !== null) return;
    setDraft('');

    // slash commands — honestos: solo /help; los demás llegan en etapas C/A.5+
    if (content.startsWith('/')) {
      const cmd = content.split(' ')[0];
      if (cmd === '/help') {
        setNotice(t('chat.help'));
      } else {
        setNotice(t('chat.slashLater').replace('{cmd}', cmd));
      }
      return;
    }

    // streaming en vivo (A.4); si el gateway/provider falla → fallback local
    setStreaming('');
    const ok = await streamChat(activeSessionId, content, {
      onDelta: (delta) => setStreaming((prev) => (prev ?? '') + delta),
      onDone: () => {
        setStreaming(null);
        qc.invalidateQueries({ queryKey: sessionKeys.messages(activeSessionId) });
        // A.5 — el medidor refleja el request recién enviado
        qc.invalidateQueries({ queryKey: sessionKeys.context(activeSessionId) });
      },
    });
    if (!ok) {
      setStreaming(null);
      try {
        await send.mutateAsync(content);
      } catch {
        setDraft(content); // gateway caído: devolver el texto (fail-open)
      }
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
              {m.model && (
                <div style={{ fontSize: 11, opacity: 0.55, marginTop: 4 }}>
                  {m.model}
                  {m.tokens_completion ? ` · ${m.tokens_completion} tok` : ''}
                </div>
              )}
            </div>
          ))}
          {streaming !== null && (
            <div
              data-testid="chat-streaming"
              style={{
                alignSelf: 'flex-start', maxWidth: '75%', padding: '8px 12px',
                borderRadius: 12, background: 'rgba(148,163,184,0.15)',
                whiteSpace: 'pre-wrap', wordBreak: 'break-word',
              }}
            >
              {streaming}
              <span className="chat-cursor">▍</span>
            </div>
          )}
          {notice && (
            <div data-testid="chat-notice" style={{ alignSelf: 'center', fontSize: 12, opacity: 0.7, background: 'rgba(148,163,184,0.1)', padding: '6px 10px', borderRadius: 8, whiteSpace: 'pre-wrap' }}>
              {notice}
            </div>
          )}
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

      {/* memory rail: medidor de contexto (A.5) + memory (Etapa D) */}
      <aside
        className="memory-rail"
        data-testid="memory-rail"
        style={{
          width: 220,
          borderInlineStart: '1px solid rgba(148,163,184,0.2)',
          padding: 14,
          display: 'flex',
          flexDirection: 'column',
          gap: 14,
        }}
      >
        <ContextMeter sessionId={activeSessionId} />
        <div style={{ borderTop: '1px solid rgba(148,163,184,0.15)', paddingTop: 10 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontWeight: 600 }}>
            <Brain width={16} height={16} /> {t('chat.memoryTitle')}
          </div>
          <p style={{ fontSize: 12, opacity: 0.6 }}>{t('chat.memorySoon')}</p>
        </div>
      </aside>
    </div>
  );
}
