"""Tests headless del grafo base (sin LLM, sin CrewAI runtime)."""

from empresa_autonoma.graph import Empresa, run_tarea


class MockImplementador:
    """Empleado mock: implementa y revisa sin LLM."""

    def implementar(self, plan: str) -> str:
        return f"código generado para: {plan}"

    def revisar(self, implementation: str) -> str:
        return f"revisión OK de: {implementation}"


def test_grafo_ejecuta_plan_implementar_revisar():
    estado = run_tarea("Fix: crash en el terminal")
    assert estado["plan"].startswith("Plan para:")
    assert estado["implementation"].startswith("Implementación mock")
    assert estado["review"].startswith("Revisión mock")


def test_grafo_con_implementador_real_ejecuta_todos_los_nodos():
    empresa = Empresa(implementador=MockImplementador())
    estado = run_tarea("Fix: crash en el terminal", empresa)

    assert "código generado" in estado["implementation"]
    assert "revisión OK" in estado["review"]
    # Los 4 nodos del grafo corrieron.
    nodos = [n for n, _ in empresa.history]
    assert nodos == ["plan", "implementar", "revisar", "merge"]


def test_grafo_registra_historia_de_la_empresa():
    empresa = Empresa(implementador=MockImplementador())
    run_tarea("Feature: canva", empresa)
    assert len(empresa.history) == 4


def test_estado_final_tiene_pr_url_y_aprobacion():
    estado = run_tarea("Feature: canva")
    assert estado["approved"] is True
    assert "pull/mock" in (estado.get("pr_url") or "")


def test_gate_humano_bloquea_merge_sin_aprobacion():
    """Human-in-the-loop: approved=False -> el grafo NO llega a merge."""
    empresa = Empresa(implementador=MockImplementador())
    graph = __import__("empresa_autonoma.graph", fromlist=["build_graph"]).build_graph(empresa)
    estado = graph.invoke({"task": "X", "approved": False})
    assert estado.get("pr_url") is None
    assert "merge" not in [n for n, _ in empresa.history]
