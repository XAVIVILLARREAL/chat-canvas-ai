# ADR-006 — Visión híbrida: local-first gratis + nube SaaS multi-tenant de pago

> **Estado:** Aceptado (2026-08-25) · **Tipo:** Arquitectura / Modelo de negocio
> **Decisiones:** Q1-Q12 del análisis de plan · Reemplaza el fantasma de "empresa autónoma"

## Contexto

El plan se contradecía en 4 documentos (README desktop Tauri vs ARQUITECTURA web-first vs MATRIZ con "empresa autónoma" vs código con `AgentTeam`). Esta ADR fija la dirección única y elimina el residuo de "empresa autónoma".

## Decisiones

### Q1 — Plataforma: HÍBRIDO (local-first + nube opcional)
- **Local-first es el producto base** (Tauri v2 + SQLite): gratis, dueño de tus datos, funciona offline.
- **Modo nube** (SaaS multi-tenant): **solo quien paga**. El mismo código corre contra Postgres+RLS y workers Linux escalables.
- El shell Tauri ya no es "diferido": es **la** entrega principal. La web (navegador) es la misma SPA servida por el gateway, modo lectura/ligero.

### Q2 — Multi-tenant SaaS SÍ · "empresa autónoma" NO
- Multi-tenancy con `tenant_id`/`project_id` + RLS fail-closed en todo dato (día 1, patrón tenaxum/Everruns).
- **Se elimina** el concepto de "empresa autónoma": nada de jerarquías de "empleados IA", presupuestos de empleados ni dashboards de empresa.
- Se elimina el residuo de código: `AgentTeam`, `Company`, `teams` (core Rust, server, shared-types, frontend).

### Q3 — Ejecución de agentes
- **Local (gratis):** los agentes corren en la máquina del usuario (spawn local, Ollama como fallback).
- **Nube 24/7 (suscripción):** workers Rust stateless en servidores **Linux escalables**; el agente sigue corriendo aunque cierres la app.
- El worker nube usa el patrón Everruns (cola `FOR UPDATE SKIP LOCKED`, sin credenciales de DB, heartbeat).

### Q4 — Secretos/keys: BYOK con local-first seguro
- **Local:** API keys del usuario en el **keychain del OS** (crate `keyring`) — nunca en disco plano ni en el bundle.
- **Nube:** las keys del usuario se cifran por tenant (envelope AES-GCM, KEK por tenant) en el servidor; el usuario trae su key (BYOK) y el servidor la usa para ejecutar 24/7.
- Nunca expuestas al webview ni a otros tenants. El servidor nunca guarda la key en claro.

### Q5 — Proveedores: "Trae tu API" (modelo Hermes Agent)
- Registro universal de proveedores: **cualquier API compatible OpenAI/Anthropic/OpenRouter/local** conectable pegando tu key o URL.
- Copiado de Hermes Agent (Noun Research): un solo trait `AgentProvider`, registro de providers, enrutamiento por costo/perfil.
- Ollama local como provider nativo (offline).

### Q6 — Offline-first (patrón Hermes)
- El modo local funciona **sin internet**: Ollama + embeddings locales (`sqlite-vec`), FTS5 local, cola de tareas local con re-sync cuando vuelve la conexión.
- Caché local (React Query + service worker + outbox) como en L.2.

### Q7 — Skills = documentos `.md` (recetas)
- Un skill es un **documento markdown** (frontmatter + instrucciones) que se materializa como agente/expert/proceso/flujo.
- Con **personalidad, nombre y cara animada amigable** (avatar generado por IA con fallback procedural).
- Sin YAML obligatorio: editor visual con validación, que compila a `.md` canónico (fuente de verdad).
- Contrato de skill (schema del frontmatter) se define desde la fase Skills, no después.

### Q8 — Nube: BYOK + 24/7
- En modo nube **se sigue usando la API key del usuario** (BYOK), pero el **programa corre 24/7**: los workers del servidor ejecutan los agentes con esa key, con límites de costo y kill-switch por cuenta.

### Q9 — i18n — no decidido por el usuario → recomendación aplicada
- Docs en español, UI **es/en** con tokens i18n desde el día 1 (barato temprano, caro tarde). T.A11Y mantiene el gate dual idioma.

### Q10 — Voz / 3D / Consejo de Expertos / Dopamina → **últimas etapas (post-v1)**
- Se mueven a etapas finales (post-MVP-3). Se mantienen las **reglas VR-ready** (coordenadas 3D, sin absolute CSS) por su costo cero.
- "Consejo de Expertos" y dopamina se simplifican/reubican tras el MVP-2 como diferenciadores opcionales.

### Q11 — Modelo de negocio
- Local = gratis (trae tu key). Nube = suscripción por tenant (24/7, sync multi-dispositivo, marketplace). Free-tier de nube con límites de ejecución.
- Marketplace de skills = motor de red (ver SDD-010 actualizado).

### Q12 — Sandbox de agentes: Linux (Ubuntu) contenedor + patrón GrokBot
- Cada agente ejecuta en **contenedor Linux** (Ubuntu base) aislado por tarea (patrón de sandboxing de GrokBot): red denegada por defecto, allowlist, timeout, `kill` limpio.
- El worker cloud provisiona contenedores; en local, cuando un skill requiere ejecución de código, se usa el sandbox contenedor local (Docker) o WASM como fallback.

## Consecuencias

1. El shell Tauri pasa a ser la entrega principal; la web es la misma SPA en modo lectura/ligero.
2. `crates/worker` (ya creado, stateless) es la base del modo nube; se extiende para provisionar contenedores Linux.
3. Se elimina toda referencia a "empresa autónoma" en docs y código.
4. El README plan maestro se alinea con esta ADR (v3.0): híbrido, BYOK, skills `.md`, nube solo de pago.
5. La MATRIZ re-escopea las fases de "empresa" a orquestación 24/7 cloud.

## Anti-decisiones

- ❌ Backend Python para la nube → Rust (axum + workers).
- ❌ BFF Node separado → un solo stack Rust.
- ❌ Keys del usuario almacenadas en claro en servidor → nunca.
- ❌ "Empresa autónoma" con empleados IA → eliminado por decisión de producto.
