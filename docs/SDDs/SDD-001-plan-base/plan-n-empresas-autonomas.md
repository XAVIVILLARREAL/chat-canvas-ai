# PLAN N — Etapa 14: Empresas autónomas multiagente

> [← Maestro](./README.md) · [← PLAN M](./plan-m-github.md) · [PLAN O →](./plan-o-marketplace-v1.md)
> Depende de: TODO lo anterior. Es el gran objetivo de la visión original: "crear empresas de desarrollo completas usando agentes".

**Entregable:** armas una empresa completa — equipo de agentes con roles (PM, arquitecto, dev, QA, reviewer, devops), jerarquía líder→operativos, presupuesto y kill-switch — que ejecuta proyectos por sí sola reportando evidencia.

<a id="n1"></a>
### N.1 — Modelo de empresa
- Tablas `companies`, `company_members` (agente+rol+skill), `budgets` (límite $/día por empresa y por agente)
- UI asistente "Nueva empresa": plantilla (web-app, api, script) → roles sugeridos → skills del Lab ([G](./plan-g-skills-lab.md)) asignados con su tool-gating ([G·G.2](./plan-g-skills-lab.md#g2))
- **Avatar + personalidad generada por IA** por cada nuevo miembro (imagen, nombre coherente, mini-bio) — identidad inmediata sin configurar nada
- **Pruebas:** Cargo test modelo + presupuesto enforcement (rechaza gasto over-budget). E2E humano: crear empresa completa desde cero

<a id="n2"></a>
### N.2 — Jerarquía líder→operativos + worktrees paralelos
- Agente PM = líder: recibe objetivo → descompone en tareas ([H·H.1](./plan-h-motor-pruebas.md#h1)) → asigna a operativos según skill/rol → operativos ejecutan con providers ([C](./plan-c-reasonix-deepseek.md#c1)); subagentes reasonix reales (explore/research) como herramientas del líder; todo traspaso es rung auditado
- **Worktrees git paralelos** (patrón Codex/Cursor): cada operativo trabaja en SU worktree aislado del mismo repo — cero choques entre agentes paralelos; merge asistido al entregar ([M·M.2](./plan-m-github.md#m2))
- Artefactos tipados fluyendo por la línea SOP (copia.md §MetaGPT): PRD→diseño→contratos→código→reporte de tests — visibles como paquetes viajando en los edges del canva ([F·F.3](./plan-f-canva-oficina.md#f3))
- **Pruebas:** Integration scripted: objetivo simple → PM crea 3 tareas → 2 operativos en paralelo (worktrees distintos) completan → merges limpios → auditoría completa en event_stream

<a id="n3"></a>
### N.3 — Presupuesto + kill-switch
- Contador de costo por empresa/agente en vivo (--metrics [C·C.2](./plan-c-reasonix-deepseek.md#c2)); al 80% aviso, al 100% pausa automática con aprobación requerida; kill-switch global y por agente (detiene tareas en curso vía task stop)
- **Pruebas:** Integration: budget simulado pequeño → pausa al llegar; kill-switch detiene todo <2s sin corrupción

<a id="n4"></a>
### N.4 — Dashboard de empresa
- Vista canva de toda la empresa (organigrama sobre [PLAN F](./plan-f-canva-oficina.md)): nodos jerárquicos, flujo de artefactos entre roles, KPIs vivos (tareas done/fallidas, costo, tiempo, escaladas [H·H.4](./plan-h-motor-pruebas.md#h4), revisiones [I·I.1](./plan-i-revision-superposiciones.md#i1)), timeline replay del Ledger
- **Split-screen "pantalla de cada agente"**: ver EN VIVO qué está haciendo cada operativo (su terminal/archivos), estilo computadora-propia de Grok Bot
- **Curva de mejora por agente**: KPI de aprendizaje ("Dev-A mejoró 30% su tasa primera-pass contigo") — los compañeros se afinan con el uso
- **Pruebas:** E2E humano: navegar dashboard, filtrar por rol/agente, replay scrubber de un proyecto completo

<a id="n5"></a>
### N.5 — Proyecto demo end-to-end real
- La prueba de fuego: empresa 3-agentes (PM flash + dev flash + QA reasoner) construye una mini-app real dentro del workspace, con tests verdes, revisada ([I·I.1](./plan-i-revision-superposiciones.md#i1)), commiteada a GitHub local — humana solo aprueba hitos
- **Pruebas:** E2E largo REAL con DeepSeek: objetivo "todo-list app con tests" entregado; video completo

<a id="n6"></a>
### N.6 — Group chat de la empresa + rutinas programadas (patrón Grok Bot)
- **Group chat visible**: PM, devs y QA conversan en un hilo compartido — pasan ownership, piden contexto, resuelven dudas entre ellos; el humano LEE el trabajo social en vivo e interviene solo en judgment calls (ellos se coordinan solos)
- **Identidad viva estilo mensajería**: avatar único POR AGENTE generado por IA, presencia (🟢 trabaja · 💤 idle), "Dev-A está escribiendo…", mensajes agrupados como persona hablando — el equipo SE SIENTE equipo (promueve idea 210 del torneo)
- **Rutinas programadas**: scheduler de trabajos recurrentes por empresa ("triage de bugs cada noche", "scoreboard lunes 9am") disparando skills/empresas sin humano presente
- **Digest automático** diario/semanal: qué hizo cada agente, costos, bloqueos, próximos pasos — generado del Ledger y archivado
- **Pruebas:** Integration: 3 agentes en group chat resuelven handoff sin humano (scripted). E2E humano: observo la conversación grupal en vivo; programo rutina nocturna y verifico ejecución + digest matutino

<a id="n7"></a>
### N.7 — Entorno compartido de empresa (adaptación del "computer compartido" de Grok Bot)
- La empresa tiene UN entorno compartido controlado: credenciales/servicios/secretos de la empresa disponibles a sus agentes CON auditoría y scopes por rol ([G·G.2](./plan-g-skills-lab.md#g2)) — a diferencia de Grok Bot (todo compartido), aquí cada acceso es rung auditado
- Los worktrees siguen aislando el CÓDIGO; el entorno compartido provee servicios comunes (registry, staging DB, deploy keys)
- **Pruebas:** Cargo test: acceso sin scope rechazado+auditado; con scope permitido+registrado

## 🚪 GATE N (el gate histórico)

**La primera empresa autónoma entrega software real de principio a fin:** objetivo hablado/escrito → PM planifica → devs implementan en worktrees paralelos → QA prueba → reviewer revisa → humano aprueba hitos con evidencia → código en git con PR. Presupuesto respetado. Auditoría completa reproducible (replay). Video documental + todas las suites humanas históricas en verde.

---
[← Maestro](./README.md) · [← PLAN M](./plan-m-github.md) · [PLAN O →](./plan-o-marketplace-v1.md)
