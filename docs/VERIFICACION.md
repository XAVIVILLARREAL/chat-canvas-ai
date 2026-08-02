# VERIFICACIÓN — Chrome DevTools MCP como el corazón del sistema

> **Idea central:** los errores no se eliminan, se hacen **imposibles de ignorar**.
> Y para una app web, la prueba definitiva es **abrirla en un navegador real y usarla como un humano** — eso es exactamente lo que hace el Chrome DevTools MCP.

## La cadena de defensa (de la más barata a la más cara)

```
1. Typecheck        (errores de tipos)
2. Lint             (estilo, código muerto)
3. Tests unit + integración  (lógica y conexiones)
4. Build            (empaquetado)
5. UI Test con Chrome DevTools MCP  ← el núcleo de ESTE producto
   (la app se abre en Chrome real y se prueba como humano:
    clic, navegar, escribir, consola, red, DOM, capturas)
6. Revisión humana  (criterio y producto)
```

Las capas 1–4 las corre el CI. La capa 5 es **tu diferenciador**: la ejecuta el UI Tester dentro del flujo de los agentes, en cada feature.

## La prueba de UI como un humano (Chrome DevTools MCP)

El UI Tester no asume: **prueba**. Y deja evidencia.

### Qué hace en cada verificación

1. **Abre la app** (dev server del proyecto) en un **Chrome headless** que corre en segundo plano en el servidor (sin ventana visible).
2. **Navega** al punto de la feature (según el SDD).
3. **Interactúa como humano**: clic en botones, escribe en inputs, scroll, espera a que cargue.
4. **Observa como humano + más**:
   - **Consola**: ¿errores JS? ¿warnings? (los humanos no ven la consola, pero el sistema sí).
   - **Red**: ¿requests fallidas? ¿lentas?
   - **DOM**: ¿el elemento esperado existe? ¿está visible? ¿los estados cambian (loading, error, vacío)?
   - **Accesibilidad**: ¿el flujo funciona sin mouse (teclado/touch)?
5. **Captura pantalla** en cada paso significativo → evidencia visual.
6. **Compara con el SDD**: lo que se diseñó es lo que se ve.
7. Veredicto:
   - ✅ **UI verificado** → capturas adjuntas al PR.
   - ❌ **Bug** → reporta con: paso exacto, error de consola, captura.

### Reglas de oro de la verificación de UI

- **Ninguna feature de UI se cierra sin navegador real.** No basta "el test unitario pasó".
- **Sin capturas no hay evidencia.** El Reviewer y tú revisáis la UI con los ojos del agente.
- **Los estados raros se prueban**: loading, error, vacío, responsive (móvil/desktop).
- **Flujo feliz + flujo de error** se verifican (no solo el camino bonito).

## El bucle de retroalimentación (el corazón del sistema)

```
Implementador escribe código
      │
      ▼
CI: typecheck → lint → tests → build   ──►  ¿Verde?
      │                                          │
      │ falla                                      │ pasa
      ▼                                          ▼
Error exacto (archivo:línea)          UI Tester: abre Chrome real
vuelve al Implementador                    y prueba como humano
      │                                          │
      │                                    ¿UI como el SDD?
      │                                   │            │
      │                          ❌ no (bug)│            │ ✅ sí
      │                                   │            ▼
      │                                   │    Capturas adjuntas al PR
      │                                   ▼            │
      │                  Bug reportado: paso + consola + captura  →  vuelve al Implementador
      ▼                                                            │
Implementador corrige y reintenta                                  │
      │                                                            ▼
      └──────────────────────────────────────────── Reviewer revisa diff + capturas
                                                                │
                                                   aprueba → merge │ pide cambios
```

- Máximo **3 intentos** por bucle; si sigue fallando → **escala al humano** (no loopea infinito).
- **Por qué funciona:** el error más común de un agente es no conocer el estado real. El CI devuelve el *ground truth* del código; el UI Tester devuelve el *ground truth* de la **app en pantalla**. Con eso, corregir es un problema resuelto, no una adivinanza.

## Revisión del diff (agente Reviewer)

- Revisa **cambios + capturas**: ¿el PR es pequeño (≤300 líneas)? ¿los tests son significativos? ¿la captura muestra lo que dice el SDD? ¿efectos secundarios?
- Nunca aprueba por presión; dudas serias → escala al humano.

## Aprobación humana (solo en hitos)

El humano aprueba: arquitectura inicial, cada hito del roadmap, tocar producción. No en cada PR.

## Métricas de éxito

- **Bugs capturados por el UI Tester** (antes de llegar a tus manos) → señal de que el sistema funciona.
- **Bugs en producción** → deben tender a cero; cada uno = test de regresión + nuevo caso para el UI Tester.
- **% de capturas que el Reviewer aprueba a la primera** → señal de que los agentes aprenden.
- **Tiempo idea → feature verificada** → mejora con el tiempo.

## Límites y honestidad

- El sistema reduce errores, no los hace imposibles: el criterio de producto sigue siendo tuyo.
- El UI Tester prueba lo que está en el SDD; si el SDD se olvidó de un caso, nadie lo prueba. Por eso el SDD se revisa también.
- Cada bug en producción = oportunidad: se convierte en test de regresión + mejora del prompt del agente.
