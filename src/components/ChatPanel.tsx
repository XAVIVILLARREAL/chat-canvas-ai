/**
 * Panel de Chat (A.1) — sesiones + mensajes + input + memory rail.
 * A.9: editar un mensaje crea una rama (variante); flechas ‹/› navegan
 * alternativas sin perder ninguna.
 */
import { useEffect, useMemo, useRef, useState } from 'react';
import { Send, Brain, Pencil, ChevronLeft, ChevronRight, Check, X } from 'lucide-react';
import { useI18n } from '../i18n';
import { useChatUiStore } from '../stores/chat-ui-store';
import { useQueryClient } from '@tanstack/react-query';
import {
  useSessions, useMessages, useSendMessage, sessionKeys,
  useCompact, useEditMessage, useActivateVariant,
} from '../hooks/useSessions';
import { streamChat, type MessageInfo } from '../lib/chatApi';
import { ContextMeter } from './ContextMeter';
import { EncargosPanel } from './EncargosPanel';
import { ResumeCard } from './ResumeCard';

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
  const compact = useCompact(activeSessionId);
  const editMsg = useEditMessage(activeSessionId);
  const activate = useActivateVariant(activeSessionId);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editDraft, setEditDraft] = useState('');

  // camino activo + mapa de grupos de variantes (A.9)
  const visible = useMemo(() => messages.filter((m) => m.active !== 0), [messages]);
  const groups = useMemo(() => {
    const g: Record<string, MessageInfo[]> = {};
    for (const m of messages) {
      if (m.variant_group) (g[m.variant_group] ??= []).push(m);
    }
    return g;
  }, [messages]);

  const active = sessions.find((s) => s.id === activeSessionId) ?? null;

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages.length, streaming]);

  const handleSend = async () => {
    const content = draft.trim();
    if (!content || !activeSessionId || send.isPending || streaming !== null) return;
    setDraft('');

    // slash commands — honestos: /help y /compact (A.8); los demás llegan en Etapa C
    if (content.startsWith('/')) {
      const cmd = content.split(' ')[0];
      if (cmd === '/help') {
        setNotice(t('chat.help'));
      } else if (cmd === '/compact') {
        setNotice(t('chat.compacting'));
        compact.mutate(undefined, {
          onSuccess: (r) =>
            setNotice(
              r.compacted
                ? t('chat.compacted').replace('{n}', String(r.removed))
                : t('chat.compactNothing'),
            ),
          onError: () => setNotice(t('chat.compactNoProvider')),
        });
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
          <ResumeCard sessionId={activeSessionId} />
          {messages.length === 0 && (
            <p style={{ opacity: 0.6, textAlign: 'center', marginTop: 40 }} data-testid="chat-empty">
              {t('chat.empty')}
            </p>
          )}
          {visible.map((m) => {
            const group = m.variant_group ? groups[m.variant_group] ?? [] : [];
            const branching = group.length > 1;
            const vIdx = group.findIndex((v) => v.id === m.id);
            const prev = branching && vIdx > 0 ? group[vIdx - 1] : null;
            const next = branching && vIdx < group.length - 1 ? group[vIdx + 1] : null;
            const isEditing = editingId === m.id;
            return (
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
                {isEditing ? (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 6, minWidth: 220 }}>
                    <textarea
                      data-testid="msg-edit-input"
                      value={editDraft}
                      onChange={(e) => setEditDraft(e.target.value)}
                      rows={3}
                      autoFocus
                      style={{
                        fontSize: 'inherit', padding: 8, borderRadius: 8, resize: 'vertical',
                        background: 'rgba(15,23,42,0.6)', color: 'inherit',
                        border: '1px solid rgba(148,163,184,0.35)',
                      }}
                    />
                    <div style={{ display: 'flex', gap: 6 }}>
                      <button
                        className="btn-primary"
                        data-testid="msg-edit-save"
                        onClick={() =>
                          editMsg.mutate(
                            { id: m.id, content: editDraft },
                            { onSuccess: () => setEditingId(null) },
                          )
                        }
                        disabled={editMsg.isPending || !editDraft.trim()}
                        style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, padding: '4px 8px', borderRadius: 8, cursor: 'pointer' }}
                      >
                        <Check width={12} height={12} /> {t('message.save')}
                      </button>
                      <button
                        data-testid="msg-edit-cancel"
                        onClick={() => setEditingId(null)}
                        style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, padding: '4px 8px', borderRadius: 8, cursor: 'pointer', background: 'transparent', border: '1px solid rgba(148,163,184,0.3)', color: 'inherit' }}
                      >
                        <X width={12} height={12} /> {t('message.cancel')}
                      </button>
                    </div>
                  </div>
                ) : (
                  <>
                    {m.content}
                    {m.role === 'user' && (
                      <button
                        data-testid={`msg-edit-${m.id}`}
                        onClick={() => { setEditingId(m.id); setEditDraft(m.content); }}
                        aria-label={t('message.edit')}
                        title={t('message.edit')}
                        style={{ marginLeft: 6, background: 'transparent', border: 'none', cursor: 'pointer', color: 'inherit', opacity: 0.5, verticalAlign: 'middle', padding: 0 }}
                      >
                        <Pencil width={11} height={11} />
                      </button>
                    )}
                    {m.model && (
                      <div style={{ fontSize: 11, opacity: 0.55, marginTop: 4 }}>
                        {m.model}
                        {m.tokens_completion ? ` · ${m.tokens_completion} tok` : ''}
                      </div>
                    )}
                    {branching && (
                      <div
                        data-testid={`msg-branch-${m.id}`}
                        style={{ display: 'flex', alignItems: 'center', gap: 4, marginTop: 4, fontSize: 11, opacity: 0.75 }}
                      >
                        <button
                          data-testid={`msg-prev-${m.id}`}
                          onClick={() => prev && activate.mutate(prev.id)}
                          disabled={!prev || activate.isPending}
                          aria-label={t('message.prevVariant')}
                          style={{ background: 'transparent', border: 'none', cursor: prev ? 'pointer' : 'default', color: 'inherit', padding: 0, opacity: prev ? 1 : 0.3 }}
                        >
                          <ChevronLeft width={13} height={13} />
                        </button>
                        <span data-testid={`msg-variant-pos-${m.id}`}>
                          {vIdx + 1}/{group.length}
                        </span>
                        <button
                          data-testid={`msg-next-${m.id}`}
                          onClick={() => next && activate.mutate(next.id)}
                          disabled={!next || activate.isPending}
                          aria-label={t('message.nextVariant')}
                          style={{ background: 'transparent', border: 'none', cursor: next ? 'pointer' : 'default', color: 'inherit', padding: 0, opacity: next ? 1 : 0.3 }}
                        >
                          <ChevronRight width={13} height={13} />
                        </button>
                      </div>
                    )}
                  </>
                )}
              </div>
            );
          })}
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
          <EncargosPanel sessionId={activeSessionId} />
        </div>
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
