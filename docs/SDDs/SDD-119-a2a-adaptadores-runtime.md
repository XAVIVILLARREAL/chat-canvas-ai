# SDD-119 — A2A: adaptadores de runtime para la empresa autónoma (Fase 1)

> Decisión de arquitectura: **ADR-003** — A2A como protocolo en la frontera
> orquestador ↔ runtimes (opencode / Claude Code / Codex / externos). Este SDD lo
> aterriza en la **Fase 1 de SDD-115 (Crews a medida)**.

## Objetivo

Cualquier runtime de agente (opencode, claude, codex, o un agente externo que
hable A2A) puede trabajar como "empleado" de la empresa con **un solo contrato**:
el protocolo **Agent2Agent**. El orquestador (`empresa_autonoma/`) deja de
depender de `AgenteImplementador` (contrato local, un solo runtime) y pasa a
**crear A2A Tasks** contra los Agent Cards publicados por cada runtime, siguiendo
su lifecycle y reflejando los estados en el canva.

**NO se usa A2A entre LangGraph y CrewAI** (mismo proceso, canales nativos).

## Flujo

```
App Flutter (oficina/canva)
   │  lanza tarea / observa estados (OfficeState)
   ▼
empresa_autonoma/  (FastAPI + CrewAI + LangGraph)
   │  CrewAI decide quién trabaja → LangGraph transiciona el grafo
   │  el nodo "empleado" crea un A2A Task (cliente A2A)
   ▼  HTTP(S) + JSON-RPC 2.0
RuntimeAdapter (FastAPI A2A server + Agent Card)
   │  traduce el Task a la invocación real del runtime
   ▼
opencode / claude / codex  →  repo/worktree
   │  streaming de eventos (status, artifacts, message/parts)
   ▼
Orquestador → canva (nodo-agente anima: working ⚡ / blocked 🚧 / waiting ⏳)
```

## Contratos (Python, `empresa_autonoma/`)

```python
# a2a/agent_card.py  —  descubrimiento y capacidades del "empleado"
@dataclass
class AgentCapability:
    name: str            # "implementar", "revisar", "testear", "deploy"...
    description: str
    parameters: dict     # esquema JSON de los parámetros que acepta

@dataclass
class AgentCard:
    name: str                     # "dev-opencode", "qa-claude", ...
    role: OfficeRole              # reutiliza roles.py
    description: str
    url: str                      # endpoint A2A del runtime (http://localhost:PORT)
    version: str
    capabilities: list[AgentCapability]
    def to_dict(self) -> dict: ...          # → JSON publicable en ~/.well-known/agent.json
    @staticmethod
    def from_dict(data: dict) -> "AgentCard": ...

# a2a/tasks.py  —  lifecycle de tarea A2A y mapeo a la oficina
class TaskState(str, Enum):
    SUBMITTED = "submitted"            # creado, sin asignar trabajo real
    WORKING   = "working"              # → OfficeState.working
    INPUT_REQUIRED = "input-required"  # → OfficeState.waiting_approval
    COMPLETED = "completed"            # → OfficeState.done
    CANCELED  = "canceled"             # → OfficeState.idle
    FAILED    = "failed"               # → OfficeState.blocked

class Task:
    id: str                            # 'a2a-<sec>:<ms>:<seq>'
    agent_card: AgentCard
    message: str                       # instrucción (TextPart)
    state: TaskState
    artifacts: list[dict]              # FilePart/DataPart (diffs, salidas)
    context: list[dict]                # historial/hilo (A2A context)
    def transition(self, next_state: TaskState) -> None: ...  # transición ilegal → StateError

# a2a/client.py  —  el orquestador habla A2A con los runtimes
class A2AClient:
    def __init__(self, session: httpx.AsyncClient): ...
    async def discover(self, url: str) -> AgentCard: ...        # GET agent card
    async def send(self, task: Task) -> Task: ...               # message/send (JSON-RPC 2.0)
    async def get(self, task_id: str) -> Task: ...              # task/get
    async def cancel(self, task_id: str) -> Task: ...           # task/cancel
    async def stream(self, task_id: str): ...                   # SSE → eventos (status/artifacts)

# a2a/server.py  —  adapter que expone un runtime como servidor A2A
class RuntimeAdapter(Protocol):     # igual espíritu que AgenteImplementador, pero A2A
    async def implementar(self, message: str, artifacts: list[dict]) -> str: ...
    async def revisar(self, message: str, artifacts: list[dict]) -> str: ...

class A2AServer:
    """FastAPI app: /agent-card (GET) + /message/send, /task/get, /task/cancel (JSON-RPC).
    Traduce Tasks → RuntimeAdapter → streaming de eventos."""
    def __init__(self, card: AgentCard, adapter: RuntimeAdapter): ...

# graph.py  —  el nodo "empleado" ahora dispara un Task A2A
class AgenteA2A(AgenteImplementador):
    """Puente: el grafo de LangGraph habla con un runtime vía A2AClient."""
    def __init__(self, client: A2AClient, card: AgentCard): ...
    async def implementar(self, plan: str) -> str:   # crea Task, escucha events, devuelve artifact
```

**Estados de la oficina** (`roles.py` / `agent_core`): el mapeo anterior sustituye
el mapeo ad-hoc de estados del runtime → canva. Un `TaskState` A2A ES un estado de
oficina con otro nombre.

**Regla monorepo:** todo lo anterior es Python (`empresa_autonoma/`). En la app
solo entra el modelo de observación (`OfficeState` ya vive en `roles.py`/canva);
la app no habla A2A directamente — el servicio lo traduce al WS/estado actual.

## Tests (TDD)

1. `empresa_autonoma/tests/test_a2a_tasks.py` (unit):
   - máquina de estados: `submitted→working→completed` OK; transición ilegal
     (`completed→working`) → `StateError`.
   - `Task.to_dict`/`from_dict` round-trip sin pérdida (artifacts y context).
2. `empresa_autonoma/tests/test_agent_card.py` (unit):
   - `AgentCard` se serializa al JSON del `.well-known/agent.json` y se
     reconstruye; capabilities/role correctos.
3. `empresa_autonoma/tests/test_a2a_server.py` (integration con `httpx` test client):
   - **fake adapter** ("dev" que devuelve texto fijo): crear Task via
     `message/send` → responde `working` → eventos SSE → `completed` con artifact.
   - `task/get` devuelve el estado actual; `task/cancel` en `working` → `canceled`.
   - El grafo `build_graph(AgenteA2A(...))` corre headless contra el fake y
     entrega el PR mock (gate de Fase 1 ampliado).
4. `empresa_autonoma/tests/test_a2a_runtime.py` (`@tags integration`, opencode real):
   - runtime real detrás de `A2AServer`; una tarea "crea hola.py" → `completed`
     con el archivo en el artifact. No corre en CI sin opencode.
5. Widget (app): la oficina renderiza el nodo-agente a partir de un estado
   `working`/`blocked`/`waiting_approval` emitido por un **fake del servicio**
   (ya es el patrón de SDD-115 §8). Sin tocar A2A en la app.

## Gate (SUPER_PLAN, Fase 1)

- [ ] `pytest` verde: tasks + agent card + server con adapter fake + grafo A2A headless.
- [ ] Un runtime real (opencode) detrás del adapter ejecuta una tarea vía A2A y
      el canva muestra su estado en vivo (working → completed).
- [ ] `melos analyze` + suite Flutter verde (sin cambios en la app salvo el
      observador de estados).

## Slices de implementación

- **1.1** `a2a/tasks.py` + `a2a/agent_card.py` (estados y contratos puros; TDD).
- **1.2** `a2a/server.py` + `a2a/client.py` (FastAPI + JSON-RPC 2.0 + SSE; fake adapter).
- **1.3** `AgenteA2A` en `graph.py` (el grafo habla A2A; pruebas headless).
- **1.4** Adapter real `opencode_adapter.py` (traduce Task → `opencode run` por
  contrato JSON, reutilizando la lógica de `AgentCommandRunner` de la app).
- **1.5** (post-gate) Publicar Agent Cards de los runtimes configurados y
  selección por rol en el manifiesto de equipo (Fase 1 de SDD-115).

## Notas de implementación

- **Versiones:** fijar spec/SDK A2A (ej. `a2a-python`) en `pyproject.toml`;
  revisar la evolución del spec en cada fase (ADR-003).
- **Streaming:** SSE para el hot-path de estado (el canva es espejo, no espera).
  Push notification vía webhook solo si un runtime corre fuera del host.
- **Auth/aislamiento:** el `A2AServer` por runtime escucha en `127.0.0.1:<puerto>`
  efímero (mismo patrón que el hub de la app); cada task corre en su worktree.
- **MCP/ACP:** no se implementan aquí; MCP queda como herramientas de los
  runtimes, ACP como canal CLI de un agente (referencias, SDD-118).
- **Fallback:** mientras no exista `A2AServer`, `AgenteImplementador` sigue
  funcionando (los tests de Fase 0 no se rompen) — el A2A se activa por
  configuración del manifiesto de equipo.
