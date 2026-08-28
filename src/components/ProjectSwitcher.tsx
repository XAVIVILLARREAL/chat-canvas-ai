/**
 * ProjectSwitcher (A.0 — Proyectos como SCOPE).
 * Lista/crea/cambia el proyecto activo; persiste la selección en settings
 * del gateway (ui.active_project) para restaurar tras reinicio.
 * Fail-open: sin gateway, se deshabilita silenciosamente (dev local puro).
 */
import { useEffect, useRef, useState } from 'react';
import { FolderOpen, Plus, Check } from 'lucide-react';
import { projectsApi, UI_KEYS, type ProjectInfo } from '../lib/projectsApi';
import { useI18n } from '../i18n';
import { useModal } from './Modal';
import { ProjectsGridContent } from './ProjectsGrid';

const DEFAULT_PROJECT: ProjectInfo = { id: 'local-default', name: 'Canvas AI' };

export function ProjectSwitcher() {
  const { t } = useI18n();
  const { openModal } = useModal();
  const [open, setOpen] = useState(false);
  const [projects, setProjects] = useState<ProjectInfo[]>([DEFAULT_PROJECT]);
  const [activeId, setActiveId] = useState<string>(DEFAULT_PROJECT.id);
  const [disabled, setDisabled] = useState(false);
  const [creating, setCreating] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    (async () => {
      const list = await projectsApi.list();
      if (!list) {
        setDisabled(true); // gateway ausente → fail-open
        return;
      }
      setProjects([...list]);
      // restaurar proyecto activo tras reinicio (settings globales)
      const settings = await projectsApi.globalSettings();
      const saved = settings?.[UI_KEYS.activeProject];
      if (typeof saved === 'string' && list.some((p) => p.id === saved)) {
        setActiveId(saved);
      }
    })();
  }, []);

  // cerrar al hacer click fuera
  useEffect(() => {
    if (!open) return;
    const close = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener('click', close);
    return () => document.removeEventListener('click', close);
  }, [open]);

  const switchTo = async (id: string) => {
    setActiveId(id);
    setOpen(false);
    await projectsApi.putGlobalSetting(UI_KEYS.activeProject, id);
  };

  const createProject = async () => {
    const name = window.prompt(t('project.newName'));
    if (!name?.trim()) return;
    const p = await projectsApi.create(name.trim());
    if (p) {
      setProjects((prev) => [...prev, p]);
      await switchTo(p.id);
    }
    setCreating(false);
  };

  const active = projects.find((p) => p.id === activeId) ?? DEFAULT_PROJECT;

  return (
    <div className="header-dropdown" ref={ref} data-testid="project-switcher">
      <button
        className="header-btn"
        disabled={disabled}
        onClick={() => setOpen((o) => !o)}
        title={t('header.projects')}
        aria-label={t('header.projects')}
        style={{ display: 'flex', alignItems: 'center', gap: 6 }}
      >
        <FolderOpen width={18} height={18} />
        <span style={{ fontSize: 13, maxWidth: 120, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
          {active.name}
        </span>
      </button>
      {open && (
        <div className="dropdown-menu" role="menu">
          {projects.map((p) => (
            <button
              key={p.id}
              className={`dropdown-item ${p.id === activeId ? 'active' : ''}`}
              data-testid={`project-${p.id}`}
              onClick={() => switchTo(p.id)}
            >
              {p.name}
              {p.id === activeId && <span className="active-badge">✓</span>}
            </button>
          ))}
          <button className="dropdown-item" data-testid="project-new" onClick={createProject}>
            <Plus width={14} height={14} /> {t('header.newProject')}
          </button>
          <button
            className="dropdown-item"
            data-testid="projects-grid-open"
            onClick={() => { setOpen(false); openModal(<><h2 style={{ margin: '0 0 16px' }}>{t('header.projects')}</h2><ProjectsGridContent /></>, { size: 'lg' }); }}
          >
            <FolderOpen width={14} height={14} /> {t('project.viewAll')}
          </button>
        </div>
      )}
      {creating && null}
      <Check style={{ display: 'none' }} />
    </div>
  );
}
