# PLAN H — Etapa 8: Motor de pruebas y resultados

> [← Maestro](./README.md) · [← PLAN G](./plan-g-skills-lab.md) · [PLAN I →](./plan-i-revision-superposiciones.md)
> Depende de: Etapas 6 (canva para mostrar resultados), 7 (skills definen el cómo). Inspiración: readiness checks de Reasonix (vistos en --metrics), SOP MetaGPT/ChatDev, "pruebas y evidencia" del AGENTS.md original.

**Entregable:** los agentes trabajan por RESULTADOS verificables — **Orden de construcción: H.1→H.2→H.5→H.6→H.3→H.4→H.7→H.8→H.9** (Shadow Workspace H.5/H.6 INMEDIATAMENTE tras el runner). Números = IDs estables. — cada tarea tiene criterios de aceptación que se prueban automáticamente y se muestran en el canva.

<a id="h1"></a>
### H.1 — Tareas con criterios
- Tabla `tasks`: criterios de aceptación estructurados (checklist verificable + tipo: test-exists / command-passes / file-contains / manual)
- Ciclo SOP: plan→implement→test→review→approve
- **Pruebas:** Cargo test ciclo estados. E2E humano: crear tarea con 3 criterios desde UI

<a id="h2"></a>
### H.2 — TestRunner sandbox
- Ejecuta comandos del proyecto activo en proceso aislado (cwd scoped, timeout, captura stdout/stderr/exit-code; red denegada por defecto estilo Codex sandbox)
- Comandos permitidos por allowlist editable (reglas allow/prompt/forbid de Codex)
- **Pruebas:** Cargo test runner: timeout kill, exit codes, allowlist enforcement. Integration con proyecto real (vitest interno)

<a id="h3"></a>
### H.3 — Resultados en el canva
- Al terminar tarea: rung TEST_RESULT ([D·D.1](./plan-d-memoria-v3code.md#d1)) + nodo-tarea muestra pass/fail/cobertura + diff asociado clicable ([B·B.4](./plan-b-sidepanels-lovable.md#b4))
- Aprobación humana basada en evidencia: ver diffs + tests → aprobar/rechazar con feedback
- **Pruebas:** E2E humano completo: agente mock "implementa X" → tests corren → verde en canva → apruebo → estado done

<a id="h4"></a>
### H.4 — Escalado inteligente
- Fallo de criterio 1ª vez → reintento mismo modelo ([C·C.2](./plan-c-reasonix-deepseek.md#c2)); fallo 2ª → escala a reasoner + notifica
- Readiness-check pre-entrega (estilo Reasonix): ¿tests? ¿verificación? ¿criterios completos? antes de marcar "lista para revisión"
- **Pruebas:** Unit router escalado. Integration: doble fallo simulado → escaló modelo y avisó

<a id="h5"></a>
### H.5 — Shadow Workspace (copia.md §Cursor/SWE-bench)
- Antes de mostrar un cambio al humano o marcar tarea "lista": el backend aplica el diff en una COPIA invisible en memoria del proyecto y pre-ejecuta en milisegundos los checks baratos (`tsgo --noEmit`, `biome check`, `cargo check` según stack detectado)
- El agente NUNCA entrega código que no compila: los errores vuelven a su scratchpad como feedback automático ANTES de la entrega visible
- Implementación: snapshot copy-on-write del workspace (hardlinks) + ejecución de checks + descarte de la copia; solo diffs limpios llegan al usuario
- **Pruebas:** Cargo test shadow-run: diff con error de tipos → rechazado y retornado al agente; diff limpio → pasa. Perf: ciclo completo <3s en proyecto mediano

<a id="h6"></a>
### H.6 — Bucle de auto-corrección silencioso (copia.md §Capa 1)
- Shadow Workspace + escalado ([H·H.4](./plan-h-motor-pruebas.md#h4)) forman bucle: fallo de check → feedback al scratchpad del agente → reintenta → máx 3 ciclos internos ANTES de gastar un ciclo visible de escalado
- Cada ciclo interno queda en el Ledger como rung `SELF_FIX` (auditable, no molesta al humano)
- Auto-purga: logs verbosos de los ciclos se descartan; solo el rung resumen sobrevive (copia.md §auto-purgado)
- **Pruebas:** Integration scripted: agente introduce error → 2 ciclos SELF_FIX invisibles → entrega limpia → Ledger muestra los rungs, el chat NO muestra ruido

<a id="h9"></a>
### H.9 — Computadora persistente del agente (patrón Grok Bot, local-first)
- Abstracción `AgentComputer` con DOS drivers:
  - **LocalDriver** (default v1): workspace + worktree + procesos sandbox ya existentes — cero requisitos extra
  - **ContainerDriver**: contenedor **Ubuntu persistente por agente** (Docker local o en tu servidor): filesystem que sobrevive entre sesiones, terminal accesible desde la UI, navegador headless disponible, snapshots/restores del estado completo de la máquina
- La máquina del agente es SU oficina: instala dependencias, deja servicios corriendo, retoma el entorno tal cual lo dejó (persistencia real estilo Grok Bot pero en TU infraestructura, no en la nube ajena)
- Snapshots manuales + automáticos pre-tarea peligrosa; reset limpio con un click; límites CPU/RAM/disco configurables ([C6](./plan-a-chat-codex.md#a4) hereda permisos)
- Terminal visible en panel ([A·A.4](./plan-a-chat-codex.md#a4)) conectada a LA máquina de ese agente
- **Respaldos del estado del agente POR ROL** (SDD-006 §4): frecuencia y retención configurables por scope ([A·A.6](./plan-a-chat-codex.md#a6)) — default estilo Claude Code (automáticos, conserva últimos 5); snapshot = estado COMPLETO (archivos+memoria) pero restauración exige replay-or-fork explícito con registro de efectos externos ya ocurridos (anti semantic-rollback ACRFence); golden snapshot de empresa heredable ([N·N.7](./plan-n-empresas-autonomas.md#n7)) con aprobación humana para actualizarlo
- **Pruebas:** Cargo test drivers tras trait común. Integration: container crea archivo → reinicia sesión → archivo sigue ahí; snapshot→restore exacto. Chaos: matar container → recrear desde snapshot. E2E humano: abre terminal del agente, trabaja, cierra app, vuelve y su entorno sigue intacto

<a id="h7"></a>
### H.7 — Best-of-N: votación entre soluciones (ganadora torneo #213, patrón Devin)
- Para tareas críticas: el orquestador lanza N ejecuciones (2-3) con semillas/enfoques distintos → cada una produce su solución + evidencia → scoring automático por criterios ([H·H.1](./plan-h-motor-pruebas.md#h1)) + review ([I·I.1](./plan-i-revision-superposiciones.md#i1))
- El humano elige entre candidatas presentadas lado-a-lado con sus scores; la no-elegida archiva como alternativa consultable
- **Pruebas:** Integration scripted: 3 candidatas mock → scores correctos → elegida la mejor. E2E humano: vista comparativa lado-a-lado funcional

<a id="h8"></a>
### H.8 — Cuarentena de tests flaky (ganadora torneo #253)
- Detector estadístico: test que falla intermitentemente sin cambio de código (N pasadas/fallos alternados) → marcado flaky → movido a cuarentena automáticamente (no bloquea gates)
- Re-verificación programática periódica: si pasa M veces seguidas sale de cuarentena; si confirma inestabilidad, ticket para el agente QA con repro mínimo
- **Pruebas:** Unit detector con historial sintético. Integration: test inestable simulado entra/sale de cuarentena correctamente; gate ignora cuarentenados

## 🚪 GATE H (demo verificable)

Tarea real end-to-end: "agrega botón de exportar CSV al panel" con criterios (`existe test del export`, `comando vitest pasa`) → el agente implementa en su flujo → TestRunner ejecuta → canva muestra ✓✓ → reviso diff clicable → apruebo → done persistido. Todo demostrado en video con suite humana verde.

---
[← Maestro](./README.md) · [← PLAN G](./plan-g-skills-lab.md) · [PLAN I →](./plan-i-revision-superposiciones.md)
