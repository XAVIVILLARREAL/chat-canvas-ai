# ARQUITECTURA.md — Arquitectura de Empresa Dev

> Documento maestro de arquitectura. Siempre consultar antes de crear componentes, servicios o features nuevas.
> **v3.5 (2026-08-24)**: alineada con ADR-005 (web-first, servidor Rust) + SDD-008 (escalado) + Plan Base v3.4. El modelo anterior (Tauri-first + backend Python) quedó superado — ver nota de supercesión en [ADR-002](./ADRs/ADR-002-arquitectura-hibrida.md).

## Vision general

Plataforma **WEB-FIRST** de orquestación de agentes: el gateway Rust (axum) **sirve la SPA React** y sostiene REST + SSE/WS de streaming; un crate de dominio compartido (`crates/core`) alimenta al servidor y al shell Tauri (diferido, solo con demanda demostrada). **Cero Python en el servidor** — la orquestación de agentes la hacen los providers Rust + Reasonix ([PLAN C](./SDDs/SDD-001-plan-base/plan-c-reasonix-deepseek.md)) y el stack del servidor está fijado en [PLAN S](./SDDs/SDD-001-plan-base/plan-s-despliegue-costos.md).

```
+-----------------------------------------------------+
|              CLIENTE (navegador v1 / Tauri futuro)   |
|  src/ — SPA React (cómputo client-first)            |
+-----------------------------------------------------+
|              GATEWAY (Rust axum, stateless)          |
|  crates/server — sirve SPA + REST + SSE/WS           |
+-----------------------------------------------------+
|              DOMINIO (crates/core — Rust)            |
|  Agentes · Tareas · Skills · Sesiones · Memoria      |
+-----------------------------------------------------+
|          WORKERS de agentes (Rust, sin DB creds)     |
|  cola Postgres SKIP LOCKED · sandboxes · heartbeat   |
+-----------------------------------------------------+
|        DATOS (Postgres+RLS · MinIO · Valkey)         |
+-----------------------------------------------------+
```

## Principio de cómputo CLIENT-FIRST (escalabilidad — regla transversal dura)

> **Regla: todo cómputo que PUEDA correr en el cliente corre en el cliente.** El servidor solo ejecuta lo que necesita ser central: agentes 24/7, estado autoritativo, sync, repos compartidos, secretos. Así el coste por usuario baja y el servidor escala con los datos, no con la CPU de cada usuario.

| Capacidad | Dónde corre | Estado |
|---|---|---|
| Renderizado UI, estado local, virtualización, edición (Monaco), diffs, previews, PDF/imágenes (wasm) | Cliente | ✅ en planes |
| Caché/offline (React Query + service worker + outbox duradero) | Cliente | ✅ L.2 |
| Búsqueda local FTS5/vectorial (memoria, knowledge) | Cliente (**wa-sqlite + OPFS / sqlite-vec WASM**) cuando los datos son del dispositivo; servidor solo para lo compartido | 🟡 [D·D.5](./SDDs/SDD-001-plan-base/plan-d-memoria-v3code.md#d5) |
| Indexación AST / repo-map | Cliente (**web-tree-sitter WASM**); servidor solo cuando un agente la necesita | 🟡 [J·J.1](./SDDs/SDD-001-plan-base/plan-j-grafo3d-repomap.md#j1) |
| Canva 3D / oficina | Cliente (**Three.js WebGPU renderer**, 2026) | 🟡 [F·F.6](./SDDs/SDD-001-plan-base/plan-f-canva-oficina.md#f6) |
| LLM local (Ollama/llama.cpp en la máquina del usuario) | Cliente (modo todo-local; el servidor solo si el usuario elige nube) | 🟡 [C·C.6](./SDDs/SDD-001-plan-base/plan-c-reasonix-deepseek.md#c6) |
| Ejecución de agentes (24/7), sandboxes, cola durable, git compartido | **Servidor** (imposible en cliente en web-first) | 🔴 server-only |
| Sync hub, auth, secretos, RLS multi-tenant | **Servidor** | 🔴 server-only |

✅ = ya en planes · 🟡 = plan con nota client-side añadida · 🔴 = server-only por diseño ([SDD-008](./SDDs/SDD-008-analisis-cliente-servidor-k8s.md))

## Stack (validado por investigación 2026-08-24)

| Capa | Elección | Por qué (medido) |
|---|---|---|
| Gateway | **Rust axum 0.8.9 + tokio 1.53 + sqlx 0.9 + rustls 0.23** | 3.475 sesiones WS/vCPU (benchmark streaming por vCPU) — el más barato por conexión; mismo patrón que Everruns (plataforma de agentes OSS más cercana) |
| Workers | **Rust** — cola Postgres `FOR UPDATE SKIP LOCKED`, **sin credenciales de DB** (patrón Everruns) | stateless + heartbeat (reclaim 30s); el lenguaje no es el cuello de botella (esperan LLM/sandbox) |
| BFF Node/Hono | **NO** | un solo stack para un solo dev = impuesto doble evitado; Hono solo si mañana se necesita ecosistema npm/edge (y entonces Hono, jamás Express) |
| Plan B pragmático | **Go** (chi/pgx) | 70% del rendimiento con ~1/4 de fricción — solo si el vibecoding Rust se atasca |
| Frontend | React 19 + Vite 8 (Rolldown) + tsgo + Biome/oxlint | toolchain moderna (10-100× vs tsc/Babel/ESLint) |

## Flujo de datos

```
+--------------+     +--------------+      +------------------+
|   Usuario    |---->|  SPA React   |----->| Gateway axum     |
|  (navegador) |     | (client-first)|     | (REST + SSE/WS)  |
+--------------+     +------+-------+      +--------+---------+
                              |                      |
                              | (cómputo local)      | (cola + eventos)
                              |                      v
                              |              +-------+--------+
                              |              | WORKERS (Rust) |
                              |              |  + sandboxes    |
                              |              +-------+--------+
                              |                      |
                              +----> Postgres+RLS / MinIO / Valkey
```

## Plataformas soportadas

| Plataforma | Runtime | Backend | Frontend | Estado |
|---|---|---|---|---|
| **Navegador (v1 — WEB-FIRST)** | Chromium/Safari/Firefox | Gateway axum (servidor) | React | Activo (meta) |
| Celular/tablet | Navegador (UI adaptada, ADR-001) | idem | React | Activo (meta) |
| Servidor | Rust (axum + workers) | Rust | N/A | Activo (meta) |
| Tauri shell (diferido, solo con demanda) | Tauri 2 + WebView | Rust local (crates/core) | React | Diferido |

## Reglas de arquitectura

1. **Cómputo client-first**: toda capacidad que pueda correr en el cliente va al cliente (tabla arriba); prohibido mandar al servidor trabajo que el navegador puede hacer gratis.
2. **Un solo frontend** — todo React en `src/`, adaptación via `useResponsive()`, no hay `src-desktop/` ni `src-mobile/`.
3. **Dominio puro en Rust** (`crates/core`) sin Tauri ni HTTP — consumido por server y (futuro) tauri-shell.
4. **Workers stateless** — sin credenciales de DB; reclaman tareas con `FOR UPDATE SKIP LOCKED` + heartbeat.
5. **Multi-tenant con Postgres + RLS fail-closed** (patrón tenaxum/Everruns); `tenant_id`/`project_id` en TODO dato desde el día 1 ([A·A.0]).
6. **Secretos SOLO en el servidor/Rust** — jamás al webview ni al bundle.
7. **Eventos**: efímeros por bus (broadcast por sesión) · durables en Postgres append-only (Ledger).
8. **Cada capa expone su contraparte MCP** (visión V3Code).
9. **Responsive TOTAL** — todas las pantallas operables en móvil 375 (ver AGENTS.md §Diseno responsive).

## Anti-patrones de arquitectura

| Mal | Bien | Por qué |
|---|---|---|
| Backend Python (FastAPI/CrewAI) para el servidor | Rust (axum + workers) | Python queda ~3× por debajo en sesiones WS/vCPU y añade un segundo stack |
| BFF Node separado | Gateway axum sirve todo | Un solo stack para un solo dev |
| Cómputo pesado en servidor que puede ir al cliente | WASM/local en el cliente (D.5, J.1, F.6, C.6) | El servidor escala con datos, no con CPU de usuarios |
| `src-desktop/`, `src-mobile/` | `src/` con `useResponsive()` | Un solo frontend |
| Tipos duplicados sin sincronizar | `packages/shared-types/` + tauri-specta | Consistencia |
| Workers con credenciales de DB | Workers stateless (cola SKIP LOCKED) | Superficie de ataque mínima |

## Checklist de arquitectura (antes de PR)

- [ ] ¿La capacidad pudo correr en el cliente y se dejó en el servidor? (client-first violado → justificar)
- [ ] Código en la carpeta correcta (src/, crates/, e2e/, docs/)
- [ ] No hay lógica de negocio en componentes React
- [ ] No hay Python ni Node server-side nuevo en el repo
- [ ] Shared types actualizados si cambió un modelo
- [ ] `project_id`/tenant en toda tabla y consulta nueva
- [ ] Workers sin credenciales de DB
- [ ] Tests de la feature (4 capas + humana móvil si es GUI)
