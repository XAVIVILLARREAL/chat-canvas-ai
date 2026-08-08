---
name: patrol-iteracion
description: Use when iterating on Flutter UI through Patrol E2E tests — run tests, capture screenshots, debug in real time (widget tree, terminal), fix, and improve. Trigger keywords: "patrol", "probar la app", "test e2e", "depurar la ui", "screenshot de la app", "iterar pruebas", "prueba en emulador/desktop".
---

# Patrol — Iteración de pruebas, debug y mejora

Guía para probar la app Flutter como un humano usando **Patrol** (E2E UI testing), depurar en tiempo real y mejorar iterativamente. Cada iteración produce **evidencia (screenshots)**.

## Objetivo del flujo

```
1. Escribir/ajustar un test Patrol (o tomar uno existente)
2. Ejecutarlo (CLI) → capturas de pantalla por paso
3. Si falla → depurar en tiempo real (widget tree / logs / terminal)
4. Corregir el bug en el código
5. Re-ejecutar → PASS con screenshots
6. Guardar la evidencia en data/evidence/ y commit
```

## Qué es Patrol (contexto)

- Framework E2E de Flutter: los tests corren **dentro de la app** (construido sobre `integration_test`), pero Patrol añade interacciones nativas y CLI dedicada.
- Permite simular humano: tap, scroll, texto, gestos; y tomar **screenshots** como evidencia.
- Ya está en `pubspec.yaml` como `dev:patrol`. El CLI se instala con:
  ```
  dart pub global activate patrol_cli
  ```
- Compatible con: Android (emulador/real), iOS (simulador/real), y desktop (Windows/macOS) vía `patrol test`.

## Estructura de tests en este proyecto

- Tests de unidad/widget: `test/*.dart` (se ejecutan con `flutter test`).
- Tests E2E de integración real (requieren red/llave): `test/*_integration_test.dart` con tag `integration`.
- Tests **Patrol** (UI dentro de la app): en `integration_test/*.dart`, con `patrol` como envoltorio.

Ejemplo mínimo de un test Patrol:

```dart
// integration_test/app_test.dart
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'flujo principal: hosts -> canva -> hub',
    ($) async {
      await $.pumpWidgetAndSettle(const EmpresaDevApp());
      await $(Icons.add).tap();
      await $.pumpAndSettle();
      await $('Conectar').tap();
      await $.pumpAndSettle();
      await $.screenshot('01-hosts');
      // interacción con el terminal, canva, etc.
    },
  );
}
```

## Ejecución

### En Windows / desktop (entorno actual de pruebas)

```bash
# opción 1: Patrol CLI (si el dispositivo es compatible)
patrol test -d windows

# opción 2: integration_test directo (fallback si Patrol no soporta el target)
flutter test integration_test/app_flow_test.dart -d windows
```

### En Android (emulador)

```bash
patrol test -d emulator-5554 integration_test/app_test.dart
```

### ⚠️ Workaround Windows (VS 2026)

El `flutter test -d windows` puede fallar con:
`CMake Error: generator : Visual Studio 16 2019 could not find any instance`.

**Causa:** flutter_tools asigna a VS 2026 (major 18) el generador por defecto `16 2019`,
que el cmake de VS 18 no reconoce. Ya se parcheó localmente:

- Archivo: `C:\tools\flutter\packages\flutter_tools\lib\src\windows\visual_studio.dart`
- Se añadió el caso `18 => 'Visual Studio 17 2022'` en `cmakeGenerator`.
- **Importante:** si el snapshot sigue dando el error, borrar `C:\tools\flutter\bin\cache\flutter_tools.snapshot`
  para que flutter lo regenere desde el source con el parche.

Verificado: `flutter test integration_test/app_flow_test.dart -d windows` → **All tests passed!**

### Regla práctica

- Si la plataforma de prueba es **desktop (Windows)**, usa `flutter test integration_test -d windows` (el más fiable hoy).
- Si es **móvil (Android/iOS)**, usa `patrol test` (aprovecha las interacciones nativas).

## Debug en tiempo real

Cuando un test falla o la UI no se ve bien:

1. **Widget tree** — inspecciona el árbol actual:
   ```bash
   # dentro del test, antes del assert:
   await $.debugDumpApp();
   # o en la app: Flutter DevTools (flutter run + 'd' para debug)
   ```
2. **Logs del test** — `patrol test` imprime los logs de la consola de la app; revisa errores de red/SSH.
3. **Terminal de la app** — si el test interactúa con el terminal SSH, captura lo que se escribe/responde (los datos van por `shell.stdout`).
4. **Screenshots intermedios** — inserta `$.screenshot('paso-N')` en cada paso para ver dónde diverge la UI.

## Flujo de arreglo (TDD real)

1. El test define el comportamiento esperado (estado final).
2. Ejecuta → falla → **lee el error exacto** (no adivines).
3. Localiza la causa: inspecciona el widget tree + logs + screenshot del paso fallido.
4. Corrige el código en `lib/` (mínimo cambio).
5. Re-ejecuta el test → PASS.
6. Actualiza el SDD correspondiente si el comportamiento cambió.

## Evidencia (Definition of Done)

- Cada iteración guarda screenshots en `data/evidence/`:
  ```bash
  # mover las capturas de Patrol a data/evidence/
  # (patrol las guarda en build/patrol/screenshots/ por defecto)
  ```
- Los screenshots demuestran: la app carga, se navega, el terminal conecta, el canva muestra nodos, el hub sincroniza.
- Solo se considera "arreglado" un bug cuando el test pasa **con evidencia visual**.

## Checklist por iteración

- [ ] Escribí/ajusté el test Patrol del comportamiento objetivo.
- [ ] Ejecuté el test y capturé screenshots de cada paso.
- [ ] Si falló: leí el error, inspeccioné el widget tree y el screenshot del paso fallido.
- [ ] Corregí el bug en `lib/` (cambio mínimo).
- [ ] Re-ejecuté → PASS.
- [ ] Guardé la evidencia en `data/evidence/`.
- [ ] Commit del código + tests + evidencia.

## Notas

- Los tests Patrol que requieren red/llave (SSH a pve) deben marcarse o aislarse; el CI usa `flutter test --exclude-tags integration`.
- Mantener los tests pequeños y con un solo objetivo para que el debug sea rápido.
- El `patrol test` necesita el dispositivo listo; en Windows desktop la app se lanza sola.
