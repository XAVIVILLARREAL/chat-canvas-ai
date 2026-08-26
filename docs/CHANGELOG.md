# CHANGELOG

> Append-only. Cada sesion deja rastro. Nunca editar dias anteriores.

## 2026-08-25 (sesion 35 — Loop humano exhaustivo: 17/17 verdes en temas+i18n+responsive)

- **Pruebas humanas REALES escritas y verdes** (Playwright CLI modo persona, móvil 375 + desktop 1440, video+screenshots por paso):
  - `temas.spec.ts` (✅×2): toggle header, persistencia tras reload, select de Config
  - `idioma.spec.ts` (✅×2): EN sin recargar → persiste → vuelta a ES → select de Config
  - `movil-drawer.spec.ts` (✅ móvil): drawer abre/cierra con toggle, sin desborde
  - Scaffold reescritos al producto actual (obsoletos de la era 'Empresa Dev'): `boot` (✅×2) · `create-agent` (✅×2, con modal NUEVO) · `keyboard-nav` (✅×2, destapó bug a11y real) · `responsive-human` (✅×2)
- **Bugs reales cazados por el loop** (iteraciones con debug en vivo):
  1. React Compiler memoizaba textos i18n (t estable de módulo) → t se crea POR LOCALE en useI18n
  2. Doble drawer: media query apuntaba a .sidebar interno además del aside → scope a .app-sidebar
  3. Tabs del drawer desbordaban (Config en x=569 fuera de pantalla) → flex-wrap en móvil
  4. Lista de agentes no enfocable por teclado → tabIndex=0 (bug a11y real)
  5. Carrera: sidebar arrancaba abierto en móvil → store inicial responsive (innerWidth>=900)
  6. Header bajo toolbar del canvas en móvil → z 1100/1200 coherentes (drawer>header>toolbar)
  7. Dropdown dejaba foco abierto tras seleccionar → blur al elegir
- **Feature nueva funcional**: modal Crear Agente (nombre+rol→store, Enter/Escape, glass-deep)
- **Suite humana completa: 17 passed / 0 failed / 1 skipped (drawer=mobile-only)** · COVERAGE-GUI 82 elementos (8 ✅)

## 2026-08-25 (sesion 34 — Temas dark/light + i18n es/en + responsive móvil FUNCIONALES)

- **Temas dark/light REALES**: tokens light completos (`[data-theme="light"]`, oklch, AA) · toggle sol/luna en Header + select en Config (`src/theme.ts`, persistencia localStorage, modo system sigue al OS) · v2 juice tokenizado (glow/ring/selection/scrollbar/mesh) para que el claro funcione.
- **i18n es/en implementada** (no solo plan): `src/i18n/` hook useI18n + locales JSON + fallback en + detección navigator · Header/Sidebar/Config traducidos · selector idioma en Header.
- **Responsive móvil funcional**: sidebar → drawer superpuesto ≤900px (clase, no inline width) · header compacto · touch targets 44px · sin scroll horizontal (verificado en capturas 375/1440).
- **Fixes funcionales encontrados al probar de verdad**: (1) faltaba ReactFlowProvider → app entera crasheaba en negro; (2) dropdowns del header visibles sin hover; (3) title 'Empresa Dev' stale en index.html; (4) zombie vite de carpeta vieja ocupaba el 1420 (matado).
- **Evidencia**: capturas Playwright 375 dark/light + 1440 dark/light.

## 2026-08-25 (sesion 33 — Ronda 2 de mercado: Buzz local + Claude Code hooks + cola de mensajes)

- **Repos locales analizados**: `/workspace/buzz` (workspace humano+agente sobre relay Nostr, Block) y `/workspace/grok` (= pesos Grok-1, modelo — no agente).
- **Nuevas funciones (F37-F40)**:
  - **F37 Cola de mensajes durante streaming** → A.4b (ya shippeada por Augment/Dyad/Onyx; issue abierto en VS Code)
  - **F38 Hooks de ciclo de vida** (PreToolUse bloquea `rm -rf` ANTES de ejecutar, PostToolUse format, Stop gatea tests — patrón Claude Code "enforcement sin alucinación") → C.11
  - **F39 Presencia e indicadores en vivo** (typing/working, presencia en sala — patrón Buzz Redis presence) → A.12
  - **F40 Reacciones 👍/❌ como rungs del event_stream** (patrón Buzz reacciones-firmadas) → A.12
- Validaciones: memorias por agente, auto-resumen, process-group kill (Buzz) ya cubiertos en D.8/A.8/H.9a.
- MATRIZ → **168 fases** · COVERAGE-GUI → **79 elementos**.

## 2026-08-25 (sesion 32 — Investigación de mercado: F33-F36 + validación del plan)

- **MERCADO-ANALISIS** (`docs/MERCADO-ANALISIS.md`): investigación 2026 (Cursor/Windsurf/Cline/Roo/Devin/Copilot/OpenCode) — tabla de table-stakes vs nuestro estado:
  - **AGREGADAS**: **F33 browser automation** del agente en sandbox (EL diferenciador de Cline) → C.10 · **F34 LSP integration** (diagnósticos reales al contexto, patrón OpenCode) → B.10 · **F35 importar rules files** (.cursorrules/.clinerules/CLAUDE.md→skill) → G.3b · **F36 Slack** en puentes N.8
  - **POST-V1 honesto**: tab-autocomplete FIM (requiere infra propia; patrón Cline = pair con extensión)
  - **VALIDACIONES de mercado**: BYOK total, human-in-the-loop, sandbox por defecto y skills .md son exactamente las tendencias ganadoras 2026
- **MATRIZ** +3 fases (C.10/B.10/G.3b) → **165 fases**; N.8 ampliado con Slack; COVERAGE-GUI +4 filas (75 elementos)

## 2026-08-25 (sesion 31 — Provider de pruebas GRATIS: OpenRouter ox-alpha free $0)

- **Regla free-first en pruebas**: los tests E2E/humanos con LLM REAL corren por defecto contra **OpenRouter `:free`** (p.ej. **ox-alpha free** de opencode — el mismo que OpenCode/Hermes Agent usan gratis) a **$0 ilimitado**; APIs de pago solo para capacidades específicas dentro del presupuesto $20/gate.
- Actualizado: MATRIZ header (regla free-first), plan-c C.7 (provider free por defecto desde C.1), plan-e E.1 (E2E real $0), ACEPTACIÓN-FINAL §0 (DoR incluye provider free), DEV-ENVIRONMENT (setup 5 min + gotchas rate-limit + CI secret opcional).
- **`.env.example`** nuevo: OPENROUTER_API_KEY · CANVAS_TEST_MODEL · VITE_API_BASE · DATABASE_URL/KEK_MASTER (nube).

## 2026-08-25 (sesion 30 — Calidad visual Liquid Glass → VR transversal)

- **SDD-013 §8 — Escalera visual**: L1 Liquid Glass 2D (hoy, MVPs) → L2 Espacial con SpatialMeta (post-v1) → L3 gafas VR/AR. Reglas no negociables por componente (SpatialMeta en unidades-metro, tokens oklch solo, transform/opacity, renderer-agnóstico, Z planificada, contraste AA→AAA) + camino a VR por hitos (F.0 → 3D.1 → J.3 → 3D.2 → WebXR exploratorio).
- **Enforcement automático**: `scripts/check-visual.mjs` + `pnpm test:visual` + job CI — hex hardcodeado y `position:absolute` en canvas no pueden CRECER (baseline: 49 violaciones heredadas del scaffold; la deuda solo baja; `--update-baseline` tras arreglar).
- **Alineación total**: AGENTS.md (VR-ready apunta a SDD-013 §8), README maestro (sección VR-ready), MATRIZ header (Liquid Glass + escalera §8 + test:visual).

## 2026-08-25 (sesion 29 — Tarjeta de Fase canónica + micro-mejoras F29-F32)

- **Tarjeta de Fase** (SDD-002 v4.1): formato canónico que separa **Resultado esperado (observable)** de las pruebas por capa [U/I/E/H] + gate + riesgos + estimación. Obligatoria en el DoR (MATRIZ header). Responde: "¿las fases aclaran los resultados esperados y las pruebas de calidad?" — ahora sí, con contrato explícito por fase.
- **TARJETAS-ETAPA-0** (`docs/TARJETAS-ETAPA-0.md`): las 9 fases de la Fundación en tarjetas completas (0.1-0.8 + cierre M0), con capas N/A justificadas, riesgos y estimaciones reales.
- **Hallazgo de estimación**: Etapa 0 era 15-20h → realista **25-35 h paralelo / 42-56 h secuencial**; MVP-ROADMAP corregido con regla "si tarda 2× se parte en slices".
- **Micro-mejoras aprobadas (F29-F32)**: pin/favoritos · modo enfoque zen · acciones masivas · rutinas programadas visibles — viajan dentro de fases existentes; COVERAGE-GUI +4 filas (71 elementos).

## 2026-08-25 (sesion 28 — Análisis de funciones del producto: +12 funciones F17-F28)

- **FEATURE-BACKLOG** (`docs/FEATURE-BACKLOG.md`): análisis completo de qué funciones agregar — contra competidores (Cursor/Cline/n8n/Lovable) y los 7 diferenciadores:
  - **AGREGADAS (12)**: tools web nativas (web_search/fetch con allowlist) · visión multimodal (screenshot→fix, PDF) · comparador A/B de modelos · compartir entrega pública read-only (alimenta KPI growth SDD-010 — ¡no existía!) · puentes WhatsApp/Telegram/Discord (killer del tier Pro) · quick capture global · dashboard personal uso/costos · forecast costo pre-envío · import ChatGPT/Claude · papelera+restaurar · perfiles BYOK · export sesión PDF/MD
  - **POST-V1**: extensión navegador, email/calendario nativo, multi-cursor, fine-tuning local
  - **RECHAZADAS con razón**: chat social, cuenta obligatoria en local, cobrar por tokens, editor generativo, sync P2P blockchain
- **MATRIZ** +5 fases: **A.10** (comparador), **C.8** (tools web), **C.9** (visión), **N.8** (puentes), **O.4** (share público) → total **154 fases**
- **PRD §6**: tabla F17-F28 con resultado medible humano por función; **COVERAGE-GUI** +12 filas (64 elementos totales)

## 2026-08-25 (sesion 27 — Aumento + optimización lógica del plan)

- **GLOSARIO** (`docs/GLOSARIO.md`): terminología canónica (sesión, skill, rung, entrega, gate, slice, BYOK, deploy-spec, DoR/DoD, north-star…) + **anti-glosario** (no usar "empresa autónoma", "tenants en local", "compila").
- **INDEX reestructurado en 6 niveles lógicos**: 1 Producto → 2 Arquitectura → 3 Plan/Ejecución → 4 Calidad/Ops → 5 Lanzamiento/Contribución → 6 Estado/Meta.
- **README maestro v3.1**: sección **"Cómo usar este plan"** (orden de lectura en 7 pasos), **Definition of Ready/Done** como checklists, **Milestone M0** (primera entrega verificable: Etapa 0 completa).
- **ETAPA-0-IMPLEMENTACION** (`docs/ETAPA-0-IMPLEMENTACION.md`): la Etapa 0 en **9 slices accionables** (0.0-0.8) con tests por slice, mini-gates y presupuesto $0 — listo para arrancar con el loop agéntico.
- **MVP-ROADMAP**: tabla de **estimación de esfuerzo** por MVP (horas orientativas) + regla de slices si una fase tarda 2× su estimación.
- **EJECUCION-ORDEN**: DoR (antes de empezar) y DoD (para cerrar) formalizados + milestone M0.

## 2026-08-25 (sesion 26 — Cobertura GUI 100% + loop agéntico con sub-agentes en paralelo)

- **REGLA DURA COBERTURA GUI 100%** (AGENTS.md + SDD-002 + MATRIZ): todo botón, función y feature tiene su prueba **Playwright humano (clicks+teclado)** — sin prueba = la feature NO existe; un botón nuevo sin su prueba = PR rechazado.
- **COVERAGE-GUI** (`docs/COVERAGE-GUI.md`): tabla maestra que mapea **cada elemento interactivo → su test humano**, ≥50 elementos en los 3 MVPs (AppShell, chat, config, providers, editor, skills, memoria, kanban, oficina, automatización, nube, sync, github, marketplace, GDPR). Fila `⬜→✅` = gate.
- **WORKFLOW-AGENTICO** (`docs/WORKFLOW-AGENTICO.md`): loop obligatorio por fase **ANALYZE (5 sub-agentes en paralelo: spec/tests/riesgo/seguridad/UX) → DECIDE → MODIFY (TDD humano) → TEST (Playwright humano + debug en tiempo real con consola/red) → ITERATE (máx 5) → DECIDE**. Sub-agentes en paralelo en TODO el plan (gates, refactors, post-mortems, PRs).
- **Enfoque en resultados funcionales**: "done" = el humano opera la feature y obtiene el resultado (video en `evidence/`); compilar NO es done. Definición formalizada en AGENTS.md, SDD-002, CONTRIBUTING y WORKFLOW-AGENTICO.
- **CONTRIBUTING** actualizado: checklist de feature incluye fila de COVERAGE-GUI + ANALYZE paralelo + evidencia humana.

## 2026-08-25 (sesion 25 — Auditoría completa del plan)

- **Auditoría exhaustiva** del plan → se arreglaron/cerraron los huecos encontrados:
- **23 links rotos** en la documentación (rutas relativas mal calculadas en DEV-ENVIRONMENT/PLATAFORMAS-TARGETS/SDD-010/SDD-003/SDD-004/SDD-007/plan-a/c/l/n/s + SECURITY) y un nombre stale `plan-m-voz-texto.md`→`plan-m-github.md`. Verificador automático: **0 rotos**.
- **Código sin rastros "empresa"**: `src-tauri/src/lib.rs` greet → "Canvas AI"; proyecto Android re-empaquetado `com.empresa_dev.app` → `com.canvas.ai.app` (namespace, applicationId, manifest package, themes, MainActivity movido a `com/canvas/ai/app/`). (El `empresa-dev-server` del smoke era un server zombie de la carpeta vieja en :3030.)
- **Docs nuevos** (cierran huecos que faltaban para "profesional real"):
  - `AUTH.md` — aclaración clave: **local SIN cuenta/login** (dueño de tu máquina) vs **nube con cuenta+sesión+RLS fail-closed** + flujo y anti-patrones
  - `API.md` — inventario REST canónico (~40 endpoints por recurso) + convenciones (versionado v1, errores, SSE, auth)
  - `DATA-LIFECYCLE.md` — migraciones sqlx (up/down, rollback vía backup), backup/restore con RPO, GDPR (acceso/portabilidad/erasure/retención) con endpoint por derecho
  - `FEATURE-FLAGS.md` — mapa centralizado de flags (tiers pricing + dark-launch de features arriesgadas), enforcement server-side, bundle Free sin código Pro
  - `UX-STANDARDS.md` — atajos de teclado, estados de UI obligatorios (carga/vacío/error/offline/streaming/saving), ayuda in-app, anti-patrones
  - `EJECUCION-ORDEN.md` — checklist de construcción en orden exacto fase por fase hasta v1.0 (navegación del plan)
  - `PRODUCT-METRICS` +observabilidad del cliente (error tracking opt-in, ErrorBoundary, alertas nube)

## 2026-08-25 (sesion 24 — Matriz de targets por plataforma: servidor + clientes)

- **PLATAFORMAS-TARGETS** (`docs/PLATAFORMAS-TARGETS.md`): matriz canónica "**qué se instala dónde**" — responde la duda de arquitectura: el plan construye **AMBOS**, el **servidor Linux 24/7** (gateway axum + workers + Postgres+RLS + sandbox, Docker+runbook) Y los **clientes instalables**:
  - Windows `.msi`/`.exe` · macOS `.app`/`.dmg` universal notarizado · Linux `.AppImage`/`.deb`/`.rpm` (CI build-desktop 3 SO ✅)
  - **Android** `.apk`/`.aab` (gen/android versionado ✅ · release Play Store en MP.3)
  - **iOS** `.ipa` — 🔲 **faltante real detectado**: `gen/apple` no existe; requiere `tauri ios init` en un Mac (MP.2)
  - Web/PWA (SPA por gateway)
- **Etapa 10 del plan maestro** reescrita con tabla de entregables por destino; **ARQUITECTURA** "Plataformas soportadas" → tabla completa con artefacto+estado; **MATRIZ +Etapa 10 (MP.1-MP.6)** (total 149 fases); **plan-s S.3**: móvil es familia local-first (no "fase 2"); **MVP-ROADMAP**: targets de entrega en MVP-3.
- **release.yml** ampliado: jobs Windows y macOS universales además de Linux (los 3 desktops publican en GitHub Releases por tag v*); Android via android-build.yml; iOS vía App Store Connect (MP.2).

## 2026-08-25 (sesion 23 — Profesionalización + diferenciadores + fix de usabilidad)

- **Fix de usabilidad real:** el frontend NO conectaba con su backend en dev (llamaba `/api/*` sin proxy y con base hardcodeada). Añadido **proxy Vite `/api`→`http://127.0.0.1:3030`** + **`VITE_API_BASE`** env en `useApi` y `canvas-store`. Ahora la app se corre end-to-end (frontend ↔ gateway Rust).
- **PRODUCT-DIFFERENTIATORS** (`docs/PRODUCT-DIFFERENTIATORS.md`): los **7 diferenciadores** que hacen el producto "increíble" (evidence-first, memory rail+time-scrubber, local-first+BYOK, skills-personaje, canvas multi-runtime, shadow workspace, humano en el centro) + regla "si no alimenta uno de los 7 → backlog".
- **SLO-RELIABILITY** (`docs/SLO-RELIABILITY.md`): TTFT <1s, streaming ≥30 tok/s, arranque <2s, uptime nube 99.9%, RTO ≤1h / RPO ≤15min, error budget, post-mortems.
- **PERFORMANCE-BUDGETS** (`docs/PERFORMANCE-BUDGETS.md`): bundle <250KB, Monaco/ReactFlow lazy, 60fps canvas 100 nodos, reglas anti-lag, CI de budgets.
- **PRICING-TIERS** (`docs/PRICING-TIERS.md`): Free local $0 (BYOK) / Pro $29 (nube 24/7) / Teams $99 (5 usuarios); BYOK en todos; flags desde v1; free-tier de nube 10h.
- **LAUNCH-CHECKLIST** (`docs/LAUNCH-CHECKLIST.md`): distribución (Releases + auto-update firmado + brew/winget), feedback loop (botón in-app + NPS + triage), legal, growth, post-launch 30d.
- **DEV-ENVIRONMENT** (`docs/DEV-ENVIRONMENT.md`): 3 comandos para correr el stack (gateway :3030 + vite :1420 proxy) + stack objetivo + gotchas.
- **Repo profesionalizado:** `SECURITY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `.editorconfig`, plantillas GitHub (bug/feature y PR), workflow `release.yml` (Releases por tag v*).
- **Consistencia:** INFRA.md y ADR-002 realineados a ADR-006 (local-first, adiós "web-first"); ARQUITECTURA "web-first"→"nube de pago"; scope "Equipo"→"Sesión" en plan-c.

## 2026-08-25 (sesion 22 — Capa de producto profesional)

- **PRD v1.0** (`docs/PRD.md`): producto primero — 4 personas + JTBD por vista + 16 features (MVP-1/2/3) cada una con **resultado medible Playwright humano** (clicks+teclado) · anti-scope explícito · riesgos top 5
- **PRODUCT-METRICS** (`docs/PRODUCT-METRICS.md`): north-star **"sesiones que terminan en ENTREGA"** canónica · activación/retención D7/costo-por-entrega · **10 eventos de producto** al `event_stream` desde v0 · telemetría OPT-IN anónima (local-first: se recopila en el dispositivo, el usuario decide exportar)
- **MVP-ROADMAP** (`docs/MVP-ROADMAP.md`): MVP-1 (semanas 1-6, base operativa) → MVP-2 (7-14, memoria+skills+resultados) → MVP-3 (15-24, automatización+nube+mercado) · gate humano por MVP · riesgos y presupuesto $20/gate
- **SCHEMA-MAESTRO** (`docs/SCHEMA-MAESTRO.md`): Etapa 0 **concretada** — DDL canónico (projects/sessions/messages/event_stream/skills+versions/providers/documents/executions/settings), migraciones versionadas, taxonomía de rungs, OpenAPI del gateway
- **CONTRATO-SKILL** (`docs/CONTRATO-SKILL.md`): frontmatter `.md` exacto (name/slug/role/model_tier/budget/tools_allowlist/personality…) con ejemplo real + 8 roles + tipos (agente/expert/proceso/flujo)
- **THREAT-MODEL** (`docs/THREAT-MODEL.md`): amenazas por capa (cliente/sandbox/gateway) + **frontera numérica del sandbox Linux** (CPU 1 · RAM 512MB · disco 1GB · pids 128 · timeout 60s · red off · mounts read-only) + **flujo BYOK** (keychain local / envelope AES-GCM por tenant)
- **plan-i18n** (`docs/SDDs/SDD-001-plan-base/plan-i18n.md`): **multilenguaje simple desde el día 1** — diccionarios JSON + hook `useI18n`, 6 idiomas iniciales (es/en/pt/de/fr/it), fallback a `en`, RTL-ready, script CI de claves faltantes
- **plan-a realineado a A.0-A.9** (BYOK, "projects como scope" — adiós fantasma "tenants", circuit breaker, backup integral) · **plan-s realineado a ADR-006** (Tauri = producto base, no "diferido") · **MATRIZ**: +Etapa 0 (0.1-0.6), A.0 renombrada, post-v1 marcado (Q6: Consejo/Voz/3D/CR/Dopamina)

## 2026-08-25 (sesion 21 — Visión híbrida ADR-006)

- **ADR-006 APROBADO — VISIÓN HÍBRIDA (Q1-Q12)**: local-first gratis (BYOK, Tauri+SQLite) como PRODUCTO BASE + nube SaaS multi-tenant DE PAGO para ejecución 24/7 (Postgres+RLS + workers Linux). Solo en la nube quien la pague. Documento canónico: `docs/ADRs/ADR-006-vision-hibrida-local-nube.md`
- **FANTASMA "EMPRESA AUTÓNOMA" ELIMINADO del código**: `AgentTeam`/`TeamMember`/`TeamHierarchy`/`CommunicationProtocol` (crates/core/domain.rs), ruta `/api/teams/*` + `AppState.teams` (crates/server), `Company` (packages/shared-types), `teams` en store/Sidebar/useApi/App (frontend). Build TS + cargo verdes.
- **BYOK (trae tu API key, modelo Hermes Agent)**: registro universal de proveedores; local → keychain del OS (keyring); nube → cifrado por tenant (envelope AES-GCM). Nada en claro.
- **Skills = documentos `.md`** (recetas con personalidad, nombre y cara animada); editor visual compila a `.md` sin YAML manual.
- **Sandbox Linux (patrón GrokBot)**: agentes/código corren en contenedor Ubuntu — red denegada por defecto, allowlist, timeout, kill limpio.
- **Plan Maestro v3.0**: nueva **Etapa 0 (Fundación)** — schema maestro + migraciones, contrato `event_stream`, secretos BYOK, sandbox Linux, persistencia real (hoy el server vive en `HashMap`). Voz/3D/Consejo de Expertos/dopamina → etapas finales (post-v1).
- **Higiene**: `package.json` → `canvas-ai`; README.md raíz + LICENSE (MIT) añadidos; ARQUITECTURA v5.0 reconciliada (local-first principal, nube de pago); MATRIZ Etapa 14 y plan-n sincronizados (N.7 modo nube 24/7); SDD-010 ratificado (local gratis + nube suscripción).

## 2026-08-24 (sesion 20)

- **BLINDAJE DE PRUEBAS v3.10 (aditivo)**: SDD-002 ampliado con contrato de pruebas por fase (criterios de negocio 1:1 con sus pruebas, chaos en I/O, E2E transversal por etapa en cada gate), regla de fases manejables por prompt (slices X.1a/X.1b con mini-gate; lista de fases grandes que siempre se parten: A.4/C.7/D.8/F.0/H.9b/N.2/N.6/VI.6/CR.1-3) y gate de deuda por fase (knip/clippy/biome, 0 TODOs, cobertura, suites históricas, evidencia); README reglas 14-16; matriz con las reglas en el header — sin quitar nada
- **ANÁLISIS FINAL v3.10**: VI.8 (Discovery Hub) absorbida y totales unificados (137 fases: 114 base + 23 intermedio); header/tabla (filas Etapas 16–19)/ORDEN alineados; secciones de revisión reordenadas cronológicamente; A.4↔V.2 aclarado (aprobaciones de opciones nativas en Etapa 1, V.2 unifica con el Consejo + pulido SDD-013); ESTADO.md a v3.10 con siguiente paso ordenado (schema maestro → mini-SDD PLAN A → A.1)
- **GUI v3.9 — Spec visual "Obsidian Glass" (SDD-013) integrada y fundida en el plan**: tokens oklch + Liquid Glass 4 capas + motion neuro + sonido por teoría musical + componentes (GlassCard/AgentNode/AnimatedBeam/Toast/⌘K) + checklist §7; implementación en src/styles.css; FUSIÓN completa: README (fuente canónica + revisión v3.9), matriz (regla "toda UI usa SDD-013; CSS improvisado prohibido" + F.0), PLAN V (colores de identidad de §1.1, AgentNode), K.3 (sonidos §5.3 canónicos), T.A11Y (contraste + checklist §7), A.4 (superficie chat con GlassCard); título/refs SDD-011→SDD-013 corregidos; 0 anclas rotas
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
