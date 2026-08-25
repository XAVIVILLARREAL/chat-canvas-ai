import React, { useState, useRef, useEffect } from 'react';
import { 
  FilePlus, Save, Download, Upload, Play, Settings, 
  ChevronDown, RotateCcw, Command, Menu,
} from 'lucide-react';
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
      if (success) useCanvasStore.getState().addToast({ type: 'success', message: 'Canvas importado correctamente' });
      else useCanvasStore.getState().addToast({ type: 'error', message: 'Error al importar canvas' });
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
    { id: 'new-canvas', label: 'Nuevo Canvas', shortcut: '⌘N', icon: FilePlus, action: onCreateCanvas },
    { id: 'save-canvas', label: 'Guardar Canvas', shortcut: '⌘S', icon: Save, action: () => {} },
    { id: 'export-canvas', label: 'Exportar Canvas', shortcut: '⌘E', icon: Download, action: handleExportCanvas },
    { id: 'import-canvas', label: 'Importar Canvas', shortcut: '⌘I', icon: Upload, action: () => {} },
    { id: 'execute-canvas', label: 'Ejecutar Canvas', shortcut: '⌘Enter', icon: Play, action: () => {} },
    { id: 'fit-view', label: 'Ajustar Vista', shortcut: 'F', icon: RotateCcw, action: fitView },
    { id: 'undo', label: 'Deshacer', shortcut: '⌘Z', icon: RotateCcw, action: undo, disabled: !canUndo() },
    { id: 'redo', label: 'Rehacer', shortcut: '⌘⇧Z', icon: RotateCcw, action: redo, disabled: !canRedo() },
    { id: 'toggle-sidebar', label: 'Toggle Sidebar', shortcut: '⌘B', icon: Menu, action: toggleSidebar },
  ];

  return (
    <header className="app-header">
      <div className="header-left">
        <button className="header-btn" onClick={toggleSidebar} title="Toggle Sidebar (⌘B)"><Menu width={20} height={20} /></button>
        <div className="canvas-menu" ref={canvasMenuRef}>
          <button className="canvas-selector" onClick={() => setShowCanvasMenu(!showCanvasMenu)} title="Cambiar Canvas">
            <FilePlus width={16} height={16} />
            <span className="canvas-name">{currentCanvas?.name || 'Sin canvas'}</span>
            <ChevronDown width={14} height={14} />
          </button>
          {showCanvasMenu && (
            <div className="canvas-dropdown">
              <div className="dropdown-header">
                <span>Canvases ({canvases.length})</span>
                <button className="dropdown-action" onClick={onCreateCanvas}><FilePlus width={12} height={12} /> Nuevo</button>
              </div>
              <div className="dropdown-list">
                {canvases.map(canvas => (
                  <button key={canvas.id} className={`dropdown-item ${currentCanvas?.id === canvas.id ? 'active' : ''}`} onClick={() => { onSwitchCanvas(canvas); setShowCanvasMenu(false); }}>
                    <span className="item-name">{canvas.name}</span>
                    <span className="item-meta">{canvas.nodes.length} nodos · v{canvas.version}</span>
                    {currentCanvas?.id === canvas.id && <span className="active-badge">Actual</span>}
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>

      <div className="header-center">
        <h1>AI Canvas</h1>
        <span className="subtitle">Automatizaciones con IA nativa</span>
      </div>

      <div className="header-right">
        <button className="header-btn command-palette-trigger" onClick={() => setShowCommandPalette(!showCommandPalette)} title="Command Palette (⌘K)"><Command width={18} height={18} /></button>
        <div className="header-divider" />
        <button className="header-btn" onClick={undo} disabled={!canUndo()} title="Deshacer (⌘Z)"><RotateCcw width={16} height={16} /></button>
        <button className="header-btn" onClick={redo} disabled={!canRedo()} title="Rehacer (⌘⇧Z)"><RotateCcw width={16} height={16} style={{ transform: 'rotate(180deg)' }} /></button>
        <div className="header-divider" />
        <div className="header-dropdown">
          <button className="header-btn" title="Archivo"><FilePlus width={18} height={18} /></button>
          <div className="dropdown-menu">
            <button className="dropdown-item" onClick={onCreateCanvas}><FilePlus width={14} height={14} /> Nuevo Canvas</button>
            <button className="dropdown-item" onClick={handleExportCanvas}><Download width={14} height={14} /> Exportar</button>
            <label className="dropdown-item"><Upload width={14} height={14} /> Importar<input type="file" accept=".json" onChange={handleImportCanvas} hidden /></label>
          </div>
        </div>
        <div className="header-divider" />
        <button className="header-btn execute-btn" disabled={loading || !currentCanvas?.nodes.length} title="Ejecutar Canvas (⌘Enter)"><Play width={18} height={18} /><span>Ejecutar</span></button>
        <div className="header-divider" />
        <button className="header-btn" title="Configuración"><Settings width={18} height={18} /></button>
      </div>

      {showCommandPalette && (
        <div className="command-palette-overlay" onClick={() => setShowCommandPalette(false)}>
          <div className="command-palette" ref={commandPaletteRef} onClick={(e) => e.stopPropagation()}>
            <div className="palette-header"><Command width={18} height={18} /><input type="text" placeholder="Escribe un comando o busca..." autoFocus className="palette-input" /><kbd>⌘K</kbd></div>
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
