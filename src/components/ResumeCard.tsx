/**
 * Card de resume (A.8) — "dónde se quedó" al reabrir una sesión con actividad.
 * Datos reales del gateway (sin inventar): último turno sin responder,
 * actividad relativa, tokens y costo acumulado. Descartable por sesión.
 */
import { useEffect, useState } from 'react';
import { History, X, MessageCircleQuestion } from 'lucide-react';
import { useI18n } from '../i18n';
import { useSessionResume } from '../hooks/useSessions';

const HOUR_MS = 3_600_000;

export function ResumeCard({ sessionId }: { sessionId: string | null }) {
  const { t, formatNumber, formatRelative } = useI18n();
  const { data: resume } = useSessionResume(sessionId);
  const [dismissed, setDismissed] = useState<Set<string>>(new Set());

  // al cambiar de sesión, la card vuelve (solo se descarta por sesión activa)
  useEffect(() => {
    if (!sessionId) return;
    setDismissed((prev) => {
      if (!prev.size) return prev;
      const next = new Set(prev);
      next.delete(sessionId);
      return next.size === prev.size ? prev : next;
    });
  }, [sessionId]);

  if (!sessionId || !resume) return null;
  if (resume.total_messages === 0) return null;
  if (dismissed.has(sessionId)) return null;

  const stale = Date.now() - resume.last_activity_at > HOUR_MS;
  const resumable = resume.unanswered || stale;
  if (!resumable) return null;

  const preview = (s: string | null, max = 120) =>
    s && s.length > max ? `${s.slice(0, max)}…` : (s ?? '');

  return (
    <div
      data-testid="resume-card"
      style={{
        alignSelf: 'stretch',
        border: '1px solid rgba(99,102,241,0.35)',
        background: 'rgba(99,102,241,0.08)',
        borderRadius: 12,
        padding: '10px 12px',
        display: 'flex',
        flexDirection: 'column',
        gap: 6,
        fontSize: 12,
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontWeight: 600 }}>
        <History width={14} height={14} />
        <span style={{ flex: 1 }}>{t('resume.title')}</span>
        <button
          data-testid="resume-dismiss"
          onClick={() => setDismissed((s) => new Set(s).add(sessionId))}
          aria-label={t('resume.dismiss')}
          style={{ background: 'transparent', border: 'none', cursor: 'pointer', color: 'inherit', padding: 2 }}
        >
          <X width={14} height={14} />
        </button>
      </div>

      {resume.unanswered && (
        <div
          data-testid="resume-unanswered"
          style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#fbbf24' }}
        >
          <MessageCircleQuestion width={13} height={13} />
          {t('resume.unanswered')}
        </div>
      )}

      <div style={{ opacity: 0.85 }}>
        {t('resume.lastActivity').replace('{when}', formatRelative(resume.last_activity_at))}
        {' · '}
        {t('resume.messages').replace('{n}', formatNumber(resume.total_messages))}
        {' · '}
        {t('resume.tokens').replace('{n}', formatNumber(resume.total_tokens))}
      </div>

      {resume.last_user_message && (
        <div style={{ opacity: 0.7 }}>
          <b>{t('resume.you')}:</b> {preview(resume.last_user_message)}
        </div>
      )}
      {resume.last_assistant_message && (
        <div style={{ opacity: 0.7 }}>
          <b>{t('resume.agent')}:</b> {preview(resume.last_assistant_message)}
        </div>
      )}

      <div style={{ fontSize: 11, opacity: 0.55 }}>{t('resume.continueHint')}</div>
    </div>
  );
}
