# DATA-LIFECYCLE — Migraciones, backup/restore y cumplimiento (GDPR)

> **Producto:** Canvas AI · **Estado:** v1.0 · 2026-08-25 · Complementa [SCHEMA-MAESTRO](./SCHEMA-MAESTRO.md), [SLO-RELIABILITY](./SLO-RELIABILITY.md) y [THREAT-MODEL](./THREAT-MODEL.md)

## 1 · Migraciones (cómo evoluciona el schema)

- Herramienta: **sqlx migrations** versionadas (`0001_*.sql`…) en `crates/core/migrations/`, up+down, **ambos dialectos** (SQLite/Postgres).
- CI con `sqlx offline` (checks compile-time sin DB viva) — [plan-s](./SDDs/SDD-001-plan-base/plan-s-despliegue-costos.md).
- Reglas: una migración = un cambio atómico · nunca editar una migración ya aplicada (se crea una nueva) · `schema_migrations` con hash (patrón del ERP).
- **Rollback:** siempre hay down; el rollback de datos de usuario se hace vía backup, no vía down (down solo para dev/CI).
- **Versionado de datos de usuario:** `settings` y `skills` llevan `schema_version` para migración suave en el cliente local (actualiza en segundo plano sin perder trabajo).

## 2 · Backup y restore

| Modo | Estrategia | RPO | Verificación |
|---|---|---|---|
| **Local-first** | export manual `.canvas-ai-backup` (firmado) + recordatorio periódico + autosave WAL | manual (depende del usuario) | drill: export→import en otra máquina sin pérdida |
| **Nube** | WAL + backups **B2 cada 15 min** + full diario + drill trimestral | **≤15 min** | restore en máquina limpia ≤30 min (S.2) |
| **Nube multi-nodo** | B2 + réplica de standby (CNPG) | ≤15 min | failover probado |

Retención de backups: full diario 30 días + semanales 12 semanas + mensuales 12 meses. Pruebas: [SLO-RELIABILITY](./SLO-RELIABILITY.md).

## 3 · Cumplimiento (GDPR / privacidad)

| Derecho | Cómo se cumple | Endpoint |
|---|---|---|
| **Acceso/portabilidad** | export completo del workspace en formato abierto (JSONL + `.md`) | `POST /api/v1/backup/export` |
| **Borrado (erasure)** | borrado real por tenant (datos + backups marcados para purge en retención) | `DELETE /api/v1/tenant` (solo owner) |
| **Rectificación** | edición normal de sesiones/skills/documentos | CRUD estándar |
| **Limitación de tratamiento** | los datos nube se usan solo para ejecutar el servicio; telemetría es opt-in anónima | [PRODUCT-METRICS](./PRODUCT-METRICS.md) |
| **Notificación de breach** | política en [SECURITY.md](../SECURITY.md) + registro en `docs/INCIDENTES/` | — |
| **Retención de logs** | `event_stream` retención por tipo (rungs 365d, telemetría 30d) | job de purga |

**Local-first = ventaja competitiva de privacidad:** en modo local no hay datos en ningún servidor ("tus datos nunca salen"). La nube solo almacena lo que el suscriptor elige sincronizar.

## 4 · Verificación

- **Migration:** up/down/up idempotente en SQLite y Postgres; `schema_migrations` hashado.
- **GDPR:** script de export produce bundle importable · erasure deja 0 filas del tenant (SQL directo) · purga de retención corre en staging.
- **Drill (S.2):** restore completo ≤30 min automatizado, trimestral.
