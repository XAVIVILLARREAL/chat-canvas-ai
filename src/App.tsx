import { useEffect } from 'react';
import { ReactFlowProvider } from '@xyflow/react';
import { Canvas } from './components/Canvas';
import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { ToastContainer } from './components/ToastContainer';
import { ModalProvider } from './components/Modal';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ChatPanel } from './components/ChatPanel';
import { LayoutGrid, MessageSquare } from 'lucide-react';
import { useChatUiStore } from './stores/chat-ui-store';
import { useI18n } from './i18n';
import { useCanvasStore } from './stores/canvas-store';
import type { Canvas as CanvasDomain } from "./types";
import './styles.css';

function App() {
  const { t } = useI18n();
  const view = useChatUiStore((st) => st.view);
  const setView = useChatUiStore((st) => st.setView);
  const {
    currentCanvas,
    sidebarOpen,
    sidebarTab,
    loading,
    canvases,
    skills,
    agents,
    mcpServers,
    executions,
    fetchCanvases,
    fetchSkills,
    fetchAgents,
    fetchMcpServers,
    fetchExecutions,
    createCanvas,
    setCurrentCanvas,
    setSidebarTab,
  } = useCanvasStore();

  useEffect(() => {
    const loadData = async () => {
      try {
        await Promise.all([
          fetchCanvases(),
          fetchSkills(),
          fetchAgents(),
          fetchMcpServers(),
          fetchExecutions(),
        ]);
      } catch (error) {
        console.error('Failed to load initial data:', error);
      }
    };
    loadData();
  }, [fetchCanvases, fetchSkills, fetchAgents, fetchMcpServers, fetchExecutions]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return;
      if ((e.metaKey || e.ctrlKey) && e.key === 'n') { e.preventDefault(); createCanvas(); }
      if ((e.metaKey || e.ctrlKey) && e.key === 's') { e.preventDefault(); }
      if ((e.metaKey || e.ctrlKey) && e.key === 'e') { e.preventDefault(); }
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') { e.preventDefault(); }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [createCanvas]);

  const handleSwitchCanvas = (canvas: CanvasDomain) => setCurrentCanvas(canvas);

  return (
    <ModalProvider>
      <div className="app">
        <Header 
          currentCanvas={currentCanvas}
          canvases={canvases}
          onCreateCanvas={createCanvas}
          onSwitchCanvas={handleSwitchCanvas}
          loading={loading}
        />
        <main className="app-main">
          {view === 'chat' ? (
            <section className="canvas-section" data-testid="chat-view"><ChatPanel /></section>
          ) : (
            <section className="canvas-section mesh-bg" data-testid="canvas-view"><ReactFlowProvider><Canvas /></ReactFlowProvider></section>
          )}
          <aside className={`app-sidebar sidebar ${sidebarOpen ? 'open' : 'closed'}`}>
            <Sidebar 
              activeTab={sidebarTab}
              onTabChange={setSidebarTab}
              skills={skills}
              agents={agents}
              mcpServers={mcpServers}
              executions={executions}
            />
          </aside>
        </main>
        <ToastContainer />
      </div>
      {/* BottomNav (solo móvil ≤900px): alterna Canvas/Chat */}
      <nav className="bottom-nav" data-testid="bottom-nav">
        <button data-testid="bottom-canvas" onClick={() => setView('canvas')} aria-label={t('view.canvas')}>
          <LayoutGrid width={20} height={20} />
          <span>{t('view.canvas')}</span>
        </button>
        <button data-testid="bottom-chat" onClick={() => setView('chat')} aria-label={t('view.chat')}>
          <MessageSquare width={20} height={20} />
          <span>{t('view.chat')}</span>
        </button>
      </nav>
    </ModalProvider>
  );
}

const queryClient = new QueryClient({
  defaultOptions: { queries: { retry: 1, refetchOnWindowFocus: false } },
});

export default function AppRoot() {
  return (
    <QueryClientProvider client={queryClient}>
      <App />
    </QueryClientProvider>
  );
}


