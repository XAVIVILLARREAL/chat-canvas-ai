# ADR-007 — Mapping modelo de dominio ↔ schema SQLite (Etapa 0, slice 0.1)

- **Estado:** Aceptado · 2026-08-27
- **Contexto:** El server axum vive en `HashMap` en memoria; el schema canónico (`SCHEMA-MAESTRO` §3) no cubre todos los tipos del dominio actual.

## Decisión

| Tipo de dominio | Tabla | Estrategia |
|---|---|---|
| `Canvas` | `canvases` (nueva en 0002) | **Payload JSON** — el dominio completo (`nodes`, `edges`, `viewport`, `settings`) como JSON en `data`. Columnas: `id`, `project_id`, `data`, `updated_at`, `deleted_at` |
| `Agent` | `agents` (nueva en 0002) | **Payload JSON** — mismo patrón |
| `MCPServer` | `mcp_servers` (nueva en 0002) | **Payload JSON** — mismo patrón |
| `Skill` | `skills` (canónica 0001) | `manifest` = skill completo como JSON; `slug` = id del skill; historial en `skill_versions` (int autoincremental, el semver del dominio vive dentro del manifest) |
| `ExecutionContext` | `executions` (canónica 0001) | **Columnas tipadas** — `status`/`trigger`/`node_states`/`variables`/`result` mapeados columna a columna (enums serde `snake_case` ↔ TEXT) |
| Workspace único local | `projects` | Proyecto por defecto `local-default` creado al arranque (local-first; multi-tenant real llega con nube/RLS en 0.2) |

## Por qué así

1. **No sobrecomplicar:** los objetos de workspace (canvas/agent/mcp) mutan rápido y su query es por id/lista — payload JSON evita mantener 3 schemas en paralelo mientras el dominio evoluciona. SQLite JSON1 permite extraer campos si se necesita.
2. **Respetar el contrato canónico donde existe:** `skills`, `executions`, `projects`, `settings`, `event_stream` ya tienen columnas definidas en `SCHEMA-MAESTRO` — se usan tal cual, sin duplicar.
3. **Portabilidad a Postgres (0.2):** `data JSON` → `JSONB` directo; `TEXT` epoch ms igual; sin lógica propietaria.

## Consecuencias

- El server pasa de `HashMap` a `repo::Db` (sqlx pool) — la data sobrevive reinicios (mini-gate 0.1).
- Los handlers son delgados: serializan dominio ↔ JSON; la lógica de negocio sigue en `canvas-ai-core`.
- Cuando el chat (sessions/messages) llegue en Etapa A, usa las tablas canónicas directamente — sin tocar este mapping.
- `documents`/`document_links`/`providers`/`settings`/`event_stream` quedan listos para sus slices (0.3, 0.4).
