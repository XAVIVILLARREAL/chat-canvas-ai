/**
 * Centro de Configuración (A.6) — 2 públicos, 4 scopes con valor efectivo y origen.
 * - No-programador: catálogo de perillas editables con clicks (valor + badge de origen).
 * - Programador: JSON de overrides del scope elegido, validado al aplicar.
 * Precedencia real del gateway: Agente > Sesión > Proyecto > Global.
 * Subagente llega en Etapa C (el contrato ya lo deja lugar).
 */
import { useEffect, useState } from 'react';
import { SlidersHorizontal, Braces, MousePointerClick } from 'lucide-react';
import { useI18n } from '../i18n';
import { useChatUiStore } from '../stores/chat-ui-store';
import {
  useEffectiveSettings, useAgents, useActiveProjectId, useWriteConfig,
} from '../hooks/useConfig';
import type { ConfigScope, SettingEntry, AgentInfo } from '../lib/configApi';

const SCOPES: ConfigScope[] = ['global', 'project', 'session', 'agent'];

const ORIGIN_COLORS: Record<string, string> = {
  global: 'rgba(56,189,248,0.9)', // sky
  project: 'rgba(99,102,241,0.9)', // indigo
  session: 'rgba(52,211,153,0.9)', // emerald
  agent: 'rgba(232,121,249,0.9)', // fuchsia
};

const KNOBS = [
  { key: 'model', type: 'text' as const },
  { key: 'temperature', type: 'number' as const, step: 0.1, min: 0, max: 2 },
  { key: 'context_max_tokens', type: 'number' as const, step: 256, min: 256 },
];

export function ConfigCenter() {
  const { t } = useI18n();
  const activeSessionId = useChatUiStore((s) => s.activeSessionId);
  const { data: projectId = 'local-default' } = useActiveProjectId();
  const { data: effective } = useEffectiveSettings(projectId, activeSessionId);
  const { data: agents } = useAgents();
  const write = useWriteConfig(activeSessionId);

  const [mode, setMode] = useState<'simple' | 'json'>('simple');
  const [scope, setScope] = useState<ConfigScope>('project');
  const [agentId, setAgentId] = useState<string>('');
  const [drafts, setDrafts] = useState<Record<string, string>>({});
  const [jsonDraft, setJsonDraft] = useState('{}');
  const [jsonError, setJsonError] = useState<string | null>(null);

  const agent: AgentInfo | null =
    agents?.find((a) => a.id === agentId) ?? null;
  const scopeAvailable = (s: ConfigScope) =>
    s !== 'session' || !!activeSessionId;
  const targetReady =
    scope === 'session' ? !!activeSessionId
    : scope === 'agent' ? !!agent
    : true;

  // JSON del programador = overrides del scope elegido (items con ese origen)
  useEffect(() => {
    if (!effective) return;
    const overrides: Record<string, unknown> = {};
    for (const it of effective.items) {
      if (it.origin === scope) overrides[it.key] = it.value;
    }
    setJsonDraft(JSON.stringify(overrides, null, 2));
    setJsonError(null);
  }, [effective, scope]);

  const entry = (key: string): SettingEntry | undefined =>
    effective?.items.find((i) => i.key === key);

  const save = (key: string, value: unknown) => {
    write.mutate({ scope, projectId, sessionId: activeSessionId, agent, key, value });
  };

  const saveKnob = (key: string) => {
    const raw = (drafts[key] ?? '').trim();
    if (!raw) return;
    const knob = KNOBS.find((k) => k.key === key)!;
    const value = knob.type === 'number' ? Number(raw) : raw;
    if (knob.type === 'number' && !Number.isFinite(value)) return;
    save(key, value);
  };

  const applyJson = () => {
    let parsed: unknown;
    try {
      parsed = JSON.parse(jsonDraft);
    } catch (e) {
      setJsonError(t('config.jsonInvalid').replace('{err}', (e as Error).message));
      return;
    }
    if (parsed === null || typeof parsed !== 'object' || Array.isArray(parsed)) {
      setJsonError(t('config.jsonNotObject'));
      return;
    }
    setJsonError(null);
    for (const [k, v] of Object.entries(parsed as Record<string, unknown>)) {
      save(k, v);
    }
  };

  const OriginBadge = ({ origin }: { origin: string }) => (
    <span
      data-testid={`cfg-origin-${origin}`}
      style={{
        fontSize: 10,
        padding: '2px 7px',
        borderRadius: 999,
        background: ORIGIN_COLORS[origin] ?? 'rgba(148,163,184,0.4)',
        color: '#0f172a',
        fontWeight: 600,
      }}
    >
      {t(`config.scope.${origin}`)}
    </span>
  );

  return (
    <div data-testid="config-center" style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontWeight: 600 }}>
        <SlidersHorizontal width={15} height={15} /> {t('config.title')}
      </div>

      {/* selector de scope destino de las escrituras */}
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
        {SCOPES.map((s) => (
          <button
            key={s}
            data-testid={`cfg-scope-${s}`}
            onClick={() => setScope(s)}
            disabled={!scopeAvailable(s)}
            title={!scopeAvailable(s) ? t('config.noSessionScope') : undefined}
            style={{
              fontSize: 11,
              padding: '4px 9px',
              borderRadius: 999,
              cursor: scopeAvailable(s) ? 'pointer' : 'not-allowed',
              opacity: scopeAvailable(s) ? 1 : 0.4,
              border: '1px solid rgba(148,163,184,0.3)',
              background: scope === s ? 'rgba(99,102,241,0.35)' : 'transparent',
              color: 'inherit',
            }}
          >
            {t(`config.scope.${s}`)}
          </button>
        ))}
      </div>

      {scope === 'agent' && (
        <select
          data-testid="cfg-agent-select"
          value={agentId}
          onChange={(e) => setAgentId(e.target.value)}
          style={{
            fontSize: 12, padding: '6px 8px', borderRadius: 8,
            background: 'rgba(15,23,42,0.5)', color: 'inherit',
            border: '1px solid rgba(148,163,184,0.25)',
          }}
        >
          <option value="">{t('config.pickAgent')}</option>
          {(agents ?? []).map((a) => (
            <option key={a.id} value={a.id}>{a.name}</option>
          ))}
        </select>
      )}

      {/* alternador de público */}
      <div style={{ display: 'flex', gap: 4 }}>
        <button
          data-testid="cfg-mode-simple"
          onClick={() => setMode('simple')}
          style={{
            display: 'flex', alignItems: 'center', gap: 4, fontSize: 11,
            padding: '4px 8px', borderRadius: 8, cursor: 'pointer',
            background: mode === 'simple' ? 'rgba(99,102,241,0.3)' : 'transparent',
            border: '1px solid rgba(148,163,184,0.3)', color: 'inherit',
          }}
        >
          <MousePointerClick width={12} height={12} /> {t('config.modeSimple')}
        </button>
        <button
          data-testid="cfg-mode-json"
          onClick={() => setMode('json')}
          style={{
            display: 'flex', alignItems: 'center', gap: 4, fontSize: 11,
            padding: '4px 8px', borderRadius: 8, cursor: 'pointer',
            background: mode === 'json' ? 'rgba(99,102,241,0.3)' : 'transparent',
            border: '1px solid rgba(148,163,184,0.3)', color: 'inherit',
          }}
        >
          <Braces width={12} height={12} /> {t('config.modeJson')}
        </button>
      </div>

      {!effective && <p style={{ fontSize: 12, opacity: 0.6 }}>{t('config.gatewayOff')}</p>}

      {effective && mode === 'simple' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {KNOBS.map((knob) => {
            const e = entry(knob.key);
            return (
              <div
                key={knob.key}
                data-testid={`cfg-knob-${knob.key}`}
                style={{ display: 'flex', flexDirection: 'column', gap: 3 }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: 12, opacity: 0.85 }}>
                    {t(`config.knob.${knob.key}`)}
                  </span>
                  {e && <OriginBadge origin={e.origin} />}
                </div>
                <div style={{ display: 'flex', gap: 4 }}>
                  <input
                    data-testid={`cfg-input-${knob.key}`}
                    type={knob.type === 'number' ? 'number' : 'text'}
                    step={knob.step}
                    min={knob.min}
                    max={knob.max}
                    value={drafts[knob.key] ?? (e?.value != null ? String(e.value) : '')}
                    onChange={(ev) => setDrafts((d) => ({ ...d, [knob.key]: ev.target.value }))}
                    onKeyDown={(ev) => ev.key === 'Enter' && saveKnob(knob.key)}
                    aria-label={t(`config.knob.${knob.key}`)}
                    style={{
                      flex: 1, minWidth: 0, fontSize: 12, padding: '5px 8px', borderRadius: 8,
                      background: 'rgba(15,23,42,0.5)', color: 'inherit',
                      border: '1px solid rgba(148,163,184,0.25)',
                    }}
                  />
                  <button
                    className="btn-primary"
                    data-testid={`cfg-save-${knob.key}`}
                    onClick={() => saveKnob(knob.key)}
                    disabled={!targetReady || write.isPending}
                    title={!targetReady ? t('config.targetMissing') : undefined}
                    style={{ fontSize: 11, padding: '5px 9px', borderRadius: 8, cursor: 'pointer' }}
                  >
                    {t('config.save')}
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {effective && mode === 'json' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          <p style={{ fontSize: 11, opacity: 0.6 }}>{t('config.jsonHint')}</p>
          <textarea
            data-testid="cfg-json"
            value={jsonDraft}
            onChange={(ev) => setJsonDraft(ev.target.value)}
            rows={8}
            spellCheck={false}
            style={{
              fontSize: 12, fontFamily: 'monospace', padding: 8, borderRadius: 8,
              background: 'rgba(15,23,42,0.6)', color: 'inherit',
              border: `1px solid ${jsonError ? 'rgba(248,113,113,0.7)' : 'rgba(148,163,184,0.25)'}`,
              resize: 'vertical',
            }}
          />
          {jsonError && (
            <p data-testid="cfg-json-error" style={{ fontSize: 11, color: '#f87171' }}>{jsonError}</p>
          )}
          <button
            className="btn-primary"
            data-testid="cfg-json-apply"
            onClick={applyJson}
            disabled={!targetReady || write.isPending}
            title={!targetReady ? t('config.targetMissing') : undefined}
            style={{ fontSize: 12, padding: '6px 10px', borderRadius: 8, cursor: 'pointer', alignSelf: 'flex-start' }}
          >
            {t('config.apply')}
          </button>
        </div>
      )}
    </div>
  );
}
