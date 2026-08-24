# PLAN J — Etapa 10: Grafo 3D Repo-Map (Three.js)

> [← Maestro](./README.md) · [← PLAN I](./plan-i-revision-superposiciones.md) · [PLAN K →](./plan-k-voz.md)
> Depende de: Etapas 8-9. Fuente: copia.md Capa 4 (Aider tree-sitter + PageRank) + V3Code (grafo de relaciones, Beast search).

**Entregable:** el repo entero como grafo 3D navegable — y el mismo índice comprime el proyecto a <1000 tokens para el contexto del agente.

<a id="j1"></a>
### J.1 — Indexador AST
- Tree-sitter (crate Rust) parsea el workspace → `repo_symbols` (file, symbol, kind, líneas) + edges import/call
- PageRank en Rust sobre el grafo; indexado incremental por watcher (solo archivos cambiados)
- **Client-first**: el indexador también compila a **WASM (web-tree-sitter)** y corre en el NAVEGADOR del usuario cuando el repo es suyo (edición/consulta instantánea sin servidor); el servidor solo indexa cuando un agente 24/7 lo necesita — el repo-map resultante viaja como tokens, no como CPU
- **Pruebas:** Cargo test con fixture multi-archivo TS/Rust: símbolos+edges correctos, pagerank orden esperado

<a id="j2"></a>
### J.2 — Repo-map compacto
- Serializador que genera mapa textual del repo rankeado por pagerank ≤1000 tokens
- Inyectable como contexto en providers ([C·C.2](./plan-c-reasonix-deepseek.md#c2)), toggle por tarea
- **Pruebas:** Unit presupuesto tokens (hard cap). Integration: prompt capturado contiene mapa

<a id="j3"></a>
### J.3 — Visor 3D
- Three.js: nodos=archivos (escala=pagerank), edges=imports; colores térmicos según actividad reciente y fallos de tests ([H](./plan-h-motor-pruebas.md#h3))
- Click→abre archivo ([B·B.2](./plan-b-sidepanels-lovable.md#b2)); controles orbit + touch; LOD para repos grandes
- **Pruebas:** E2E humano: rotar/zoom, click nodo abre archivo correcto; perf 60fps con 500 archivos

## 🚪 GATE J

Abro el grafo 3D del propio proyecto empresa-dev: veo clusters reales (components/hooks/stores), los archivos más "importantes" destacan por tamaño, los que fallan tests brillan en rojo, click me lleva al código. Y una pregunta al chat usa el repo-map (verificado en request capturado). Video 360° + suites verdes.

---
[← Maestro](./README.md) · [← PLAN I](./plan-i-revision-superposiciones.md) · [PLAN K →](./plan-k-voz.md)
