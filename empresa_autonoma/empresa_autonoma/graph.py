"""Grafo base de la empresa autónoma (LangGraph).

Flujo: [plan] -> [implementar] -> [revisar] -> (aprobación) -> [merge].

Testeable HEADLESS: cada nodo recibe el estado y puede inyectarse con un
implementador mock (sin LLM) — ver tests/test_graph.py.

Las funciones de nodo usan `AgenteImplementador` (protocolo): el "empleado"
que realmente edita el repo. En pruebas es un mock; en producción es un
runtime (opencode/claude code/codex) lanzado por CrewAI.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Protocol

from langgraph.graph import END, START, StateGraph
from langgraph.graph.state import CompiledStateGraph
from typing_extensions import TypedDict


class TaskState(TypedDict, total=False):
    task: str
    plan: str
    implementation: str
    review: str
    approved: bool
    pr_url: str | None
    error: str | None


class AgenteImplementador(Protocol):
    """Protocolo del 'empleado' que ejecuta un paso."""

    def implementar(self, plan: str) -> str: ...
    def revisar(self, implementation: str) -> str: ...


@dataclass
class Empresa:
    """La 'empresa' en sí: nodos del grafo + empleados inyectables."""

    implementador: AgenteImplementador | None = None
    history: list[tuple[str, str]] = field(default_factory=list)

    def _run(self, node: str, state: TaskState) -> TaskState:
        self.history.append((node, state.get("task", "")))
        return state

    # --- nodos ---
    def node_plan(self, state: TaskState) -> TaskState:
        state["plan"] = f"Plan para: {state['task']}"
        return self._run("plan", state)

    def node_implement(self, state: TaskState) -> TaskState:
        if self.implementador is None:
            state["implementation"] = f"Implementación mock de: {state.get('plan', '')}"
        else:
            state["implementation"] = self.implementador.implementar(state.get("plan", ""))
        return self._run("implementar", state)

    def node_review(self, state: TaskState) -> TaskState:
        if self.implementador is None:
            state["review"] = "Revisión mock: OK"
        else:
            state["review"] = self.implementador.revisar(state.get("implementation", ""))
        return self._run("revisar", state)

    def node_merge(self, state: TaskState) -> TaskState:
        state["approved"] = True
        state["pr_url"] = "https://github.com/XAVIVILLARREAL/empresa-desarrollo-autonoma/pull/mock"
        return self._run("merge", state)


def build_graph(empresa: Empresa | None = None) -> CompiledStateGraph:
    """Compila el grafo base. Sin empresa = nodos mock (headless)."""
    e = empresa or Empresa()

    g = StateGraph(TaskState)
    g.add_node("plan", e.node_plan)
    g.add_node("implementar", e.node_implement)
    g.add_node("revisar", e.node_review)
    g.add_node("merge", e.node_merge)

    g.add_edge(START, "plan")
    g.add_edge("plan", "implementar")
    g.add_edge("implementar", "revisar")

    # Gate humano: revisar -> merge salvo que la tarea venga con "approved": False
    # (bloqueado esperando aprobación humana). Por defecto (sin decidir) se
    # entrega — en producción el orquestador setea approved por la app.
    def gate_review(state: TaskState) -> str:
        if state.get("approved") is False:
            return END
        return "merge"

    g.add_conditional_edges("revisar", gate_review)
    g.add_edge("merge", END)

    return g.compile()


def run_tarea(task: str, empresa: Empresa | None = None) -> dict:
    """Ejecuta una tarea end-to-end sobre el grafo. Devuelve el estado final."""
    graph = build_graph(empresa)
    return graph.invoke({"task": task})
