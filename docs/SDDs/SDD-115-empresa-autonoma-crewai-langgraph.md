# SDD-115 — Empresa Autónoma de Desarrollo (CrewAI + LangGraph)

> **Objetivo:** construir una **oficina de desarrollo autónoma** donde cada agente
> es un "empleado" especializado (rol de oficina) que trabaja tareas reales del
> repo, coordinado por **CrewAI** (quién trabaja) + **LangGraph** (cómo fluye el
> trabajo), con una **vista animada estilo juego** en la app Flutter.
>
> Visión rectora en `AGENTS.md` (§ Visión — EMPRESA AUTÓNOMA). La app actual
> (terminal + canva + hub) es la base sobre la que se construye la "oficina".

---

## 1. Concepto

La meta no es "chat con agentes": es una **empresa que trabaja sola**. Al abrir
la app ves la oficina animada: cada agente es un personaje con estado visible
(trabajando ⚡, bloqueado 🚧, esperando aprobación ⏳, inactivo 💤). Los agentes
reciben una tarea, la descomponen, se la reparten entre roles, y van avanzando
hasta entregar un PR — con aprobación humana en los puntos críticos.

## 2. Stack

| Capa | Elección | Rol |
|---|---|---|
| Orquestación | **CrewAI** (Python) | Roles "empleado", crews, delegación declarativa |
| Grafos de estado | **LangGraph** (Python) | Control fino, loops, human-in-the-loop, checkpoints |
| Runtimes | opencode / Claude Code / Codex | Cada empleado usa el runtime que mejor hace su rol |
| Vista oficina | Flutter (canva + animaciones) | Espejo del grafo; la UI observa, no decide |
| Persistencia | Checkpoints LangGraph + SQLite/Postgres | La empresa se pausa y reanuda |

## 3. Arquitectura

```
Flutter (oficina animada, canva)
      │  observa estados / envía tareas / aprueba
      ▼
empresa_autonoma/  (servicio Python: FastAPI + CrewAI + LangGraph)
      │  executa el grafo, gestiona crews y checkpoints
      ▼
Runtimes de agentes (opencode, claude code, codex) → git repo real
```

- **La app NUNCA ejecuta agentes**; solo manda intenciones y recibe estado.
- **El servicio `empresa_autonoma/` es el cerebro**; expone REST/WS a la app.
- **Cada agente publica su estado** vía el mismo modelo que `agent_core`
  (`AgentState`: idle/working/blocked/unknown) + estados de oficina
  (esperando aprobación, en revisión, etc.).

## 4. Grafo base (LangGraph)

Nodo inicial: **tarea** → flujo:

```
[Tarea] → [Plan] → [Implementar] → [Revisar] ─┐
                ▲                              │ aprobado
                └─────── (loop: correcciones) ─┘
                                │
                          [Merge/PR] → [Deploy]
```

**Gates con human-in-the-loop (nodos de aprobación):**
- Aprobar el plan antes de implementar (opcional por configuración).
- Aprobar el PR antes de merge.
- Aprobar el deploy.

**Checkpoints:** cada transición guarda estado (LangGraph `checkpointer`) →
si el servicio se apaga, se reanuda desde donde iba.

## 5. Crews (CrewAI) — roles de oficina

| Rol | Responsabilidad | Nodo canva |
|---|---|---|
| **Producto** | Descompone la tarea, define criterios de aceptación | 🎯 |
| **Arquitecto** | Decide enfoque, valida el plan | 🏛️ |
| **Dev** | Implementa (ejecuta opencode/codex en el repo) | 👨‍💻 |
| **QA** | Prueba, encuentra regresiones | 🧪 |
| **Devops** | Build/deploy, infra | ⚙️ |
| **Revisor** | Code review del PR | 🔍 |
| **PM** | Coordina, prioriza, reporta estado | 📋 |

Cada rol es un nodo-personaje en la oficina. Un crew = equipo armado para una
tarea (ej.: dev+QA+revisor para una feature).

## 6. Oficina animada (vista en la app)

- **Escenario:** el canva existente se convierte en la oficina (fondo
  tech-grid glassmorphism, SDD-114).
- **Personajes:** nodos-agente con animación de estado (glow cian = trabajando,
  violeta = bloqueado, verde = listo), sprite/emoji por rol, burbuja de
  actividad.
- **Trazas:** el flujo del grafo se dibuja como líneas animadas entre nodos
  (aristas con luz).
- **Aprobaciones:** un nodo "⏳ espera aprobación" hace ping y muestra el diff
  para aprobar/rechazar desde la app.

## 7. Fases (gates)

| Fase | Entregable | Gate |
|---|---|---|
| **0 — Fundación** | `empresa_autonoma/` con CrewAI+LangGraph, grafo base "plan→implementar→revisar→merge" con 1 agente dev (opencode) | Grafo corre headless; run de demo termina en un PR local |
| **1 — Crews** | Roles + delegación; cada agente es un nodo en el canva | Tarea end-to-end con 2+ roles |
| **2 — Oficina animada** | Vista estilo juego en la app (personajes, estados animados) | Screenshots + E2E: la oficina muestra el estado en vivo |
| **3 — Integración repo** | Leer issues/PRs, crear ramas, PRs reales con aprobación humana | PR real desde la empresa con aprobación en la app |
| **4 — Autonomía supervisada** | Tareas end-to-end con gates y trazabilidad completa | Checklist de autonomía supervisada ✅ |

## 8. Pruebas (headless)

- **Grafos testables:** LangGraph permite testear el grafo con nodos mock
  (sin LLM). Los tests de grafos corren en CI.
- Integraciones con LLM/runtimes: tag `integration` (no en CI normal).
- La app consume el servicio con un **fake de `empresa_autonoma`** en tests de
  widgets (la oficina se renderiza aunque no haya servicio).

## 9. Reglas duras

1. La app NO ejecuta agentes ni importa CrewAI/LangGraph (son Python).
2. Todo cambio de repo pasa por aprobación humana (nodo en el grafo).
3. La empresa debe poder pausarse y reanudarse (checkpoints).
4. Observabilidad: el grafo publica, la UI espeja. La UI nunca decide.
5. `melos analyze` + tests verdes para la parte Flutter; `pytest` para el
   servicio Python.

## 10. Estado

- ✅ **Fase 0 — Fundación (parcial):** `empresa_autonoma/` con `pyproject.toml`,
  `roles.py` (catálogo de roles de oficina + estados), `graph.py` (grafo base
  LangGraph: plan→implementar→revisar→merge con gate humano headless) y
  `tests/test_graph.py` (5 tests PASS, sin LLM). Falta: integrar CrewAI real
  + FastAPI (server.py) + ejecutar con runtime opencode real.
- ⬜ Fase 1 — Crews (pendiente).
- ⬜ Fase 2 — Oficina animada (pendiente).
- ⬜ Fase 3 — Integración repo (pendiente).
- ⬜ Fase 4 — Autonomía supervisada (pendiente).
