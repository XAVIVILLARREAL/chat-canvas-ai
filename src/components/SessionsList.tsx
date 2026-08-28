/**
 * SessionsList (A.1) — contenido del tab "Sesiones" del sidebar.
 * Lista desde React Query (gateway, fail-open) + crear; seleccionar cambia
 * la vista a chat.
 */
import { useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { MessageSquare, Plus } from 'lucide-react';
import { useI18n } from '../i18n';
import { useSessions, useCreateSession, sessionKeys } from '../hooks/useSessions';
import { useChatUiStore } from '../stores/chat-ui-store';

export function SessionsList() {
  const { t } = useI18n();
  const { data: sessions = [], isLoading } = useSessions();
  const create = useCreateSession();
  const setActiveSession = useChatUiStore((s) => s.setActiveSession);
  const setView = useChatUiStore((s) => s.setView);
  const activeSessionId = useChatUiStore((s) => s.activeSessionId);
  const qc = useQueryClient();
  const [nuevoNombre, setNuevoNombre] = useState('');

  const crear = async () => {
    const title = nuevoNombre.trim() || t('sessions.untitled');
    try {
      const s = await create.mutateAsync(title);
      setActiveSession(s.id);
      qc.invalidateQueries({ queryKey: sessionKeys.all });
      setView('chat');
      setNuevoNombre('');
    } catch {
      // fail-open: sin gateway no se puede crear
    }
  };

  return (
    <div className="sidebar-list" data-testid="sessions-list">
      <div className="list-header">
        <h3>{t('sidebar.sessions')}</h3>
      </div>
      <div style={{ display: 'flex', gap: 6, padding: '0 12px 8px' }}>
        <input
          data-testid="session-name-input"
          value={nuevoNombre}
          onChange={(e) => setNuevoNombre(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && crear()}
          placeholder={t('sessions.new')}
          style={{ flex: 1, minWidth: 0, background: 'rgba(15,23,42,0.5)', border: '1px solid rgba(148,163,184,0.25)', borderRadius: 8, padding: '6px 8px', color: 'inherit', fontSize: 12 }}
        />
        <button className="btn-primary" data-testid="session-create" onClick={crear} disabled={create.isPending}
          style={{ padding: '6px 8px', borderRadius: 8, cursor: 'pointer' }} title={t('sessions.new')}>
          <Plus width={14} height={14} />
        </button>
      </div>
      {isLoading ? (
        <p style={{ opacity: 0.5, padding: 12, fontSize: 12 }}>…</p>
      ) : sessions.length === 0 ? (
        <div className="empty-state"><p>{t('sessions.empty')}</p></div>
      ) : (
        <ul className="item-list">
          {sessions.map((s) => (
            <li
              key={s.id}
              tabIndex={0}
              data-testid={`session-${s.id}`}
              className={`item ${activeSessionId === s.id ? 'selected' : ''}`}
              onClick={() => { setActiveSession(s.id); setView('chat'); }}
            >
              <div className="item-main">
                <span className="item-icon"><MessageSquare width={14} height={14} /></span>
                <div className="item-info">
                  <span className="item-name">{s.title}</span>
                  <span className="item-meta">{new Date(s.created_at).toLocaleDateString()}</span>
                </div>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
