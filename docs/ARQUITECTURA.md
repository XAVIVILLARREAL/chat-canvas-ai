# ARQUITECTURA.md — Arquitectura de Canvas AI

> Documento maestro de arquitectura. Siempre consultar antes de crear componentes, servicios o features nuevas.
> **v5.0 (2026-08-25)**: alineada con **ADR-006** — visión híbrida local-first (gratis) + nube multi-tenant de pago (BYOK).

## Visión general

**Canvas AI** es una herramienta de IA generalista **híbrida**: el producto base es **local-first** (Tauri v2 + SQLite, gratis, BYOK), y existe un **modo nube** multi-tenant de pago (Postgres+RLS + workers Linux 24/7) para quien quiera ejecución continua. El gateway Rust (Axum) sirve la SPA React y soporta REST + SSE/WS de streaming. Un crate de dominio compartido (`canvas-ai-core`) alimenta al servidor y al shell Tauri. Los agentes se comunican via ACP Protocol (Hermes) y MCP (stdio/HTTP/SSE). **BYOK**: cada usuario trae su API key (keychain del OS en local; cifrada por tenant en nube).

**Referencias arquitectónicas**: Hermes Agent (ACP, subagents, MCP, BYOK), GrokBot (sessions, sandbox Linux), ERP AI Canvas (deploy-spec, node types).

```
+-----------------------------------------------------+
|              CLIENTE (Tauri desktop = principal)     |
|  src/ — SPA React (cómputo client-first, local)     |
|  + SQLite + SQLiteVec (datos locales, offline)      |
+-----------------------------------------------------+
|              GATEWAY (Rust axum, stateless)          |
|  crates/server — sirve SPA + REST + SSE/WS           |
+-----------------------------------------------------+
|              DOMINIO (crates/core — Rust)            |
|  Agentes · Tareas · Skills · Sesiones · Memoria      |
+-----------------------------------------------------+
|          WORKERS de agentes (Rust, sin DB creds)     |
|  crates/worker — cola SKIP LOCKED · sandbox Linux    |
|  (nube 24/7) · spawn local (desktop) · hb 30s        |
+-----------------------------------------------------+
|        DATOS (local: SQLite · nube: Postgres+RLS)    |
+-----------------------------------------------------+
```
> ✅ `crates/worker` creado (2026-08-24, patrón Everruns): stateless sin credenciales de DB, heartbeat 30s — el claim SKIP LOCKED y el sandbox Linux llegan con C.3/H.9a. En modo nube los workers son los que corren los agentes 24/7 (ADR-006 Q3/Q8).

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
| Ejecución de agentes (24/7), sandboxes, cola durable, git compartido | **Servidor** (modo nube de pago, ADR-006) | 🔴 server-only |
| Sync hub, auth, secretos, RLS multi-tenant | **Servidor** | 🔴 server-only |

✅ = ya en planes · 🟡 = plan con nota client-side añadida · 🔴 = server-only por diseño ([SDD-008](./SDDs/SDD-008-analisis-cliente-servidor-k8s.md))

## Stack (validado por investigación 2026-08-24)

| Capa | Elección | Por qué (medido) |
|---|---|---|
| Gateway | **Rust axum 0.8.9 + tokio 1.53 + sqlx 0.9 + rustls 0.23** | 3.475 sesiones WS/vCPU (benchmark streaming por vCPU) — el más barato por conexión; mismo patrón que Everruns (plataforma de agentes OSS más cercana) |
| Workers | **Rust** — cola Postgres `FOR UPDATE SKIP LOCKED`, **sin credenciales de DB** (patrón Everruns) | stateless + heartbeat (reclaim 30s); el lenguaje no es el cuello de botella (esperan LLM/sandbox) |
| BFF Node/Hono | **NO** | un solo stack para un solo dev = impuesto doble evitado; Hono solo si mañana se necesita ecosistema npm/edge (y entonces Hono, jamás Express) |
| Tipos compartidos | **OpenAPI del gateway** (crates/core specta → JSON schema → openapi-typescript/orval) | fuente de verdad única; `shared-types` deja de ser manual (v3.8) |
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

## Plataformas soportadas (targets de entrega)

> Matriz canónica completa (qué se instala dónde + estado): [PLATAFORMAS-TARGETS](./PLATAFORMAS-TARGETS.md)

| Plataforma | Runtime | Backend | Frontend | Artefacto | Estado |
|---|---|---|---|---|---|
| **Windows** | Tauri 2 + WebView2 | Rust local (crates/core) + SQLite | React | `.msi`/`.exe` | CI build-desktop ✅ |
| **macOS** | Tauri 2 + WKWebView | idem | React | `.app`/`.dmg` (universal, notarizado) | CI build-desktop ✅ |
| **Linux desktop** | Tauri 2 + WebKitGTK | idem | React | `.AppImage`/`.deb`/`.rpm` | CI build-desktop ✅ |
| **Android** | Tauri mobile | Rust local + SQLite (BYOK) | React | `.apk`/`.aab` | gen/android ✅ · release 🔲 |
| **iOS** | Tauri mobile | Rust local + SQLite (BYOK) | React | `.ipa` | **🔲 gen/apple pendiente (Mac)** |
| **Web/PWA** | Navegador | gateway axum (nube) | React | SPA estática | parcial |
| **Servidor Linux (nube 24/7, de pago)** | Linux (Docker, contenedores Ubuntu) | axum + workers + Postgres+RLS | N/A | imágenes Docker + Compose | Etapa 10 (plan-s) |

## Reglas de arquitectura

1. **Cómputo client-first**: toda capacidad que pueda correr en el cliente va al cliente; prohibido mandar al servidor trabajo que el navegador puede hacer gratis. En local-first, **casi todo es local**.
2. **Híbrido local + nube (ADR-006)**: mismo dominio y frontend; local = SQLite (gratis), nube = Postgres+RLS (de pago); `tenant_id`/`project_id` en TODO dato desde el día 1 (RLS fail-closed en nube).
3. **BYOK**: el usuario trae su API key. Local → keychain del OS (crate `keyring`). Nube → cifrada por tenant (envelope AES-GCM, KEK por tenant). Nunca en claro, nunca al webview.
4. **Sandbox Linux (patrón GrokBot)**: el código de agentes corre en contenedor Ubuntu aislado — red denegada por defecto, allowlist, timeout, kill limpio.
5. **Un solo frontend** — todo React en `src/`, adaptación via `useResponsive()`, no hay `src-desktop/` ni `src-mobile/`.
6. **Dominio puro en Rust** (`crates/core`) sin Tauri ni HTTP — consumido por server y tauri-shell.
7. **Workers stateless** — sin credenciales de DB; reclaman tareas con `FOR UPDATE SKIP LOCKED` + heartbeat.
8. **Secretos SOLO en el servidor/Rust local** — jamás al webview ni al bundle.
9. **Auth MVP desde el día 1** (modo nube): sesión/token + RLS fail-closed; passkeys/QR post-base ([SDD-008]).
10. **Postgres en Compose desde el día 1** (para probar RLS real); SQLite es el almacén local por defecto.
11. **Eventos**: efímeros por bus (broadcast por sesión) · durables en Postgres/SQLite append-only (Ledger).
12. **Cada capa expone su contraparte MCP** (visión V3Code).
13. **Responsive TOTAL** — todas las pantallas operables en móvil 375 (ver AGENTS.md §Diseno responsive).

## Anti-patrones de arquitectura

| Mal | Bien | Por qué |
|---|---|---|
| Backend Python (FastAPI/CrewAI) para el servidor | Rust (axum + workers) | Python queda ~3× por debajo en sesiones WS/vCPU y añade un segundo stack |
| BFF Node separado | Gateway axum sirve todo | Un solo stack para un solo dev |
| Cómputo pesado en servidor que puede ir al cliente | WASM/local en el cliente (D.5, J.1, F.6, C.6) | El servidor escala con datos, no con CPU de usuarios |
| `src-desktop/`, `src-mobile/` | `src/` con `useResponsive()` | Un solo frontend |
| Tipos duplicados sin sincronizar | `packages/shared-types/` + tauri-specta | Consistencia |
| Workers con credenciales de DB | Workers stateless (cola SKIP LOCKED) | Superficie de ataque mínima |
| Keys del usuario en claro / en el bundle | Keychain del OS (local) · cifrado por tenant (nube) | BYOK seguro (ADR-006) |
| Nube gratuita para todo el mundo | Local gratis · nube 24/7 de pago | Modelo de negocio (ADR-006) |

## Checklist de arquitectura (antes de PR)

- [ ] ¿La capacidad pudo correr en el cliente y se dejó en el servidor? (client-first violado → justificar)
- [ ] Código en la carpeta correcta (src/, crates/, e2e/, docs/)
- [ ] No hay lógica de negocio en componentes React
- [ ] No hay Python ni Node server-side nuevo en el repo
- [ ] Shared types actualizados si cambió un modelo
- [ ] `project_id`/tenant en toda tabla y consulta nueva
- [ ] Workers sin credenciales de DB
- [ ] Tests de la feature (4 capas + humana móvil si es GUI)
