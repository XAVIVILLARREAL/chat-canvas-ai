# PLAN J — Etapa 10: Grafo 3D Repo-Map (Three.js)

> [← Maestro](./README.md) · [← PLAN I](./plan-i-revision-superposiciones.md) · [PLAN K →](./plan-k-voz.md)
> Depende de: Etapas 8-9. Fuente: copia.md Capa 4 (Aider tree-sitter + PageRank) + V3Code (grafo de relaciones, Beast search).

**Entregable:** el repo comprimido a <1000 tokens para el contexto del agente (J.1/J.2, en base) — el visor 3D navegable (J.3) se MOVIÓ al [Plan Intermedio (3D)](../SDD-005-plan-intermedio.md) (decisión v3.8): es una vista premium que comparte motor con el visor 3D unificado.

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
### J.3 — Visor 3D (MOVIDO al Plan Intermedio — [SDD-005 3D](../SDD-005-plan-intermedio.md))
- **Decisión v3.8 (ratificada)**: J.3 se construye en el intermedio junto a 3D.1/3D.2 (visor unificado de documentos+kanban+sesiones) — J.1/J.2 sí quedan en base porque el repo-map alimenta el contexto del agente
- Tres.js: nodos=archivos (escala=pagerank), edges=imports; colores térmicos según actividad y fallos de tests ([H](./plan-h-motor-pruebas.md#h3)); click→abre archivo ([B·B.2](./plan-b-sidepanels-lovable.md#b2)); LOD
- **Pruebas:** E2E humano: rotar/zoom, click nodo abre archivo correcto; perf 60fps con 500 archivos

## 🚪 GATE J

El repo-map (J.2) entra al contexto del agente: una pregunta al chat usa el mapa (verificado en request capturado, ≤1000 tokens) y el índice AST (J.1) indexa el workspace en <100ms/archivo — con el indexador también corriendo en el navegador (WASM, client-first). El VISOR 3D se demuestra en el intermedio (J.3 + 3D.2). Suites verdes.

---
[← Maestro](./README.md) · [← PLAN I](./plan-i-revision-superposiciones.md) · [PLAN K →](./plan-k-voz.md)
