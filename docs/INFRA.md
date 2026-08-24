# INFRA.md — Mejoras de Infraestructura

> Resumen de todas las herramientas y configuraciones modernas implementadas en el proyecto.

## Herramientas de compilacion y build

### TypeScript-Go (tsgo)
- **Paquete:** `@typescript/native-preview` v7.0
- **Comando:** `pnpm typecheck`
- **Velocidad:** 10-100x mas rapido que tsc
- **Configuracion:** `tsconfig.json` + `tsconfig.node.json`
- **Beneficio:** Compila TypeScript nativo en Go, elimina el cuello de botella de tsc

### Vite 8 + Rolldown
- **Paquete:** `vite` v8.2.2
- **Bundler:** Rolldown (Rust) reemplaza esbuild + Rollup
- **Velocidad:** 10-30x mas rapido en production builds
- **Configuracion:** `vite.config.ts`
- **Beneficio:** Un solo bundler unificado para dev y production

### React Compiler via Oxc
- **Paquete:** `oxc-transform-react` v0.145.0
- **Integracion:** `@vitejs/plugin-react` v6.1.0 con `compiler: true`
- **Velocidad:** 10x mas rapido que Babel
- **Beneficio:** Memorizacion automatica, elimina `useMemo`, `useCallback`, `React.memo` manuales

## Herramientas de calidad

### Biome (reemplaza ESLint + Prettier)
- **Paquete:** `@biomejs/biome` v2.5.9
- **Velocidad:** 10-35x mas rapido que ESLint+Prettier
- **Configuracion:** `biome.json`
- **Comandos:** `pnpm lint`, `pnpm lint:fix`, `pnpm format`
- **Beneficio:** Un solo tool para lint + format, basado en Rust

### oxlint (lint complementario)
- **Paquete:** `oxlint` v1.79.0
- **Comando:** `pnpm lint:oxc`
- **Beneficio:** Parser/linter Rust ultra-rapido, reglas complementarias a Biome

### knip (detectar codigo muerto)
- **Paquete:** `knip` v6.32.2
- **Configuracion:** `knip.json`
- **Comando:** `pnpm lint:dead`
- **Beneficio:** Detecta imports, funciones y tipos no usados automaticamente

## Framework y librerias

### React 19.2
- **Paquete:** `react` v19.2.8
- **Features nuevos:** `use()`, `useOptimistic`, `useFormStatus`, `useActionState`
- **React Compiler:** Estable desde v1.0 (octubre 2025)
- **Beneficio:** Hooks modernos + memorizacion automatica

### Zustand (estado global)
- **Paquete:** `zustand` v5.0.15
- **Tamanio:** 1KB
- **Store:** `src/stores/app-store.ts`
- **Beneficio:** Sin boilerplate, DevTools, persistencia via plugin

### TanStack React Query (estado server)
- **Paquete:** `@tanstack/react-query` v5.101.4
- **Beneficio:** Caching, reintentos, loading states automaticos para datos del gateway Rust

## Arquitectura hibrida

### Un solo codebase (web-first)
- **Navegador v1 (WEB-FIRST):** la SPA React la sirve el gateway axum (`crates/server`) — cero instalación
- **Tauri (DIFERIDO):** envoltorio de la misma web + superpoderes nativos, solo con demanda demostrada
- **Frontend:** React compartido en `src/`
- **Dominio Rust:** `crates/core` (compartido por server y tauri-shell)

### Estructura de carpetas
```
src/                    # React (compartido, web-first)
crates/core             # Dominio Rust (agentes, tareas, skills, sesiones)
crates/server           # Gateway axum (sirve SPA + REST + SSE/WS)
src-tauri/              # Rust (Tauri — shell diferido)
packages/shared-types/  # Tipos TypeScript compartidos
e2e/                    # Playwright tests
docs/                   # Documentacion
```
> ⚠️ NO existe `services/python/`: el backend server es **Rust** (ADR-005 + SDD-008 + Plan Base v3.4). Corregido 2026-08-24.

### Capas
| Capa | Carpeta | Tecnologia |
|---|---|---|
| Frontend | `src/` | React + TypeScript |
| Gateway Server | `crates/server` | Rust (axum) — sirve la SPA + API + SSE/WS |
| Dominio | `crates/core` | Rust — agentes, tareas, skills, sesiones |
| Shared Types | `packages/shared-types/` | TypeScript |

### Comunicacion
- Frontend <-> Gateway axum: HTTP/WS/SSE (web-first)
- Gateway <-> Workers: cola Postgres `FOR UPDATE SKIP LOCKED` + eventos
- Workers <-> Postgres+RLS: datos multi-tenant (proyectos como tenants)

### Documentacion
- **ADR-002:** `docs/ADRs/ADR-002-arquitectura-hibrida.md`
- **ARQUITECTURA.md:** `docs/ARQUITECTURA.md`

## Integracion Rust-TypeScript

### tauri-specta (IPC type-safe)
- **Paquete:** `tauri-specta` v2.0.0-rc.25
- **Funcion:** Genera bindings TypeScript automaticamente desde comandos Rust
- **Configuracion:** `src-tauri/src/lib.rs` + `src/bindings.ts`
- **Beneficio:** Compile-time safety, autocompletado, errores en compile time no en runtime

### Tauri Plugins (9 plugins)
| Plugin | Para que |
|---|---|
| `tauri-plugin-store` | Persistencia JSON nativa |
| `tauri-plugin-notification` | Notificaciones sonoras |
| `tauri-plugin-global-shortcut` | Atajos de teclado globales |
| `tauri-plugin-http` | HTTP client desde Rust |
| `tauri-plugin-dialog` | Dialogos nativos del SO |
| `tauri-plugin-clipboard-manager` | Portapapeles |
| `tauri-plugin-single-instance` | Evitar instancias multiples |
| `tauri-plugin-window-state` | Recordar tamanho/posicion |
| `tauri-plugin-opener` | Abrir URLs/archivos |

### Capabilities (modelo de permisos)
- **Archivo:** `src-tauri/capabilities/default.json`
- **Permisos:** Por ventana, no global
- **Beneficio:** Seguridad explicita por defecto, auditable

## CSS moderno (sin Sass)

| Feature | Reemplaza | Soporte |
|---|---|---|
| Container queries | Media queries para componentes | 95%+ |
| CSS nesting | Sass/Less | 92%+ |
| `:has()` selector | JavaScript class toggling | 93%+ |
| `oklch()` / `color-mix()` | Sass `lighten()`/`darken()` | 93%+ |
| Cascade layers | `!important` battles | 95%+ |

**Beneficio:** Sass es innecesario. CSS nativo + TailwindCSS es suficiente.

## Diseno responsive

### AppShell adaptativo
- **Desktop:** Sidebar + Area principal + Right Panel
- **Tablet:** Sidebar iconos + Area principal + Panel overlay
- **Mobile:** Header + Area fullscreen + Bottom Nav

### Hook `useResponsive`
- **Archivo:** `src/hooks/useResponsive.ts`
- **Retorna:** `{ isMobile, isTablet, isDesktop, width, height, breakpoint }`
- **Uso:** `const { isMobile } = useResponsive();`

### Breakpoints (TailwindCSS defaults)
| Breakpoint | Width | Target |
|---|---|---|
| `sm` | 640px | Mobile landscape |
| `md` | 768px | Tablet portrait |
| `lg` | 1024px | Desktop |
| `xl` | 1280px | Desktop grande |

### Canvas adaptativo
- **Mobile:** Minimap oculto, controls flotantes, zoom pinch, touch gestures
- **Desktop:** Minimap visible, controls fijos, zoom rueda mouse, drag-and-drop

### Navegacion
- **Mobile:** BottomNav (4 tabs: Canva, Agentes, Skills, Chat)
- **Desktop:** Sidebar vertical con iconos + labels

### Touch targets
- **Mobile:** 44px min (Apple HIG / Material Design)
- **Desktop:** 24px min

### Testing responsive
- **Playwright:** Tests en mobile (375px) y desktop (1440px)
- **Comando:** `pnpm test:e2e` (ejecuta ambas vistas)

### Documentacion
- **ADR-001:** `docs/ADRs/ADR-001-responsive-design.md` — decisiones de arquitectura
- **RESPONSIVE.md:** `docs/RESPONSIVE.md` — guia practica con componentes

## Testing E2E

### Playwright + tauri-plugin-playwright
- **Paquete:** `@playwright/test` v1.62.1 + `@srsholmes/tauri-playwright` v0.4.1
- **Plugin Rust:** `tauri-plugin-playwright` v0.4 (feature flag `e2e-testing`)
- **Configuracion:** `e2e/playwright.config.ts`
- **Fixtures:** `e2e/fixtures.ts`
- **Tests:** `e2e/tests/`
- **Comandos:**
  - `pnpm test:e2e` — todos los tests (chromium + webkit)
  - `pnpm test:e2e:chromium` — solo chromium
  - `pnpm test:e2e:webkit` — solo webkit
  - `pnpm test:e2e:ui` — interfaz visual de Playwright
- **Modos de testing:**

| Modo | Plataforma | Que hace |
|---|---|---|
| `browser` | Todas | Headless Chromium con IPC mockeado, rapido, para CI |
| `tauri` | Todas | Socket bridge al webview real de Tauri, E2E verdadero |
| `cdp` | Windows | CDP directo a WebView2, testing nativo Windows |

- **Beneficio:** Tests E2E contra el webview real de Tauri, no solo contra un browser. En Windows funciona con CDP nativo.

## Package manager

### pnpm (reemplaza npm)
- **Lock file:** `pnpm-lock.yaml`
- **CI:** `pnpm/action-setup@v4` + `pnpm install --frozen-lockfile`
- **Beneficio:** 2-3x mas rapido que npm, monorepo nativo, estricto con dependencias

## Skills de opencode

Skills personalizados en `.opencode/skills/` para guiar el desarrollo y testing.

### dev
- **Trigger:** "dev", "super plan", "plan", "siguiente fase", "implementar", "gate", "probar", "progreso"
- **Funcion:** Guia de desarrollo por fases con pruebas de comprobacion (gates)
- **Flujo:** SDD primero → TDD → CI local → cerrar fase con gate
- **Fases:** 7 etapas desde fundacion visual hasta vibecoding + Playwright E2E

### dev-4b
- **Trigger:** "4b", "etapa 4b", "skills"
- **Funcion:** Resumen de estado de la Etapa 4b (gestor visual de skills + laboratorio)
- **Contenido:** SDD-113, slices completados, CI, gate pendiente

### commit-es
- **Trigger:** "commit", "mensaje de commit"
- **Funcion:** Redacta commits cortos en espanol con contexto
- **Restricciones:** Prefijos feat/fix/docs/chore, maximo 72 caracteres

### patrol-iteracion
- **Trigger:** "patrol", "probar la app", "test e2e", "depurar la ui", "screenshot de la app"
- **Funcion:** Iteracion de pruebas Flutter via Patrol E2E
- **Flujo:** Test → screenshot → debug widget tree → fix → re-ejecutar → evidencia
- **Plataformas:** Android emulador, iOS simulador, Windows desktop
- **Nota:** Windows tiene workaround para VS 2026 (cmake generator)

### terminal-sos
- **Trigger:** "terminal", "ssh", "sftp"
- **Funcion:** Diagnostico rapido de problemas SSH/SFTP
- **Contexto:** dartssh2, conectividad, errores comunes

## Stack completo verificado

| Herramienta | Comando | Velocidad vs alternativa |
|---|---|---|
| tsgo | `pnpm typecheck` | 10-100x vs tsc |
| Biome | `pnpm lint` | 10-35x vs ESLint+Prettier |
| oxlint | `pnpm lint:oxc` | Ultra-rapido (Rust) |
| knip | `pnpm lint:dead` | Detecta codigo muerto |
| Vite 8 | `pnpm dev:frontend` | 10-30x vs Rollup |
| React Compiler | `compiler: true` | 10x vs Babel |
| tauri-specta | Auto-generado | Type-safe IPC |

## Scripts disponibles

```
pnpm dev            — Tauri dev server
pnpm build          — Tauri production build
pnpm typecheck      — tsgo (type checking)
pnpm lint           — Biome (lint + format check)
pnpm lint:fix       — Biome auto-fix
pnpm lint:oxc       — oxlint (lint complementario)
pnpm lint:dead      — knip (detectar codigo muerto)
pnpm format         — Biome format
pnpm check:all      — tsgo + biome + oxlint en serie
pnpm test:e2e       — Playwright E2E (chromium + webkit)
pnpm test:e2e:ui    — Playwright UI mode
pnpm test:e2e:chromium — Playwright solo chromium
pnpm test:e2e:webkit   — Playwright solo webkit
```
