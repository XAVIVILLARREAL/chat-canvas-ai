# SDD-002 — Sistema de Pruebas Spec-Driven + Playwright Humano

> Fecha: 2026-08-22 . Estado: Aprobado . Aplica a: TODOS los planes del [SDD-001](./SDD-001-plan-base/README.md)

## Principio rector

Ninguna feature existe hasta que su SPEC define cómo se prueba, y sus pruebas pasan **simulando un humano real** en la interfaz. "Compila" y "el test unitario pasa" NO bastan: la interfaz debe ser operada como la operaría una persona.

## Las 4 capas de verificación

| Capa | Herramienta | Qué verifica | Cuándo |
|---|---|---|---|
| 1. Unit | Vitest (`src/**`) | Lógica pura: stores, hooks, utils | Cada fase X.1 |
| 2. Integración | Cargo test (`src-tauri`) | Commands Rust, SQLite, providers | Cada fase con backend |
| 3. E2E funcional | Playwright browser-mode | Flujos completos con selectores estables | Cada fase X.3 |
| 4. **E2E HUMANO** ⭐ | **Playwright CLI modo humano** | Que un humano REAL puede operar todo: clicks por rol/texto, tecleo carácter a carácter, scroll de rueda, hover, pausas de pensamiento, evidencia visual por paso | Cada GATE |

## La suite Humana (capa 4) — qué la hace "humana"

Ubicación: `e2e/human/` · Config: `e2e/playwright.human.config.ts` · Comando: `pnpm test:e2e:human`

### Reglas de simulación humana

1. **Selectores como humano**: `getByRole`, `getByText`, `getByLabel` — NUNCA CSS/XPath frágil. El humano busca lo que VE
2. **Tecleo real**: carácter por carácter con delays aleatorios (40–120ms), no `fill()` instantáneo salvo campos enormes
3. **Clicks con intención**: hover antes del click (200–500ms), pausa post-click (150–400ms)
4. **Pensamiento**: pausas aleatorias 300–900ms entre acciones (humanThink)
5. **Scroll con rueda**: `mouse.wheel`, no saltos programáticos
6. **Navegación por teclado**: Tab/Enter/Escape donde un humano la usaría
7. **Evidencia obligatoria**: screenshot por CADA paso en `evidence/human/<test>/NN-paso.png` + video SIEMPRE + trace on-retry
8. **Asserts legibles**: cada paso loguea qué "ve" y qué "espera" el humano

### Fixture humano

`e2e/human/human-fixture.ts` expone:
- `h.page` — página con video/screenshot configurados
- `h.step(nombre, fn)` — ejecuta acción + screenshot numerado + log
- `h.humanClick(locator)` / `h.humanFill(locator, texto)` / `h.humanPress(key)`
- `h.humanThink(min?, max?)` — pausa aleatoria
- `h.humanWheel(deltaY)`

### Suites vigentes

| Suite | Recorre |
|---|---|
| `boot.spec.ts` | Arranque: título visible, subtítulo leíble, layout sin roturas |
| `create-agent.spec.ts` | Flujo completo: crear agente → card aparece → click card → panel muestra detalle → seleccionar/deseleccionar |
| `keyboard-nav.spec.ts` | Operable 100% teclado: foco visible, Enter activa botones |
| `responsive-human.spec.ts` | Misma app en mobile 375 y desktop 1440, navegación humana en ambas |

## Flujo Spec-Driven por feature (obligatorio)

```
1. SPEC     → sección en SDD del plan: comportamiento observable + criterios
2. TESTS    → escribir primero las 4 capas que fallan (unit/int/e2e/humano)
3. IMPL     → código mínimo que pone TODO en verde
4. REFACTOR → limpiar sin romper (suites re-corren)
5. GATE     → demo humana grabada + todas las suites verdes
```

Una feature SIN spec escrita no se codea. Un gate sin suite humana no se cierra.

## Integración con los gates del SDD-001

Cada gate (A/B/C/D/E) añade a su checklist: **suite humana ampliada** cubriendo las features nuevas del plan. La suite crece con el producto: al llegar a Gate E debe existir un walkthrough humano completo de punta a punta.

## Anti-patrones prohibidos

| Prohibido | Por qué |
|---|---|
| `page.fill()` en tests humanos | No simula tecleo; usar `humanFill` |
| Selectores `.class > div:nth(3)` | El humano no ve clases; rompe con cualquier refactor |
| Test sin screenshots | Sin evidencia visual el gate no es auditable |
| `test.skip()` permanente | Deuda oculta; se arregla o se elimina |
| Mockear la UI misma | Se mockea el PROVIDER/backend, jamás la interfaz bajo prueba |
