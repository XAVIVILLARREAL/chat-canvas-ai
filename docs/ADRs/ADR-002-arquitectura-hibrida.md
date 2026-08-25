# ADR-002: Arquitectura Hibrida — Un solo codebase, multiplataforma

> Fecha: 2026-08-21 . Estado: **Superado en parte** (2026-08-24) . Contexto: Desktop + Mobile + Server
> ⚠️ **Nota de supercesión**: la decisión de "backend server Python (CrewAI/LangGraph)" y el modelo Tauri-first de este ADR quedan **SUPERADOS** por [ADR-005](./ADR-005-modelo-despliegue-dual.md) + [SDD-008](../SDDs/SDD-008-analisis-cliente-servidor-k8s.md) + Plan Base v3.4 (README): **WEB-FIRST** (el gateway axum sirve la web; Tauri diferido) y **servidor Rust** (crates/core + axum + workers Everruns, cero Python). Se conserva de este ADR: un solo codebase React, `useResponsive()`, estructura src/ y shared-types.

## Contexto

Canvas AI necesita funcionar en:
- **Desktop:** Windows, macOS, Linux (ya funciona con Tauri 2.0)
- **Mobile:** Android, iOS (Tauri mobile)
- **Server:** Python service (CrewAI + LangGraph)

La pregunta clave: como organizar el codigo para que sea escalable, mantenible y multiplataforma sin crear deuda tecnica.

## Decision: Un solo codebase con Tauri

**Tauri 2.0 es la plataforma unica** para desktop y mobile. No Flutter, no React Native, no dos codebases.

### Por que Tauri para todo?

| Criterio | Tauri | Flutter | React Native |
|---|---|---|---|
| Desktop | Nativo (Rust) | Embebido | Embebido |
| Mobile | Nativo (Rust) | Nativo | Nativo |
| Codebase compartido | Si (mismo React) | No (Dart) | Parcial (JS) |
| Backend Rust | Si (ya lo tenemos) | No | No |
| Bundle size | Chico (~5MB) | Mediano (~15MB) | Grande (~30MB) |
| Seguridad | Excelente (sandbox) | Buena | Media |
| Estado actual | Maduro (v2.0) | Maduro | Maduro |

**Ganador:** Tauri — un solo codebase, React + Rust, funciona en todas las plataformas.

## Arquitectura resultante

```
canvas-ai/
├── src/                    # React frontend (COMPARTIDO)
│   ├── components/
│   │   ├── layout/         # AppShell, Header, Sidebar, BottomNav
│   │   ├── canvas/         # ReactFlow, nodos, edges
│   │   ├── agents/         # AgentCard, AgentPanel
│   │   ├── skills/         # SkillCard, SkillEditor
│   │   └── ui/             # Button, Input, Modal (generics)
│   ├── hooks/
│   ├── stores/
│   ├── utils/
│   └── types/
│
├── src-tauri/              # Rust backend (TAURI)
│   ├── src/
│   │   ├── commands/       # Comandos Tauri (IPC)
│   │   ├── platforms/      # Logica por plataforma
│   │   │   ├── mod.rs      # Dispatcher
│   │   │   ├── desktop.rs  # Especifico desktop
│   │   │   └── mobile.rs   # Especifico mobile
│   │   ├── db/             # SQLite (sqlx)
│   │   ├── security/       # Crypto, auth
│   │   └── lib.rs          # Entry point
│   ├── capabilities/       # Permisos por ventana
│   ├── Cargo.toml          # Dependencias Rust
│   └── tauri.conf.json     # Config Tauri
│
├── packages/
│   └── shared-types/       # Tipos TypeScript compartidos
│       ├── src/
│       │   ├── agent.ts    # Tipos de agentes
│       │   ├── skill.ts    # Tipos de skills
│       │   ├── task.ts     # Tipos de tareas
│       │   ├── canvas.ts   # Tipos del canva
│       │   └── index.ts    # Barrel export
│       ├── package.json
│       └── tsconfig.json
│
├── services/
│   └── python/             # Python service (CrewAI)
│       ├── app/
│       │   ├── main.py     # FastAPI entry point
│       │   ├── agents/     # CrewAI agents
│       │   ├── skills/     # Skills engine
│       │   └── models/     # Data models
│       ├── requirements.txt
│       ├── pyproject.toml
│       └── Dockerfile
│
├── e2e/                    # Playwright tests
├── docs/                   # Documentacion
├── reference/              # Referencias de diseno
├── package.json            # Node.js root
├── vite.config.ts          # Vite config
└── tsconfig.json           # TypeScript config
```

## Capas de la arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                    FRONTEND (React)                      │
│  Compartido entre desktop y mobile via Tauri            │
│  UI adaptativa (mobile-first, ver ADR-001)              │
├─────────────────────────────────────────────────────────┤
│                    BACKEND LOCAL (Rust)                  │
│  Tauri commands, SQLite, filesystem, seguridad          │
│  Logica por plataforma (desktop.rs / mobile.rs)         │
├─────────────────────────────────────────────────────────┤
│                    BACKEND SERVER (Python)               │
│  CrewAI + LangGraph, orquestacion de agentes            │
│  Comunica via WebSocket/HTTP con el frontend            │
├─────────────────────────────────────────────────────────┤
│                    SHARED TYPES (TypeScript)             │
│  Tipos de dominio compartidos entre todas las capas     │
│  Fuente de verdad para contratos de datos               │
└─────────────────────────────────────────────────────────┘
```

## Plataformas soportadas

| Plataforma | Runtime | Backend | Frontend |
|---|---|---|---|
| Windows | Tauri + WebView2 | Rust nativo | React |
| macOS | Tauri + WKWebView | Rust nativo | React |
| Linux | Tauri + WebKitGTK | Rust nativo | React |
| Android | Tauri + WebView | Rust (NDK) | React |
| iOS | Tauri + WKWebView | Rust (via lib) | React |
| Server | Python standalone | Python (FastAPI) | N/A |

## Reglas de arquitectura

### 1. Frontend compartido
- **Todo el codigo React va en `src/`** — no hay `src-desktop/` ni `src-mobile/`
- **Adaptacion via `useResponsive()`** — no via archivos separados
- **Componentes genericos en `ui/`** — Button, Input, Modal, etc.
- **Componentes de dominio en carpetas propias** — `agents/`, `skills/`, `canvas/`

### 2. Backend local (Rust)
- **Comandos Tauri en `commands/`** — cada feature su propio archivo
- **Logica por plataforma en `platforms/`** — desktop.rs y mobile.rs
- **SQLite en `db/`** — persistencia local
- **Seguridad en `security/`** — crypto, auth, perfiles

### 3. Backend server (Python)
- **Aislado en `services/python/`** — no mezclar con Node.js
- **FastAPI como entry point** — API REST + WebSocket
- **CrewAI + LangGraph** — orquestacion de agentes
- **Docker para deploy** — containerizado

### 4. Shared types
- **Fuente de verdad en `packages/shared-types/`** — tipos TypeScript
- **Python genera sus propios modelos** — Pydantic models
- **Sincronizacion manual** — cuando cambia un tipo, actualizar ambos lados
- **OpenAPI spec** — contrato entre frontend y Python service

### 5. Comunicacion entre capas

```
Frontend (React)  ←IPC→  Backend Local (Rust)
Frontend (React)  ←WS/HTTP→  Backend Server (Python)
Backend Local (Rust)  ←WS→  Backend Server (Python)
```

## Consecuencias

### Positivas
- Un solo codebase para desktop y mobile
- React + Rust (ya tenemos expertise)
- Shared types evitan inconsistencias
- Python aislado pero en el mismo repo
- Escalable: agregar plataforma = agregar archivo en `platforms/`

### Negativas
- Tauri mobile es joven (v0.4.1) — puede tener bugs
- Python esta separado del ecosistema Node.js
- Shared types requieren sincronizacion manual

### Riesgos mitigados
- Tauri 2.0 ya es estable para desktop
- Tauri mobile esta creciendo rapido
- OpenAPI puede generar types automaticamente (futuro)

## References

- [Tauri 2.0](https://v2.tauri.app/)
- [Tauri Mobile](https://v2.tauri.app/mobile/)
- [CrewAI](https://www.crewai.com/)
- [LangGraph](https://langchain-ai.github.io/langgraph/)
