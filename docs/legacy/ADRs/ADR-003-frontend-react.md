# ADR-003 — El frontend se queda en React (no Svelte/Solid)

- **Estado:** Aceptado (2026-08-02)
- **Decisión:** El frontend del proyecto **permanece en React 19**. No se adopta Svelte/SvelteKit ni SolidJS.
- **Tags:** frontend, stack, rendimiento

## Contexto

Se evaluó si cambiar a Svelte/SvelteKit o SolidJS mejoraría el rendimiento de una app grande (ERP/tablero). Ambos eliminan el Virtual DOM y usan reactividad fina (menos memoria, menos re-renders). La duda es legítima: el canva + kanban + streaming de agentes puede crecer mucho.

## Decisión

Mantener **React 19**. Aplicar optimizaciones dentro de React en vez de cambiar de framework:

1. **React Compiler** (`babel-plugin-react-compiler`) — auto-memoización de componentes sin `useMemo`/`React.memo` manuales.
2. **Virtual scroll** obligatorio en listas >50 items (canva/kanban).
3. **Stores Zustand por feature + WebSocket tipado** — cada ventanita actualiza solo su store, no todo el canva.
4. **Code-splitting** por espacio (Canva/Kanban/Sesión) con `React.lazy` + `Suspense`.
5. **Perf budget** en CI: <100KB JS crítico, <2s carga en 4G (Lighthouse CI).

## Consecuencias

**Positivas:**
- Se mantiene la reutilización del **fork de opencode** (`packages/console`, `packages/web` — escritos en React).
- Se conserva el ecosistema: shadcn/ui, React Flow (xyflow), Zustand, TanStack Query.
- Un solo framework en todo el monorepo (frontend + UI del fork del agente).
- React Compiler resuelve la mayoría de re-renders sin cambio de arquitectura.

**Negativas / a vigilar:**
- React sigue usando el VDOM (más memoria que Svelte en teoría), aunque el Compiler + virtual scroll lo compensan en la práctica.
- La reactividad fina de Solid no está disponible; si un grid en vivo llegara a degradarse, se aísla ese componente (no se cambia todo el framework).

## Alternativas evaluadas

| Alternativa | Por qué se descartó |
|---|---|
| Svelte/SvelteKit | Rompe reutilización del fork de opencode (React); dos frameworks en el monorepo |
| SolidJS | Sin shadcn/ui, sin React Flow estable, sin reutilización del fork; curva nueva para el agente |

## Referencias

- `docs/ADRs/ADR-002-ai-first-stack.md` — stack AI-first (fork opencode como motor).
- `docs/FUNDACION.md` — decisiones base.
- `docs/STACK-AI-FIRST.md` — evaluación por capa.
