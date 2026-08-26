import React, { useState, useRef, useEffect } from 'react';
import { 
  FilePlus, Save, Download, Upload, Play, Settings, 
  ChevronDown, RotateCcw, Command, Menu,
} from 'lucide-react';
import { Sun, Moon, Languages } from 'lucide-react';
import { useTheme } from '../theme';
import { useI18n, useI18nStore, SUPPORTED_LOCALES } from '../i18n';
import { useCanvasStore } from '../stores/canvas-store';
import type { Canvas } from '../types';
import './Header.css';

interface HeaderProps {
  currentCanvas: Canvas | null;
  canvases: Canvas[];
  onCreateCanvas: () => void;
  onSwitchCanvas: (canvas: Canvas) => void;
  loading: boolean;
}

export const Header: React.FC<HeaderProps> = ({
  currentCanvas,
  canvases,
  onCreateCanvas,
  onSwitchCanvas,
  loading,
}) => {
  const { resolved, toggle: toggleTheme } = useTheme();
  const { t, locale } = useI18n();
  const [showCanvasMenu, setShowCanvasMenu] = useState(false);
  const [showCommandPalette, setShowCommandPalette] = useState(false);
  const canvasMenuRef = useRef<HTMLDivElement>(null);
  const commandPaletteRef = useRef<HTMLDivElement>(null);

  const {
    toggleSidebar,
    undo,
    redo,
    canUndo,
    canRedo,
    exportCanvas,
    fitView,
  } = useCanvasStore();

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (canvasMenuRef.current && !canvasMenuRef.current.contains(e.target as Node)) {
        setShowCanvasMenu(false);
      }
      if (commandPaletteRef.current && !commandPaletteRef.current.contains(e.target as Node)) {
        setShowCommandPalette(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return;
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') { e.preventDefault(); setShowCommandPalette(!showCommandPalette); }
      if (e.key === 'Escape') { setShowCanvasMenu(false); setShowCommandPalette(false); }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [showCommandPalette]);

  const handleImportCanvas = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (event) => {
      const json = event.target?.result as string;
      const success = useCanvasStore.getState().importCanvas(json);
      if (success) useCanvasStore.getState().addToast({ type: 'success', message: t('toast.importOk') });
      else useCanvasStore.getState().addToast({ type: 'error', message: t('toast.importError') });
    };
    reader.readAsText(file);
    e.target.value = '';
  };

  const handleExportCanvas = () => {
    const json = exportCanvas();
    if (!json) return;
    const blob = new Blob([json], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${currentCanvas?.name || 'canvas'}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const commandPaletteItems = [
    { id: 'new-canvas', label: t('palette.newCanvas'), shortcut: '⌘N', icon: FilePlus, action: onCreateCanvas },
    { id: 'save-canvas', label: t('palette.saveCanvas'), shortcut: '⌘S', icon: Save, action: () => {} },
    { id: 'export-canvas', label: t('palette.exportCanvas'), shortcut: '⌘E', icon: Download, action: handleExportCanvas },
    { id: 'import-canvas', label: t('palette.importCanvas'), shortcut: '⌘I', icon: Upload, action: () => {} },
    { id: 'execute-canvas', label: t('palette.executeCanvas'), shortcut: '⌘Enter', icon: Play, action: () => {} },
    { id: 'fit-view', label: t('palette.fitView'), shortcut: 'F', icon: RotateCcw, action: fitView },
    { id: 'undo', label: t('palette.undo'), shortcut: '⌘Z', icon: RotateCcw, action: undo, disabled: !canUndo() },
    { id: 'redo', label: t('palette.redo'), shortcut: '⌘⇧Z', icon: RotateCcw, action: redo, disabled: !canRedo() },
    { id: 'toggle-sidebar', label: t('palette.toggleSidebar'), shortcut: '⌘B', icon: Menu, action: toggleSidebar },
  ];

  return (
    <header className="app-header">
      <div className="header-left">
        <button className="header-btn" onClick={toggleSidebar} title={t("header.toggleSidebar")}><Menu width={20} height={20} /></button>
        <div className="canvas-menu" ref={canvasMenuRef}>
          <button className="canvas-selector" onClick={() => setShowCanvasMenu(!showCanvasMenu)} title={t("header.changeCanvas")}>
            <FilePlus width={16} height={16} />
            <span className="canvas-name">{currentCanvas?.name || t('header.noCanvas')}</span>
            <ChevronDown width={14} height={14} />
          </button>
          {showCanvasMenu && (
            <div className="canvas-dropdown">
              <div className="dropdown-header">
                <span>{t("header.canvases", { n: canvases.length })}</span>
                <button className="dropdown-action" onClick={onCreateCanvas}><FilePlus width={12} height={12} /> {t("header.new")}</button>
              </div>
              <div className="dropdown-list">
                {canvases.map(canvas => (
                  <button key={canvas.id} className={`dropdown-item ${currentCanvas?.id === canvas.id ? 'active' : ''}`} onClick={() => { onSwitchCanvas(canvas); setShowCanvasMenu(false); }}>
                    <span className="item-name">{canvas.name}</span>
                    <span className="item-meta">{canvas.nodes.length} nodos · v{canvas.version}</span>
                    {currentCanvas?.id === canvas.id && <span className="active-badge">{t("header.current")}</span>}
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>

      <div className="header-center">
        <h1>{t("app.title")}</h1>
        <span className="subtitle">{t("app.subtitle")}</span>
      </div>

      <div className="header-right">
        <button className="header-btn command-palette-trigger" onClick={() => setShowCommandPalette(!showCommandPalette)} title={t("header.commandPalette")}><Command width={18} height={18} /></button>
        <div className="header-divider" />
        <button className="header-btn" onClick={undo} disabled={!canUndo()} title={t("header.undo")}><RotateCcw width={16} height={16} /></button>
        <button className="header-btn" onClick={redo} disabled={!canRedo()} title={t("header.redo")}><RotateCcw width={16} height={16} style={{ transform: 'rotate(180deg)' }} /></button>
        <div className="header-divider" />
        <div className="header-dropdown">
          <button className="header-btn" title={t("header.file")}><FilePlus width={18} height={18} /></button>
          <div className="dropdown-menu">
            <button className="dropdown-item" onClick={onCreateCanvas}><FilePlus width={14} height={14} /> {t("header.newCanvas")}</button>
            <button className="dropdown-item" onClick={handleExportCanvas}><Download width={14} height={14} /> {t("header.export")}</button>
            <label className="dropdown-item"><Upload width={14} height={14} /> {t("header.import")}<input type="file" accept=".json" onChange={handleImportCanvas} hidden /></label>
          </div>
        </div>
        <div className="header-divider" />
        <button className="header-btn execute-btn" disabled={loading || !currentCanvas?.nodes.length} title={t("header.executeTitle")}><Play width={18} height={18} /><span>{t("header.execute")}</span></button>
        <div className="header-divider" />
        <button className="header-btn" onClick={toggleTheme} title={t("header.theme")} aria-label={t("header.theme")}>
          {resolved === 'dark' ? <Sun width={18} height={18} /> : <Moon width={18} height={18} />}
        </button>
        <div className="header-dropdown">
          <button className="header-btn" title={t("header.language")} aria-label={t("header.language")}><Languages width={18} height={18} /></button>
          <div className="dropdown-menu">
            {SUPPORTED_LOCALES.map((l) => (
              <button key={l} className={`dropdown-item ${locale === l ? 'active' : ''}`} onClick={(e) => { useI18nStore.getState().setLocale(l); (e.currentTarget as HTMLElement).blur(); }}>
                {l.toUpperCase()}{locale === l && <span className="active-badge">✓</span>}
              </button>
            ))}
          </div>
        </div>
        <button className="header-btn" title={t("header.settings")}><Settings width={18} height={18} /></button>
      </div>

      {showCommandPalette && (
        <div className="command-palette-overlay" onClick={() => setShowCommandPalette(false)}>
          <div className="command-palette" ref={commandPaletteRef} onClick={(e) => e.stopPropagation()}>
            <div className="palette-header"><Command width={18} height={18} /><input type="text" placeholder={t("palette.placeholder")} autoFocus className="palette-input" /><kbd>⌘K</kbd></div>
            <div className="palette-list">
              {commandPaletteItems.map(item => (
                <button key={item.id} className={`palette-item ${item.disabled ? 'disabled' : ''}`} onClick={() => { item.action(); setShowCommandPalette(false); }} disabled={item.disabled}>
                  <item.icon width={14} height={14} /><span>{item.label}</span><kbd>{item.shortcut}</kbd>
                </button>
              ))}
            </div>
          </div>
        </div>
      )}
    </header>
  );
};

export default Header;
