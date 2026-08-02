# ARQUITECTURA — Sistema multi-agente con LangGraph + Chrome DevTools MCP

## Visión general

Capas: una **app web** (frontend + backend) expone canva, kanban y sesiones. Debajo, un **orquestador LangGraph** ejecuta el flujo de los agentes con estado, reintentos y pausas humanas. Los agentes usan herramientas vía **MCP**, con **Chrome DevTools MCP como herramienta central**: prueban la UI en un navegador real como lo haría un humano.

```
┌─────────────────────────────────────────────────────────────────┐
│                     APP WEB (mobile-first)                       │
│   Canva (sesiones/proyectos) · Kanban (tickets/CI) · Sesión/IDE  │
└───────────────────────────┬─────────────────────────────────────┘
                            │ REST + WebSocket (eventos en vivo)
┌───────────────────────────▼─────────────────────────────────────┐
│                        BACKEND (Node/TS)                         │
│   · Auth, proyectos, sesiones, tablero (SQLite/Postgres)        │
│   · Streaming de eventos → la UI muestra todo lo que pasa        │
└───────────────────────────┬─────────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────────┐
│                  ORQUESTADOR LangGraph                           │
│  Grafo de estados: cada ticket = una ejecución del grafo         │
│  · checkpoints (se puede pausar/reanudar)                        │
│  · retry + límite de intentos                                    │
│  · human-in-the-loop (interrupts: "aprueba hito")                │
│  · nodos = roles de agentes (Project Lead, Implementador, QA,    │
│    UI Tester, Reviewer)                                          │
└───────────────────────────┬─────────────────────────────────────┘
                            │ herramientas vía MCP
              ┌─────────────┼──────────────┬──────────────┐
              ▼             ▼              ▼              ▼
    ┌────────────────┐ ┌─────────┐  ┌──────────┐   ┌────────────┐
    │Chrome DevTools │ │filesys- │  │ shell/   │   │ git / CI   │
    │MCP (el núcleo) │ │tem      │  │ node     │   │            │
    │ navega, clic,  │ │         │  │          │   │            │
    │ escribe, eval, │ │         │  │          │   │            │
    │ screenshots,   │ │         │  │          │   │            │
    │ console, net   │ └─────────┘  └──────────┘   └────────────┘
    └────────────────┘
```

## Componentes

### 1. Frontend (React 19 + Vite + TS + Tailwind v4)
- **Canva** (React Flow): tarjetas de sesión por proyecto; click → abre la sesión.
- **Kanban**: tablero de la empresa; estados de tickets, CI, PRs, evidencia visual.
- **Sesión/IDE**: chat + editor + terminal + panel Browser (lo que el agente ve en Chrome).
- Realtime vía WebSocket: cada herramienta del agente emite eventos → la UI los muestra en vivo.

### 2. Backend (Node + TypeScript)
- API REST + WebSocket.
- Persistencia: proyectos, sesiones, tickets, mensajes, posiciones del canva.
- Gestiona el ciclo de vida de ejecuciones LangGraph (lanzar, pausar, reanudar).
- Ejecuta localmente (tus máquinas) o en servidor (modo empresa, multi-usuario).

### 3. Orquestador LangGraph — el cerebro

Un **grafo de estados** (no un loop ad-hoc). Cada ticket del kanban es una ejecución del grafo:

```
[Planificar] → [Implementar] → [Tests unit/integ] → [UI Test con Chrome DevTools MCP]
      │                            │                      │ falla → vuelve a Implementar (max 3)
      ▼                            ▼                      ▼ pasa
[Revisar diff] ◄────────── [Capturas = evidencia] → [Merge]
      │
      └─ human-in-the-loop: "aprueba" en hitos / tocar producción
```

**Por qué LangGraph y no un loop propio:**
- **Checkpoints**: cada paso queda guardado; puedes pausar, reanudar o rebobinar (time-travel) a un estado anterior.
- **Interrupts (human-in-the-loop)**: el grafo se detiene donde corresponde ("aprueba este hito") y espera.
- **Reintentos y límites**: el grafo reintenta con política configurable y escala al humano al agotar intentos.
- **Estado explícito**: todo el contexto vive en un estado tipado → auditable y reanudable tras un crash.
- **Producción**: es el estándar para multi-agente confiable (LangChain ecosystem).

### 4. Capa MCP — Chrome DevTools MCP como el núcleo

Los agentes no "confían en que funciona": **lo prueban en un Chrome real**.

> 💡 **Headless en el servidor:** el Chrome del agente corre **siempre en segundo plano, del lado del servidor** (Chromium headless, sin ventana visible). El usuario nunca ve la ventana del navegador; la evidencia visual llega como **capturas de pantalla** que el agente toma y adjunta.

Capacidades del Chrome DevTools MCP (como Antigravity/Chrome DevTools):
- **Navegar** a la URL de la app en desarrollo.
- **Interactuar como humano**: clic, escribir, scroll, hover, esperar.
- **Evaluar JS** en la página (estado, datos, condiciones).
- **Leer la consola y la red**: errores JS, requests fallidas, warnings.
- **Inspeccionar el DOM**: elementos visibles/ocultos, accesibilidad (a11y tree).
- **Screenshots**: capturas de cada paso → evidencia visual para el reviewer y para ti.

Reglas de uso:
- **Ninguna feature de UI se cierra sin verificación en navegador real.**
- El UI Tester deja **capturas** adjuntas al ticket/PR (prueba de que el flujo funciona).
- El bucle: el UI Tester hace clic → la app responde → el agente compara con lo esperado (SDD) → si hay error de consola o flujo roto → devuelve el error al implementador.

### 5. Memoria del proyecto
- `SPEC.md`, `SDD.md` por feature, `ADRs/` (decisiones de arquitectura).
- Índice del código (grafo de conocimiento) que los agentes consultan.
- Historial de verificación: capturas y errores por PR (para no repetir errores).

### 6. Tablero / Kanban
- El kanban **es la cara visible de LangGraph**: cada ticket en "En curso" corresponde a una ejecución del grafo.
- Columnas: `Backlog → Pendiente → En curso → PR → CI → Revisión → Listo`.
- Eventos del grafo → WebSocket → el kanban se actualiza en vivo.

## Flujo de control de una feature

1. El humano pide una feature (texto o voz) → el Project Lead crea ticket + SDD.
2. El ticket pasa a "En curso" → LangGraph ejecuta: Implementador escribe código + QA escribe tests.
3. CI (typecheck → lint → unit/integration) corre; si falla, el error exacto vuelve al Implementador (max 3).
4. **UI Test**: el UI Tester lanza la app y la prueba en Chrome real vía Chrome DevTools MCP; toma capturas.
5. Reviewer revisa el diff + las capturas; aprueba o pide cambios.
6. Merge cuando: CI verde + UI verificado con evidencia + (si es hito) aprobación humana.

## Reglas de seguridad

- **Límite de autonomía**: nada toca producción sin aprobación humana.
- **Git como red**: todo en ramas; revertir siempre es posible.
- **Presupuesto de intentos**: N fallos → escala al humano (no loops infinitos).
- **Chrome headless en el servidor**: el navegador del agente corre en segundo plano en el servidor, sin ventana; es controlado y desechable, y nunca abre una ventana en el cliente.
