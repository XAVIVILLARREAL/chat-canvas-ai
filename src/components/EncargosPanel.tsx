/**
 * Panel de Encargos (A.7) — "haz X" sin escribir prompt: el usuario da título
 * + criterios, el gateway compone el prompt y un provider BYOK lo completa.
 * La evidencia queda en el encargo (result/tokens/duración) y como mensajes
 * de la sesión. Notificación por toast al terminar; polling solo en curso.
 */
import { useEffect, useRef, useState } from 'react';
import { ClipboardList, ChevronDown, ChevronUp, Loader2 } from 'lucide-react';
import { useI18n } from '../i18n';
import { useCanvasStore } from '../stores/canvas-store';
import { useEncargos, useCreateEncargo, encargosKeys } from '../hooks/useEncargos';
import { useQueryClient } from '@tanstack/react-query';
import type { EncargoInfo } from '../lib/encargosApi';

const STATUS_ICON: Record<string, string> = {
  pending: '⏳',
  running: '⚙️',
  completed: '✅',
  failed: '❌',
};

export function EncargosPanel({ sessionId }: { sessionId: string | null }) {
  const { t, formatNumber } = useI18n();
  const { data: encargos = [] } = useEncargos();
  const create = useCreateEncargo(sessionId);
  const addToast = useCanvasStore((s) => s.addToast);
  const qc = useQueryClient();

  const [open, setOpen] = useState(false);
  const [title, setTitle] = useState('');
  const [criteria, setCriteria] = useState('');
  const [expanded, setExpanded] = useState<string | null>(null);
  const prevStatuses = useRef<Map<string, string>>(new Map());

  // notificación de vuelta con evidencia (toast) cuando un encargo termina
  useEffect(() => {
    for (const e of encargos) {
      const before = prevStatuses.current.get(e.id);
      prevStatuses.current.set(e.id, e.status);
      if (!before || before === e.status) continue;
      if (e.status === 'completed') {
        addToast({
          type: 'success',
          message: `${t('encargo.toastCompleted')}: ${e.title} · ${formatNumber(e.tokens)} tok`,
          duration: 6000,
        });
      } else if (e.status === 'failed') {
        addToast({
          type: 'error',
          message: `${t('encargo.toastFailed')}: ${e.title}${e.error ? ` — ${e.error.slice(0, 80)}` : ''}`,
          duration: 6000,
        });
      }
      qc.invalidateQueries({ queryKey: ['sessions', e.session_id, 'messages'] });
    }
  }, [encargos, addToast, t, formatNumber, qc]);

  const submit = async () => {
    const ti = title.trim();
    const cr = criteria.trim();
    if (!ti || !cr || create.isPending) return;
    try {
      await create.mutateAsync({ title: ti, criteria: cr });
      addToast({ type: 'info', message: `${t('encargo.toastStarted')}: ${ti}`, duration: 4000 });
      setTitle('');
      setCriteria('');
      setOpen(false);
      qc.invalidateQueries({ queryKey: encargosKeys.all });
    } catch {
      // fail-open: sin gateway no se puede crear (toast del error lo dice)
      addToast({ type: 'warning', message: t('encargo.gatewayOff'), duration: 4000 });
    }
  };

  const inFlight = encargos.some((e) => e.status === 'pending' || e.status === 'running');

  return (
    <div data-testid="encargos-panel" style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontWeight: 600 }}>
          <ClipboardList width={16} height={16} />
          {t('encargo.title')}
          {inFlight && <Loader2 width={13} height={13} className="spin" />}
        </div>
        <button
          data-testid="encargo-toggle-form"
          onClick={() => setOpen((o) => !o)}
          aria-label={t('encargo.new')}
          style={{
            fontSize: 16, lineHeight: 1, padding: '2px 8px', borderRadius: 8,
            cursor: 'pointer', border: '1px solid rgba(148,163,184,0.3)',
            background: 'transparent', color: 'inherit',
          }}
        >
          +
        </button>
      </div>

      {open && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          <input
            data-testid="encargo-title"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && submit()}
            placeholder={t('encargo.titlePlaceholder')}
            style={{
              fontSize: 12, padding: '6px 8px', borderRadius: 8,
              background: 'rgba(15,23,42,0.5)', color: 'inherit',
              border: '1px solid rgba(148,163,184,0.25)', minWidth: 0,
            }}
          />
          <textarea
            data-testid="encargo-criteria"
            value={criteria}
            onChange={(e) => setCriteria(e.target.value)}
            placeholder={t('encargo.criteriaPlaceholder')}
            rows={3}
            style={{
              fontSize: 12, padding: '6px 8px', borderRadius: 8, resize: 'vertical',
              background: 'rgba(15,23,42,0.5)', color: 'inherit',
              border: '1px solid rgba(148,163,184,0.25)', minWidth: 0,
            }}
          />
          <button
            className="btn-primary"
            data-testid="encargo-create"
            onClick={submit}
            disabled={create.isPending || !title.trim() || !criteria.trim()}
            style={{ fontSize: 12, padding: '6px 10px', borderRadius: 8, cursor: 'pointer', alignSelf: 'flex-start' }}
          >
            {t('encargo.create')}
          </button>
        </div>
      )}

      {encargos.length === 0 && !open && (
        <p style={{ fontSize: 12, opacity: 0.6 }}>{t('encargo.empty')}</p>
      )}

      <div style={{ display: 'flex', flexDirection: 'column', gap: 6, maxHeight: 220, overflowY: 'auto' }}>
        {encargos.map((e: EncargoInfo) => (
          <div
            key={e.id}
            data-testid={`encargo-item-${e.status}`}
            style={{
              border: '1px solid rgba(148,163,184,0.2)', borderRadius: 10,
              padding: '6px 8px', fontSize: 12,
            }}
          >
            <div
              style={{ display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer' }}
              onClick={() => setExpanded((x) => (x === e.id ? null : e.id))}
            >
              <span aria-label={e.status}>{STATUS_ICON[e.status] ?? '•'}</span>
              <span style={{ flex: 1, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                {e.title}
              </span>
              {expanded === e.id
                ? <ChevronUp width={13} height={13} />
                : <ChevronDown width={13} height={13} />}
            </div>
            {expanded === e.id && (
              <div data-testid="encargo-evidence" style={{ marginTop: 6, fontSize: 11, opacity: 0.85 }}>
                {e.status === 'completed' && e.result && (
                  <pre style={{ whiteSpace: 'pre-wrap', wordBreak: 'break-word', margin: 0 }}>
                    {e.result}
                  </pre>
                )}
                {e.status === 'failed' && e.error && (
                  <p style={{ color: '#f87171', margin: 0 }}>{e.error}</p>
                )}
                {(e.status === 'pending' || e.status === 'running') && (
                  <p style={{ margin: 0 }}>{t('encargo.inFlight')}</p>
                )}
                <p style={{ margin: '6px 0 0', opacity: 0.6 }}>
                  {e.model ? `${e.model} · ` : ''}
                  {e.tokens > 0 ? `${formatNumber(e.tokens)} tok · ` : ''}
                  {e.duration_ms != null ? `${(e.duration_ms / 1000).toFixed(1)}s` : ''}
                </p>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
