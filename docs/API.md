# API — Superficie REST del gateway (borrador canónico)

> **Producto:** Canvas AI · **Estado:** v0.1 borrador · 2026-08-25
> **Regla:** el artefacto canónico es el **OpenAPI generado** desde `crates/core` (specta) en la Etapa 0.5. Este documento es el **inventario de intención** (lo que debe existir) para que la implementación no invente rutas. Cambios = re-generar OpenAPI, nunca editar esto a mano para contradecirlo.

## 1 · Convenciones

- Base: `/api` · Prefijo por recurso · JSON · Errores `{ "error": { "code", "message", "details?" } }`
- **Auth (nube):** token en cookie httpOnly o `Authorization: Bearer`; `X-Tenant-ID`/`project_id` resuelto del token (nunca confiar en el header del cliente para el tenant, solo para select explícito).
- **IDs:** UUID v4 · fechas en epoch ms.
- **Versionado:** `/api/v1/*` desde el día 1 (aunque v1 sea la única).
- **Streaming:** SSE para chat (`/api/v1/sessions/:id/stream`) y eventos (`/api/v1/events/stream`).

## 2 · Inventario por recurso

| Recurso | Endpoints |
|---|---|
| **Health** | `GET /healthz` · `GET /api/v1/version` |
| **Proyectos** | `GET/POST /api/v1/projects` · `GET/PATCH/DELETE /api/v1/projects/:id` |
| **Sesiones** | `GET/POST /api/v1/sessions` · `GET/PATCH/DELETE /api/v1/sessions/:id` · `POST /api/v1/sessions/:id/fork` · `GET /api/v1/sessions/:id/stream` (SSE) |
| **Mensajes** | `GET /api/v1/sessions/:id/messages` · `POST /api/v1/sessions/:id/messages` · `GET /api/v1/messages/:id` |
| **Skills** | `GET/POST /api/v1/skills` · `GET/PATCH/DELETE /api/v1/skills/:id` · `GET /api/v1/skills/:id/versions` · `POST /api/v1/skills/:id/test` |
| **Providers (BYOK)** | `GET/POST /api/v1/providers` · `PATCH/DELETE /api/v1/providers/:id` · `POST /api/v1/providers/:id/test` (key NUNCA en respuestas; solo `key_ref`+`connected`) |
| **Canvas/automatización** | `GET/POST /api/v1/canvases` · `GET/PATCH/DELETE /api/v1/canvases/:id` · `POST /api/v1/canvases/:id/execute` · `GET /api/v1/canvases/:id/executions` |
| **Ejecuciones** | `GET /api/v1/executions` · `GET /api/v1/executions/:id` · `POST /api/v1/executions/:id/cancel|retry` |
| **Documentos (segundo cerebro)** | `GET/POST /api/v1/documents` · `GET/PATCH/DELETE /api/v1/documents/:id` · `GET /api/v1/documents/:id/links` · `POST /api/v1/documents/search` (semántica) |
| **Event_stream** | `GET /api/v1/sessions/:id/events` (rungs, paginado cursor) · `GET /api/v1/events/stream` (SSE) |
| **Settings** | `GET/PUT /api/v1/settings` (por scope/proyecto) |
| **Auth (nube)** | `POST /api/v1/auth/register|login|logout|refresh` · `GET /api/v1/auth/me` · `DELETE /api/v1/auth/devices/:id` |
| **MCP** | `GET/POST /api/v1/mcp/servers` · `GET/PATCH/DELETE /api/v1/mcp/servers/:id` · `POST /api/v1/mcp/servers/:id/call` |
| **Backup/export** | `POST /api/v1/backup/export` (bundle firmado) · `POST /api/v1/backup/import` · `DELETE /api/v1/backup/:id` |

## 3 · Contratos de datos

Fuente: [SCHEMA-MAESTRO](./SCHEMA-MAESTRO.md) · tipos generados por `crates/core` (specta → OpenAPI → openapi-typescript para el frontend). El frontend **jamás** define tipos a mano si pueden venir del OpenAPI.

## 4 · Verificación

- **OpenAPI 0.5:** generado sin errores + frontend compila contra los tipos generados.
- **Contrato:** todo endpoint del inventario existe o está marcado `[deferred]` con fecha en la MATRIZ.
- **E2E humano:** el flujo F1-F16 (PRD) pasa por esta API, no por atajos.
