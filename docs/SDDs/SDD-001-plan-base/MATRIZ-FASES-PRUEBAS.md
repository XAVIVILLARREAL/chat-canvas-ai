# MATRIZ COMPLETA — Todas las fases del Plan Base y sus pruebas

> Generada de los planes (fuente de verdad). **Regenerar en CADA cambio de fases** (regla de ejecución #10 del [README](./README.md)).
> Orden = ORDEN DE EJECUCIÓN maestro (no alfabético): así la matriz es también el checklist de construcción.
> Capas por fase: **[U]**nit vitest · **[I]**ntegración cargo/mock · **[E]**2E Playwright · **[H]**umana suite modo persona.
> **Reglas duras**: fase GUI ⇒ **[E]+[H] obligatorias** · **COBERTURA GUI 100%**: todo botón/función/feature con su prueba humana (tabla [COVERAGE-GUI](../../COVERAGE-GUI.md)) — fase GUI sin sus filas ✅ = incompleta · **toda fase GUI se prueba en móvil 375px + desktop 1440px** (suite humana `responsive-human.spec.ts` en cada gate — no hay pantalla "solo desktop") · **cómputo client-first**: todo lo que pueda correr en el cliente va al cliente (server = datos, no CPU de usuarios) · **toda UI usa los tokens de [SDD-013](../SDD-013-gui-visual-spec.md) (Obsidian Glass + Liquid Glass, escalera §8 hacia VR)** — CSS improvisado prohibido, checklist §7 auditado en F.5, `pnpm test:visual` bloquea deuda nueva · **cada fase es manejable por prompt (slices si excede ~1 sesión IA)** · **criterios de negocio 1:1 con sus pruebas + E2E transversal por etapa en cada gate** · fase sin fila aquí NO se construye · presupuesto de pruebas: **free-first** — tests REALES con provider gratuito (OpenRouter `:free`, p.ej. **ox-alpha free**) a $0; APIs de pago solo si la fase exige capacidades específicas y **máx $20/gate** (resto mock-first) · evidencia de gate = video + `evidence/` · **i18n multilenguaje desde el día 1** ([plan-i18n](./plan-i18n.md)) · **eventos de producto al `event_stream` desde v0** ([PRODUCT-METRICS](../../PRODUCT-METRICS.md)) · **[PRD](../../PRD.md) como fuente de "qué construir"** (features→resultado humano) · **loop agéntico por fase** (5 sub-agentes en paralelo + iteración, [WORKFLOW-AGENTICO](../../WORKFLOW-AGENTICO.md)).
> **Docs operativos que rigen fases (consultar al tocar):** [AUTH](../../AUTH.md) (auth local/nube) · [API](../../API.md) (inventario REST) · [DATA-LIFECYCLE](../../DATA-LIFECYCLE.md) (migraciones/GDPR) · [FEATURE-FLAGS](../../FEATURE-FLAGS.md) (tiers/dark-launch) · [UX-STANDARDS](../../UX-STANDARDS.md) (atajos/estados UI) · [THREAT-MODEL](../../THREAT-MODEL.md) (seguridad) · [SLO-RELIABILITY](../../SLO-RELIABILITY.md) (objetivos) · [PERFORMANCE-BUDGETS](../../PERFORMANCE-BUDGETS.md) (perf) · orden de construcción: [EJECUCION-ORDEN](../../EJECUCION-ORDEN.md).
> **Tarjeta de Fase obligatoria en el DoR** ([SDD-002](../SDD-002-testing-spec-driven.md)): al iniciar una fase se llena su tarjeta — resultado esperado observable, pruebas por capa [U/I/E/H], gate, riesgos y estimación. Ejemplos vigentes: [TARJETAS-ETAPA-0](../../TARJETAS-ETAPA-0.md).

## Etapa 0 · Fundación (schema maestro + eventos + secretos) — `SCHEMA-MAESTRO.md` + `THREAT-MODEL.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| 0.1 | Schema maestro + migraciones ✅ 2026-08-27 | Cargo test repos en SQLite y Postgres; migración idempotente up/down/up; `project_id` en toda tabla ([SCHEMA-MAESTRO](../../SCHEMA-MAESTRO.md)) — **SQLite + Postgres verdes**: migraciones por dialecto (`migrations/{sqlite,postgres}/`), 0001 (11 tablas) + 0002_workspace + up/down/up idempotente en AMBOS · repos CRUD · server wired ([ADR-007](../../ADRs/ADR-007-mapping-dominio-sqlite.md)) · commits `ad46ac8`, `aaf4486` |
| 0.2 | Contrato `event_stream` (ledger) | Trigger append-only rechaza UPDATE/DELETE; seed project→session→message→rung; taxonomía completa ([PRODUCT-METRICS](../../PRODUCT-METRICS.md)) |
| 0.3 | Secretos BYOK + vault | Key cifrada/descifrable con la correcta; nunca en claro al webview ([THREAT-MODEL](../../THREAT-MODEL.md)) |
| 0.4 | Frontera del sandbox Linux | Contrato de contenedor: límites CPU/RAM/disco/timeout, red off, mounts read-only ([THREAT-MODEL](../../THREAT-MODEL.md)) |
| 0.5 | OpenAPI del gateway | Tipos specta→OpenAPI generado sin errores; frontend consumible |
| 0.6 | i18n infraestructura | Unit hook `useI18n` + snapshot diccionario; fallback a `en` ([plan-i18n](./plan-i18n.md)) |

## Etapa 1 · Chat núcleo + proyectos como scope — `plan-a-chat-codex.md` (ADR-006)
| Fase | Nombre | Pruebas |
|---|---|---|
| A.0 | Proyectos como SCOPE (FUNDACIÓN) | Unit: repos filtran por project_id; scopes global→proyecto. Integration: cross-proyecto vacío; override local no muta global; tabs restauran tras reinicio. E2E: 2 proyectos alternando tabs, skill global vs copia local. HUMANA @core: entrar por card, cambiar tab, nada se mezcla |
| A.1 | AppShell + stores | Vitest stores+hook. E2E: layout mobile 375px (BottomNav) y desktop 1440px (sidebar) |
| A.2 | Persistencia SQLite (settings CIFRADA) | Cargo test repositorios. Integration: roundtrip mensaje con project_id |
| A.3 | Trait AgentProvider + DeepSeekDirect | Unit con mock-server SSE. Integration: orden de chunks |
| A.4 | UX Codex (2 perillas, tool-calls, diff, slash) | E2E browser-mode con provider MOCK scriptado: prompt→streaming→tool-call→aprobar→diff visible→/fork duplica sesión. HUMANA (Gate A): cambiar perilla cambia comportamiento observado |
| A.4b | Cola de mensajes durante streaming (F37) | E2E HUMANA: escribo 2 mensajes mientras el agente responde → cola visible/editable/reordenable → auto-envío FIFO al quedar libre; pausa de cola funciona; error en envío → cola se pausa para revisión |
| A.12 | Presencia e indicadores en vivo + reacciones (F39/F40) | E2E: agente trabajando → indicador typing/working <1s tras evento; reacción 👍/❌ sobre mensaje → rung en event_stream; 2 humanos en la sesión → presencia de ambos visible |
| A.5 | Medidor y debug de contexto (torneo) | Unit: desglose de tokens por fuente con fixtures. Integration: request capturado = lo que muestra el medidor. E2E HUMANA: abrir medidor en sesión real; ajustar límite → siguiente request lo refleja |
| A.6 | Centro de Configuración (2 públicos, 5 scopes) | Unit store settings + herencia global/proyecto. E2E HUMANA: no-programador cambia ajuste con clicks; programador edita JSON validado; override por proyecto visible |
| A.7 | Modo ENCARGO (v1: tarea mínima; H.1 formaliza) | E2E HUMANA: crear encargo sin escribir prompt; agente mock lo completa; notificación de vuelta con evidencia |
| A.8 | Resume inteligente (v1 sin rungs; D.1 enriquece) | Integration: sesión interrumpida → resume card correcta. E2E HUMANA: cerrar a mitad → reabrir → continuar fluido |
| A.9 | Ramas visuales al editar (‹2/3›) | Unit tree-store. E2E HUMANA: edito mensaje 2× → flechas ‹› navegan alternativas sin perder ninguna |
| A.10 | Comparador A/B de modelos ([FEATURE-BACKLOG](../../FEATURE-BACKLOG.md) F19) | E2E HUMANA: mismo prompt a 2 modelos lado a lado → elijo ganadora → rung DECISION guarda preferencia y el router la aprende |
| A.0b | Importar historial ChatGPT/Claude (F25) | E2E HUMANA: importo JSON exportado de ChatGPT → sesiones reconstruidas con fechas/roles correctos; JSON corrupto → error accionable sin perder nada |
| A.2b | Papelera + restaurar (F26) | E2E HUMANA: elimino sesión/skill → aparece en papelera → restauro intacto; vaciar papelera pide confirmación |
| A.7b | Forecast de costo pre-envío (F24) | Unit: estimación tokens×precio del modelo. E2E HUMANA: antes de Enter veo "≈ tokens ≈ $" y coincide ±20% con el costo real del mensaje |
| A.11 | Export sesión a PDF/Markdown (F28) | E2E HUMANA: exporto sesión → reporte con rungs + resultado final legible y compartible |

## Etapa 2 · Sidepanels Lovable — `plan-b-sidepanels-lovable.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| B.1 | Workspace virtual + detección Codex | Cargo test seguridad paths (anti path-traversal). E2E: árbol refleja archivos creados por el agente |
| B.2 | Editor Monaco | E2E: abrir archivo escrito por agente, editarlo, persistir |
| B.3 | Live Preview | Unit debounce watcher. E2E: agente escribe HTML → preview actualizado <2s |
| B.4 | Sincronización chat ↔ paneles | E2E flujo integrado completo |
| B.5 | Fast Apply (feature-flag + chaos-test) | Cargo test aplicador: 500 deltas/sec sintéticos sin pérdida ni desorden. E2E HUMANA: archivo grande escribiéndose fluido en vivo |
| B.6 | @menciones archivos (símbolos cuando exista J.1) | E2E HUMANA: `@` filtra <100ms, flechas navegan, Enter inserta chip; chip llega como ruta anclada |
| B.7 | Revisión por HUNKS | E2E HUMANA: diff de 3 hunks → aprueba 2, rechaza 1 con nota → solo aprobados se aplican; rechazo citado en el siguiente turno |
| B.8 | Consola → "enviar error al agente" | E2E: mock TypeError en preview → badge → click envía contexto completo → respuesta corrige y error desaparece |
| B.9 | Artefactos versionados (‹v2/v5›) | Integration versionado por escritura relevante. E2E HUMANA: navegar 3 versiones, comparar side-by-side, restaurar antigua |
| B.10 | **LSP integration**: diagnósticos reales al contexto del agente ([MERCADO-ANALISIS](../../MERCADO-ANALISIS.md) F34) | Integration: error de tipos real (tsc/rustc vía LSP) llega al agente sin que el humano lo pegue; agente corrige → diagnóstico desaparece; LSP caído → degradación limpia |

## Etapa P · Centro MCP — `plan-p-centro-mcp.md` (tras Gate B, en paralelo con C/D)
| Fase | Nombre | Pruebas |
|---|---|---|
| P.1 | Cliente MCP core (Rust) | Cargo test contra fixture-server MCP stdio local: list/call/stream; timeout + kill limpio |
| P.2 | Centro MCP visual (doble público) | E2E HUMANA dual: (a) no-programador conecta server popular solo con clicks y entiende errores; (b) programador pega JSON complejo → validación inmediata |
| P.3 | Seguridad y control de llamadas externas | Cargo test enforcement scopes + rate limit. Chaos: server que devuelve basura → circuit breaker aísla sin tumbar agentes |
| P.4 | Plantillas 1-click y descubrimiento | Unit schema plantilla. E2E HUMANA: instalar "GitHub" desde cero hasta primer tool-call exitoso <5 min sin leer docs |

## Etapa 3 · Runtime Reasonix+DeepSeek+Ollama+API — `plan-c-reasonix-deepseek.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| C.0 | Residual del spike | Fixtures versionados; script humo curl documentado |
| C.1 | ReasonixProvider | Cargo test parser con fixtures reales de C.0 |
| C.2 | Enrutamiento por costo + telemetría | Unit router + cálculo costos. E2E: badge costo sube durante sesión real barata |
| C.3 | Robustez | Chaos integration: kill -9 → recuperación automática; estado consistente post-cancel |
| H.9a | Aislamiento contenedor mínimo (plan-h, se ejecuta AQUÍ) | Cargo test: spawn/kill/timeout con fixture. Chaos: matar contenedor a mitad → agente se recupera en uno nuevo con estado consistente; red denegada por defecto verificada |
| C.5 | Motor Contexto/Caché configurable (SDD-006 §1) | Unit hash/orden estable. Integration DeepSeek real: cache_hit>90% post warm-up; cambio de knob → aviso de caché fría. E2E HUMANA: aplicar preset de rol en un click |
| C.6 | OllamaProvider local (ready-to-plug) | Unit: detección/parsing /api/tags + errores conexión. Integration Ollama real: chat streaming + embeddings; preset KV verificado por memoria consumida. E2E HUMANA: conectar Ollama desde cero con la guía in-app |
| C.7 | Registro universal de proveedores (v1; OAuth/small_model → C.7b post-base) | Unit: parser/validador registro, merge catálogo, blacklist/whitelist, small_model routing. Integration: 3 proveedores REALES vía el mismo trait (streaming + precios correctos); OAuth device-flow mockeado. E2E: agregar proveedor desde JSON; selector muestra precio/contexto. HUMANA @core-ampliada: no-programador conecta OpenRouter pegando key <2 min y elige modelo viendo precio; whitelist esconde modelos |
| C.8 | Tools web nativas: web_search + web_fetch ([FEATURE-BACKLOG](../../FEATURE-BACKLOG.md) F17) | Unit: parser + caché LRU + allowlist enforcement. Integration: fetch a fixture local; chaos: dominio bloqueado → error accionable. E2E HUMANA: "investiga X" → respuesta cita 2+ fuentes con links |
| C.9 | Visión multimodal: imágenes/PDF ([FEATURE-BACKLOG](../../FEATURE-BACKLOG.md) F18) | Integration real: screenshot con bug plantado → agente lo corrige en código; PDF → extracción correcta; fallback claro si el provider no soporta visión |
| C.10 | **Browser automation del agente** ([MERCADO-ANALISIS](../../MERCADO-ANALISIS.md) F33) | Integration: agente navega fixture local, click, screenshot → describe lo que ve; sandbox: red SOLO a dominios allowlisted; chaos: sitio caído → error accionable. E2E HUMANA: "entra al staging y dime qué está roto" → reporta con captura |
| C.11 | **Hooks de ciclo de vida del usuario** (F38, patrón Claude Code): PreToolUse/PostToolUse/Stop | Cargo test: PreToolUse bloquea comando `rm -rf` (exit non-zero → bloqueado ANTES de ejecutar); PostToolUse formatea archivo editado; Stop no libera hasta tests verdes; hook malicioso → aislado en sandbox, sin credenciales. E2E HUMANA: configuro hook format-on-save en 1 pantalla |

## Etapa 4 · Memoria V3Code — `plan-d-memoria-v3code.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| D.0 | Restaurar artefactos de referencia | Criterio manual: archivos presentes en `reference/v3code/` local |
| D.1 | Capa 1: Decision Ledger | Cargo test append-only (UPDATE/DELETE rechazados por trigger). Integration: rung al finalizar |
| D.2 | Capa 2: Workspace Knowledge + Lock | Cargo test FTS ranking + invariantes presentes en contexto capturado |
| D.3 | Capa 3: Memory Rail UI + inyección | E2E componentes rail/scrubber. Integration: request capturado por mock contiene contexto esperado |
| D.4 | Gobernanza de decisiones (varve) | Cargo test ciclo estados + enforcement de scope. E2E HUMANA: agente propone → acepto con evidencia → otra tarea toca archivo gobernado → aviso de decisión activa |
| D.5 | Índice semántico dual local (**client-first: wa-sqlite OPFS + sqlite-vec WASM**) | Integration: consulta ("cómo manejamos auth") retorna la decisión correcta sin palabras compartidas; indexado incremental <100ms/archivo. E2E: búsqueda local en el navegador sin servidor. (v1 FTS5; KNN cuando existan Ollama/J.1 — fail-open) |
| D.6 | Memory Router + shards + checkpoints | Unit aging policy. Integration: prompt de auth carga SOLO shard auth (request capturado). E2E checkpoint: rebobinar a turno N restaura archivos exactos |
| D.7 | Blame-rung: "por qué existe esto" (torneo) | Unit: mapping diff→decisión con fixture. Integration: commit de agente → blame muestra decisión aceptada correcta. E2E HUMANA: clic en línea de código → cadena completa navegable |
| D.8 | Memorias multi-tipo (v1: working/episódica/semántica; relacional+reflexión → D.8b) | Unit decay/scoring con fixtures. Integration: contradicción invalida sin borrar; consolidación idempotente. E2E HUMANA: ajustar λ de un tipo → ranking cambia; leakage test entre proyectos |

## Etapa 5 · Cierre Base — `plan-e-integracion-total.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| E.1 | E2E punta a punta REAL (provider **free** OpenRouter ox-alpha, $0 — o DeepSeek ≤$20 si exige capacidades) | Playwright browser-mode completo + video evidencia en `evidence/` |
| E.2 | Chaos / robustez transversal | Suite chaos automatizada, 6/6 recuperaciones verificadas |
| E.3 | Pulido responsive + performance + cierre | Suite humana completa re-corrida + perf budgets + knip + contraste AA + docs al día |

## Etapa 6 · Canva Oficina — `plan-f-canva-oficina.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| F.0 | Design System core "Obsidian Glass" + capa de experiencia ([SDD-013](../SDD-013-gui-visual-spec.md) canónico) | Vitest tokens/primitivas (oklch de SDD-013 §1). E2E HUMANA: contraste AA automatizado contra la paleta §1.1; toast deshace acción destructiva; status bar refleja modelo/coste reales; checklist SDD-013 §7 |
| F.1 | Fundaciones ReactFlow | E2E HUMANA: arrastrar nodo, conectar dos nodos, zoom con rueda y pinch |
| F.2 | Nodos-agente vivos (datos reales) | E2E: crear agente en chat → nodo aparece; mock provider working → badge cambia |
| F.3 | Edges semánticos + Animated Beams | Unit mapping evento→edge. Visual gate con screenshots/video |
| F.4 | Tareas y Kanban sobre el canva | E2E HUMANA: drag tarea todo→doing→done; persistencia verificada tras reinicio |
| F.7 | Command Palette global ⌘K (torneo) | E2E HUMANA: ⌘K→3 letras→Enter ejecuta acción correcta; paleta lista proyectos/agentes/comandos; hotkey personalizada persiste |
| F.5 | Identidad visual dirigida por IA | Suite humana completa re-corrida + checklist RESPONSIVE.md + contraste automatizado básico |
| F.6 | Performance del canva (**WebGPU renderer, 100% cliente**) | Benchmark programático: 100 nodos + 150 edges @60fps (WebGPU; WebGL fallback); suite humana sin jank percibido |

## Etapa 7 · Skills Lab — `plan-g-skills-lab.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| G.1 | Modelo de datos + CRUD | Cargo test repos. E2E HUMANA: crear/editar/duplicar/eliminar skill desde cero |
| G.1b | Perfiles BYOK trabajo/personal (F27) | E2E HUMANA: creo 2 perfiles con keys distintas → cambio perfil en un proyecto → providers/keys conmutan; el proyecto recuerda su perfil |
| G.2 | Editor visual + Tool-Gating | Unit validación + enforcement de gating (agente QA no invoca write). E2E HUMANA: crear skill completo solo con clicks y tecleo |
| G.3 | Compilador a dialectos | Cargo test snapshot por dialecto. Roundtrip: compilar→ejecutar en reasonix real→respuesta esperada |
| G.3b | **Importar rules files del mercado** ([MERCADO-ANALISIS](../../MERCADO-ANALISIS.md) F35): `.cursorrules`/`.clinerules`/`CLAUDE.md`/`.windsurfrules` → skill | E2E HUMANA: pego un CLAUDE.md real → skill importado válido (frontmatter generado) → funciona igual que uno nativo; archivo inválido → error accionable |
| G.4 | Laboratorio sandbox | E2E: probar skill real con DeepSeek barato; costo del ensayo visible; resultado persistido |
| G.6 | Rutinas por demostración "follow along" | Integration: sesión grabada de N pasos → skill propuesto con N pasos correctos; corrección humana se persiste. E2E HUMANA: grabo "preparar release" → skill creado → lo ejecuto programado |
| G.7 | Identidad viva de Skills/Agentes (Gems) | E2E HUMANA completo: crear skill → 3 avatares generados → ceremonia de nacimiento → personaje en Oficina/Sesiones con su emoji · laboratorio responde con avatar · editar bio actualiza en todas las ventanas · caída de IA → avatar procedural sin romper flujo (voz se completa en K.1) |
| G.5 | Optimizador DSPy-lite (tardía, opcional) | Integration con corpus del motor de pruebas |

## Etapa 8 · Motor de pruebas — `plan-h-motor-pruebas.md` (orden: H.1→H.2→H.5→H.6→H.3→H.4→H.7→H.8→H.9b; H.9a ya corrió en Etapa 3)
| Fase | Nombre | Pruebas |
|---|---|---|
| H.1 | Tareas con criterios | Cargo test ciclo estados. E2E HUMANA: crear tarea con 3 criterios desde UI |
| H.2 | TestRunner sandbox | Cargo test: timeout kill, exit codes, allowlist enforcement. Integration con proyecto real (vitest interno) |
| H.5 | Shadow Workspace | Cargo test shadow-run: diff con error de tipos → rechazado y retornado al agente; limpio → pasa. Perf: ciclo completo <3s en proyecto mediano |
| H.6 | Bucle auto-corrección silencioso | Integration scripted: error → 2 ciclos SELF_FIX invisibles → entrega limpia → Ledger muestra rungs, el chat NO muestra ruido |
| H.3 | Resultados en el canva | E2E HUMANA completo: agente mock implementa → tests corren → verde en canva → apruebo → estado done |
| H.4 | Escalado inteligente | Unit router escalado. Integration: doble fallo simulado → escaló modelo y avisó |
| H.7 | Best-of-N (torneo) | Integration scripted: 3 candidatas mock → scores correctos → elegida la mejor. E2E HUMANA: vista comparativa lado-a-lado funcional |
| H.8 | Cuarentena de tests flaky (torneo) | Unit detector con historial sintético. Integration: test inestable entra/sale de cuarentena; gate ignora cuarentenados |
| H.9b | Computadora persistente del agente | Cargo test drivers tras trait común. Integration: container crea archivo → reinicia sesión → sigue ahí; snapshot→restore exacto. Chaos: matar container → recrear desde snapshot. E2E HUMANA: terminal del agente, cerrar app, volver → entorno intacto |

## Etapa 9 · Revisión auto + Superposiciones — `plan-i-revision-superposiciones.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| I.1 | Review integrado | Integration con reasonix real: diff con bug plantado → review lo señala. Parser de salida |
| I.2 | Detector de estancamiento | Unit watchdog timers. E2E: mock provider colgado → badge blocked + alerta |
| I.3 | Superposición (takeover) | Integration scripted: primer provider falla a mitad → segundo retoma desde rungs → completa |
| I.4 | Approvals reviewer agéntico | Integration: 10 aprobaciones simuladas → reviewer recomienda correctamente las 2 peligrosas. E2E HUMANA: cola con badges de pre-revisión |
| I.5 | Reflect (aprender de sesiones pasadas) | Integration corpus sintético: 3 correcciones plantadas → propuesta generada una sola vez (dedup). E2E: propuesta visible → acepto → aparece como knowledge activo |
| I.6 | Proactividad + pipeline de bugs | Integration: bug plantado en fixture → tarea creada con repro correcta y asignada. E2E HUMANA: sugerencia proactiva visible → acepto → pipeline ejecuta completo |

## Etapa 10 · Grafo 3D Repo-Map — `plan-j-grafo3d-repomap.md` (J.1–J.2 en base · **J.3 → INTERMEDIO 3D**, v3.8)
| Fase | Nombre | Pruebas |
|---|---|---|
| J.1 | Indexador AST (**client-first: también WASM/web-tree-sitter**) | Cargo test con fixture multi-archivo TS/Rust: símbolos+edges correctos, pagerank orden esperado. E2E: indexado en el navegador del usuario sin servidor |
| J.2 | Repo-map compacto | Unit presupuesto tokens (hard cap ≤1000). Integration: prompt capturado contiene mapa |

## Etapa 13 · GitHub nativo — `plan-m-github.md` (ANTES que K/L)
| Fase | Nombre | Pruebas |
|---|---|---|
| M.1 | Auth + repos | Integration con GitHub real (cuenta de prueba): device flow completo, clone real. Mock server para CI |
| M.2 | Ciclo git diario | Integration git real en repo fixture: flujo feliz + conflicto resuelto por UI |
| M.3 | PRs e Issues + memoria commiteada | Integration API GitHub: PR creado con body correcto; issue comentado. E2E HUMANA: ciclo feature→commit→push→PR sin terminal |

## Etapa 12 · Sync multi-device + Co-Work — `plan-l-sync-cowork.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| L.1 | SyncHub server | Integration: 2 clientes mock → misma sesión converge; conflicto LWW resuelto documentado; agente sigue activo tras desconectar ambos clientes |
| L.2 | Cliente sync sin fricción | E2E HUMANA: crear en laptop → aparece en móvil → editar ambos → resolver eligiendo |
| L.4 | Push dispatcher cross-platform | Integration dispatcher con mocks APNs/FCM/VAPID. E2E HUMANA: agente termina en servidor → push llega al móvil → abrir muestra el delta correcto |
| L.3 | Co-Work en vivo (feature-flag, post-v1) | Integration CRDT: dos docs convergen tras ediciones concurrentes. E2E: B refleja acciones de A |

## Etapa 11 · Voz — `plan-k-voz.md` (**K.3 en base** · **K.1/K.2 → INTERMEDIO CR**, v3.8)
| Fase | Nombre | Pruebas |
|---|---|---|
| K.3 | Sonidos + política de interrupción (transversal: U.5/V.4/I) | E2E: mock eventos → sonido correcto por tipo (spy Audio); evento menor NO suena pero aparece en digest; toggles persisten |

## Etapa 14 · Orquestación de sesiones — `plan-n-orchestration.md` (sin "empresa autónoma", ADR-006)
| Fase | Nombre | Pruebas |
|---|---|---|
| N.1 | Gestión de sesiones | E2E: crear 3 sesiones, cambiar entre ellas, aislamiento verificado, export/import |
| N.2 | Invocación de agentes | E2E: invocar 2 agentes en la misma sesión → contextos aislados + costos separados |
| N.3 | Delegación de sub-agentes (patrón Hermes ACP) | E2E: skill con 3 sub-agentes → resultado integrado; timeout/retry |
| N.4 | Control Room: vista de sesiones activas | E2E: 3 sesiones como nodos → layout → interactuar; persistencia tras reinicio |
| N.5 | Tracking de actividad | Unit tracking events. E2E: dashboard muestra datos reales (costo, agentes usados) |
| N.6 | Plantillas de sesiones | E2E: crear desde plantilla → agentes configurados |
| N.7 | Modo nube 24/7 (suscripción, ADR-006) | Integration: cola 20 tareas → consumo ordenado + corte por presupuesto. Chaos: provider cae → pausa limpia. E2E: cierro app → reabro en otro dispositivo → sesión siguió con evidencia |
| N.8 | Puentes de mensajería: WhatsApp/Telegram/Discord/**Slack** ([FEATURE-BACKLOG](../../FEATURE-BACKLOG.md) F21+F36, nube Pro) | Integration: mensaje desde Telegram → agente responde; auth 1:1 con cuenta + rate-limit; streaming resumido + link a evidencia |
| N.9 | **AGENTE SUPERVISOR** del Control Room (chief-of-staff GrokBot/Hermes; atiende los puentes N.8) | Integration: "pausa sesión X" → pausa real + rung DECISION; presupuesto del supervisor agotado → avisa y se detiene. E2E HUMANA vía Telegram: estado REAL de cualquier sesión, pausa con confirmación numerada ([V·V.2]), crear sesión por orden — todo auditado en event_stream |
| N.5b | Dashboard personal de uso/costos (F23) | E2E HUMANA: abro dashboard → costo por proyecto/día, top skills y entregas REALES del event_stream; filtros por rango de fechas |

## Etapa 15 · Marketplace + v1.0 — `plan-o-marketplace-v1.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| O.1 | Bundles `.canvas-ai-bundle` | Cargo test roundtrip export→import idempotente; firma verificada; import malicioso rechazado (validación manifest) |
| O.2 | MCP público del cerebro | Integration real: Claude Code conectado al MCP responde preguntas del workspace usando nuestro grafo. Snapshot tests de tools |
| O.3 | Release v1.0 | Checklist DoD gigante: **[ACEPTACIÓN FINAL](../../ACEPTACION-FINAL.md) 20/20 recorridos humanos verdes** (móvil+desktop, video); todas las suites humanas históricas re-corridas; builds CI verdes; demo documental final |
| O.4 | Compartir entrega pública (link read-only) ([FEATURE-BACKLOG](../../FEATURE-BACKLOG.md) F20) | E2E HUMANA: genero link con expiración → se abre SIN cuenta → contenido correcto; revoco → 404; local exporta HTML estático |

## INTERMEDIO (INTERCALADO v3.8 — cada ventana tras su fase base habilitadora; NO después de la base) — `../SDD-005-plan-intermedio.md`
> VI tras F/G · KR tras H · 3D tras J · K.1/K.2 con CR · CR al final (paralelo a N/O). Consejo de Expertos ADELANTADO: audita los gates de la propia base (dogfood).
> **Q6 · POST-V1 (no bloquean base ni MVP-3):** Consejo de Expertos (VI.5–VI.8) · Voz (K.1/K.2) · 3D (J.3/3D.*) · Control Room (CR.*) · Dopaminérgico (U.2–U.8). Se diseñan, se referencian, pero NO entran a MVP-1/2/3.

### Etapa 16 · Canvas Planeación — VI.1–VI.4 (tras Gate F: necesita D.2 + F.1)
| Fase | Nombre | Pruebas |
|---|---|---|
| VI.1 | Modelo de documentos | Cargo test parser enlaces/headings con fixture .md real. Integration: crear/editar/borrar doc actualiza grafo |
| VI.2 | Layout IA del grafo | Unit clustering determinista con seeds. E2E: arrastrar nodo, recargar → posición conservada |
| VI.3 | Canvas interactivo Obsidian-style | E2E HUMANA: grafo >200 docs sin jank; buscar→subgrafo resaltado; abrir doc desde nodo; móvil 375 operativo |
| VI.4 | Edición humano+IA sobre el grafo (ETAPA/FASE/PLAN) | Integration síntesis crea doc+edges. E2E HUMANA: selecciona 3 notas→sintetiza→edita→deshacer→re-hacer |

### Consejo de Expertos + Discovery Hub — VI.5–VI.8 (ADELANTADO tras Gate G — DOGFOOD: audita los gates de la base)
| Fase | Nombre | Pruebas |
|---|---|---|
| VI.5 | CONSEJO DE EXPERTOS: skills auditores visuales | Unit: skill experto compila y gating READ-ONLY bloquea escritura ([G·G.2]). E2E: convoco 2 expertos sobre nodo-PLAN → personajes conectados al subgrafo; escritura directa → bloqueada |
| VI.6 | Auditoría EN PARALELO + preguntas-opciones | Integration: 3 expertos mock en paralelo agrupados sin cruzarse; respuesta aplica rung DECISION + diff correcto ([D·D.4]). Chaos: experto falla a mitad → marcado, resto sigue. E2E HUMANA: 5 preguntas de 3 expertos → diffs aceptados visibles en el plan |
| VI.7 | Juice del Consejo (dopaminérgico) | Snapshot por estado de experto × intensidad. E2E: responder 3× → variantes distintas + arpegio audible (audio spy); reduced-motion → flujo completo sin partículas |
| VI.8 | Discovery Hub: explorador GitHub + Repo Scout (IA proactiva) | Unit: skill scout compila y gating READ-ONLY bloquea escritura. Integration: buscar "react table" → results con preview. E2E HUMANA: busco repo → agrego como referencia → nodo aparece en grafo; scout sugiere repos → selecciono 1 → se agrega; preview README; filter funciona; historial persiste |

### Etapa 17 · Kanban de Resultados — KR.1–KR.5 (tras Gate H; KR.3 tras N.3/N.6)
| Fase | Nombre | Pruebas |
|---|---|---|
| KR.1 | Tablero de resultados (evidencia-first) | Unit estados. E2E: tarea avanza columnas automáticamente con eventos reales |
| KR.2 | Bloques animados de pruebas | Parser resultados Playwright/vitest→eventos UI. E2E con mock runner: secuencia animada correcta |
| KR.3 | Modo autonomía prolongada (tras N.3/N.6) | Integration: cola mock 20 tareas → consumo ordenado + corte por presupuesto. Chaos: provider cae → pausa limpia |
| KR.4 | Vista evidencia por etapa | E2E HUMANA: recorrer evidencia completa de una tarea sin salir del kanban |
| KR.5 | Filtros y salud del board | E2E: filtros combinados; card estancada muestra badge |

### Etapa 19 · Preparación espacial + Visor 3D — 3D.1 + J.3 + 3D.2 (tras Gate J)
| Fase | Nombre | Pruebas |
|---|---|---|
| 3D.1 | Modelo espacial transversal (SpatialMeta F.0/F.4) | Unit schema SpatialMeta + persistencia. Integration: drag → recargar → posición conservada. Roundtrip export/import escena |
| J.3 | Visor 3D (movido de la base, v3.8) | E2E HUMANA: rotar/zoom, click nodo abre archivo correcto; perf 60fps con 500 archivos |
| 3D.2 | Visor 3D unificado (grafo+kanban+sesiones en capas) | Demo navegación 3 capas; perf 60fps con datos reales |

### Voz (intermedio) — K.1–K.2 (movidas de la base, v3.8; las consume CR)
| Fase | Nombre | Pruebas |
|---|---|---|
| K.1 | TTS de respuestas | Unit cliente WS + caché de audio por hash(texto+voz). E2E con mock WS: botón aparece, cola ordena |
| K.2 | STT dictado | E2E con mock del API: "dictado" inserta texto, editar y enviar |

### Etapa 18 · CONTROL ROOM — CR.1–CR.5 (AL FINAL: paralelo a N/O; consume K.1/K.2 + todo)
| Fase | Nombre | Pruebas |
|---|---|---|
| CR.1 | Mapa global en vivo | E2E HUMANA: 3 proyectos con actividad simulada → mapa refleja estados <1s tras cada evento |
| CR.2 | Cards de sesión vivas | E2E HUMANA: cards aparecen/desaparecen con sesiones reales; hablar por voz desde la card y recibir TTS sin abrir el chat |
| CR.3 | Órdenes maestras por voz/texto | Integration routing comando→destino correcto. E2E HUMANA: 5 órdenes habladas, todas enrutadas y confirmadas |
| CR.4 | Organización espacial semántica | Unit similitud→layout sugerido. E2E: buscar agrupa/ilumina correctamente |
| CR.5 | Alertas y modo vigilancia | E2E: inyectar severidad mixta → solo los que superan umbral aparecen; acuse limpia alerta |

## Transversal V · Visual GrokBot — `plan-v-visual-grokbot.md` (V.0 desde A.1/A.4; V.1–V.2 con F.0/G.7; V.3 con N.6; V.4 con G.6/K.3/U.5 — complementa, no quita nada)
| Fase | Nombre | Pruebas |
|---|---|---|
| V.0 | Chat-first AppShell: la app es mensajería (desks) | E2E HUMANA: usuario nuevo entiende "es un chat con mi equipo" en <30s; navegar conversación→panel→volver sin perder el hilo; mobile 375 sin roturas |
| V.1 | Identidad por avatar geométrico + estados en 2 capas | E2E HUMANA: identificar de un vistazo quién trabaja / espera aprobación / tiene no-leído (sin leer texto); editar perfil desde el chat y ver el cambio en sidebar+canva+grupo; caída de IA → avatar geométrico determinista |
| V.2 | Actividad INLINE en el hilo + aprobaciones numeradas | E2E HUMANA: responder aprobación de opciones numeradas con UN tap; archivo creado visible inline y abrible con un click; flujo completo del hilo sin abrir paneles |
| V.3 | Group chat de bots visual (handoffs visibles) | E2E HUMANA: crear grupo de 3 agentes y verlos coordinar con handoffs en vivo e identidades claras; @mencionar a uno y que solo ese responda; intervenir en un judgment call |
| V.4 | Rutinas visibles + notificaciones persistentes | E2E HUMANA: grabar "preparar release" con indicador de seguimiento; badge de no-leído persiste hasta abrir el hilo (app enfocada); digest del lunes llega como mensaje del PM |

## Transversal S · Despliegue/Costos/Stack — `plan-s-despliegue-costos.md` (S.1+S.2 prerequisito de Etapa 1)
| Fase | Nombre | Pruebas |
|---|---|---|
| S.1 | Hosting por etapas con costos reales | E2E: despliegue Compose desde cero con IaC en VPS limpio ≤15 min |
| S.2 | Stack servidor Rust eficiente | Integration: restore completo desde backup B2 en máquina limpia ≤30 min (drill trimestral automatizado). HUMANA: operador cambia preset KV/hardware en un click y ve el efecto en memoria real |
| S.3 | Cliente Tauri eficiente (**producto base, ADR-006**) | E2E HUMANA del shell — streaming sobrevive background (iOS), auto-update firmado verificado, degradación gráfica planificada (WebKitGTK) documentada |
| S.4 | Presupuesto de costos proyectado | Unit: cálculo costos por scope ([C·C.2]) contra tabla de precios del registro ([C·C.7]) |
| S.5 | Captura rápida global (hotkey del SO, F22) | E2E HUMANA desktop: hotkey global → mini-ventana → escribo tarea → envío → notificación al terminar con evidencia; sin foco en la app principal funciona |

## Etapa 10 · Multi-plataforma + Nube — `PLATAFORMAS-TARGETS.md` (clientes instalables + servidor Linux 24/7)
| Fase | Nombre | Pruebas |
|---|---|---|
| MP.1 | Desktop Windows/macOS/Linux (CI) | CI `build-desktop` verde en 3 SO por push; `.msi`/`.dmg`/`.AppImage` generados en release |
| MP.2 | **iOS**: generar `gen/apple` en un Mac | `tauri ios init` 1 vez → versionar `src-tauri/gen/apple/`; build en CI macOS; `.ipa` firmado (App Store) |
| MP.3 | Android release | `android-build.yml` → APK debug ✅; release: `.aab` firmado + publicación Play Store; E2E móvil 375 |
| MP.4 | Web/PWA | Build estático servido por gateway; accesible en navegador (misma SPA) |
| MP.5 | Servidor Linux 24/7 (nube de pago) | Deploy Compose desde cero ≤15 min; workers Linux; Postgres+RLS; RTO ≤1h / RPO ≤15min (drill) ([S·S.1] y [THREAT-MODEL](../../THREAT-MODEL.md)) |
| MP.6 | Sync multi-dispositivo (suscriptores) | Misma sesión desktop↔móvil converge; conflicto LWW resuelto ([L·L.1/L·L.2]) |

## Transversal T · Excelencia — `plan-t-excelencia.md` (T.SEC/T.QA desde Etapa 1)
| Fase | Nombre | Pruebas |
|---|---|---|
| T.SEC | Seguridad profesional | CI falla si cargo-audit encuentra CVE crítico. Integration: intento de XSS vía respuesta del agente → neutralizado. Suite path-traversal completa verde |
| T.A11Y | A11Y + i18n (es/en) + **RESPONSIVE TOTAL** | axe-core gate en CI (violación seria = rojo). E2E HUMANA dual idioma. Auditoría contraste en cada tema. **Suite humana responsive (375/768/1440) re-corrida en CADA gate — todas las pantallas operables en móvil** |
| T.ONB | Onboarding que convierte | E2E HUMANA: usuario nuevo → primer agente trabajando <5 min sin documentación externa |
| T.QA | Calidad continua (anti-deuda) | Pipelines con gates activos (budgets perf + **regresión responsive en CI**: scroll horizontal en móvil, touch targets, layout a 375px = build rojo). Dashboard de tendencia |
| T.BIZ | Comercial y legal (antes de v1.0) | Flags verificados; bundle Free NO incluye código Pro compilado; docs legales revisadas |

## Transversal U · Dopaminérgico — `plan-u-motivacion.md` (U.1 con F.0; resto tras cada ventana)
| Fase | Nombre | Pruebas |
|---|---|---|
| U.1 | Primitivas + JUICE calibrado (en F.0) | Snapshot visual por primitiva × 3 intensidades. E2E: misma acción 2× → variantes distintas (error de predicción); audio spy verifica arpegio (éxito) / tritono (fallo); toggle mute silencia todo |
| U.2 | Micro-feedback en ejecución | E2E: mock runner 10 tests → 10 ticks ordenados + worklog colapsa a una línea verde al éxito; tarea fallida a 70% conserva barra avanzada; contador $ visible subiendo durante stream |
| U.3 | Celebraciones gated + cofres funcionales | E2E HUMANA: hito menor NO dispara overlay; hito gated SÍ con cofre abrible cuyo contenido es funcional; screenshot adjunta visible en la evidencia; dos hitos iguales seguidos → animaciones diferentes |
| U.4 | Progresión honesta (niveles, rachas, heatmap) | Unit XP/fiabilidad. E2E: escudo consume automáticamente el día hueco conservando racha; heatmap pinta relativo al máximo histórico propio; recap generado íntegramente de rungs reales |
| U.5 | Flow-protection + anti-spinner | E2E: run de 20 min → usuario cierra app → vuelve → inbox lista outcome + push recibido; 5 interrupciones triviales agrupadas en 1 batch; hover card muestra checkpoint reversible |
| U.6 | Glanceables (widget 2 datos) | E2E desktop: widget refleja operación del día en vivo; expresión cambia según cercanía de cierre de jornada; badge SVG regenera con datos correctos |
| U.7 | Onboarding emocional (unboxing) | E2E HUMANA completo cronometrado: nuevo usuario → agente trabajando ante sus ojos ≤90s → tarjeta fundador emitida; cada paso deja valor persistente real |
| U.8 | Anti-dark-patterns | Verificación en cada release: lista de prohibidos (logros falsos, culpa de rachas, urgencia artificial, comparación pública) + métrica norte "sesiones que terminan en ENTREGA" |

---
**Total: 168 fases** — **Etapa 0 6** + **Etapa 10 (MP) 6** + **base 133** (A–P 110 incl. H.9a/H.9b, A.4b/A.12/A.10/C.8/C.9/C.10/C.11/B.10/G.3b/A.0b/A.2b/A.7b/A.11/G.1b/N.5b/N.8/N.9/O.4, sin J.3/K.1/K.2 + V 5 + S/T/U 18 incl. S.5) + **intermedio 23** (VI 8 + KR 5 + CR 5 + 3D 3 + K.1/K.2 2). Regenerar tras CADA cambio de fases. Post-v1 marcado (Q6): Consejo (VI.5+), Voz (K.1/K.2), 3D (J.3/3D.*), CR, Dopamina (U.2-U.8), tab-FIM ([MERCADO-ANALISIS](../../MERCADO-ANALISIS.md)).
