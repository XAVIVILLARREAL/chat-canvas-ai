# Empresa Autónoma — servicio de orquestación (CrewAI + LangGraph)

Servicio Python que orquesta la "oficina de desarrollo autónoma": cada agente es
un empleado (rol) y el trabajo fluye por un grafo de estado (LangGraph) con
crews (CrewAI). Ver `docs/SDDs/SDD-115-empresa-autonoma-crewai-langgraph.md`.

## Estructura

```
empresa_autonoma/
├── pyproject.toml          # deps: crewai, langgraph, fastapi, uvicorn
├── empresa_autonoma/
│   ├── __init__.py
│   ├── graph.py            # grafo base (LangGraph): plan -> implementar -> revisar -> merge
│   ├── roles.py            # roles de oficina (dev, qa, revisor, ...) como dataclasses
│   └── server.py           # API REST/WS para la app Flutter (FastAPI)
└── tests/
    └── test_graph.py       # tests headless del grafo (sin LLM)
```

## Comandos

```bash
python -m venv .venv
.venv/Scripts/activate          # Windows
pip install -e ".[dev]"
pytest                          # tests headless del grafo
uvicorn empresa_autonoma.server:app --port 8100
```

## Reglas

- La app Flutter NUNCA ejecuta agentes; solo habla con este servicio.
- Todo cambio de repo pasa por un nodo de aprobación humana (human-in-the-loop).
- El grafo es testeable headless (nodos mock, sin LLM) — corre en CI.
- Los runtimes reales (opencode/claude/codex) se inyectan como "empleados".
