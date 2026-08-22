# ARQUITECTURA.md — Arquitectura de Empresa Dev

> Documento maestro de arquitectura. Siempre consultar antes de crear componentes, servicios o features nuevas.

## Vision general

Empresa Dev es una **plataforma multiplataforma** construida sobre Tauri 2.0 + React + Rust + Python. Un solo codebase para desktop y mobile, con un backend server en Python para orquestacion de agentes.

```
+-----------------------------------------------------+
|                    FRONTEND (React)                  |
|  src/ — Compartido entre desktop y mobile           |
+-----------------------------------------------------+
|                    BACKEND LOCAL (Rust)              |
|  src-tauri/ — Tauri commands, SQLite, seguridad     |
+-----------------------------------------------------+
|                    BACKEND SERVER (Python)           |
|  services/python/ — CrewAI, LangGraph, FastAPI      |
+-----------------------------------------------------+
|                    SHARED TYPES (TypeScript)         |
|  packages/shared-types/ — Tipos de dominio          |
+-----------------------------------------------------+
```

## Flujo de datos

```
+--------------+     +--------------+     +--------------+
|   Usuario    |---->|   Frontend   |---->| Backend Local|
|  (interactua)|     |   (React)    | IPC |    (Rust)    |
+--------------+     +------+-------+     +------+-------+
                              |                  |
                              | WebSocket/HTTP   | WebSocket
                              |                  |
                       +------v-------+   +------v-------+
                       | Backend      |   |   SQLite     |
                       | Server       |   |  (local)     |
                       | (Python)     |   +--------------+
                       +--------------+
```

## Plataformas soportadas

| Plataforma | Runtime | Backend | Frontend | Estado |
|---|---|---|---|---|
| Windows | Tauri + WebView2 | Rust nativo | React | Activo |
| macOS | Tauri + WKWebView | Rust nativo | React | Activo |
| Linux | Tauri + WebKitGTK | Rust nativo | React | Activo |
| Android | Tauri + WebView | Rust (NDK) | React | Activo |
| iOS | Tauri + WKWebView | Rust (via lib) | React | Activo |
| Server | Python standalone | Python (FastAPI) | N/A | Futuro |

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
- **OpenAPI spec** — contrato entre frontend y Python service (futuro)

### 5. Comunicacion entre capas

```
Frontend (React)  <-IPC->  Backend Local (Rust)
Frontend (React)  <-WS/HTTP->  Backend Server (Python)
Backend Local (Rust)  <-WS->  Backend Server (Python)
```

## Anti-patrones de arquitectura

| Mal | Bien | Por que |
|---|---|---|
| `src-desktop/`, `src-mobile/` | `src/` con `useResponsive()` | Un solo frontend |
| Python en `src/` | `services/python/` | Aislamiento de tecnologias |
| Tipos duplicados sin sincronizar | `packages/shared-types/` | Consistencia |
| Logica de negocio en componentes React | Stores + hooks | Separacion de responsabilidades |
| API keys en codigo | `.env` + config | Seguridad |

## Checklist de arquitectura (antes de PR)

- [ ] Codigo en la carpeta correcta (src/, src-tauri/, services/, packages/)
- [ ] No hay logica de negocio en componentes React
- [ ] No hay Python en src/ ni src-tauri/
- [ ] Shared types actualizados si cambio un modelo
- [ ] Comunicacion entre capas via IPC/WS, no imports directos
- [ ] Platform-specific code en platforms/ (no en commands/)
- [ ] Tests para la feature implementada
