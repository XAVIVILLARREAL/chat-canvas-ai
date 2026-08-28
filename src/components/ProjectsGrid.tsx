/**
 * ProjectsGrid (A.0) — card-grid de proyectos ("entrar por card").
 * Se abre como modal desde el ProjectSwitcher; entrar = cambiar de proyecto
 * (persistido en settings del gateway). Fail-open sin gateway.
 */
import { useCallback, useEffect, useState } from 'react';
import { FolderOpen, Plus, LogIn } from 'lucide-react';
import { projectsApi, UI_KEYS, type ProjectInfo } from '../lib/projectsApi';
import { useI18n } from '../i18n';
import { useModal } from './Modal';

export function ProjectsGridContent({ onEnter }: { onEnter?: (id: string) => void }) {
  const { t } = useI18n();
  const { closeAllModals } = useModal();
  const [projects, setProjects] = useState<ProjectInfo[]>([]);
  const [activeId, setActiveId] = useState<string>('');
  const [disabled, setDisabled] = useState(false);

  const reload = useCallback(async () => {
    const list = await projectsApi.list();
    if (!list) {
      setDisabled(true);
      return;
    }
    setProjects(list);
    const settings = await projectsApi.globalSettings();
    const saved = settings?.[UI_KEYS.activeProject];
    if (typeof saved === 'string') setActiveId(saved);
  }, []);

  useEffect(() => {
    reload();
  }, [reload]);

  const enter = async (id: string) => {
    setActiveId(id);
    await projectsApi.putGlobalSetting(UI_KEYS.activeProject, id);
    closeAllModals(); // entrar cierra el grid — el header queda accesible
    onEnter?.(id);
  };

  const create = async () => {
    const name = window.prompt(t('project.newName'));
    if (!name?.trim()) return;
    const p = await projectsApi.create(name.trim());
    if (p) {
      await reload();
      await enter(p.id);
    }
  };

  if (disabled) {
    return <p style={{ opacity: 0.7 }}>{t('project.gatewayOff')}</p>;
  }

  return (
    <div className="projects-grid" data-testid="projects-grid" style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: 16 }}>
      {projects.map((p) => (
        <div
          key={p.id}
          data-testid={`card-${p.id}`}
          className="project-card"
          style={{
            border: '1px solid rgba(148,163,184,0.25)',
            borderRadius: 14,
            padding: 16,
            display: 'flex',
            flexDirection: 'column',
            gap: 8,
            cursor: 'pointer',
            background: p.id === activeId ? 'rgba(99,102,241,0.12)' : 'rgba(15,23,42,0.35)',
          }}
          onClick={() => enter(p.id)}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <FolderOpen width={18} height={18} />
            <strong style={{ flex: 1, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{p.name}</strong>
            {p.id === activeId && <span className="active-badge">✓</span>}
          </div>
          <span style={{ fontSize: 12, opacity: 0.6 }}>
            {p.created_at ? new Date(p.created_at).toLocaleDateString() : ''}
          </span>
          <button
            className="btn-primary"
            data-testid={`enter-${p.id}`}
            onClick={(e) => { e.stopPropagation(); enter(p.id); }}
            style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6 }}
          >
            <LogIn width={14} height={14} /> {t('project.enter')}
          </button>
        </div>
      ))}
      <div
        data-testid="card-new"
        className="project-card project-card-new"
        onClick={create}
        style={{
          border: '1px dashed rgba(148,163,184,0.4)',
          borderRadius: 14,
          padding: 16,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 8,
          cursor: 'pointer',
          minHeight: 110,
          opacity: 0.8,
        }}
      >
        <Plus width={18} height={18} /> {t('header.newProject')}
      </div>
    </div>
  );
}
