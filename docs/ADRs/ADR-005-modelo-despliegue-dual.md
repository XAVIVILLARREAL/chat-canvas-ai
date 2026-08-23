# ADR-005 · Modelo de Despliegue Dual — Local-first + Servidor Central (modo nube)

> Fecha: 2026-08-23 · Estado: Aceptado · Complementa: [ADR-002](./ADR-002-arquitectura-hibrida.md) (un codebase), [ADR-003](./ADR-003-voz-y-sincronizacion.md) (sync WS), [ADR-004](./ADR-004-integracion-github.md) (GitHub)
> Visión del producto: **desarrollar desde cualquier dispositivo sin fricción** — laptop, celular, browser — con sesiones y agentes sincronizados, y los agentes **siguen trabajando aunque te desconectes**.

## Contexto

El diseño actual es *local-first*: cada instalación Tauri trae su backend Rust embebido + SQLite. Eso da privacidad total pero **no sincronización ni continuidad**: cerrar la laptop = detener el trabajo. El usuario define el norte:

1. Abrir desde cualquier dispositivo y **continuar donde dejaste** (sesiones, agentes, canvas)
2. Los agentes trabajan **en un servidor** contra repos persistentes (estilo Codespaces/Discord: el backend corre siempre)
3. Base git propia en el servidor ("un GitHub nuestro") que además **se conecta/puentea a GitHub**
4. Stack eficiente, open source, comercializable — preferencia Rust/Go

## Decisión

### D1 — Un solo dominio Rust, dos binarios (LA decisión habilitante)

Refactorizar `src-tauri` a workspace Cargo con crates separados por responsabilidad:

```
crates/
  core/        # dominio puro: Agent, Task, Skill, Session, reglas (sin Tauri ni HTTP)
  tauri-shell/ # shell desktop/mobile: IPC → llama a core (el actual src-tauri)
  server/      # binario axum: HTTP/WS → llama al MISMO core (etapa 12+)
```

Hoy hay ~70 líneas de Rust — el refactor cuesta horas ahora, reescribirlo después costaría semanas. **Se aplica antes de arrancar Etapa 1.** La flexibilidad "local o nube" deja de ser una promesa y pasa a ser una propiedad del build.

### D2 — Persistencia abstracta via sqlx

`sqlx` ya está en el stack y soporta SQLite **y** PostgreSQL con el mismo código. Modo local usa SQLite; modo servidor usa PostgreSQL + Row Level Security por tenant (patrones probados del proyecto hermano ERP: `X-Tenant-ID`, RLS fail-closed, ledger de auditoría). Feature-flag por compilación, no forks.

### D3 — Git de base propio, ligero; puente a GitHub

NO embeber Forgejo/Gitea en v1 (peso + mantenimiento). El servidor gestiona **repos bare git en disco** detrás del trait `GitService` ya definido en [Plan M](../SDDs/SDD-001-plan-base/plan-m-github.md):

- Lectura/diff/log: **gitoxide** (Rust, Apache/MIT) — rápido, sin shelling out
- Operaciones complejas (merge, rebase): CLI git del sistema
- Puente GitHub: **octocrab** (Rust, Apache/MIT) — OAuth Device Flow, push/mirror, crear PRs, sincronizar issues
- Cada acción de agente = commits en ramas/worktrees → resultados revisables como diffs (encaja con el motor de pruebas H)
- Si algún día se quiere forjo completo con UI web (issues/PRs propios): evaluar embeber **Forgejo (MIT, Go)** como servicio opcional del compose — nunca como dependencia del core

### D4 — Sesiones resumibles = CRDT + event log

Una sesión de trabajo es `{doc Yrs (estado canvas/chat/agentes) + event log append-only}`. El SyncHub del [Plan L](../SDDs/SDD-001-plan-base/plan-l-sync-cowork.md) evoluciona a componente permanente del servidor:

- **yrs** (y-crdt, JetBrains, MIT): el mismo CRDT corre en cliente y servidor — converge multi-dispositivo, tolera offline
- Referencia de arquitectura: y-sweet (servidor Yjs en Rust)
- Resume desde celular = descargar doc + replay de eventos → historial completo, cero fricción
- Los agentes corren en el servidor dentro de **sandboxes Docker** (bollard, Apache-2.0): límites CPU/RAM/red por tenant; el trabajo continúa aunque todos los dispositivos se desconecten

### D5 — Stack 100% Rust MIT/Apache (comercializable)

| Componente | Crate | Licencia | Rol |
|---|---|---|---|
| Runtime async | tokio | MIT | Servidor |
| API/WebSocket | axum | MIT | Gateway |
| DB | sqlx | MIT/Apache | SQLite ↔ Postgres |
| CRDT | yrs | MIT | Sync sesiones/canvas |
| Git | gitoxide | MIT/Apache | Repos del servidor |
| GitHub | octocrab | Apache/MIT | Puente GitHub |
| Docker API | bollard | Apache | Sandboxes de agentes |

Sin AGPL en dependencias embebidas (Coder es AGPL — solo referencia de arquitectura, no dependencia). Todo permite SaaS comercial cerrado sin obligación de publicar código propio.

### D6 — Tres modos de despliegue, un codebase

| Modo | Qué corre | Para quién |
|---|---|---|
| **Local-first** (default) | App Tauri autocontenida (core + SQLite) | Privacidad total, uso individual/offline |
| **Self-host** | `docker compose up` → servidor Rust + Postgres + storage | Empresas quieren sus agentes 24/7 en SU servidor |
| **Cloud SaaS** (futuro) | Nuestro servidor multi-tenant con quotas/RBAC/auditoría | Producto comercial recurrente |

## Fases (mapeadas al roadmap vigente — no lo reemplazan)

1. **Ahora:** refactor workspace crates (D1) — prerrequisito barato de Etapa 1
2. **Etapa 12 (Plan L):** el SyncHub binario se construye sobre `crates/server` — nace el modo nube
3. **Etapa 13 (Plan M):** `GitService` sirve primero los repos locales y luego los del servidor (mismo trait, dos backends)
4. **Etapa 14 (Empresas autónomas):** orquestador de agentes elige ejecución local vs sandbox servidor según config del tenant
5. **Post-v1:** multi-tenant SaaS formal (auth/RBAC/quotas/auditoría — donar patrones del ERP hermano)

## Alternativas consideradas y descartadas

| Alternativa | Por qué no |
|---|---|
| Embeber Forgejo/Gitea desde v1 | Peso, acoplamiento, UI duplicada; GitService + gitoxide cubre lo necesario; Forgejo queda como opción opcional posterior |
| Reescribir todo en Go | Rompería compartir dominio entre Tauri y servidor — la ventaja competitiva ES un solo core Rust |
| P2P sin servidor | Contradice ADR-003 (WS decidido) y no resuelve "agentes siguen trabajando sin mí" |
| Solo SaaS (abandonar local-first) | Pierde el diferenciador de privacidad: el código de las empresas clientes puede quedarse en su máquina |

## Riesgos

| Riesgo | Mitigación |
|---|---|
| Sandboxing de agentes en servidor (ejecutan código) | Docker + perfiles no-red + límites por tenant; microVMs (Firecracker) si se requiere aislamiento fuerte multi-tenant |
| Costos LLM centralizados en modo cloud | Presupuestos por tenant (patrón ERP), enrutamiento por costo ya diseñado (Plan C) |
| Latencia móvil en canvas | CRDT optimista local + reconciliación; canvas renderiza estado local, servidor converge |
| Complejidad de dos backends GitService | Un solo trait, tests compartidos contra ambos backends desde el día 1 |

## Consecuencias

- ✅ Flexibilidad real: mismo producto corre embebido, self-hosted o en nuestra nube
- ✅ El trabajo de los agentes es continuo y auditable (event log + commits)
- ✅ Cero reescritura futura: la decisión D1 tomada HOY evita el refactor caro de mañana
- ⚠️ Disciplina: `crates/core` debe mantenerse libre de dependencias Tauri/HTTP (lint de imports en CI)
