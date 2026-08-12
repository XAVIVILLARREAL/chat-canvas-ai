# SDD-120 — Etapa 7: SDD++ + Playwright E2E + CI

> Cierra la Etapa 7 del SUPER_PLAN: gates automáticos por fase. Playwright CLI
> contra `flutter build web`, `patrol_cli` para flujos mobile, y CI (GitHub
> Actions) que corre analyze + tests + E2E web por PR.

## Objetivo

Cada feature del proyecto arranca como SDD enlazado en el canva y se verifica
con **E2E automáticos sin intervención humana**:

1. **E2E web** (`tool/e2e_web.ps1`): Playwright (Chromium headless) contra el
   build web real → la app carga, se navega, se edita y **persiste tras
   recargar**.
2. **Patrol** (`patrol_cli`): mismo flujo crítico en Android (dispositivo real).
3. **CI**: un job nuevo en `.github/workflows/ci.yml` que corre el E2E web en
   cada PR junto a analyze + tests. Gate: un PR con feature + SDD + tests +
   E2E pasa completo.

**Adaptación honesta del gate** ("conectar SSH, abrir archivo, editar,
guardar"): dartssh2 usa `dart:io` y **no corre en Flutter web** (sin proxy
WebSocket — eso es Etapa 8.4). El E2E web cubre el flujo crítico que SÍ es
posible en browser: canva → nota `.md` → editar → guardar → **persistencia
tras recarga**. SSH/SFTP real sigue cubierto por los integration tests de
desktop ya existentes (`ssh_integration_test.dart`, tag `integration`) y por
patrol en Android (donde `path_provider`/`dart:io` funcionan nativamente).

## Flujo E2E web (sin intervención humana)

```
tool/e2e_web.ps1
  ├─ flutter build web --debug --dart-define=E2E_WEB=true   (si falta build/web)
  ├─ servidor estático 127.0.0.1:8765 (patrón verify_ui.ps1, HttpListener)
  ├─ npx playwright test tool/ (spec e2e_web.spec.js, chromium headless)
  │    1. goto http://127.0.0.1:8765/  → app carga
  │    2. click pestaña/acción Canva   → canva renderiza nodos
  │    3. click "Añadir" → "Nueva nota" → escribo título+texto → guardar
  │    4. abrir la nota → editar body → guardar
  │    5. reload() → la nota y el texto editado SIGUEN ahí (persistencia web)
  └─ exit 0 = gate web OK
```

Clave técnica: Flutter web renderiza en canvas; **sin árbol de semántica el
DOM no tiene botones accesibles**. Por eso el build usa `--dart-define=E2E_WEB`
que hace `SemanticsBinding.instance.ensureSemantics()` en `main.dart` →
Flutter genera el árbol `flt-semantics` y Playwright interactúa por
role/name (estándar de E2E Flutter web).

## Contratos

```powershell
# apps/empresa_dev/tool/e2e_web.ps1
param([switch]$SkipBuild)   # no rebuild si ya hay build/web/index.html
# 1. build web con --dart-define=E2E_WEB=true (si SkipBuild off y falta index.html)
# 2. servidor estático 127.0.0.1:8765 (mismo bloque HttpListener de verify_ui.ps1)
# 3. Push-Location tool; npx playwright test; Pop-Location
# exit: 0 verde / 1 rojo. Imprime evidencia (capturas en tool/test-results/).
```

```js
// apps/empresa_dev/tool/playwright.config.js + tool/e2e_web.spec.js
// import { test, expect } from '@playwright/test';
// test('flujo crítico web: canva -> nota -> editar -> guardar -> persiste', ...)
//   - página con flt-semantics visible (getByRole)
//   - el body editado aparece tras page.reload() (persistencia localStorage)
//   - screenshots por paso -> tool/test-results/
```

```yaml
# .github/workflows/ci.yml — job nuevo "e2e-web" (ubuntu-latest)
#   - checkout + flutter 3.32.x + flutter build web --debug --dart-define=E2E_WEB=true
#   - node 24 + npx playwright install --with-deps chromium + npm i @playwright/test
#   - python3 -m http.server 8765 (servidor CI) &
#   - npx playwright test (config tool/playwright.config.js)
```

```dart
// apps/empresa_dev/lib/services/canva_store.dart — fallback web
// CanvaStorage (interfaz): load() -> String? / save(String)
//   FileStorage:   archivo canva_state.json (path_provider, impl actual)
//   WebStorage:    localStorage['canva_state'] (dart:html, solo web)
// CanvaStore usa kIsWeb ? WebStorage : FileStorage  → persistencia en browser
```

**Nota:** `dart:html` no compila en tests de VM → la selección
`kIsWeb ? WebStorage : FileStorage` vive en una factory `CanvaStore.forPlatform()`
y el cuerpo de WebStorage usa conditional import (`storage_io.dart` /
`storage_web.dart`) o `package:web`; los tests unit inyectan un storage fake.

## Tests (TDD)

1. `apps/empresa_dev/test/canva_store_web_test.dart` (unit, storage fake):
   - `CanvaStore.forPlatform()` devuelve impl web en `kIsWeb` (fake del branch).
   - save→load round-trip con storage fake; load con `null` → `CanvaState.empty()`.
   - persistencia: jsonEncode → jsonDecode conserva nodos/edges (reuso de
     `canva_widget_test.dart` si ya cubre JSON).
2. `apps/empresa_dev/test/main_e2e_flag_test.dart` (widget):
   - con `--dart-define=E2E_WEB=true` se llama `ensureSemantics()` (flag activo);
   - sin el define, comportamiento actual intacto.
3. `tool/e2e_web.spec.js` (E2E real, este archivo ES el test del gate):
   - carga, canva, crear nota, editar, guardar, reload → persiste.
4. `apps/empresa_dev/patrol_test/canva_flow_test.dart` (patrol, gate manual):
   - mismo flujo en Android real: canva → nota → editar → guardar → relanzar
     app → persiste (vía `integration_test` + `PatrolApp`).

## Gate (SUPER_PLAN Etapa 7)

- [ ] Playwright CLI contra `flutter build web` (`tool/e2e_web.ps1`).
- [ ] `patrol_cli` para flujos mobile (test escrito + `patrol` en pubspec ya
      está `^4.8.0`; ejecución real = gate manual con dispositivo Android).
- [ ] CI (GitHub Actions) corre analyze + tests + E2E web por PR.
- [ ] Prueba de comprobación: un PR con feature + SDD + tests + E2E pasa completo.

## Slices de implementación (TDD por slice)

- **7.1** Fallback web del `CanvaStore` (interfaz `CanvaStorage` +
  `WebStorage` con conditional import + factory `forPlatform`) + tests unit.
- **7.2** Flag `E2E_WEB` en `main.dart` → `SemanticsBinding.ensureSemantics()`
  + widget test del flag.
- **7.3** Tooling E2E web: `tool/package.json` + `playwright.config.js` +
  `e2e_web.spec.js` + `tool/e2e_web.ps1` → correr localmente (gate web).
- **7.4** Patrol: `patrol_test/canva_flow_test.dart` + sección `patrol:` en
  pubspec + docs de comando (`patrol test -d <device>`). Gate manual.
- **7.5** CI: job `e2e-web` en `.github/workflows/ci.yml`.

## Notas de implementación

- **Por qué `--dart-define` y no semantics siempre on:** semantics tiene costo
  de render; solo se activa en el build E2E. El flag es constante en
  compilación (`const bool.fromEnvironment('E2E_WEB')`).
- **Playwright local (Windows):** node 24 + npm 11 ya disponibles; `npm i
  @playwright/test` en `tool/` + `npx playwright install chromium` (una vez).
  `e2e_web.ps1` usa `npx playwright test` desde `tool/`.
- **CI:** runner ubuntu instala chromium headless shell con `--with-deps`;
  servidor con `python3 -m http.server 8765` en background (GitHub Actions no
  usa HttpListener de PowerShell). El spec es el mismo en local y CI
  (config apunta a `http://127.0.0.1:8765`).
- **Persistencia web:** `WebStorage` usa `window.localStorage` con la misma
  clave `canva_state`; sin red, sin plugins nativos. El resto de stores
  (evidence, agent, vibecoding) NO necesitan fallback para el gate — solo el
  canva participa en el flujo crítico del E2E.
- **Patrol en Windows sin emulador:** se deja el test + config versionado y el
  gate queda como gate manual (mano humana con dispositivo Android), igual que
  los otros gates manuales del proyecto.
