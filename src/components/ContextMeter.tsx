/**
 * Medidor de contexto (A.5) — desglose de tokens por fuente en vivo.
 * Vive en el memory rail del chat. Ajustar el límite escribe el override
 * `context_max_tokens` del proyecto → el siguiente request del gateway lo
 * refleja (el historial viejo se recorta primero). Fail-open: sin gateway
 * el medidor simplemente no muestra datos.
 */
import { useEffect, useState } from 'react';
import { Gauge, TriangleAlert } from 'lucide-react';
import { useI18n } from '../i18n';
import { useContextInfo, useSetContextLimit } from '../hooks/useSessions';
import type { ContextSource } from '../lib/chatApi';

const SOURCE_LABEL_KEYS: Record<string, string> = {
  system: 'context.source.system',
  historial: 'context.source.historial',
  knowledge: 'context.source.knowledge',
  tools: 'context.source.tools',
  archivos: 'context.source.files',
};

const BAR_COLORS: Record<string, string> = {
  system: 'rgba(56,189,248,0.75)', // sky
  historial: 'rgba(99,102,241,0.75)', // indigo
  knowledge: 'rgba(52,211,153,0.75)', // emerald
  tools: 'rgba(251,191,36,0.75)', // amber
  archivos: 'rgba(232,121,249,0.75)', // fuchsia
};

export function ContextMeter({ sessionId }: { sessionId: string | null }) {
  const { t, formatNumber } = useI18n();
  const { data: ctx } = useContextInfo(sessionId);
  const setLimit = useSetContextLimit(sessionId);
  const [draftLimit, setDraftLimit] = useState('');
  const [editing, setEditing] = useState(false); // no pisar el input mientras se escribe

  // sincroniza el input con el límite efectivo que llega del gateway
  useEffect(() => {
    if (ctx && !editing) setDraftLimit(String(ctx.limit_tokens));
  }, [ctx?.limit_tokens, editing]); // eslint-disable-line react-hooks/exhaustive-deps

  const pct = (tokens: number) =>
    ctx && ctx.limit_tokens > 0 ? Math.min(100, (tokens / ctx.limit_tokens) * 100) : 0;
  const truncated = ctx ? ctx.total_tokens > ctx.sent_tokens : false;

  const applyLimit = () => {
    if (!ctx) return;
    const n = parseInt(draftLimit, 10);
    if (!Number.isFinite(n) || n < 256 || n === ctx.limit_tokens) return;
    setLimit.mutate({ projectId: ctx.project_id, limit: n });
  };

  const SourceRow = ({ s }: { s: ContextSource }) => (
    <div data-testid={`ctx-row-${s.source}`} style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11 }}>
        <span style={{ opacity: 0.75 }}>{t(SOURCE_LABEL_KEYS[s.source] ?? s.source)}</span>
        <span style={{ opacity: 0.9, fontVariantNumeric: 'tabular-nums' }}>
          {formatNumber(s.tokens)}
        </span>
      </div>
      <div
        style={{
          height: 5,
          borderRadius: 3,
          background: 'rgba(148,163,184,0.15)',
          overflow: 'hidden',
        }}
      >
        <div
          data-testid={`ctx-bar-${s.source}`}
          style={{
            height: '100%',
            width: `${pct(s.tokens)}%`,
            borderRadius: 3,
            background: BAR_COLORS[s.source] ?? 'rgba(148,163,184,0.6)',
            transition: 'width 300ms ease',
          }}
        />
      </div>
    </div>
  );

  return (
    <div data-testid="context-meter" style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontWeight: 600 }}>
        <Gauge width={16} height={16} /> {t('context.title')}
      </div>

      {!ctx && <p style={{ fontSize: 12, opacity: 0.6 }}>{t('context.noSession')}</p>}

      {ctx && (
        <>
          <div data-testid="context-total" style={{ fontSize: 12, opacity: 0.85 }}>
            {truncated
              ? t('context.sentOf')
                  .replace('{sent}', formatNumber(ctx.sent_tokens))
                  .replace('{total}', formatNumber(ctx.total_tokens))
              : t('context.total').replace('{total}', formatNumber(ctx.total_tokens))}
            {' · '}
            {t('context.limit').replace('{limit}', formatNumber(ctx.limit_tokens))}
          </div>
          {truncated && (
            <div
              data-testid="context-truncated"
              style={{ display: 'flex', alignItems: 'center', gap: 5, fontSize: 11, color: '#fbbf24' }}
            >
              <TriangleAlert width={13} height={13} /> {t('context.truncated')}
            </div>
          )}

          {ctx.sources.map((s) => (
            <SourceRow key={s.source} s={s} />
          ))}

          <div style={{ display: 'flex', gap: 6, marginTop: 4 }}>
            <input
              data-testid="context-limit-input"
              type="number"
              min={256}
              value={draftLimit}
              onFocus={(e) => {
                setEditing(true);
                e.currentTarget.select(); // escribir reemplaza el valor completo
              }}
              onBlur={() => setEditing(false)}
              onChange={(e) => setDraftLimit(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && applyLimit()}
              aria-label={t('context.limit')}
              style={{
                flex: 1,
                minWidth: 0,
                background: 'rgba(15,23,42,0.5)',
                border: '1px solid rgba(148,163,184,0.25)',
                borderRadius: 8,
                padding: '6px 8px',
                fontSize: 12,
                color: 'inherit',
              }}
            />
            <button
              className="btn-primary"
              data-testid="context-limit-apply"
              onClick={applyLimit}
              disabled={setLimit.isPending}
              style={{ fontSize: 12, padding: '6px 10px', borderRadius: 8, cursor: 'pointer' }}
            >
              {t('context.apply')}
            </button>
          </div>
          <p style={{ fontSize: 11, opacity: 0.5 }}>{t('context.limitHint')}</p>
        </>
      )}
    </div>
  );
}
