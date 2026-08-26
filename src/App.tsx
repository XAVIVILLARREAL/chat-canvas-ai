import { useEffect } from 'react';
import { ReactFlowProvider } from '@xyflow/react';
import { Canvas } from './components/Canvas';
import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { ToastContainer } from './components/ToastContainer';
import { ModalProvider } from './components/Modal';
import { useCanvasStore } from './stores/canvas-store';
import './styles.css';

function App() {
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

  const handleSwitchCanvas = (canvas: any) => setCurrentCanvas(canvas);

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
          <section className="canvas-section mesh-bg"><ReactFlowProvider><Canvas /></ReactFlowProvider></section>
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
    </ModalProvider>
  );
}

export default App;
