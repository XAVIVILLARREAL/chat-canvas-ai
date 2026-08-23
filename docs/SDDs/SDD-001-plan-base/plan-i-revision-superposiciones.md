# PLAN I — Etapa 9: Revisión automática + Superposiciones de agentes

> [← Maestro](./README.md) · [← PLAN H](./plan-h-motor-pruebas.md) · [PLAN J →](./plan-j-grafo3d-repomap.md)
> Depende de: Etapas 3 (subagentes reasonix verificados: review, security-review, explore), 8 (ciclo de tareas).

**Entregable:** el sistema detecta errores automáticamente y los asigna al agente correcto; cuando un agente falla o se bloquea, otro lo superpone y toma control. (Visión original items 8-9.)

<a id="i1"></a>
### I.1 — Review integrado
- Al aprobar tarea ([H·H.3](./plan-h-motor-pruebas.md#h3)) → corre `reasonix review` (subagente read-only real del servidor) sobre el diff → veredicto + issues file:line en card del chat + rung REVIEW en ledger
- Security-review opcional para cambios sensibles (auth/, crypto/)
- **Pruebas:** Integration con reasonix real: diff con bug plantado → review lo señala. Parser de salida

<a id="i2"></a>
### I.2 — Detector de estancamiento
- Watchdog por agente: sin progreso N minutos / tool-failures seguidas / criterio fallido 2+ veces → estado "blocked" visible en canva + notificación sonora/visual
- **Pruebas:** Unit watchdog timers. E2E: mock provider colgado → badge blocked + alerta

<a id="i3"></a>
### I.3 — Superposición (takeover)
- Agente suplente (mismo skill, perfil fresh) recibe: contexto del Ledger hasta el fallo ([D](./plan-d-memoria-v3code.md#d1)) + diagnóstico del watchdog → continúa la tarea
- La original queda marcada "superada por"; auditoría completa del traspaso en event_stream
- **Pruebas:** Integration scripted: primer provider falla a mitad → segundo retoma desde rungs → completa

<a id="i4"></a>
### I.4 — Approvals reviewer agéntico (patrón Codex auto_review)
- Cuando la cola de aprobaciones crece ([A·A.4](./plan-a-chat-codex.md#a4)), un agente revisor PRE-analiza cada petición elegible (escalaciones de sandbox, tools con side-effects) y adjunta recomendación + riesgo
- El humano SIEMPRE decide — el reviewer solo acelera: badge verde "revisado ✓ sin riesgos" vs amarillo con razones
- Reglas allow/prompt/forbid por prefijo de comando (Codex granular): lo ya permitido ni pasa por revisión
- **Pruebas:** Integration: 10 aprobaciones simuladas → reviewer recomienda correctamente las 2 peligrosas. E2E humano: cola con badges de pre-revisión

<a id="i5"></a>
### I.5 — Reflect: aprender de sesiones pasadas (patrón codevira, sin LLM para detectar)
- Job periódico lee trajectories históricas ([D·D.1](./plan-d-memoria-v3code.md#d1)) detectando patrones SIN modelo: correcciones humanas repetidas al mismo agente, tareas re-trabajadas 2+, criterios que siempre fallan a la primera
- Output: propuestas de lección ("QA siempre rechaza X → añadir criterio temprano") que entran a la cola de gobernanza [D·D.4](./plan-d-memoria-v3code.md#d4) — el humano acepta o descarta
- Cierre del ciclo SRE: el sistema mejora sus propios procesos con evidencia, no corazonadas
- **Pruebas:** Integration con corpus sintético: 3 correcciones plantadas → propuesta generada una sola vez (dedup). E2E: propuesta visible, acepto, aparece como knowledge activo

<a id="i6"></a>
### I.6 — Proactividad + pipeline de bugs (patrón Grok Bot)
- **Cola de sugerencias proativas** aprobables: "2 PRs sin revisar 24h, ¿los reviso?", "tests de main rotos desde ayer", "dependencia con CVE" — el agente DETECTA y PROPONE, el humano decide (gobernanza)
- **Pipeline de bugs estilo Grok Bot**: error detectado (review/watchdog/consola) → crea tarea con pasos de reproducción → asigna al agente correcto por skill → fix entregado con test que fallaba/ahora pasa
- Política de interrupción: bloqueos/aprobaciones interrumpen; progreso normal se agrupa en digest silencioso
- **Pruebas:** Integration: bug plantado en fixture → tarea creada con repro correcta y asignada. E2E humano: sugerencia proativa visible → acepto → pipeline ejecuta completo

## 🚪 GATE I (demo verificable)

Demo 1: tarea aprobada con bug escondido → review automático lo marca con file:line antes del merge humano. Demo 2: mato el proveedor a mitad de tarea → watchdog declara blocked → suplente toma control usando memoria del Ledger → entrega. Video + suites humanas.

---
[← Maestro](./README.md) · [← PLAN H](./plan-h-motor-pruebas.md) · [PLAN J →](./plan-j-grafo3d-repomap.md)
