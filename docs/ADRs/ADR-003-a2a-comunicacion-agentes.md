# ADR-003 — A2A como protocolo de comunicación en la frontera orquestador ↔ runtimes

- **Estado:** Aceptado (2026-08, propuesto). Spec en evolución — a vigilar.
- **Decisión:** Los agentes de la empresa autónoma se comunican con los **runtimes
  (opencode / Claude Code / Codex / externos) mediante el protocolo abierto
  Agent2Agent (A2A)**. **NO** se usa A2A entre CrewAI y LangGraph (mismo proceso).
- **Tags:** agentes, a2a, crewai, langgraph, interop, empresa-autonoma

## Contexto

La empresa autónoma (`empresa_autonoma/`, SDD-115) orquesta a varios "empleados"
IA que corren en runtimes distintos: opencode, Claude Code, Codex — y en el
futuro, agentes externos de terceros. Hoy el único contrato entre el orquestador
y un runtime es `AgenteImplementador` (`graph.py`): un Protocol local, ad-hoc,
en el mismo proceso. Eso funciona para un solo runtime mock, pero no escala a
**multi-runtime y multi-vendor** (el diseño dice "cada empleado usa el runtime
que mejor hace su rol" — SDD-115 §2).

Creo erróneo meter un protocolo de red *entre* CrewAI y LangGraph: son dos
librerías Python en el mismo proceso que ya se coordinan por canales nativos
(channels de LangGraph, delegación de CrewAI). A2A entre ellas sería
serialización sin necesidad.

## Decisión

- **A2A (Agent2Agent) como lingua franca en la frontera**:
  `orquestador (Python) ↔ runtime de agente`, vía HTTP(S) + JSON-RPC 2.0.
- **Interno** (LangGraph ↔ CrewAI): canales nativos del proceso, como hoy.
  A2A **nunca** media dentro de `empresa_autonoma/`.
- **Cada runtime se publica con un Agent Card** (identidad, capacidades/rol,
  endpoint de tasks). El orquestador actúa como **cliente A2A**: crea un Task,
  sigue su lifecycle (`submitted → working → input-required → completed/canceled/failed`),
  recibe streaming (SSE) y push notifications.
- **Task lifecycle A2A = estados de la oficina**: el mapa de estados alimenta
  directamente el canva/`OfficeState` (working ⚡, blocked 🚧, waiting_approval ⏳).
- **Externos (futuro)**: cualquier agente que hable A2A puede entrar a un crew
  con solo publicar su Agent Card — sin adaptador propio.
- **Complementariedad:** MCP = herramientas que un agente usa; ACP = cliente↔agente
  (CLI). A2A = agente↔agente. Los tres conviven; este ADR solo fija A2A.

## Consecuencias

**Positivas:**
- Un solo contrato para todos los runtimes: cambiar de opencode a Codex es
  cambiar un Agent Card, no reescribir el contrato.
- Los estados de la oficina ya tienen forma estándar (task lifecycle) → menos
  mapeo ad-hoc entre la app, el grafo y el runtime.
- Interop real con agentes externos sin escribir adaptadores por proveedor.
- Es la dirección que tomó la industria (protocolo bajo Linux Foundation con
  SDKs oficiales `a2a-python` / `a2a-js` e integraciones LangGraph/CrewAI).

**Negativas / a vigilar:**
- Overhead HTTP/JSON-RPC vs llamada directa: aceptable porque solo media la
  frontera (procesos distintos), no el hot-path interno.
- Spec joven y en evolución: fijar versiones de spec/SDK; revisar en cada fase.
- Complejidad extra de infraestructura (servidor A2A por runtime + client en el
  orquestador) que no existía con `AgenteImplementador`.

## Alternativas descartadas

| Alternativa | Por qué |
|---|---|
| **A2A entre CrewAI y LangGraph** | Mismo proceso; canales nativos ya coordinan. Añadir HTTP = sin beneficio |
| Contrato propio (`AgenteImplementador` como estándar) | Sirve para 1 runtime mock; no escala a multi-vendor ni a externos |
| MCP como protocolo de agentes | MCP es para *tools* (agente→herramienta), no para agente↔agente; no cubre lifecycle de tasks ni agent cards |
| ACP (Agent Client Protocol) | Orientado a cliente↔agente (un CLI hablando con un agente), no a orquestar varios agentes entre sí |

## Referencias

- `docs/SDDs/SDD-115-empresa-autonoma-crewai-langgraph.md` (arquitectura base).
- `docs/SDDs/SDD-119-a2a-adaptadores-runtime.md` (diseño de implementación, Fase 1).
- Spec A2A (Agent2Agent, Linux Foundation) + SDKs `a2a-python`/`a2a-js`.
