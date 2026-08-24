# AGENTS.md — Empresa Dev (Tauri + multiagente visual)

> Guia de trabajo para los agentes en este proyecto. Leer antes de tocar codigo.

## Que es este proyecto

Un **entorno de desarrollo agenteico visual** hecho en **Tauri** (React + Rust): un sistema multiagente donde los usuarios crean **empresas de desarrollo de programacion** completas usando agentes de IA basados en skills, con un canva visual como interfaz principal. No es un editor de codigo — es una **fabrica visual de empresas de desarrollo** donde los agentes trabajan, prueban y entregan resultados.

- **Idea rectora:** *Crear empresas de desarrollo autonomas visualmente, donde los agentes son empleados que trabajan por resultados y pruebas, no por codigo.*
- **Documentacion:** `docs/INDEX.md` — mapa completo de todos los .md del proyecto.
- **Estado actual:** `docs/ESTADO.md` — donde estamos ahora (corto, autoadministrado).
- **Historial:** `docs/CHANGELOG.md` — append-only, cada sesion deja rastro.

## La vision

### Producto principal

Un sistema donde puedes:

1. **Crear una empresa de desarrollo** — armas un equipo de agentes IA con roles (dev, QA, reviewer, PM, devops), cada uno con skills especializados
2. **Visualizar la oficina** — canva animado estilo juego donde ves a los agentes trabajando en tiempo real
3. **Crear agentes con skills** — editor visual de skills (sin YAML), laboratorio para probarlos, exportar a cualquier dialecto (opencode, Cursor, Claude Code)
4. **Trabajar por resultados** — los agentes ejecutan tareas, corren pruebas, entregan diffs; tu apruebas o rechazas
5. **Sincronizar entre dispositivos** — celular, desktop, y a futuro gafas de RA; continuar donde dejaste
6. **Comunicarte con voz** — hablar con los agentes, que te respondan con TTS
7. **Detectar actividad** — sonidos/notificaciones cuando un agente deja de trabajar o necesita aprobacion
8. **Git nativo en la app** — push, pull, branches, pull requests todo desde la interfaz visual, sin terminal
9. **Revision de errores** — el sistema detecta errores automaticamente y los asigna al agente correcto para su arreglo
10. **Superposiciones de agentes** — cuando un agente falla, otro agente puede superponerse y tomar control de la tarea

### El diferenciador visual

- **Identidad visual dirigida por IA** — la IA elige estilo y recursos visuales (ver Recursos de diseno visual) buscando el maximo impacto en cada pantalla
- **Oficina animada** — agentes como personajes con estados visibles (trabajando, bloqueado, esperando)
- **Canva interactivo** — nodos, conexiones, zoom, drag-and-drop, minimap
- **Grafo 3D** — visualizacion de relaciones entre archivos, imports, llamadas
- **Facil de usar** — disenado para crear sistemas complejos sin escribir codigo de configuracion

### El enfoque: pruebas y resultados, no codigo

Los agentes no solo escriben codigo — **prueban y demuestran resultados**:

- Cada tarea tiene criterios de aceptacion verificables
- Los agentes corren pruebas automaticamente
- Los resultados se muestran en el canva (pass/fail, cobertura, diffs)
- El humano aprueba basado en evidencia, no en codigo
- Las empresas se construyen sobre ciclos de: **plan -> implementar -> probar -> aprobar -> entregar**

## Stack tecnologico

| Capa | Tecnologia | Por que |
|---|---|---|
| Framework | **Tauri 2.0** | Rust backend + web frontend, bundles chicos, seguridad |
| Frontend | **React 19.2 + TypeScript** | Ecosistema enorme, React Compiler, hooks modernos |
| Bundler | **Vite 8 (Rolldown)** | 10-30x mas rapido que Rollup, un solo bundler Rust |
| TS Compiler | **TypeScript-Go (tsgo)** | 10-100x mas rapido que tsc, TypeScript 7 nativo en Go |
| React Compiler | **Oxc Transform** | Memorizacion automatica, 10x mas rapido que Babel |
| IPC type-safe | **tauri-specta** | Genera bindings TypeScript desde comandos Rust |
| Lint + Format | **Biome** | Rust-based, 10-35x mas rapido que ESLint+Prettier |
| Lint adicional | **oxlint** | Parser/linter Rust ultra-rapido, reglas complementarias |
| Codigo muerto | **knip** | Detecta imports, funciones y tipos no usados |
| Estado global | **Zustand** | 1KB, sin boilerplate, DevTools, persistencia via plugin |
| Estado server | **TanStack React Query** | Caching, reintentos, loading states automaticos |
| Estilos | **CSS moderno + TailwindCSS** | Container queries, :has(), nesting; el estilo lo define la IA con skills de diseno |
| Editor | **Monaco Editor** | VS Code editor, LSP nativo, 100+ lenguajes |
| Canva 2D | **ReactFlow** | Nodos, edges, zoom, drag-and-drop, minimap |
| Canva 3D | **Three.js** | Grafo del proyecto, visualizacion de relaciones |
| Backend | **Rust (Tauri)** | Hub server, DB, filesystem, seguridad |
| DB local | **SQLite (sqlx)** | Persistencia rapida y segura |
| Persistencia UI | **tauri-plugin-store** | Store nativo JSON, persiste estado del canva/config |
| Agentes | **Python (CrewAI + LangGraph)** | Orquestacion de agentes, grafos de estado |
| Voz | **Web Speech API + TTS** | STT nativo del browser, TTS via API |
| Comunicacion | **WebSocket** | Real-time con Python service (agentes) |
| Notificaciones | **tauri-plugin-notification** | Sonidos + notificaciones nativas |
| Testing E2E | **Playwright + tauri-plugin-playwright** | Tests E2E en CI, Chromium + WebKit, modo Tauri real |

## Arquitectura

```
+-----------------------------------------------------+
|               FRONTEND (React + TypeScript)          |
|                                                     |
|  +-------------+ +----------+ +------------------+ |
|  | Canva 2D/3D | | Editor   | | Panel de agentes | |
|  | ReactFlow   | | Monaco   | | (estados, voz)   | |
|  | Three.js    | | LSP      | |                  | |
|  +-------------+ +----------+ +------------------+ |
|  +-------------+ +----------+ +------------------+ |
|  | Skills Lab  | | Tablero  | | Chat con agentes | |
|  | (crear,     | | Kanban   | | (voz + texto)    | |
|  |  probar)    | |          | |                  | |
|  +-------------+ +----------+ +------------------+ |
+----------------------|------------------------------+
                       | IPC (Tauri commands)
+----------------------|------------------------------+
|               BACKEND RUST                           |
|                                                     |
|  +----------+ +----------+ +----------------------+|
|  | Hub      | | SQLite   | | Filesystem +         ||
|  | Server   | | (sqlx)   | | Procesos del SO      ||
|  | (axum)   | |          | |                      ||
|  +----------+ +----------+ +----------------------+|
|  +----------+ +----------+ +----------------------+|
|  | Seguridad| | Sync multi-device                ||
|  | (crypto) | | (WebSocket)                      ||
|  +----------+ +----------------------------------+|
+----------------------|------------------------------+
                       | WebSocket / HTTP
+----------------------|------------------------------+
|            CEREBRO (Python, separado)                |
|                                                     |
|  +----------+ +----------+ +----------------------+|
|  | LangGraph| | CrewAI   | | MCP Server           ||
|  | (grafos) | | (crews)  | | (herramientas)       ||
|  +----------+ +----------+ +----------------------+|
|  +----------+ +----------+ +----------------------+|
|  | Skills   | | Memoria  | | Checkpoints          ||
|  | engine   | | agente   | | (persistencia)       ||
|  +----------+ +----------+ +----------------------+|
+-----------------------------------------------------+
```

## Recursos de diseno visual (reference/)

Skills y guias de diseno clonadas localmente para dar identidad grafica al proyecto. Consultar antes de tocar UI.

| Recurso | Ruta | Uso |
|---|---|---|
| **apple-design-skill** (dickwu) | `reference/apple-design-skill/SKILL.md` | Auditor UI/UX basado en Apple HIG, multiplataforma (Tauri + Flutter). 53 guias en `references/hig/` (color, tipografia, accesibilidad, dark mode, glassmorphism) |
| **ui-ux-pro-max** | `reference/ui-ux-pro-max/` | Catalogo de estilos: 84 estilos (glassmorphism, claymorphism, brutalismo...), 192 paletas, 74 pares tipograficos, 98 reglas UX. Skills en `cli/assets/skills/` |
| **impeccable** (pbakaus) | `reference/impeccable/plugin/skills/impeccable/SKILL.md` | Lenguaje anti-"estetica IA generica": tipografia, color, motion, spatial. Comandos: polish, audit, critique, animate |
| **liquid-glass-web** (Zettersten) | `reference/liquid-glass-web/skills/liquid-glass/SKILL.md` | Liquid Glass real en web: CSS `backdrop-filter` + SVG `feDisplacementMap`, plantillas React para el canva |
| **magic-ui** | `reference/magic-ui/skills/magic-ui/SKILL.md` | 150+ componentes animados React+Tailwind+Motion: Border Beam / Shine Border (bordes iluminados), Animated Beam (aristas de luz entre nodos del canva), meteors, particles, aurora text, shimmer button |
| **react-bits** | `reference/react-bits/AGENTS/SKILLS/` | Componentes interactivos de alto impacto: Spotlight Cards, Click Spark, fondos Silk/Aurora, Blur Text. Skills propios para encontrar/mejorar animaciones |
| **v3code** | `reference/v3code/README.md` | Arquitectura de 3 capas de memoria, Memory Rail (centipede), gutter de atribucion, auto model router y Human-Tweak Lock |

### Como elegir (decide la IA)

1. **La IA elige el skill y el estilo visual** segun la tarea, buscando siempre el resultado mas impresionante — no hay identidad fija predefinida
2. Puede combinar recursos: `ui-ux-pro-max` para elegir estilo + paleta + tipografia, `impeccable` para pulir y evitar la estetica generica de IA, `liquid-glass-web` para efectos de vidrio en el canva, `apple-design-skill` para auditar contraste/accesibilidad antes de entregar
3. Evitar mezclar dos estilos prescriptivos contradictorios en la misma pantalla
4. Criterio final intransferible: jerarquia clara, contraste WCAG AA, motion con proposito, coherencia entre pantallas
5. Actualizar con `git pull` dentro de cada carpeta (son clones shallow)

## Reglas de trabajo

1. **SDD por feature** — antes de implementar, escribir el diseno (objetivo, flujo, contratos, tests)
2. **TDD** — primero el test que falla, despues el codigo que lo pasa
3. **CI desde dia 1** — `pnpm typecheck` (tsgo) + `pnpm test` + `cargo test`
4. **Gate por fase** — cada fase tiene su verificacion; una fase no se cierra sin pasar su gate
5. **Definition of Done** — tests verdes + probado en 2 plataformas + gate cumplido
6. Max 3 intentos por error antes de escalar al humano
7. **Responsive first** — toda UI se disena mobile-first, despues se adapta a desktop (ver ADR-001 + RESPONSIVE.md)
8. **Simpleza ante todo** — no sobrecomplicar; si una solucion tiene mas de 3 pasos, buscar una mas simple (TODO el proyecto: React, Rust, tests, scripts)
9. **Orden en codigo** — mantener estructura logica: imports ordenados, archivos por responsabilidad, carpetas por dominio (TODO el proyecto)
10. **Sin deuda tecnica** — no hacer "fix temporal"; si se detecta, documentar y arreglar antes de continuar (TODO el proyecto)

## Arquitectura (siempre se sigue)

**Una sola arquitectura para todo el proyecto.** No hay versiones separadas ni codebases duplicados.

### Capas

| Capa | Ubicacion | Tecnologia | Responsabilidad |
|---|---|---|---|
| Frontend | `src/` | React + TypeScript | UI compartida (desktop + mobile) |
| Backend Local | `src-tauri/` | Rust | Tauri commands, SQLite, seguridad |
| Backend Server | `services/python/` | Python + FastAPI | CrewAI, LangGraph, orquestacion |
| Shared Types | `packages/shared-types/` | TypeScript | Tipos de dominio compartidos |

### Reglas de arquitectura

1. **Un solo frontend** — todo React va en `src/`, no hay `src-desktop/` ni `src-mobile/`
2. **Adaptacion via codigo** — usar `useResponsive()` para cambiar comportamiento, no archivos separados
3. **Python aislado** — nunca mezclar Python con Node.js o Rust en la misma carpeta
4. **Shared types** — los tipos de dominio van en `packages/shared-types/`, no duplicar
5. **Platform-specific** — logica especifica de plataforma en `src-tauri/src/platforms/`
6. **IPC para frontend-backend** — comunicacion via comandos Tauri, no imports directos
7. **WS/HTTP para server** — comunicacion con Python via WebSocket o HTTP, no IPC

### Documentacion

- **ADR-002:** `docs/ADRs/ADR-002-arquitectura-hibrida.md` — decisiones de arquitectura
- **ARQUITECTURA.md:** `docs/ARQUITECTURA.md` — diagramas, estructura, reglas

## Codigo limpio y ordenado (siempre se sigue — TODO el proyecto)

**El codigo debe ser legible, predecible y mantenible en TODAS las capas:** React, Rust, TypeScript, tests, scripts, configs. Si otro agente o humano lo abre, debe entenderlo en minutos, no horas. No hay excepciones por "ser solo un script" o "ser temporal".

### Reglas de orden

1. **Una responsabilidad por archivo** — un componente, un hook, un utilitario
2. **Imports ordenados** — primero externos (react, zustand), despues internos (@/components, @/hooks)
3. **Carpetas por dominio** — no por tipo (no `components/`, `hooks/`; si `canva/`, `agents/`, `skills/`)
4. **Nombres descriptivos** — `useCanvasZoom` no `useHelper2`; `AgentCard` no `Card`
5. **Funciones pequenas** — maximo 50 lineas por funcion; si es mas grande, dividir
6. **Constantes arriba** — valores magicos no existen; siempre `const MAX_AGENTS = 10`

### Estructura de carpetas

```
src/
  components/
    layout/       — AppShell, Header, Sidebar, BottomNav
    canvas/       — ReactFlow, nodos, edges
    agents/       — AgentCard, AgentPanel
    skills/       — SkillCard, SkillEditor
    ui/           — Button, Input, Modal (generics)
  hooks/
    useResponsive.ts
    useCanvas.ts
    useAgents.ts
  stores/
    app-store.ts
  utils/
    format.ts
    validate.ts
  types/
    agent.ts
    skill.ts
    canvas.ts
```

### Reglas de simpleza

1. **No abstractar prematuramente** — si solo se usa una vez, no crear abstraccion
2. **No crear wrappers inutiles** — si TailwindCSS ya hace algo, no envolverlo
3. **No over-engineering** — un `if` simple es mejor que un patron de diseno con 5 archivos
4. **Config > Codigo** — preferir configuracion flexible sobre codigo rigido
5. **Features no son capas** — no crear `features/canvas/CanvasContainer/CanvasPresenter/`
6. **YAGNI** — You Ain't Gonna Need It; no construir para "futuro" que no existe

### Anti-patrones a evitar

| Mal | Bien | Por que |
|---|---|---|
| `utils/helpers.ts` con 200 lineas | `utils/format.ts`, `utils/validate.ts` | Responsabilidad unica |
| `components/` con 50 archivos | `components/canva/`, `components/agents/` | Organizacion por dominio |
| `handleClick`, `handleClick2`, `handleClick3` | `handleAgentClick`, `handleSkillClick` | Nombres descriptivos |
| `any` en tipos | Tipo especifico o `unknown` | Type safety |
| `// TODO: arreglar despues` | Arreglar ahora o documentar en SDD | Sin deuda tecnica |
| Copy-paste de 100 lineas | Extraer a funcion compartida | DRY |
| `useEffect` con 10 dependencias | Dividir en efectos mas pequenos | Mantenibilidad |

### Checklist de orden (antes de PR)

- [ ] Archivos en carpetas correctas por dominio
- [ ] Imports ordenados (externos primero, internos despues)
- [ ] Funciones < 50 lineas
- [ ] Sin valores magicos (constantes extraidas)
- [ ] Sin `any` (tipos definidos)
- [ ] Sin TODOs pendientes (arreglar o documentar en SDD)
- [ ] Nombres descriptivos (sin `data1`, `temp`, `helper`)
- [ ] Un componente por archivo
- [ ] Tests cubren casos principales

## Diseno responsive (siempre se sigue)

**Todo componente UI se disena para mobile primero.** Desktop es un caso especial, no al reves.

### Reglas clave

1. **Mobile-first** — escribir estilos para mobile, despues usar `md:`, `lg:`, `xl:` para desktop
2. **AppShell adaptativo** — usar hook `useResponsive()` para cambiar layout
3. **Breakpoints** — usar defaults de Tailwind (sm:640, md:768, lg:1024, xl:1280)
4. **Touch targets** — minimo 44px en mobile, 24px en desktop
5. **Canvas adaptativo** — ReactFlow con config mobile (minimap oculto, controls flotantes)
6. **Navegacion** — BottomNav en mobile, Sidebar en desktop
7. **Paneles** — BottomSheet en mobile, RightPanel en desktop
8. **Animaciones** — respetar `prefers-reduced-motion`
9. **Testing** — Playwright testea ambas vistas (mobile 375px + desktop 1440px)

### Hook `useResponsive`

```typescript
const { isMobile, isTablet, isDesktop, width } = useResponsive();
```

Uso en componentes:
```tsx
{isMobile ? <MobileHeader /> : <DesktopHeader />}
```

### Documentacion

- **ADR-001:** `docs/ADRs/ADR-001-responsive-design.md` — decisiones de arquitectura
- **RESPONSIVE.md:** `docs/RESPONSIVE.md` — guia practica con componentes

## Flujo SDD obligatorio (siempre se sigue)

**Todo desarrollo sigue este flujo.** Sin excepciones. Ni rapido ni rapido.

### Fase de diseno (SDD)

1. **Crear SDD** en `docs/SDDs/SDD-XXX-nombre.md` antes de tocar codigo
2. **Definir fases y prefases** — cada feature se divide en:
   - **Fase X.1** — logica pura (unit tests)
   - **Fase X.2** — integracion (integration tests)
   - **Fase X.3** — UI/interfaz grafica (E2E Playwright)
   - **Fase X.4** — pulido visual y responsive
3. **Cada prefase tiene su gate** — no se avanza sin pasar el gate anterior

### Prefases de pruebas E2E (Playwright CLI)

Cuando la feature involucra **interfaz grafica (GUI)**, se crean pruebas E2E con Playwright:

**Simulacion humana:**
- `page.click('selector')` — clickear botones, links, elementos
- `page.fill('selector', 'texto')` — escribir en inputs, forms
- `page.press('selector', 'Enter')` — presionar teclas
- `page.hover('selector')` — hover sobre elementos
- `page.dragAndDrop('source', 'target')` — drag and drop (canva)
- `page.mouse.wheel(0, 100)` — scroll

**Verificacion:**
- `expect(page.locator('h1')).toContainText('texto')` — verificar texto visible
- `expect(page.getByRole('button')).toBeEnabled()` — verificar estado
- `expect(page.locator('.loading')).not.toBeVisible()` — verificar que algo desaparece
- `expect(page).toHaveURL(/pattern/` — verificar navegacion

**Debugging:**
- `console.log` del browser se captura via `page.on('console', ...)`
- `page.screenshot({ path: 'evidence/paso-N.png' })` — evidencia visual por paso
- `page.video.start()` / `page.video.stop()` — grabar video completo del test
- `trace: 'on-first-retry'` — trace completo en fallos
- `page.locator('selector').highlight()` — resaltar elemento para debug visual

**Estructura de test E2E para GUI:**
```typescript
test.describe("Feature X", () => {
  test("flujo completo: crear → editar → eliminar", async ({ page }) => {
    // Paso 1: Navegar
    await page.goto("/");
    await expect(page.locator("h1")).toContainText("Empresa Dev");

    // Paso 2: Crear
    await page.getByRole("button", { name: "Crear" }).click();
    await page.fill('input[name="nombre"]', "Mi Agente");
    await page.getByRole("button", { name: "Guardar" }).click();

    // Paso 3: Verificar
    await expect(page.getByText("Mi Agente")).toBeVisible();
    await page.screenshot({ path: "evidence/01-creado.png" });

    // Paso 4: Editar
    await page.getByText("Mi Agente").click();
    await page.fill('input[name="nombre"]', "Agente Editado");
    await page.getByRole("button", { name: "Guardar" }).click();

    // Paso 5: Verificar edicion
    await expect(page.getByText("Agente Editado")).toBeVisible();
    await page.screenshot({ path: "evidence/02-editado.png" });

    // Paso 6: Eliminar
    await page.getByRole("button", { name: "Eliminar" }).click();
    await page.getByRole("button", { name: "Confirmar" }).click();

    // Paso 7: Verificar eliminacion
    await expect(page.getByText("Agente Editado")).not.toBeVisible();
    await page.screenshot({ path: "evidence/03-eliminado.png" });
  });
});
```

### Criterio de aprobacion

Una feature se considera **completada** solo cuando:

- [ ] SDD creado y aprobado
- [ ] Todas las fases del SDD cumplidas
- [ ] Unit tests verdes
- [ ] Integration tests verdes
- [ ] E2E Playwright tests verdes (si hay GUI)
- [ ] Screenshots de evidencia en `evidence/`
- [ ] Console sin errores en el browser
- [ ] Gate de la fase cerrado
- [ ] Commit con evidencia adjunta

## Gestion automatica de documentacion

La AI gestiona los documentos **sola**, sin intervencion humana. El humano solo revisa y aprueba.

### Al iniciar sesion (automatico)

1. Leer `docs/ESTADO.md` -> saber fase actual, SDDs recientes, gates pendientes
2. Leer ultimas 10 lineas de `docs/CHANGELOG.md` -> que paso recientemente
3. Si `ESTADO.md` no existe -> crear uno base con el formato actual

### Durante la sesion (automatico)

| Accion | Documento | Accion |
|---|---|---|
| Disenar una feature | `docs/SDDs/SDD-XXX-nombre.md` | Crear SDD con numeracion secuencial |
| Decidir algo de arquitectura | `docs/ADRs/ADR-XXX-nombre.md` | Crear ADR |
| Completar un gate | `docs/SUPER_PLAN.md` | Marcar `[x]` en el gate |
| Cualquier accion significativa | `docs/CHANGELOG.md` | Append al dia actual |
| Cambiar la arquitectura | `docs/ARQUITECTURA.md` | Actualizar seccion afectada |

### Al cerrar sesion (automatico)

1. Reescribir `docs/ESTADO.md` (formato corto: donde estamos, gates pendientes, SDDs recientes)
2. Actualizar `docs/INDEX.md` si se crearon docs nuevos
3. Actualizar `docs/ARQUITECTURA.md` si cambio la arquitectura

### Numeracion

- **SDDs:** buscar el SDD mas alto existente + 1 (empezar desde SDD-001 para nuevos)
- **ADRs:** buscar el ADR mas alto existente + 1 (empezar desde ADR-001 para nuevos)
- **CHANGELOG:** append al dia actual; **nunca** editar dias anteriores

### Formato de ESTADO.md (se reescribe completo cada sesion)

```
# ESTADO ACTUAL

> Sesion: YYYY-MM-DD . Fase: nombre . SDD mas reciente: SDD-XXX

## Donde estamos
(breve resumen de 5 lineas)

## Gates pendientes
- [ ] Gate X: descripcion

## SDDs recientes
- SDD-XXX: nombre (fecha)

## Ultimos cambios
(ultimas 5 lineas del CHANGELOG)
```

## Roadmap

### Fase 1 — Fundacion visual (Semanas 1-3)
- Setup Tauri + React + TailwindCSS + TypeScript
- Canva 2D basico con ReactFlow (nodos arrastrables, edges)
- Tema visual base (la IA lo define usando los skills de `reference/`)
- Primer agente visual en el canva (nodo con estado)
- Tablero Kanban basico

### Fase 2 — Skills y agentes (Semanas 4-6)
- Editor visual de skills (formularios, drag-and-drop)
- Skills engine en Python (parseo, ejecucion)
- Laboratorio de skills (probar en sandbox)
- Exportar skills a dialectos (opencode, Cursor, Claude Code)
- Roles de agente (dev, QA, reviewer, PM, devops)

### Fase 3 — Motor de pruebas (Semanas 7-9)
- Sistema de tareas con criterios de aceptacion
- Ejecucion de pruebas automaticas
- Resultados en el canva (pass/fail, cobertura)
- Diffs visuales y aprobacion humana
- Ciclo plan -> implementar -> probar -> aprobar

### Fase 4 — Comunicacion y sync (Semanas 10-12)
- Chat con agentes (texto)
- Voz (STT para hablar, TTS para que respondan)
- Notificaciones sonoras (agente trabaja, necesita aprobacion, se detuvo)
- Sync basico entre dispositivos via WebSocket
- Grafo 3D del proyecto con Three.js

### Fase 5 — Empresa autonoma (Semanas 13-16)
- Crear empresa completa (asignar roles, configurar skills)
- Orquestacion CrewAI (agentes trabajando en paralelo)
- LangGraph para grafos de estado
- Dashboard de la empresa (metricas, progreso)
- Exportar resultados

## Features pendientes (documentadas en ADRs)

### Integracion GitHub (ADR-004)
- Login con GitHub (OAuth)
- Ver repos del usuario
- Clonar repositorios
- Push/Pull desde la app
- Crear Pull Requests
- Ver y crear Issues
- Gestionar ramas

### Voz (ADR-003)
- STT: Web Speech API nativo del browser
- TTS: Edge TTS (voces naturales en espanol)
- Comandos de voz para agentes
- Respuestas por voz de los agentes

### Sincronizacion (ADR-003)
- Sync sesiones via WebSocket (estado de agentes)
- Sync config via WebSocket (preferencias)
- Sync skills via WebSocket (skills creados)
- Resolucion de conflictos (LWW para config, merge manual para sesiones)

### Documentacion de ADRs

| ADR | Tema | Estado |
|---|---|---|
| ADR-001 | Responsive Design y Cross-Platform | Aprobado |
| ADR-002 | Arquitectura Hibrida Monorepo | Aprobado |
| ADR-003 | Voz y Sincronizacion | Pendiente |
| ADR-004 | Integracion GitHub | Pendiente |


## 🪟 LAS 5 VENTANAS DEL PROYECTO (lógica de negocio — ver SDD-005)

Cada proyecto de desarrollo (tenant, [A.0]) tiene SU PROPIO conjunto de ventanas visuales. Son vistas sobre los mismos datos (Ledger/knowledge/sesiones), no silos:

1. **🏢 CANVA MULTIAGENTES** (Etapa 6) — organigrama editable: equipos, flujos de skills, creación de bots complejos. Nodos-agentes con estados vivos.
2. **🕸️ GRAFO DE DOCUMENTOS** (Plan Intermedio, Etapa 16) — estilo Obsidian/Graphify: grafo de los .md del proyecto organizado por IA pero TOTALMENTE editable por el humano; síntesis y resúmenes humano+IA sencillos y prácticos. Debe verse increíble (cerebros de Obsidian).
3. **📋 KANBAN DE RESULTADOS** (Plan Intermedio, Etapa 17) — tipo Jira pero optimizado para agentes: cards y bloques ANIMADOS mostrando evidencia (tests Playwright pasando/fallando, resultados por etapa); orientado a dejar a la IA trabajando horas autónomamente y ver qué se consiguió.
4. **🎛️ CONTROL ROOM** (Plan Intermedio, Etapa 18 — fusiona sesiones+mapa global) — TODAS las sesiones de agentes como cards vivas (hablar TTS/STT, ver resultados, retomar) sobre el mapa maestro GLOBAL de todos los proyectos en acción: métricas vivas, órdenes por voz/texto enrutadas al destino correcto, modo vigilancia de excepciones. Mission control del sistema entero.

**Principio de MOTIVACIÓN (PLAN U)**: la interfaz convierte cada proceso en una escalera de micro-victorias VERIFICABLES (test ✓ → criterio → tarea → gate → nivel) — dopamina por progreso real del Ledger, nunca actividad vacía; intensidad configurable Apagado/Festivo y anti-dark-patterns prohibidos por plan.

**Regla transversal**: toda la capa visual se construye con tokens/primitivas del Design System ([F.0]) y con estructuras de datos ESPACIALMENTE listas (posiciones, clusters, profundidades) para proyección futura en 3D/gafas (Etapa 10 Three.js es la primera; las demás ventanas heredan la preparación).

Detalle completo y fases: `docs/SDDs/SDD-005-plan-intermedio.md` · El Canvas Planeación (V2) alimenta Kanban/motor; la Control Room (V5) unifica todos los proyectos.
