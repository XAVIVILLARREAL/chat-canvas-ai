# SDD-004 — Análisis exhaustivo: Grok Bot (xAI/Cursor) → qué robamos para Empresa Dev

> Fecha: 2026-08-23 · Estado: Aprobado · Fuentes: anuncio oficial x.ai, Cursor Forum, The Verge, InfoQ, Digital Trends, Europa Press (ago 2026)

## ⚠️ Nota de acceso

Grok Bot **NO es descargable ni open source**: beta cerrada por suscripción (SuperGrok Plus/Heavy, Cursor Pro+/Ultra/Teams), alojado en la nube de xAI. El análisis se basa en su documentación oficial y cobertura de prensa — que es abundante y detallada. Robamos PATRONES de producto, no código.

## Qué es Grok Bot (hechos verificados)

Sistema de **"compañeros IA siempre encendidos"** (bots) que:
- Tienen **su propia computadora persistente en la nube** (browser + filesystem + terminal)
- **Inician sesión en herramientas reales** del usuario (email, CRM, webs SIN API/MCP vía computer-use)
- Terminan trabajos **end-to-end** y solo vuelven cuando necesitan aprobación/judgment call
- Se les **escribe como a un colega** (chat, mismo hilo en móvil/desktop)
- Corren **en paralelo**: un "chief of staff" gestiona especialistas; hay **group chats donde los bots coordinan solos**, pasan ownership y asignan trabajo
- Los bots **se mensajean ENTRE ELLOS** e intercambian contexto en threads compartidos
- **Rutinas por demostración**: le pides "sígueme la próxima vez que haga esto" → observa → guarda la rutina → la re-ejecuta solo (on demand o programada) aceptando correcciones
- **Memoria persistente**: aprende tu voz, tus casos borde, cuándo molestarte vs seguir; retoma hilos abandonados, empuja handoffs estancados, se vuelve **proactivo**
- La computadora es **por cuenta** (compartida entre tus bots), cada bot con su pantalla

## Posicionamiento: ellos vs nosotros

| Dimensión | Grok Bot | Empresa Dev |
|---|---|---|
| Dominio | Negocio general (ventas, ops, inbox) | **Empresa de DESARROLLO autónoma** |
| Ejecución | Computer-use sobre apps ajenas | Código real: repo, tests, diffs, PRs |
| Evidencia | "vuelve cuando terminó" | **Aprobación con evidencia verificable** (tests, diffs, rungs) |
| Modelo | Cerrado, nube xAI, $120–300/mes | Local-first, Reasonix+DeepSeek barato, tuyo |
| Interfaz | Chat tipo mensajería | **Chat + paneles Lovable + oficina animada** |
| Multiagente | Sí (grupo, jerarquía) | Sí (jerarquía PM→operativos + worktrees) |

**Conclusión estratégica**: ellos validan el mercado de "delegar a un equipo"; nuestro diferencial es el DOMINIO (desarrollo) y la CONFIANZA (evidencia estructurada). De ellos robamos la capa SOCIAL/COORDINACIÓN, que es donde son más fuertes.

## 🎯 IDEAS ROBADAS (12, mapeadas a nuestro roadmap)

| # | Idea Grok Bot | Adaptación a Empresa Dev | Aterriza |
|---|---|---|---|
| G1 | **Group chat de bots que coordinan solos** | Chat GRUPAL de la empresa visible: PM, devs y QA conversan en vivo, pasan ownership, tú lees como espectador (o intervienes). Es la oficina animada PERO con diálogo real de trabajo | [N·N.4](./SDD-001-plan-base/plan-n-empresas-autonomas.md#n4) nueva sub-fase |
| G2 | **Chief of staff gestiona especialistas** | Refuerzo del patrón PM-líder: el PM NO ejecuta, delega, hace seguimiento y resume. Explícito en su skill | [N·N.2](./SDD-001-plan-base/plan-n-empresas-autonomas.md#n2) refuerzo |
| G3 | **Rutinas por demostración ("follow along")** | Modo GRABAR en Skills Lab: haces el trabajo una vez, el sistema observa pasos y propone un skill editable; aceptas correcciones y queda versionado | [G·G.6](./SDD-001-plan-base/plan-g-skills-lab.md#g6) nueva fase |
| G4 | **Rutinas programadas (cron de agentes)** | Tareas agendadas: "triage de bugs cada noche", "scoreboard lunes 9am" — el scheduler dispara empresas/skills sin humano | [N·N.6](./SDD-001-plan-base/plan-n-empresas-autonomas.md#n6) nueva fase |
| G5 | **Proactividad: retoma hilos, empuja handoffs estancados** | Watchdog existente ([I·I.2](./SDD-001-plan-base/plan-i-revision-superposiciones.md#i2)) + agente propone: "hay 2 PRs sin revisar 24h, ¿reviso?" — cola de sugerencias proativas aprobables | [I·I.6](./SDD-001-plan-base/plan-i-revision-superposiciones.md#i6) nueva fase |
| G6 | **Sabe cuándo molestar vs seguir** | Política de interrupción por severidad+confianza: bloqueos/aprobaciones interrumpen; progreso silencioso agrupa en digest. Configurable | [K·K.3](./SDD-001-plan-base/plan-k-voz.md#k3) refuerzo |
| G7 | **Aprende tu voz y estilo** | Memoria de preferencias ([D·D.2](./SDD-001-plan-base/plan-d-memoria-v3code.md#d2)): tono de commits/PRs/comentarios del usuario; los agentes redactan "en tu voz" | D·D.2 refuerzo |
| G8 | **Mismo hilo móvil/desktop** | Ya cubierto por [L](./SDD-001-plan-base/plan-l-sync-cowork.md) — validación de que el hilo continuo es el modelo correcto | ✓ confirmación |
| G9 | **Handoff entre bots con resumen** | Traspasos con resumen autogenerado obligatorio (ya auditado en rungs) + visible en el group chat | [N·N.2](./SDD-001-plan-base/plan-n-empresas-autonomas.md#n2) refuerzo |
| G10 | **Scoreboard semanal / digests** | Digest de empresa: qué hizo cada agente, costos, bloqueos — generado automáticamente (diario/semanal) al Drive/historial | [N·N.4](./SDD-001-plan-base/plan-n-empresas-autonomas.md#n4) refuerzo |
| G11 | **Computer propio por bot, pantalla propia** | Ya tenemos worktrees paralelos ([N·N.2](./SDD-001-plan-base/plan-n-empresas-autonomas.md#n2)) — confirmación de patrón; añadir vista "pantalla de cada agente" en dashboard (split-screen de actividades) | N·N.4 refuerzo |
| G12 | **Ejemplo estrella: bug→ticket→debugger bot** | Pipeline de bugs nativo: error detectado ([I](./SDD-001-plan-base/plan-i-revision-superposiciones.md#i1)) → crea tarea con repro → la asigna al agente correcto → entrega fix con test | [I·I.6](./SDD-001-plan-base/plan-i-revision-superposiciones.md#i6) incluido |

## ❌ Lo que NO copiamos (y por qué)

| Antipatrón Grok Bot | Razón |
|---|---|
| Cloud-only cerrado | Nosotros local-first: privacidad, costo cero de servidor, control total |
| Computer-use sobre apps ajenas como núcleo | Nuestro dominio es el REPO (archivos/tests/git) — más determinista y auditable que clickear pantallas |
| "Vuelve cuando terminó" sin evidencia estructurada | Nuestra apuesta: aprobación por evidencia (diffs+tests+rungs) genera MÁS confianza y es vendible enterprise |
| Computadora compartida por cuenta | Riesgo de contaminación entre bots; nuestros worktrees aíslan mejor |

## Impacto en el roadmap

- Etapa 9: +fase I.6 (proactividad + pipeline de bugs estilo G12/G5)
- Etapa G: +fase G.6 (rutinas por demostración — diferenciador fuerte)
- Etapa N: refuerzos N.2/N.4 + nuevas N.5b group-chat visible, N.6 rutinas programadas
- Estimación global ajustada: +1 semana total (las fases nuevas son UI/orquestación sobre mecanismos ya previstos)


## APÉNDICE — Extracción TOTAL de ideas Grok Bot (28, estado de integración)

| # | Idea Grok Bot | Estado en nuestro roadmap |
|---|---|---|
| 1 | Computadora propia persistente por bot | ✅ [H·H.9](./SDD-001-plan-base/plan-h-motor-pruebas.md#h9) LocalDriver + ContainerDriver Ubuntu |
| 2 | Group chat de bots que coordinan solos | ✅ N.6 |
| 3 | Chief of staff gestiona especialistas | ✅ N.2 reforzado |
| 4 | Rutinas por demostración (follow along) | ✅ G.6 |
| 5 | Rutinas programadas / cron | ✅ N.6 |
| 6 | Proactividad: retoma hilos, empuja handoffs | ✅ I.6 |
| 7 | Pipeline bug→ticket→debugger | ✅ I.6 |
| 8 | Sabe cuándo molestar vs seguir | ✅ K.3 política interrupción |
| 9 | Aprende tu voz y estilo | ✅ D.2 preferencias aplicadas a commits/PRs |
| 10 | Mismo hilo móvil/desktop | ✅ Etapa L (confirmación de modelo) |
| 11 | Handoffs entre bots con resumen | ✅ N.2 visible en group chat |
| 12 | Digests/scoreboards automáticos | ✅ N.6 digest + N.4 scoreboard |
| 13 | Pantalla propia por bot (split view) | ✅ N.4 split-screen en vivo |
| 14 | Curva "se afina contigo" medible | ✅ N.4 KPI aprendizaje por agente |
| 15 | Computer compartido por cuenta | 🔄 Adaptado: N.7 entorno compartido CON auditoría por acceso |
| 16 | Menos promptear, más delegar | ✅ A.7 Modo ENCARGO (resultado+plazo+autonomía) |
| 17 | Trabajo aterriza en tools reales, no drafts | ✅ Ya es nuestro core (commits/PRs reales) — principio reforzado |
| 18 | Conectores/MCP donde exista, computer-use el resto | 🔄 Escalera equivalente: MCP/tools primero ([PLAN P](./plan-p-centro-mcp.md)), terminal después |
| 19 | Solo te llama para judgment calls | ✅ K.3 + cola unificada A.4/I.4 |
| 20 | Zero-config onboarding: mensajéalo y ya | ✅ A.1 empty-states + wizard primer agente |
| 21 | Retomar trabajo de conversaciones viejas | ✅ A.8 resume inteligente al abrir |
| 22 | Negocia/en redacta EN TU VOZ | ✅ D.2 perfil de estilo → commits/PRs/comentarios |
| 23 | Jobs nocturnos overnight (research mientras duermes) | ✅ N.6 programadas (corren aunque cierres) |
| 24 | Asignación de ownership autónoma justificada | ✅ N.2 decisión de asignación replayable |
| 25 | Página central de aprobaciones/seguridad | ✅ Hub de aprobaciones A.4/I.4 unificado + A.6 settings |
| 26 | Apps desktop+iOS paridad | 📋 Backlog: Tauri mobile post-v1 (ADR-002) |
| 27 | Gating por suscripción/tiers | 📋 Backlog negocio: O.3 pricing tiers |
| 28 | Preocupación comunidad: control del usuario | ✅ Nuestro answer BY DESIGN: kill-switch + permisos granulares + local-first |

**Cobertura final: 24/28 integradas o reforzadas · 4 backlog consciente · 0 ignoradas**
