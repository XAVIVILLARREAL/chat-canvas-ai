# AUTH — Autenticación y autorización (local vs nube)

> **Producto:** Canvas AI · **Estado:** v1.0 · 2026-08-25 · Complementa [THREAT-MODEL](./THREAT-MODEL.md) y [ARQUITECTURA](./ARQUITECTURA.md)
> **Decisión clave:** en **local-first NO hay cuenta ni login** (eres el dueño de tu máquina). La **nube** (de pago) es donde existe la cuenta, la sesión y la autorización RLS.

## 1 · Modelo por modo

| Aspecto | Local-first (gratis) | Nube (suscripción) |
|---|---|---|
| Identidad | **ninguna** — la app local es tuya | cuenta (email+password, luego passkeys/OAuth) |
| Login | no aplica | sesión + token (httpOnly cookie / bearer) |
| Alcance de datos | workspace local (carpeta) | `tenant_id`/`project_id` + **RLS fail-closed** |
| Secretos | keychain del OS (BYOK) | vault cifrado por tenant (BYOK) |
| Sync | — | auth por cuenta; dispositivo autorizado por el usuario |

## 2 · Flujo en la nube (v1)

1. **Registro/login:** email + password → sesión en el gateway (token firmado, TTL 7d con refresh).
2. **Auth de API:** cada request lleva el token; el gateway resuelve `actor_type`/`actor_id` y lo inyecta en PostgREST (patrón tenaxum/Everruns).
3. **RLS fail-closed:** sin `tenant_id` válido → **0 filas** (nunca fallback abierto). Todo query filtrado por el tenant del token.
4. **Dispositivos:** los clientes (desktop/móvil/web) se ligan a la cuenta para sync (solo suscriptores); revocación por dispositivo.
5. **Passkeys/WebAuthn y OAuth** (Google/GitHub) → post-base (ADR-003, ya preparado en el plan).

## 3 · Lo que NUNCA pasa

- ❌ Login obligatorio en la app local (mata el pitch local-first).
- ❌ Tokens de proveedores LLM viajando al cliente nube (BYOK siempre del usuario).
- ❌ RLS sin fallback seguro: `pre_request` fail-closed desde el día 1.
- ❌ Sesiones de agente accesibles entre tenants.

## 4 · Verificación

- **Unit:** RLS devuelve 0 filas sin tenant; token expirado rechazado.
- **Integration:** 2 tenants → los datos del A jamás visibles para B (SQL directo, no solo UI).
- **E2E humano:** modo local arranca **sin login** · modo nube: registro→login→sesión persiste→logout→revocación de dispositivo.
- **Chaos:** token revocado en caliente → siguiente request 401 y la sesión de agente no se pierde.
