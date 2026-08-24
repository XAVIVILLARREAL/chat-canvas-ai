# CHANGELOG

> Append-only. Cada sesion deja rastro. Nunca editar dias anteriores.

## 2026-08-24 (sesion 20)

- **PRE-ARRANQUE v3.8 aplicado**: crate `crates/worker` CREADO (patrón Everruns: stateless sin DB creds, heartbeat 30s — compila ✓) + checklist pre-arranque en README (auth MVP en A.0 con RLS día 1, Postgres en Compose desde día 1, schema maestro + contrato event_stream antes de A.2, tipos vía OpenAPI del gateway/openapi-typescript, KEK decidida, docker socket solo en worker, recursos DeepSeek/Ollama/GitHub-test, una sesión a la vez)
- **ORDEN v3.8 — Plan Intermedio INTERCALADO (ratificado por el usuario)**: el intermedio deja de ser "el plan después de la base" — carril de vistas entre fases base (VI tras F/G, KR tras H, 3D tras J, CR al final paralelo a N/O); J.3 (visor 3D) y K.1/K.2 (voz TTS/STT) se MOVIERON de la base al intermedio (K.3 política de interrupción SE QUEDA en base por transversal); Consejo de Expertos ADELANTADO como DOGFOOD (audita los gates de la propia base en cuanto existan G.1/G.2); matriz reestructurada con secciones base vs intermedio — **136 fases totales (114 base + 22 intermedio)**
- **SÍNTESIS (sesión unificada)**: integrados PLAN V (Visual GrokBot) + Consejo de Expertos (VI.5–VI.7) — la "pregunta con opciones" es UNA primitiva visual compartida (aprobaciones del agente V.2 = radio-cards del Consejo VI.6, con cross-links en plan-v y SDD-005); los avatares geométricos deterministas de V.1 aplican también a los expertos auditores; README v3.7 (16 etapas, ~124 fases) con fila Etapa 16 + regla 13 RENDERER AGNÓSTICO (SpatialMeta en F.0/F.4, cadena 2D→3D→gafas sin refactor)
- **SDD-005 PLAN VI ampliado — CONSEJO DE EXPERTOS (VI.5–VI.7)** en Canvas Planeación: 5 skills auditores visuales (🔐 ciberseguridad · 🎨 frontend · 🏗️ infraestructura · 📈 escalabilidad · 🧭 arquitectura, + creables por usuario) con tool-gating READ-ONLY [G·G.2] e identidad viva [G·G.7]; auditoría EN PARALELO con panel derecho de preguntas-opciones en cards animadas; responder aplica rung DECISION [D·D.4] + diff aceptable al .md; cards-debate ante conflictos entre expertos; juice dopaminérgico [U·U.1/U.3] (micro-vida, cascada por respuesta, variantes aleatorias, score de madurez, Acta del Consejo) con cero dark patterns. GATE VI ampliado; estimación intermedio ~10–12 sem (VI: 4–5). README maestro sincronizado (espacios reservados)

## 2026-08-24

- **REVISIÓN PROFUNDA Plan Base v3.4** (SDD-001): análisis completo de los 20 planes + matriz + README maestro
- Fases reintegradas: **A.5** (medidor/debug de contexto) y **D.7** (blame-rung) — estaban prometidas en ORDEN/torneo pero no existían; C.4 documentada como reservada (absorbida en C.5/C.7)
- **H.9 partida**: H.9a (aislamiento contenedor mínimo) se ejecuta tras C.3 y cumple la condición NO negociable de seguridad de PLAN C; H.9b (computadora persistente) al final de H
- **P (Centro MCP)** pasa a tras el Gate B en paralelo con C/D; **M (GitHub) antes que K/L** ahora DENTRO del ORDEN; voz (K) al final del bloque (J→M→L→K)
- **Multiplataforma corregida a WEB-FIRST** en el README (tabla qué-corre-dónde + diagrama cerebro-tres-cuerpos): navegador = v1 servido por el gateway; Tauri diferido hasta demanda
- **A.7/A.8** con v1 mínima en Etapa 1 (tarea simple / resume sin rungs) que H.1/D.1 formalizan; **C.7 y D.8** con alcance v1 acotado (C.7b/D.8b post-base)
- **MATRIZ regenerada: 112 fases** (95 A–P + 17 S/T/U) en orden de ejecución, regla dura "fase GUI ⇒ [E]+[H]", presupuesto **máx $20/gate** con APIs reales (resto mock-first)
- Cross-refs rotos reparados: A.9→A.4 fork · C.7→router C.2 · plan-s→C.2 · H.9 enlace inválido · plan-u link a plan-kr inexistente → referencia a Etapa 17
- Rangos de fases de la tabla maestra corregidos (B.1–B.9, F.0–F.7, G.1–G.7, H.1–H.9, L.1–L.4, N.1–N.7); estimación recalibrada a ~24–32 semanas
- **RESPONSIVE TOTAL endurecido**: regla transversal dura en AGENTS.md + SDD-002 + plan-t (T.A11Y/T.QA) + README (regla 11) + matriz — TODAS las pantallas/secciones/ventanas mobile-first, verificadas en móvil 375 + desktop 1440 en cada gate (suite humana responsive); no existe pantalla "solo desktop"
- **REVISIÓN DE ARQUITECTURA v3.5 + stack validado por investigación**: CÓMPUTO CLIENT-FIRST como regla transversal #12 (D.5 wa-sqlite/OPFS + sqlite-vec WASM · J.1 web-tree-sitter WASM · F.6 Three.js WebGPU · C.6 Ollama local en el cliente) — el servidor escala con datos, no con CPU de usuarios; ARQUITECTURA.md reescrita (backend Python fantasma eliminado, web-first+Rust confirmado); INFRA.md corregido; ADR-002 marcado superado en parte por ADR-005/SDD-008; stack validado: axum 0.8.9 + tokio 1.53 + sqlx 0.9 + rustls 0.23 (3.475 sesiones WS/vCPU), sin BFF Node, Go como plan B
- **PLAN V v3.6 — Visual GrokBot (transversal social)**: la capa visual de Grok Bot (xAI/Cursor) verificada con docs oficiales + reviews — chat-first "desks" (la app es mensajería, no dashboard), identidad por avatar geométrico (el color es QUIÉN, el estado es capa aparte: puntos=working, needs-attention, badge no-leído), actividad/aprobaciones INLINE en el hilo (opciones numeradas ▸ 1. X · 2. Y con un tap), group chat 2–6 bots con handoffs visibles, rutinas con indicador de seguimiento + notificaciones persistentes + digests como mensajes. COMPLEMENTA sin quitar: Codex sigue siendo la referencia de paneles/diffs. Fases V.0–V.4 integradas en matriz (total 117 fases) y cruzadas con A.1/A.4/F.0/G.7/B.4/N.6/G.6/K.3/U.5

- **SDD-010 Modelo de Negocio** (3 investigaciones paralelas: outcome-pricing · growth devtools · costos hosting):
- 3 ESCENARIOS soportados por el mismo codebase ADR-005: A todo-local (Ollama en tu máquina→Tauri su hogar natural, SKU posterior) · B servidor propio (web-first ideal) · C nube gestionada (el negocio recurrente)
- MONETIZACIÓN con datos: Motor principal = open-core + managed hosting ($16-110 costo real → cobrar $29-149/mes margen 60-80%, modelo n8n $5.2B val); Pay-per-results = arma de diferenciación SOLO tras >70% success-rate medido y entregas binariamente verificables POR NUESTROS TESTS (ventaja única del mercado; Fin $100M ARR $0.99/resolución pero Devin abandonó outcome puro — 42% PRs mergeados = revenue erraticísimo; Agentforce $2/conversación fracasó $900/día); Enterprise on-prem ilimitado anual después (Harvey $1,200+/seat sin outcomes; Adecco-Agentforce acuerdo ilimitado)
- GROWTH secuencia medida: KPI norte = % usuarios que COMPARTEN artefacto en sesión 1 (output filmable = activo #1, Lovable 25M proyectos/año=25K signups orgánicos/mes) · Show HN sábado título-numérico sin "AI" (-33% portada si la incluyes; HN supera PH 20x tráfico) · MCP registries 30min superficie permanente (caso: cliente pago en 2min vía agente descubriendo MCP) · errores fatales documentados (construir antes que distribuir, influencers antes de activation 94% fallo)
- EXIT paths verificados: ARR creciente × usuarios × talento (Cursor rechazó OpenAI → reportado $60B; Google pagó $2.4B Windsurf tech+equipo; Salesforce compró Intercom validando outcome)
- T.BIZ del plan-t ahora referencia SDD-010 como estrategia adoptada


## 2026-08-23 (sesion 12)

- **SDD-008 Análisis cliente-servidor autónomo + escalado** (3 investigaciones paralelas: K8s para agentes IA · sync multi-dispositivo · servidor Rust multi-tenant)
- DECISIÓN CENTRAL elevada: el trabajo persiste en SERVIDOR central (Linux/docker/k8s); dispositivos = ventanas+controles delgados
- Arquitectura servidor Rust adoptada (patrón Everruns open source): gateway axum stateless + workers SIN credenciales DB reclamando tareas FOR UPDATE SKIP LOCKED + heartbeat; Postgres+RLS fail-closed con crate tenaxum; fan-out broadcast POR SESIÓN multi-dispositivo; deltas efímeros/eventos terminales persistentes; reconexión ?since_id
- Sync sin fricción (patrón Linear endosado CTO): delta-sync con cursor por dispositivo + outbox duradero idempotente para comandos offline + conflictos LWW por campo invisibles con keep-both
- Auth: passkeys sincronizadas primarias + QR pairing TTL<2min + sesiones revocables por dispositivo + refresh rotativo con detección de reuso
- L.4 NUEVA fase: push dispatcher cross-platform APNs/FCM/ntfy-VAPID (payload mínimo→delta-sync al abrir)
- Camino de escalado por fases: HOY Docker Compose + driver sandbox abstracto → tracción: k3s + CRD agent-sandbox (SIG-Apps Google, warm pools, hibernación, scale-to-zero KEDA) + gVisor → serio: namespaces endurecidos + Kata/Firecracker + CloudNativePG + Karpenter + OpenCost chargeback por tenant
- Anti-trampas documentadas: KEDA ScaledJob para trabajos largos · PVC individual+s3 (no RWX) · LISTEN/NOTIFY requiere conexión no-pooled · tenant_id jamás como label Prometheus

## 2026-08-23 (sesion 13)

- **PLAN S Despliegue/Costos/Stack creado** (todo consolidado en la base): hosting 3 etapas CON PRECIOS REALES ago-2026 (Hetzner CAX21 ARM $11.5 MVP → CAX41+doble nodo → bare-metal ~$45/nodo; managed 4-7x más caro), reglas de dinero (B2 backups $3.5/TB-mes, R2 artefactos egresos $0, DeepSeek Flash $0.14/$0.28 cache-hit -98%, IaC obligatoria por DRAM shock/subidas 30-170%)
- Stack servidor Rust FIJADO: tokio 1.52/axum 0.8.9/sqlx 0.9 offline-mode/sonic-rs hot-path/rustls-aws-lc/mold+cranelift+sccache/distroless-nonroot — versiones pinneadas ago-2026
- Patrones Tauri obligatorios integrados a A.4: streaming via Channel<TokenEvent> batch 30ms en Rust (sobrevive background iOS), payloads binarios Channel<Vec<u8>> 11x@64KB, lazy Monaco/ReactFlow, degradación gráfica Linux planificada (WebKitGTK punto débil declarado), updater sin delta → sidecars lazy post-install
- Presupuesto proyectado visión completa: MVP ~$21-42/mes · escala media ~$125-245/mes (costo lineal con uso, no con arquitectura)
- Investigaciones completadas: hosting costos reales + stack Rust 2026 + Tauri 2.11 (completan K8s/sync/servidor-Rust de SDD-008)

## 2026-08-23 (sesion 14)

- **AUDITORÍA FINAL del plan base** (cobertura por dimensión con grep automatizado): detectados 6 huecos que estaban solo en backlog del torneo — keyring/CSP/passkeys/i18n/accesibilidad/onboarding/licencia-SBOM
- **PLAN T Excelencia transversal creado**: T.SEC seguridad profesional (keyring OS, CSP, cargo-audit+deny+SBOM en CI, modelo de amenazas) · T.A11Y+i18n (axe-core gate CI, es/en central desde el primer componente) · T.ONB (primera corrida guiada, proyecto ejemplo, primer agente <5min) · T.QA calidad continua (budgets de perf en CI = build rojo si regresa, flaky-quarantine también humana, revisión trimestral deuda) · T.BIZ comercial/legal (open-core MIT/Apache + Pro flaggeado, ToS/privacy, telemetría opt-in)
- Totales finales: 18 planes · ~95 fases · 77 anclajes · 0 rotos

## 2026-08-23 (sesion 15)

- **PLAN U Sistema de Progreso Dopaminérgico creado**: micro-feedback en ejecución (tick por test pasado, pop por criterio cumplido, pulso por tool-call), celebraciones escalonadas (tarea→tarjeta vuela / GATE→confetti+resumen / empresa entrega→overlay completo con stats), progresión XP solo por resultados VERIFICADOS + niveles de agente + rachas honestas + recap semanal estilo Wrapped generado del Ledger
- Intensidad configurable (Apagado/Sutil/Normal/Festivo) respeta reduced-motion y silencio
- U.5 Tuning responsable: A/B interno sobre retención propia, anti-patrones PROHIBIDOS explícitos (logros falsos, culpa de racha, urgencia artificial), métrica norte = sesiones que terminan en ENTREGA no tiempo-en-app
- AGENTS.md: principio de MOTIVACIÓN añadido a la sección visual

## 2026-08-23 (sesion 16)

- **PLAN U v2 reescrito tras investigación profunda** (Duolingo/game-design/juice/flow + gamificación devtools — 2 sub-agentes): de 5 a 8 fases con hallazgos medidos
- Añadidos: JUICE checklist por acción core (hit-stop 100ms/squash/partículas-comunican/shake-solo-fallo) · física Linear en cards (-28% fricción NASA-TLX) · celebraciones 1.2s con VARIANTES aleatorias (error de predicción Schultz) · sonido teoría musical tuta (arpegio Do éxito/tritono error) + chime por tipo evento + mute-focused + cooldown · milestones GATED a rareza real (+1.7% retención D7 Duolingo) con COFRES FUNCIONALES (core loop con inversión) · screenshot/demo adjunta por agente (aprobar viendo resultado no diff) · worklog colapsa al éxito (patrón clack) · barra avanza aunque falle · racha con ESCUDO-perdón ganable · heatmap anual relativo al propio máximo (perdona reinicio) · ligas internas pools ~30 · **inbox de resultados anti-spinner** (spinner mata retención @12s; lenguaje "lanzó un run y fue a revisar resultados") · flow-protection agrupa interrupciones · aprobaciones agrupadas en lote (Copilot 7 prompts frustan) · checkpoints nombrados revertibles en hover · session insights timeline verde-roja (Devin) · widget tray 2 DATOS (¿operó hoy?+racha, patrón Duolingo) · onboarding unboxing Arc/Raycast (demo 90s=producción real, tarjeta fundador)
- Anti-patrones reforzados con test ético de incertidumbre y regla SDT triple-presencia

## 2026-08-23 (sesion 17)

- **SDD-009 Debate adversarial de decisiones** (sub-agentes abogados del diablo con investigación 2026):
- DEBATE CLIENTE: caso demoledor contra desktop-first para agentes-centralizados (Lovable $400-500M ARR solo-web; SmartScreen sin reputación=62% completación instalación; WebKitGTK mantenedor "no futuro"; local-first≠desktop-client — privacidad se vende como on-prem del SERVIDOR) → VEREDICTO WEB-FIRST: gateway sirve la React app directamente; tauri-shell diferido a demanda; CLI ligero para repos locales ⚠️ pendiente ratificación usuario
- DEBATE SYNC: mantener delta-sync propio para v0.x (patrón simple genuino) + trigger definido para adoptar PowerSync Open Edition $0 self-hosted si crecen conflictos multi-editor
- DEBATE RUNTIME: Reasonix verificado MIT bundlable + cache-hit 99.82% medido ($12 vs $61 por 435M tokens) → MVP Reasonix-core CON 4 condiciones no negociables (contenedor efímero por sesión SymJack/pin+CI/transcripts JSONL día-1/disparadores OwnLoop) → crecimiento híbrido → escala OwnLoopProvider principal con base OSS mini-swe-agent/OpenHands SDK
- Lección transversal: "harness ES el producto" (todos los competidores verticalizaron); industria estandarizó bordes ACP/App-Server para que la salida sea barata

## 2026-08-23 (sesion 18)

- **G.7 Identidad viva de Skills y Agentes (estilo Gems)**: avatar IA + emoji-firma único + mini-bio de personalidad + voz TTS por skill/agente; ceremonia de NACIMIENTO al crear (overlay "Nace X — bienvenido al equipo"); preview en vivo en el editor; biblioteca de linajes visuales; presencia animada en las 4 ventanas; fallback procedural si IA cae
- AGENTS.md: nuevo principio de EQUIPO VIVO — personajes con identidad IA, manipulación total del equipo como piezas vivas (armar/clonar/promover/pausar/despedir), regla Octocat (jamás hablan por hablar), organización neuro-psicológica por departamento/color

## 2026-08-23

- **SDD-003 Torneo de ideas**: 500 ideas generadas de productos de mercado (25 categorías × 20) → eliminatoria por categoría → 10 debates cruzados documentados → **20 ganadoras** con rúbrica Valor/Viabilidad/Mantenibilidad/Encaje ≥17
- Ganadoras clave base: prefijo estable caché + auto-compacción + dashboard cache_hit (Reasonix real), medidor/debug-view de contexto, cola de mensajes, @menciones, revisión por hunks, consola-preview→agente, blame-rung V3Code, checkpoints reset, golden outputs skills, cuarentena flaky, risk-score, merge train, best-of-N, ⌘K paleta
- Las 480 no ganadoras quedan como backlog vivo re-visible al cerrar cada etapa
- Confirmados los 3 pilares de la BASE: interfaz Codex completa / caché optimizado Reasonix / 6 capas memoria V3Code (mapeo capa→fase explícito en SDD-003)
- Nuevas fases planificadas: C.5, A.5, B.6-B.8, D.7, F.7, H.7-H.8 (+ampliaciones G.4/N.2/I.4) — cada ganadora con sus 4 capas de prueba definidas

- **SDD-001 v3.1 — robo de ideas ganadoras (ronda 2)**: incorporadas a los planes TODAS las ideas no usadas de copia.md + patrones hermanos
- Shadow Workspace (H.5) + bucle auto-corrección silencioso con rungs SELF_FIX y auto-purgado (H.6) — copia.md §Cursor/Capa1
- Fast Apply / escritura especulativa streaming (B.5) — copia.md §Cursor/Morph
- Gobernanza de decisiones varve: proposed→accepted→violated, evidencia obligatoria, scopes file-glob (D.4)
- Índice semántico dual local con sqlite-vec embebido — cero servicios externos, fail-open a FTS5 (D.5)
- Memory router fino + shards temáticos + aging policy + checkpoints git-backed V3Code (D.6)
- Approvals reviewer agéntico auto_review + reglas granulares por prefijo (I.4) — Codex
- Reflect: aprender lecciones de transcripciones pasadas sin LLM (I.5) — codevira
- Tool-gating estricto por rol en skills (G.2) — Cline/RooCode
- Worktrees paralelos por operativo + artefactos SOP tipados viajando por edges (N.2)
- MCP público del cerebro hacia agentes externos (O.2) — V3Code/Zed
- Sección "EL PRODUCTO" en README maestro: el flujo estrella que combina todas las features ganadoras
- Red re-verificada: 112 links entre 16 archivos, 33 anclajes usados / 49 definidos, 0 rotos

- **SDD-001 v3 MEGA-PLAN**: roadmap expandido a 15 etapas (~60 fases) tras investigación profunda de las 3 fuentes
- Investigación V3Code oficial (v3code.dev): memory rail rungs clicables, time scrubber, auto-router visible, checkpoints, agentes en workspace propio paralelo, MCP
- Descubiertos subagentes built-in de Reasonix: explore/research/review/security-review → integrados a etapas 9 (revisión auto) y 14 (empresas)
- Patrones robados a varve/codevira: gobernanza decisiones proposed→accepted, memory_pack con presupuesto tokens, locks content-aware por símbolo, decisions.md commiteado
- Nuevos planes: plan-f canva+oficina (ReactFlow+Animated Beams+Kanban), plan-g skills lab (compilador dialectos incl reasonix subagent), plan-h motor pruebas (sandbox+readiness checks), plan-i revisión auto+superposiciones, plan-j grafo3D repo-map pagerank, plan-k voz (Edge TTS/Web Speech), plan-l sync multi-device+Co-Work CRDT, plan-m GitHub nativo (device flow+PRs+decisions.md), plan-n empresas autónomas (jerarquía+presupuesto+kill-switch+dashboard), plan-o marketplace+v1.0
- README maestro reescrito con mapa 15 etapas, grafo dependencias, estimación global ~19-26 semanas
- Red de referencias verificada: 94 links entre 16 archivos, 16/16 anclajes usados resueltos

- **SDD-006 Investigación profunda con 3 sub-agentes** (KV-cache/cuantización · jerarquías config · memorias CoALA/Mem0/Zep/Letta/HippoRAG)
- C.5 Motor de Contexto y Caché configurable: prefijo estable+warm-up · cuantización KV fp16/fp8/int4/int2 ventana residual 128 · eviction query-aware/sinks/H2O · compresión ninguna/ligera2x/agresiva5x · compacción 70/100/50 · presets POR ROL (PM/QA/dev) — todo en 5 scopes Global→Proyecto→Equipo→Agente→Subagente
- D.8 Motor de memorias multi-tipo CoALA: working/episódica/semántica/relacional-bi-temporal/indexada/procedimental · decay Ebbinghaus λ-por-tipo que rankea sin borrar · scoring relevance3+importance2+recency0.5 tuneable · reflexión por umbral ~150 · escritura auto/explícita/con-aprobación · namespacing anti-leakage
- H.9 ampliado: respaldos de estado POR ROL con retención configurable + guard replay-or-fork anti semantic-rollback (ACRFence) + golden snapshot heredable (N.7)
- A.6 jerarquía completa de 5 scopes: vista de VALOR EFECTIVO con origen (git --show-origin) · reset por capa · merge por tipo de campo · políticas enforced 🔒 · claves prohibidas por nivel — aplicado a TODO lo configurable
- **C.6 OllamaProvider ready-to-plug**: tercer driver local OpenAI-compat localhost:11434 · knobs KV verificados docs v0.32 (f16/q8_0/q4_0 GLOBAL, fallback silencioso advertido por UI) · flash attention 3-estado · presets por hardware GPU/laptop/CPU · embeddings plug-and-play para D.5 — privacidad total/offline/costo cero
- **C.7 Registro universal de proveedores API (patrón OpenCode/models.dev)**: registro declarativo openai-compat|anthropic|google · catálogo models.dev MIT autocompleta 75+ proveedores con precios reales · drivers genéricos cubren todo el mercado sin código nuevo · tarjetas 1-click pegando solo la key + JSON experto · telemetría con precios reales
- **SDD-007 análisis exhaustivo OpenCode** (docs oficiales providers): 14 ideas robadas — /connect unificado con OAuth a SUSCRIPCIONES ya pagadas (ChatGPT Plus/Claude Pro/Copilot device-flow), blacklist/whitelist de modelos por scope, small_model para tareas internas baratas, gateways con headers custom, locales first-class (LM Studio/llama.cpp además de Ollama), lista curada verificada estilo Zen, auth.json separado del config, esquema del registro documentado
- **ADR-005 integrado al roadmap como prerequisito Etapa 1** (workspace Cargo core/tauri-shell/server)
## 2026-08-21

- **RESET COMPLETO** — Migration de Flutter a Tauri (React + Rust)
- Nueva vision: sistema multiagente visual para crear empresas de desarrollo
- Archivado todo lo anterior en `_reciclaje/` (apps, packages, empresa_autonoma, SDDs, ADRs, docs obsoletos, buzz, herdr, build, tools, pubspec, melos)
- Reescrito AGENTS.md completo con nueva vision, stack y roadmap
- Nuevo roadmap en 5 fases (fundacion visual -> skills -> pruebas -> sync -> empresa autonoma)
- Docs que se mantienen: INDEX.md, CHANGELOG.md, ESTADO.md (reescritos para nuevo inicio)
- Actualizado .gitignore para Tauri (antes era Flutter)
- Actualizado .github/workflows/ci.yml para Tauri (npm + cargo test)
- Limpieza de restos de Flutter en raiz (.dart_tool, pubspec, melos, copia.md, plan.md)
- Agregado TypeScript-Go (tsgo) v7.0 como compilador de TypeScript
- Creado package.json con scripts (dev, build, lint, test, typecheck)
- Creado tsconfig.json para TypeScript-Go
- Creado src/index.ts placeholder
- Agregado Biome (lint + format, reemplaza ESLint+Prettier)
- Agregado oxc (parser/linter Rust complementario) → reemplazado por oxlint (CLI disponible)
- Agregado Zustand (estado global, 1KB)
- Agregado TanStack React Query (estado del server)
- Configurado biome.json para React + TypeScript
- Actualizado CI con biome + tsgo
- Actualizado package.json con todos los scripts
- Agregado React 19.2.8 + React DOM
- Agregado Vite 8.2.2 con Rolldown
- Agregado React Compiler via oxc-transform-react (Rust, 10x mas rapido que Babel)
- Agregado @vitejs/plugin-react 6.1.0
- Agregado tauri-specta para IPC type-safe (Rust -> TypeScript bindings)
- Agregado knip para detectar codigo muerto
- Creado vite.config.ts con React Compiler habilitado
- Creado index.html para Vite
- Creado src/ con estructura React (App, stores, hooks, components, types, styles)
- Creado src/stores/app-store.ts con Zustand (agents, tasks, skills)
- Creado src/styles.css con glassmorphism neon
- Creado src-tauri/ con Cargo.toml, lib.rs, main.rs, build.rs
- Creado src-tauri/tauri.conf.json con plugins esenciales
- Creado src-tauri/capabilities/default.json con permisos por ventana
- Configurado tauri-specta para generar bindings TypeScript automaticamente
- Corregido tsconfig.node.json (composite: true para referencias)
- Auto-fix de Biome (imports sorting, formatting)
- Fix de non-null assertion en main.tsx
- Verificacion: tsgo, biome, oxlint todos pasan sin errores
- Creado docs/INFRA.md con resumen de todas las mejoras de infraestructura
- Agregado Playwright E2E testing (@playwright/test v1.62.1)
- Agregado @srsholmes/tauri-playwright v0.4.1 para tests contra webview real
- Agregado tauri-plugin-playwright v0.4 (feature flag e2e-testing)
- Creado e2e/ con playwright.config.ts, fixtures.ts, tests/app.spec.ts
- Configurado 3 modos de testing: browser, tauri, cdp (Windows)
- Agregados scripts test:e2e, test:e2e:ui, test:e2e:chromium, test:e2e:webkit
- Agregado playwright:default a capabilities
- Actualizado INFRA.md con seccion de Skills de opencode (5 skills documentados)
- Actualizado AGENTS.md con flujo SDD obligatorio, fases/prefases, pruebas E2E Playwright CLI simulando clicks/teclado/debug
- Creado ADR-001: Responsive Design y Cross-Platform (decisiones de arquitectura)
- Creado docs/RESPONSIVE.md: guia practica con componentes, hooks y testing
- Agregada regla #7 "Responsive first" a Reglas de trabajo
- Agregada seccion "Diseno responsive" con 9 reglas clave
- Agregadas reglas #8-10: Simpleza, Orden, Sin deuda tecnica (aplican a TODO el proyecto)
- Actualizada seccion "Codigo limpio y ordenado" para enfatizar que aplica a todas las capas (React, Rust, tests, scripts)
- Creado ADR-002: Arquitectura Hibrida Monorepo (un solo codebase, Tauri mobile)
- Creado docs/ARQUITECTURA.md: documento maestro de arquitectura
- Creado packages/shared-types/: tipos TypeScript de dominio (agent, skill, task, canvas, company)
- Creada estructura services/python/ para Python service (CreadAI)
- Creada estructura src-tauri/src/platforms/ para logica por plataforma
- Agregadas 7 reglas de arquitectura a AGENTS.md
- Agregada seccion "Arquitectura hibrida" a INFRA.md
- Creado ADR-003: Voz y Sincronizacion (Web Speech API + Edge TTS + WebSocket)
- Creado ADR-004: Integracion GitHub (OAuth, repos, push/pull, PRs, issues)
- Agregadas features pendientes a AGENTS.md (GitHub, Voz, Sync)
- Actualizado ADR-003: Decision clara de NO implementar P2P/rsync, usar WebSocket + GitHub
- Agregados 3 items a la vision: Git nativo, revision de errores, superposiciones de agentes
- Agregada seccion "Codigo limpio y ordenado" con 6 reglas de orden, 6 de simpleza, anti-patrones y checklist

## 2026-08-21 (sesion 2)

- Agregados recursos de diseno visual en 
eference/ (clones shallow, depth 1):
  - apple-design-skill (dickwu) — auditor HIG multiplataforma (Tauri + Flutter), 53 guias
  - ui-ux-pro-max (nextlevelbuilder) — catalogo de 84 estilos, paletas y tipografia
  - impeccable (pbakaus) — lenguaje anti-estetica-IA-generica (polish, audit, animate)
  - liquid-glass-web (Zettersten) — Liquid Glass CSS/SVG real para el canva
- Nueva seccion "Recursos de diseno visual" en AGENTS.md con rutas y reglas de uso

## 2026-08-21 (sesion 3)

- Eliminada la identidad fija "glassmorphism neon": AGENTS.md ya no prescribe un estilo unico
- Nueva regla en AGENTS.md: la IA decide que skill/estilo usar por tarea (ui-ux-pro-max, impeccable, liquid-glass-web, apple-design-skill) buscando maximo impacto
- Actualizados El diferenciador visual, tabla de stack, Roadmap Fase 1, gate 0.3 en ESTADO.md

## 2026-08-21 (sesion 4)

- Descarga y clonado de artefactos de V3Code (v3code.dev) en `reference/v3code/`
- Análisis e ingeniería inversa de la arquitectura de memoria de 3 capas:
  - Capa 1: Editor Layer & Memory Rail (gutter con tintes de sesión y Human-Tweak Lock)
  - Capa 2: Workspace & Knowledge Graph (índice semántico local y relaciones de código)
  - Capa 3: Chat & Decision Ledger (rungs discretos con time scrubber & replay)
- Descargados componentes interactivos completos (`memory-heatmap.html`, `model-router.html`, `visual-edit.html`, tokens CSS y bundle React)
- Creado `reference/v3code/README.md` con especificación técnica de adopción para Tauri + React + Rust + Python
- Actualizado AGENTS.md con la referencia a V3Code

## 2026-08-21 (sesion 4)

- Clonados en reference/: magic-ui (22k estrellas, 150+ componentes animados con Border Beam / Animated Beam para el canva, incluye skill de agente) y react-bits (46k estrellas, componentes interactivos con skills propios)
- Referenciados ambos en la tabla de Recursos de diseno visual de AGENTS.md

## 2026-08-21 (sesion 5)

- Creación y consolidación del documento maestro `copia.md` sintetizando los mejores IDEs open source y la infraestructura SOTA de IA más avanzada del mundo:
  - **V3Code**: Memoria de 6 capas, carril de memoria en Monaco y Human-Tweak Lock (0 tokens).
  - **Cursor SOTA**: Shadow Workspace (pre-validación invisible en memoria) y Fast Apply / Speculative Diffs (+1.000 tokens/s).
  - **LightRAG & `sqlite-vec`**: RAG de grafo dual (código + arquitectura) con búsqueda vectorial nativa en SQLite embebido sin dependencias externas.
  - **Aider**: Repo-Map AST con Tree-sitter y PageRank (<1.000 tokens) + Dual-Model Mode.
  - **OpenHands**: EventStream pub/sub inmutable para Time-Travel y replay visual.
  - **Cline / Roo Code**: Custom modes por rol y Tool Gating para evitar saturación de prompts.
  - **MetaGPT & ChatDev**: SOPs y línea de montaje de artefactos verificables ("Code = SOP").
  - **DSPy**: Compiladores y optimizadores declarativos de prompts para el Skills Lab.
  - **Zed**: Context Servers over MCP y arquitectura de ultra-baja latencia en Rust.
- Esquema de base de datos SQLite + `sqlite-vec` consolidado en `copia.md` para persistencia en Tauri (`sqlx`).

## 2026-08-21 (sesion 5)

- Creado docs/"referencia de diseno.md": catalogo completo de los 6 skills de diseno instalados (links, estrellas, rutas locales, uso, actualizacion) + evaluados no instalados
- Actualizado INDEX.md con el nuevo documento

## 2026-08-22

- **Sesión servidor Linux headless**: clonado repo en /workspace, deps instaladas, auditoría INFRA completa
- Fix vite.config.ts: minify esbuild→oxc (Vite 8/Rolldown ya no bundla esbuild), __dirname→import.meta.dirname
- Instalado Rust 1.98 + deps sistema Tauri Linux (webkit2gtk-4.1, gtk-3, ayatana-appindicator, rsvg, xdo)
- Fix Cargo.toml: tauri-plugin-playwright deja de ser optional (tauri-build valida permiso playwright:default); runtime sigue gated por feature e2e-testing
- Fix lib.rs: migrado a API real tauri-specta rc25 (collect_commands!, specta_typescript::Typescript, invoke_handler(builder), mount_events en setup)
- Generados iconos Tauri completos (32x32→1024, icns/ico, android/ios) via @tauri-apps/cli icon
- Agregado vitest + vitest.config.ts (scoped src/**, --passWithNoTests) — antes tomaba specs de Playwright
- knip limpio: entry index.html, scope src+e2e, ignore @srsholmes/tauri-playwright (reservado modo tauri)
- Eliminado src/index.ts placeholder vacío; types.ts sin exports internos; removido devDep @vitejs/plugin-react-swc (sin uso)
- Verificación completa verde: typecheck/lint/lint:oxc/knip/vitest/build 198ms/cargo test/E2E chromium 4 passed
- Spike reasonix v1.23.0: default deepseek-v4-flash; modos serve (HTTP+SSE), acp (stdio), run --events-jsonl, task --json confirmados
- **Creado SDD-001-plan-base**: super plan en 5 planes (A chat Codex-core, B sidepanels Lovable, C Reasonix+DeepSeek runtime, D memoria V3Code 3 capas, E integración total) con fases, pruebas y gates verificables
- SDD-001 v2 optimizado tras investigación de las 3 fuentes: mapeo explícito de qué copiar de Codex (2 perillas, diff con feedback, slash commands), Reasonix verificado en vivo (eventos/metrics/trajectory/permisos) y V3Code (artefactos ausentes → fase D.0 restauración)
- Hallazgo clave: ~31k tokens base por run Reasonix ($0.0043 trivial) → enrutamiento por costo (simple→DeepSeekDirect, tools→flash, plan→reasoner); estimación total 4.5-6 semanas
- **Reestructurado SDD-001 a carpeta referenciada**: docs/SDDs/SDD-001-plan-base/ con README maestro + un archivo por plan (plan-a…plan-e), cross-links entre todos
- **Creado SDD-002-testing-spec-driven.md**: sistema de pruebas spec-driven con 4 capas (unit/integración/E2E funcional/E2E humano)
- **Infraestructura Playwright HUMANO**: e2e/playwright.human.config.ts (video siempre, secuencial, desktop+mobile) + e2e/human/human-fixture.ts (h.step con screenshot por paso, humanClick con hover+pausas, humanFill carácter a carácter 40-120ms, humanThink, humanWheel) + 4 suites: boot, create-agent, keyboard-nav, responsive — **12/12 passed** (desktop 1440 + Pixel 7)
- Fix UI real: botón "Crear primer agente" ahora conectado al store (addAgent) — era un botón muerto sin onClick
- Script nuevo: pnpm test:e2e:human · Reglas del SDD-001 actualizadas: cada gate exige suite humana ampliada
- Actualizado ESTADO.md e INDEX.md

- **SDD-005 Cierre Multiplataforma**: multiplataforma pasa de diseño a verificado
  - Entorno Android instalado en servidor (JDK 21, SDK 34 + build-tools + NDK r27 en /opt/android-sdk, 4 targets Rust android) — documentado en docs/MULTIPLATAFORMA.md
  - Proyecto Android nativo generado y VERSIONADO: src-tauri/gen/android/ (gradle wrapper incluido); .gitignore ajustado (solo gen/schemas queda ignorado)
  - CI nuevo job build-desktop: matriz ubuntu/windows/macos con cargo check + build frontend en cada push (DoD 2+ plataformas ahora continuo)
  - Workflow manual "Android Build" (workflow_dispatch): genera APK debug como artefacto sin toolchain local
  - docs/MULTIPLATAFORMA.md: comandos por plataforma; iOS documentado (requiere Mac para ios init)
- **ADR-005 Modelo de Despliegue Dual (ACEPTADO)**: visión "desarrollar desde cualquier dispositivo sin fricción" convertida en decisión arquitectónica
  - D1: refactor a workspace Cargo (crates/core + tauri-shell + server) — el MISMO dominio Rust corre embebido en Tauri Y como binario axum; se ejecuta ANTES de Etapa 1 (~70 líneas hoy, barato ahora, caro después)
  - D2: sqlx como abstracción SQLite(local) ↔ PostgreSQL+RLS(servidor), feature-flag sin forks
  - D3: git de base propio ligero — repos bare vía gitoxide detrás del trait GitService (Plan M), puente GitHub con octocrab; Forgejo queda como opción posterior NO core
  - D4: sesiones resumibles = doc Yrs CRDT + event log; agentes corren en sandboxes Docker server-side y siguen trabajando sin dispositivos conectados
  - D5: stack 100% Rust MIT/Apache (tokio/axum/sqlx/yrs/gitoxide/octocrab/bollard) — comercializable SaaS sin AGPL embebido
  - D6: tres modos de despliegue con un codebase: local-first / self-host docker / cloud multi-tenant futuro
  - Fases mapeadas al roadmap vigente: L nace el servidor, M sirve ambos backends git, N orquesta local vs sandbox
- **ADR-005 D1 EJECUTADO — workspace Cargo**: la flexibilidad "local o nube" ya es propiedad del build
  - crates/core (empresa-dev-core): dominio puro (Agent/Task, sin Tauri ni HTTP) — regla dura documentada en lib.rs
  - src-tauri: shell fino que consume el core; comando draft_agent demuestra fábrica de dominio via core
  - crates/server (empresa-dev-server): binario axum puerto 3030 — /healthz + /api/version + /api/domain/agent-demo sirven el MISMO tipo Agent por HTTP (prueba viva del modelo dual)
  - Cargo.lock movido a raíz; perfiles dev/release al workspace; CI actualizado a cargo test/check --workspace
  - Verificación verde: check/test --workspace ✓ · servidor smoke (healthz/version/agent-demo) ✓ · typecheck/biome/knip/vitest/build ✓ · E2E chromium 4/4 ✓
- **Plan Base README — nueva sección "Cómo funciona la plataforma"**: modelo mental simple del producto (un core tres cuerpos, sesión = doc CRDT + diario, viaje laptop→celular paso a paso, git como memoria, tabla qué-corre-dónde)
