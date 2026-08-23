# PLAN B — Sidepanels Lovable (ver lo que se construye)

> [← Maestro](./README.md) · [← PLAN A](./plan-a-chat-codex.md) · [PLAN C →](./plan-c-reasonix-deepseek.md)
> Depende de: [PLAN A](./plan-a-chat-codex.md) (stores, provider trait, eventos).

**Entregable:** pides una mini-app y la VES aparecer archivo por archivo, con preview corriendo en vivo.

## Fases

<a id="b1"></a>
### B.1 — Workspace virtual + detección Codex
- Proyecto activo en `~/EmpresaDev/projects/<id>/` (fs scoped por Rust) — con [A·A.0](./plan-a-chat-codex.md#a0), cambiar de TAB cambia árbol+editor+preview completos: cada proyecto vive en su mundo
- Artefactos versionados ([B·B.9](./plan-b-sidepanels-lovable.md#b9)) y diffs siempre dentro del proyecto activo

- Detección inicial estilo Codex: carpeta con git → preset **Auto**; sin git → **Solo lectura** hasta que el usuario confíe
- File tree lazy + commands fs seguros (anti path-traversal, cargo deny list)
- **Pruebas:** Cargo test seguridad paths. E2E: árbol refleja archivos creados por el agente

<a id="b2"></a>
### B.2 — Editor Monaco
- Tabs de archivos abiertos; read/write real; guardar Cmd/Ctrl+S
- Indicador "AGENTS.md cargado" del proyecto (solo lectura v1 — el que lo lee es Reasonix, ver [C·C.2](./plan-c-reasonix-deepseek.md#c2))
- **Pruebas:** E2E abrir archivo escrito por agente, editarlo, persistir

### B.3 — Live Preview
- iframe sandbox (`allow-scripts`, origen opaco, sin same-origin al app) renderizando el index.html del proyecto
- Watcher de escrituras (notify crate) → debounce 300ms → evento `workspace://changed` → refresh preview
- **Pruebas:** unit debounce watcher. E2E: agente escribe HTML → preview actualizado <2s

<a id="b4"></a>
### B.4 — Sincronización chat ↔ paneles (patrón desktop Codex)
- Click en card de tool-call ([A·A.4](./plan-a-chat-codex.md#a4)) abre el archivo/diff tocado en la WorkArea
- **Diff clicable con feedback**: cada fila de diff tiene acción "feedback" → texto se inyecta como contexto del siguiente turno
- Badge "N cambios" en tab Preview mientras el agente genera
- **Pruebas:** E2E flujo integrado completo

<a id="b5"></a>
### B.5 — Fast Apply: escritura especulativa (copia.md §Cursor/Morph)
- Desacoplar razonamiento del agente de la ESCRITURA: los diffs llegan como stream y se aplican a archivo a >velocidad de lectura humana, sin truncamientos ni reescrituras completas
- Protocolo: eventos `file_delta` (path, range, contenido) desde el provider → aplicador en Rust con cola ordenada → optimistic UI en Monaco/Preview mientras persiste
- Si un delta llega inválido → rollback del archivo a último estado bueno + aviso inline (fail-safe)
- **Pruebas:** Cargo test aplicador: 500 deltas/sec sintéticos sin pérdida ni desorden. E2E humano: ver un archivo grande escribirse fluido en vivo

<a id="b9"></a>
### B.9 — Artefactos versionados (patrón Claude artifacts)
- El preview/archivo principal de una tarea se trata como ARTEFACTO con historial de versiones navegable
- Selector ‹v2/v5› + comparación side-by-side entre dos versiones + "restaurar esta versión" (con rung en Ledger)
- Cada versión muestra quién/cuándo (agente o humano) y qué criterio la cambió
- **Pruebas:** Integration versionado automático por escritura relevante. E2E humano: navegar 3 versiones, comparar side-by-side, restaurar antigua

## 🚪 GATE B (demo verificable)

Prompt real: *"crea una landing para una cafetería"* → aparecen archivos en el árbol, Monaco los muestra al click, el preview renderiza la página terminada en vivo. El usuario no tocó código. Feedback en un diff se refleja en la corrección del agente.

Evidencia: video + suites verdes.

---
[← Maestro](./README.md) · [← PLAN A](./plan-a-chat-codex.md) · [PLAN C →](./plan-c-reasonix-deepseek.md)
