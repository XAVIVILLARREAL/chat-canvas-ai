import { useAppStore } from "./stores/app-store";

export function App() {
  const { agents, selectedAgent, selectAgent } = useAppStore();

  return (
    <div className="app">
      <header className="app-header">
        <h1>Empresa Dev</h1>
        <p className="subtitle">Sistema multiagente visual</p>
      </header>

      <main className="app-main">
        <section className="canvas-section">
          <h2>Oficina</h2>
          <div className="canvas">
            {agents.length === 0 ? (
              <div className="empty-state">
                <p>No hay agentes creados</p>
                <button type="button" className="btn-primary">
                  Crear primer agente
                </button>
              </div>
            ) : (
              <div className="agents-grid">
                {agents.map((agent) => (
                  <button
                    key={agent.id}
                    type="button"
                    className={`agent-card ${selectedAgent?.id === agent.id ? "selected" : ""}`}
                    onClick={() => selectAgent(agent)}
                  >
                    <div className={`agent-status status-${agent.status}`} />
                    <span className="agent-name">{agent.name}</span>
                    <span className="agent-role">{agent.role}</span>
                  </button>
                ))}
              </div>
            )}
          </div>
        </section>

        <aside className="panel">
          <h2>Panel</h2>
          {selectedAgent ? (
            <div className="agent-detail">
              <h3>{selectedAgent.name}</h3>
              <p>Rol: {selectedAgent.role}</p>
              <p>Estado: {selectedAgent.status}</p>
            </div>
          ) : (
            <p className="empty-state">Selecciona un agente</p>
          )}
        </aside>
      </main>
    </div>
  );
}
