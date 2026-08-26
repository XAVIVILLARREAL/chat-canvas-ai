# PERFORMANCE-BUDGETS — Presupuestos de rendimiento (medidos, no deseados)

> **Producto:** Canvas AI · **Estado:** v1.0 · 2026-08-25 · Gate en [T.QA](./SDDs/SDD-001-plan-base/plan-t-excelencia.md#tqa) — regresión = build rojo.

## 1 · Arranque y bundle

| Métrica | Presupuesto | Verificación |
|---|---|---|
| Tiempo a UI interactiva (local, SSD) | **< 2 s** | bench CI cold start |
| Bundle JS inicial (gzip) | **< 250 KB** total | `vite build` + analyzer |
| Monaco | **lazy** (carga on-demand) | nunca en el chunk inicial |
| ReactFlow | lazy | — |
| CSS | **< 50 KB** gzip | — |

## 2 · Interacción

| Métrica | Presupuesto |
|---|---|
| Canvas 100 nodos + 150 edges | **60 fps** (WebGL/WebGPU; WebGL fallback) |
| Búsqueda fuzzy en lista > 500 items | **< 100 ms** |
| Streaming: TTFT | **< 1 s** ([SLO-RELIABILITY](./SLO-RELIABILITY.md)) |
| Live preview (agente escribe → preview) | **< 2 s** |
| Persistencia de canvas (drag → guardado) | **< 100 ms** debounced, sin jank |

## 3 · Reglas de implementación (anti-lag)

1. **Virtualización** en toda lista > 50 items (`useVirtualList`).
2. **`motion`**: animar solo `transform` y `opacity`; sin `layout` en listas grandes; stagger máx 20 items.
3. **Sin `will-change`** salvo animaciones continuas.
4. **React Query**: `staleTime` por tipo (catálogos 60-120s · datos 10-30s · tiempo real 0s); invalidar tras mutación.
5. **IPC Tauri** (plan-s S.3): streaming por `Channel<TokenEvent>` batch 30ms; payloads grandes binarios (`Channel<Vec<u8>>`), no JSON.
6. **Monaco** nunca en el hilo principal durante el streaming del chat (chunk separado + idle-load).
7. **Server Rust**: `sonic-rs` en hot-path LLM (>100 KB), `postcard/rkyv` interno ([plan-s](./SDDs/SDD-001-plan-base/plan-s-despliegue-costos.md#s2)).

## 4 · Verificación en CI

- `vite build` con presupuesto de tamaño (falla si excede).
- Bench de arranque con Puppeteer/Playwright: cold + warm.
- Canvas 60fps: test de frames en CI (dev) y bench manual en cada gate F.6.
- Regresión responsive en CI: scroll horizontal en móvil, touch targets, layout a 375px = rojo.
