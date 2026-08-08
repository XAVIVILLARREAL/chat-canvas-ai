---
description: Inicia el ciclo de iteración de pruebas, debug y mejora de la app Flutter (Patrol/integration_test E2E en Windows) — prueba como humano, captura evidencia, arregla y mejora.
agent: build
---

# /dev — Iteración de pruebas y mejora

Inicia el ciclo completo de prueba → debug → arreglo → mejora de la app **empresa_dev** (Flutter). $ARGUMENTS es el objetivo o bug a probar/arreglar.

## Flujo obligatorio

1. **Entender el objetivo**: lee `$ARGUMENTS` y el estado actual (git status, tests). Si es un bug, identifica el área (terminal/SSH, SFTP, canva, tabs, hub, hosts).
2. **Escribir/ajustar el test E2E** en `integration_test/app_flow_test.dart` (o un archivo nuevo `integration_test/<area>_test.dart`). Usa la skill `patrol-iteracion` si hay ambigüedad en el método.
3. **Ejecutar en Windows** (entorno local):
   ```bash
   flutter test integration_test/app_flow_test.dart -d windows
   ```
   - Si falla el build por VS 2026, ver la skill `patrol-iteracion` (parche en `visual_studio.dart`; si insiste, borrar `C:\tools\flutter\bin\cache\flutter_tools.snapshot`).
   - **Importante:** borrar `build/windows` antes de cada corrida E2E (evita caches de generador).
4. **Depurar en tiempo real** si falla: lee el **error exacto** (Expected/Actual/Which del assert). Inspecciona el widget tree (`await tester.debugDumpApp()`) y los logs.
5. **Corregir** el código en `lib/` (cambio mínimo) y re-ejecutar.
6. **Evidencia**: guarda screenshots de los pasos en `data/evidence/`. Un bug solo está "arreglado" si el test pasa con evidencia visual.
7. **Commit**: `git add -A && git commit` en español (feat:/fix:/test:/docs:), y sincroniza al servidor.

## Trucos de tests E2E (lecciones verificadas)

- **Finders específicos**: si un widget aparece varias veces, usa `find.byTooltip('...')` o `find.widgetWithText(Widget, 'text')` en vez de `find.byIcon(...)`. (Ej.: había 2 `Icons.cell_tower` → se resolvió con tooltip).
- **Duplicados en UI**: si el finder encuentra 2 widgets, es un bug real de UI (botón duplicado). Corrige el código, no solo el test.
- **Iconos en botones con tooltip**: usar el tooltip como selector estable.
- **pumpAndSettle**: tras cada navegación/tap, llamar `await tester.pumpAndSettle()`.
- **pageBack**: para volver de pantallas full-screen.

## Reglas

- TDD: primero el test que falla, después el código.
- Máx 3 intentos por error antes de escalar al humano.
- `flutter analyze` 0 issues antes de terminar.
- Correr también los tests unitarios: `flutter test --exclude-tags integration`.
- Verificar que la app E2E abarca: hosts → tabs → canva → hub.

## Áreas de la app

| Área | Dónde | Cómo probarla |
|---|---|---|
| Terminal SSH | `lib/screens/terminal_screen.dart` | Conectar a pve (llave), escribir comando |
| SFTP | `lib/screens/sftp_screen.dart` | Listar/subir/bajar |
| Tabs (sesiones) | `lib/screens/tabs_screen.dart` | Abrir/cerrar pestañas |
| Canva (lienzo) | `lib/screens/canva_screen.dart` | Nodos, conexiones, persistencia |
| Hub sync | `lib/screens/hub_screen.dart` | Modo hub/cliente, token |
| Conmutador Tabs/Canva | `lib/main.dart` | SegmentedButton alterna vistas |

## Verificado (2026-08)

- `flutter test integration_test/app_flow_test.dart -d windows` → **All tests passed!**
- El ciclo completo (test → fallo → depurar → arreglar → PASS) se ejecutó con éxito.
