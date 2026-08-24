# MATRIZ COMPLETA — Todas las fases del Plan Base y sus pruebas

> Generada automáticamente de los planes (fuente de verdad). Regenerar tras cambiar fases.

> Capas por fase: **[U]**nit vitest · **[I]**ntegración cargo/mock · **[E]**2E Playwright · **[H]**umana suite modo persona. Fase GUI ⇒ E+H obligatorias.


## Etapa 1 · Chat núcleo Codex + tenants — `plan-a-chat-codex.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| A.0 | Proyectos como TENANTS: cards + tabs + historial aislado (FUNDACIÓN, va sobre todo lo demás) | - Unit: repos filtran por project_id en TODAS las consultas; resolución de scopes global→local |
| A.1 | AppShell + stores | Vitest stores+hook. E2E: layout mobile 375px (BottomNav) y desktop 1440px (sidebar) |
| A.2 | Persistencia SQLite | Cargo test repositorios; integration roundtrip mensaje |
| A.3 | Trait AgentProvider + DeepSeekDirect | unit con mock-server SSE; integration orden de chunks |
| A.4 | UX Codex (el corazón copiado) | E2E browser-mode con provider MOCK scriptado (sin key real): prompt→streaming→tool-call→aprobar→diff visible→slash fork duplica sesión |
| A.6 | Centro de Configuración (flexible para todos los públicos) | Unit store settings + herencia global/proyecto. E2E humano: no-programador cambia un ajuste solo con clicks; programador edita JSON crudo validado; override por proyecto visible |
| A.7 | Modo ENCARGO: dar trabajo, no prompts (patrón Grok Bot) | E2E humano: crear encargo sin escribir un prompt; agente mock lo completa; notificación de vuelta con evidencia |
| A.8 | Resume inteligente al abrir (patrón Grok Bot) | Integration: sesión interrumpida → resume card correcta. E2E humano: cerrar a mitad de tarea → reabrir → continuar fluido |
| A.9 | Ramas visuales al editar mensajes (patrón ChatGPT) | Unit tree-store. E2E humano: edito mensaje 2 veces → flechas ‹› navegan alternativas sin perder ninguna |

## Etapa 2 · Sidepanels Lovable — `plan-b-sidepanels-lovable.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| B.1 | Workspace virtual + detección Codex | Cargo test seguridad paths. E2E: árbol refleja archivos creados por el agente |
| B.2 | Editor Monaco | E2E abrir archivo escrito por agente, editarlo, persistir |
| B.3 | Live Preview | unit debounce watcher. E2E: agente escribe HTML → preview actualizado <2s |
| B.4 | Sincronización chat ↔ paneles (patrón desktop Codex) | E2E flujo integrado completo |
| B.5 | Fast Apply: escritura especulativa (copia.md §Cursor/Morph) | Cargo test aplicador: 500 deltas/sec sintéticos sin pérdida ni desorden. E2E humano: ver un archivo grande escribirse fluido en vivo |
| B.6 | @menciones de archivos/símbolos (ganadora torneo #002) | — |
| B.7 | Revisión por HUNKS (ganadora torneo #124) | — |
| B.8 | Consola preview → "enviar error al agente" (ganadora torneo #143) | — |
| B.9 | Artefactos versionados (patrón Claude artifacts) | Integration versionado automático por escritura relevante. E2E humano: navegar 3 versiones, comparar side-by-side, restaurar antigua |

## Etapa P · Centro MCP — `plan-p-centro-mcp.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| P.1 | Cliente MCP core (Rust) | Cargo test contra fixture-server MCP local (stdio): list/call/stream. Timeout + kill limpio |
| P.2 | Centro MCP visual (doble público) | E2E humano dual: (a) no-programador conecta server popular solo con clicks y entiende errores; (b) programador pega JSON complejo y ve validación inmediata |
| P.3 | Seguridad y control de llamadas externas | Cargo test enforcement scopes + rate limit. Chaos: server que devuelve basura → circuit breaker aísla sin tumbrar agentes |
| P.4 | Plantillas 1-click y descubrimiento | Unit schema plantilla. E2E humano: instalar "GitHub" desde cero hasta primer tool-call exitoso <5 min sin leer docs |

## Etapa 3 · Runtime Reasonix+DeepSeek+Ollama+API universal — `plan-c-reasonix-deepseek.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| C.0 | Residual del spike (medio día) | fixtures versionados; script humo curl documentado |
| C.1 | ReasonixProvider | Cargo test parser con fixtures reales de C.0 |
| C.2 | Enrutamiento por costo + telemetría (el diferenciador) | unit router + cálculo costos. E2E: badge costo sube durante sesión real barata |
| C.3 | Robustez | chaos integration kill -9 → recuperación automática; estado consistente post-cancel |
| C.5 | Motor de Contexto y Caché configurable (SDD-006 §1) | Unit hash/orden estable. Integration DeepSeek real: cache_hit>90% post warm-up; cambio de knob → aviso de caché fría. E2E humano: aplicar preset de rol en un click |
| C.6 | OllamaProvider local, ready-to-plug (SDD-006 §5) | Unit: detección/parsing de /api/tags y errores de conexión. Integration con Ollama real: chat streaming completo + embeddings generados; cambio de preset KV verificado por memoria consumida. E2E human |
| C.7 | Registro universal de proveedores API (análisis exhaustivo OpenCode/models.dev → [SDD-007](../SDD-007-analisis-opencode-modelsdev.md)) | — |

## Etapa 4 · Memoria V3Code — `plan-d-memoria-v3code.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| D.0 | Restaurar artefactos de referencia (prerequisito) | — |
| D.1 | Capa 1: Decision Ledger | Cargo test append-only (UPDATE/DELETE rechazados por trigger); integration rung al finalizar |
| D.2 | Capa 2: Workspace Knowledge + Human-Tweak Lock | Cargo test FTS ranking + invariants presentes en contexto capturado |
| D.3 | Capa 3: Memory Rail UI + inyección automática | E2E componentes rail/scrubber. Integration: request capturado por mock contiene contexto esperado |
| D.4 | Gobernanza de decisiones (patrón varve) | Cargo test ciclo estados + enforcement de scope. E2E humano: agente propone → acepto con evidencia → otra tarea toca archivo gobernado → aviso de decisión activa |
| D.5 | Índice semántico dual local (patrón V3Code: "dual semantic indexing + Beast search") | Integration: consulta ("cómo manejamos auth") retorna la decisión correcta aunque no comparta palabras. Indexado incremental <100ms/archivo |
| D.6 | Memory Router + shards + checkpoints (patrones CLAUDE.md-router / V3Code) | Unit aging policy. Integration router: prompt de auth carga SOLO shard auth (verificado en request capturado). E2E checkpoint: rebobinar a turno N restaura archivos exactos |
| D.8 | Motor de memorias multi-tipo configurable (SDD-006 §3) | Unit decay/scoring con fixtures. Integration: contradicción invalida (bi-temporal) sin borrar; consolidación idempotente. E2E humano: ajustar λ de un tipo y ver el ranking cambiar; leakage test entre  |

## Etapa 5 · Cierre Base — `plan-e-integracion-total.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| E.1 | E2E punta a punta REAL (key DeepSeek de prueba) | Playwright browser-mode completo + video evidencia en `evidence/` |
| E.2 | Chaos / robustez transversal | suite chaos automatizada, todos con recuperación verificada |
| E.3 | Pulido responsive + performance + cierre | — |

## Etapa 6 · Canva Oficina — `plan-f-canva-oficina.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| F.0 | Design System core + capa de experiencia (prerrequisito de TODO lo visual) | Vitest tokens/primitivas. E2E humano: contraste AA automatizado, toast deshace acción destructiva, status bar refleja modelo/coste reales |
| F.1 | Fundaciones ReactFlow | E2E humano: arrastrar nodo, conectar dos nodos, zoom con rueda y pinch |
| F.2 | Nodos-agente vivos (datos reales) | E2E: crear agente en chat → nodo aparece; mock provider working → badge cambia |
| F.3 | Edges semánticos + Animated Beams | unit mapping evento→edge. Visual gate con screenshots/video |
| F.4 | Tareas y Kanban sobre el canva | E2E humano: drag tarea todo→doing→done; verificar persistencia tras reinicio |
| F.5 | Identidad visual dirigida por IA | suite humana completa re-corrida + checklist RESPONSIVE.md + contraste automatizado básico |
| F.7 | Command Palette global ⌘K (ganadora torneo #173, patrón Zed/Raycast) | — |
| F.6 | Performance del canva | test de rendimiento programático + suite humana sin jank percibido |

## Etapa 7 · Skills Lab — `plan-g-skills-lab.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| G.1 | Modelo de datos + CRUD | Cargo test repos. E2E humano: crear/editar/duplicar/eliminar skill desde cero |
| G.2 | Editor visual + Tool-Gating (copia.md §Cline/RooCode) | Unit validación + enforcement de gating (agente QA no puede invocar write). E2E humano: crear skill completo solo con clicks y tecleo |
| G.3 | Compilador a dialectos | Cargo test compiler snapshot tests por dialecto. Roundtrip: compilar→ejecutar en reasonix real→respuesta esperada |
| G.4 | Laboratorio sandbox | E2E: probar skill real con DeepSeek barato; costo del ensayo visible; resultado persistido |
| G.5 | Optimizador DSPy-lite *(tardía, opcional)* | Integration con corpus del motor de pruebas |
| G.6 | Rutinas por demostración "follow along" (patrón Grok Bot) | Integration: sesión grabada de N pasos → skill propuesto con N pasos correctos; corrección humana se persiste. E2E humano: grabo "preparar release" → skill creado → lo ejecuto programado |

## Etapa 8 · Motor de pruebas — `plan-h-motor-pruebas.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| H.1 | Tareas con criterios | Cargo test ciclo estados. E2E humano: crear tarea con 3 criterios desde UI |
| H.2 | TestRunner sandbox | Cargo test runner: timeout kill, exit codes, allowlist enforcement. Integration con proyecto real (vitest interno) |
| H.3 | Resultados en el canva | E2E humano completo: agente mock "implementa X" → tests corren → verde en canva → apruebo → estado done |
| H.4 | Escalado inteligente | Unit router escalado. Integration: doble fallo simulado → escaló modelo y avisó |
| H.5 | Shadow Workspace (copia.md §Cursor/SWE-bench) | Cargo test shadow-run: diff con error de tipos → rechazado y retornado al agente; diff limpio → pasa. Perf: ciclo completo <3s en proyecto mediano |
| H.6 | Bucle de auto-corrección silencioso (copia.md §Capa 1) | Integration scripted: agente introduce error → 2 ciclos SELF_FIX invisibles → entrega limpia → Ledger muestra los rungs, el chat NO muestra ruido |
| H.9 | Computadora persistente del agente (patrón Grok Bot, local-first) | Cargo test drivers tras trait común. Integration: container crea archivo → reinicia sesión → archivo sigue ahí; snapshot→restore exacto. Chaos: matar container → recrear desde snapshot. E2E humano: ab |
| H.7 | Best-of-N: votación entre soluciones (ganadora torneo #213, patrón Devin) | Integration scripted: 3 candidatas mock → scores correctos → elegida la mejor. E2E humano: vista comparativa lado-a-lado funcional |
| H.8 | Cuarentena de tests flaky (ganadora torneo #253) | Unit detector con historial sintético. Integration: test inestable simulado entra/sale de cuarentena correctamente; gate ignora cuarentenados |

## Etapa 9 · Revisión auto + Superposiciones — `plan-i-revision-superposiciones.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| I.1 | Review integrado | Integration con reasonix real: diff con bug plantado → review lo señala. Parser de salida |
| I.2 | Detector de estancamiento | Unit watchdog timers. E2E: mock provider colgado → badge blocked + alerta |
| I.3 | Superposición (takeover) | Integration scripted: primer provider falla a mitad → segundo retoma desde rungs → completa |
| I.4 | Approvals reviewer agéntico (patrón Codex auto_review) | Integration: 10 aprobaciones simuladas → reviewer recomienda correctamente las 2 peligrosas. E2E humano: cola con badges de pre-revisión |
| I.5 | Reflect: aprender de sesiones pasadas (patrón codevira, sin LLM para detectar) | Integration con corpus sintético: 3 correcciones plantadas → propuesta generada una sola vez (dedup). E2E: propuesta visible, acepto, aparece como knowledge activo |
| I.6 | Proactividad + pipeline de bugs (patrón Grok Bot) | Integration: bug plantado en fixture → tarea creada con repro correcta y asignada. E2E humano: sugerencia proativa visible → acepto → pipeline ejecuta completo |

## Etapa 10 · Grafo 3D Repo-Map — `plan-j-grafo3d-repomap.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| J.1 | Indexador AST | Cargo test con fixture multi-archivo TS/Rust: símbolos+edges correctos, pagerank orden esperado |
| J.2 | Repo-map compacto | Unit presupuesto tokens (hard cap). Integration: prompt capturado contiene mapa |
| J.3 | Visor 3D | E2E humano: rotar/zoom, click nodo abre archivo correcto; perf 60fps con 500 archivos |

## Etapa 11 · Voz — `plan-k-voz.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| K.1 | TTS de respuestas | Unit cliente WS + caché de audio por hash(texto+voz). E2E con mock WS: botón aparece, cola ordena |
| K.2 | STT dictado | E2E con mock del API: "dictado" inserta texto, editar y enviar funciona |
| K.3 | Sonidos de estado + política de interrupción ("sabe cuándo molestar") | E2E: mock eventos → sonido correcto por tipo (spy Audio); evento menor NO suena pero aparece en digest; toggles persisten |

## Etapa 12 · Sync multi-device + Co-Work — `plan-l-sync-cowork.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| L.1 | SyncHub server (el puente) | Integration: 2 clientes mock → misma sesión converge; conflicto LWW resuelto documentado; agente sigue activo tras desconectar ambos clientes |
| L.2 | Cliente sync sin fricción | E2E humano: crear en laptop → aparece en móvil → editar ambos → resolver eligiendo |
| L.3 | Co-Work en vivo *(tras feature-flag; puede moverse a post-v1)* | Integration CRDT: dos docs convergen tras ediciones concurrentes. E2E: B refleja acciones de A |
| L.4 | Push dispatcher cross-platform (despertar sin drenar batería) | Integration dispatcher con mocks APNs/FCM/VAPID. E2E humano: agente termina en servidor → push llega al móvil → abrir muestra el delta correcto |

## Etapa 13 · GitHub nativo — `plan-m-github.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| M.1 | Auth + repos | Integration con GitHub real (cuenta de prueba): device flow completo, clone real. Mock server para CI |
| M.2 | Ciclo git diario | Integration git real en repo fixture: flujo completo feliz + conflicto resuelto por UI |
| M.3 | PRs e Issues + memoria commiteada | Integration API GitHub: PR creado con body correcto; issue comentado. E2E humano: ciclo feature→commit→push→PR sin terminal |

## Etapa 14 · Empresas autónomas — `plan-n-empresas-autonomas.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| N.1 | Modelo de empresa | Cargo test modelo + presupuesto enforcement (rechaza gasto over-budget). E2E humano: crear empresa completa desde cero |
| N.2 | Jerarquía líder→operativos + worktrees paralelos | Integration scripted: objetivo simple → PM crea 3 tareas → 2 operativos en paralelo (worktrees distintos) completan → merges limpios → auditoría completa en event_stream |
| N.3 | Presupuesto + kill-switch | Integration: budget simulado pequeño → pausa al llegar; kill-switch detiene todo <2s sin corrupción |
| N.4 | Dashboard de empresa | E2E humano: navegar dashboard, filtrar por rol/agente, replay scrubber de un proyecto completo |
| N.5 | Proyecto demo end-to-end real | E2E largo REAL con DeepSeek: objetivo "todo-list app con tests" entregado; video completo |
| N.6 | Group chat de la empresa + rutinas programadas (patrón Grok Bot) | Integration: 3 agentes en group chat resuelven handoff sin humano (scripted). E2E humano: observo la conversación grupal en vivo; programo rutina nocturna y verifico ejecución + digest matutino |
| N.7 | Entorno compartido de empresa (adaptación del "computer compartido" de Grok Bot) | Cargo test: acceso sin scope rechazado+auditado; con scope permitido+registrado |

## Etapa 15 · Marketplace + v1.0 — `plan-o-marketplace-v1.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| O.1 | Bundles `.empresa-bundle` | Cargo test roundtrip export→import idempotente; firma verificada; import malicioso rechazado (validación manifest) |
| O.2 | MCP público del cerebro (patrón V3Code/Zed) | Integration real: Claude Code conectado al MCP responde preguntas del workspace usando nuestro grafo. Snapshot tests de tools |
| O.3 | Release v1.0 | Checklist DoD gigante: todas las suites humanas históricas re-corridas en las 3 vistas; builds CI verdes; demo documental final |

## Transversal U · Progreso Dopaminérgico — `plan-u-motivacion.md`
| Fase | Nombre | Pruebas |
|---|---|---|
| U.1 | Primitivas dopaminérgicas + JUICE calibrado (en [F·F.0](./plan-f-canva-oficina.md#f0)) | — |
| U.2 | Micro-feedback en ejecución (cada segundo cuenta) | — |
| U.3 | Celebraciones escalonadas, gated y con cofres funcionales | — |
| U.4 | Progresión honesta: niveles, rachas-perdonables y heatmap | — |
| U.5 | Flow-protection y anti-spinner (el hallazgo más importante) | — |
| U.6 | Glanceables fuera de la app (widget de 2 DATOS, patrón Duolingo) | — |
| U.7 | Onboarding emocional: el unboxing (Arc/Raycast) | — |
| U.8 | Anti-dark-patterns (vigilado por [U.9]) | — |

## Transversal S · Despliegue/Costos/Stack — `plan-s-despliegue-costos.md`
| Fase | Nombre | Pruebas |
|---|---|---|
