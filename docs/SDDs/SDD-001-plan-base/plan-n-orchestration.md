# PLAN N — Orquestación de Sesiones y Agentes

> [← PLAN M](./plan-m-github.md) · [← Maestro](./README.md) · [PLAN O →](./plan-o-marketplace-v1.md)
> **Este plan REEMPLAZA el concepto obsoleto de "Empresas Autónomas"**
> Canvas AI NO crea empresas autónomas. Es una herramienta de IA generalista donde el usuario orquesta sesiones y agentes.

---

## Contexto del cambio

**Antes (obsoleto):** Canvas AI creaba "empresas autónomas" con roles, jerarquías, presupuestos, kill-switches y "empleados IA" con identidad de negocio.

**Ahora (actual):** Canvas AI es una **herramienta de IA generalista** donde:
- El usuario crea **sesiones** (conversaciones, proyectos, tareas)
- Dentro de cada sesión invoca **agentes** (skills con identidad)
- Los agentes pueden orquestar **sub-agentes** (multi-agent loops)
- Todo se visualiza en el **Control Room** (canvas visual)
- No hay concepto de "empresa", "rol de negocio", "presupuesto de empleado", ni "kill-switch de empleado"
- **Modo nube (ADR-006)**: quien pague la suscripción puede orquestar sesiones 24/7 — los agentes corren en workers Linux aunque cierres la app; presupuesto y límites por cuenta, no "por empleado"

---

## Fases

### N.1 — Gestión de sesiones

Cada sesión es un **contexto de trabajo**:
- Sesión = conversación + proyecto + agentes activos
- Múltiples sesiones simultáneas (tabs o sidebar)
- Sesiones se pueden agrupar por proyecto
- Historial de sesiones con búsqueda
- Export/import de sesiones completas

Tabla `sessions` (ya definida en Plan A):
- `id, title, project_id, status, agent_config, metadata`
- `created_at, updated_at, total_tokens, total_cost_usd`

**Pruebas:** E2E: crear 3 sesiones, cambiar entre ellas, verificar aislamiento.

---

### N.2 — Invocación de agentes

Dentro de una sesión, el usuario invoca agentes:
- **Slash command**: `/agent qa` → activa el skill QA en esta sesión
- **Panel de skills**: click en un skill → se activa en la sesión actual
- **Multi-agent**: un skill puede invocar otros skills (delegación)
- **Auto-invocación**: el sistema sugiere skills basado en el contexto

Cada agente activo tiene:
- Avatar visible en el chat
- Contexto propio (no mezcla con otros agentes)
- Herramientas propias (tool-gating)
- Costo propio (tracking separado)

**Pruebas:** E2E: invocar 2 agentes en la misma sesión, verificar contextos aislados.

---

### N.3 — Delegación de sub-agentes (patrón Hermes)

Un agente puede delegar a sub-agentes:
- **ACP Protocol**: comunicación via JSON-RPC sobre stdio/HTTP/SSE
- **Contrato claro**: el agente padre define inputs/outputs del sub-agente
- **Timeout y retry**: configuración por sub-agente
- **Resultado**: el sub-agente responde al padre, el padre integra

Ejemplo:
```
Agente "Dev" recibe: "Crear endpoint /api/users"
  → Delega a sub-agente "Coder" (escribe el código)
  → Delega a sub-agente "Tester" (escribe tests)
  → Delega a sub-agente "Reviewer" (revisa calidad)
  → Agregador: combina resultados
  → Dev presenta resultado final al usuario
```

**Pruebas:** E2E: skill con 3 sub-agentes → ejecutar → verificar resultado integrado.

---

### N.4 — Control Room: vista de sesiones activas

En el Control Room canvas:
- Cada sesión activa es un **nodo grande** con:
  - Título de la sesión
  - Avatar del agente principal
  - Estado (active/thinking/working/done)
  - Último mensaje (preview)
  - Costo acumulado
- **Conexiones** entre sesiones que se comunican
- **Notas** pegadas en el canvas (contexto libre)
- **Resultados** como nodos attachados a sesiones
- **Automatizaciones** como nodos连接ados a sesiones

Layout automático:
- Sesiones activas arriba
- Resultados abajo
- Notas a los lados
- Conexiones como edges con labels

**Pruebas:** E2E: 3 sesiones activas en el canvas → verificar layout → interactuar.

---

### N.5 — Tracking de actividad

Cada acción se registra (sin exceso de detalle):
- Sesión creada, activada, pausada, archivada
- Agente invocado, resultado recibido
- Sub-agente delegado, resultado integrado
- Costo acumulado por sesión
- Tiempo activo por sesión

Dashboard simple:
- Sesiones activas ahora
- Costo total del día
- Agentes más usados
- Sesiones más productivas

**Pruebas:** Unit: tracking events. E2E: verificar dashboard muestra datos reales.

---

### N.6 — Plantillas de sesiones

Sesiones pre-configuradas para casos de uso comunes:
- **Code Review**: sesión con skill reviewer + tester
- **Bug Fix**: sesión con skill debugger + coder
- **Feature Dev**: sesión con skill PM + coder + tester
- **Data Analysis**: sesión con skill analyst + viz
- **Writing**: sesión con skill writer + editor

Plantillas son skills especiales que configuran la sesión completa.

**Pruebas:** E2E: crear desde plantilla → verificar que los agentes están configurados.

---

### N.7 — Modo nube 24/7 (suscripción, ADR-006)

Para quien pague la nube, la orquestación corre 24/7:
- **Workers Linux** (contenedores Ubuntu, patrón GrokBot) ejecutan los agentes en el servidor
- La cola de sesiones es **durable** (Postgres + workers stateless `FOR UPDATE SKIP LOCKED`)
- **BYOK**: se usa la API key del usuario, cifrada por tenant (envelope AES-GCM)
- **Presupuesto por cuenta**: límite de ejecución diario/mensual configurable; pausa limpia al alcanzarlo
- El usuario cierra la app → los agentes siguen trabajando → al volver, digest + evidencia en el Control Room
- Reanudación: la sesión se puede retomar desde cualquier dispositivo (sync L)

**Pruebas:** Integration: 20 tareas en cola → consumo ordenado + corte por presupuesto. Chaos: provider cae → pausa limpia, reanuda al volver. E2E: cierro la app → reabro en otro dispositivo → la sesión siguió y muestra evidencia.

---

### N.9 — Agente Supervisor del Control Room ([FEATURE-BACKLOG](../../FEATURE-BACKLOG.md) F21, patrón chief-of-staff de GrokBot/Hermes)

Un agente especial —**el Supervisor**— con visibilidad de TODOS los proyectos y TODAS las sesiones de la cuenta. Es quien atiende los puentes de mensajería (WhatsApp/Telegram/Discord) y el Control Room:

- **Es un skill especial** (`role: supervisor` en [CONTRATO-SKILL](../../CONTRATO-SKILL.md)): personalidad/nombre/avatar propios del usuario.
- **Tools exclusivas (tool-gating estricto):**
  - `list_projects` / `list_sessions(status)` — ver todo el estado real (del event_stream, no inventado)
  - `control_session(id, pause|resume|cancel|prompt)` — actuar sobre cualquier sesión
  - `create_session(project_id, template?)` — abrir trabajo nuevo por orden
  - `query_costs(range)` / `report_deliveries(range)` — métricas y entregas
  - `notify(channel, msg)` — responder por el puente de mensajería
- **Órdenes por voz/texto desde el chat que sea:** "¿en qué anda la sesión auth?" · "pausa la de scraping" · "¿cuánto gastamos hoy?" · "crea una sesión para el fix del login" → ejecuta y **confirma con evidencia**.
- **Juicio humano:** acciones destructivas (cancelar, borrar, gastar >umbral) requieren **confirmación con opciones numeradas** (primitiva [V·V.2](./plan-v-visual-grokbot.md)) — el Supervisor pregunta, no decide solo.
- **Guardrails:** presupuesto propio por canal, rate-limit, kill-switch; TODO comando queda como rung en el event_stream (auditable).
- **Alcance:** 1 Supervisor por cuenta (local) / por tenant (nube). NO es jerarquía de empleados: es el mayordomo del usuario sobre SU trabajo.

**Pruebas:** Integration: orden "pausa sesión X" → pausa real + rung DECISION del supervisor. Chaos: presupuesto del supervisor agotado → avisa y deja de actuar (no rompe sesiones). E2E HUMANA (vía Telegram mock): "¿en qué anda la sesión auth?" → responde estado REAL del event_stream; "pausa la de scraping" → pide confirmación numerada → confirmo → pausada; "crea sesión para el login fix" → creada y visible en el Control Room.

---

## 🚪 GATE N (demo verificable)

Abro Canvas AI → creo una sesión "Mi Proyecto" → invoco el skill "Coder" → el agente aparece con su avatar → le pido crear un archivo → lo crea → invoco "Tester" en la misma sesión → Tester escribe tests → ambos agentes aparecen en el Control Room → verifico el costo acumulado → archivo la sesión → aparece en el historial. Suite humana verde.

---

[← PLAN M](./plan-m-github.md) · [← Maestro](./README.md) · [PLAN O →](./plan-o-marketplace-v1.md)
