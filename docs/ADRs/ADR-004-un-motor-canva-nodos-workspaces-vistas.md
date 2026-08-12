# ADR-004 — Un solo motor de canva: nodos extensibles + workspaces + vistas

- **Estado:** Aceptado (2026-08-12).
- **Decisión:** **UN único motor de canva reutilizable** (`CanvaView` + `canva_core`
  como modelo) sirve a TODOS los dominios: hosts, notas `.md`, sesiones de
  agentes, propuestas, el tablero de tareas y la oficina multiagente. Los nodos
  son el punto de extensión (`CanvaNodeType` crece), cada canva es un
  **documento/workspace** sobre el mismo lienzo, y las **vistas** filtran por
  dominio. **NO** se construyen pantallas de canva separadas por dominio.
- **Tags:** canva, arquitectura, workspaces, nodos, oficina, tablero, empresa-autonoma

## Contexto

El canva nació como la superficie del "Termius con supervitaminas" (hosts SSH +
notas). Sobre esa misma superficie se han ido apilando dominios con semánticas
distintas:

- **Hosts SSH** (Etapa 1) → `CanvaNodeType.host`.
- **Notas `.md` con `[[links]]`** (Etapa 4) → `note`, con `DocsMapBuilder.build()`
  que ya carga un canva entero desde una carpeta.
- **Sesiones de agente opencode** (Etapa 2) → `agent`.
- **Propuestas vibecoding** (Etapa 6) → `proposal` (nodo-diff).
- **Visión empresa autónoma** (SDD-115, AGENTS.md): el canva ES el tablero
  (tarjetas = nodos, columnas = estados) y ES la oficina (agentes como
  empleados con estados `working/blocked/waiting_approval`), y varias
  "empresas" operan en paralelo sobre worktrees distintos.
- **Etapa 8.2**: el canva como espejo en vivo del grafo LangGraph.

Con tantos dominios sobre el lienzo, el riesgo real es fragmentar el producto en
**N pantallas canva** (un canva de `.md`, otro de agentes, otro de la oficina):
código duplicado, UX fragmentada, y el LOD/clustering/benchmark de 8.6 tendría
que reimplementarse por pantalla.

## Decisión

1. **Un widget `CanvaView`** (en `apps/empresa_dev/lib/widgets/`) encapsula el
   motor: `InteractiveViewer` + `TransformationController`, culling por
   viewport, clusters por zoom, painter de edges y drag/tap. Renderiza
   **cualquier** `List<CanvaNode>`; el LOD (SDD-121) ya es agnóstico del tipo de
   nodo. `CanvaScreen` pasa a ser una instancia de `CanvaView` con su store.
2. **Los nodos son el punto de extensión.** `CanvaNodeType` crece por dominio
   (`task`/`card` para el tablero, `office` para el agente-empleado, etc.). Cada
   tipo aporta su card/painter (dispatcher por tipo); el render genérico del LOD
   (RRect + label) cubre los tipos sin card propia.
3. **Un canva = un documento/workspace.** El estado de un canva (`CanvaState`)
   es la unidad de persistencia (`CanvaStore` keyed por id de documento). Varios
   workspaces coexisten y el usuario cambia entre ellos (tabs/selección). La
   **multi-empresa** de la visión = varios workspaces operando en paralelo sobre
   el mismo lienzo, cada uno aislado en su worktree.
4. **Vistas por dominio dentro de un documento.** Un filtro "solo md" / "solo
   oficina" / "tablero" recorta los nodos antes del render (el culling y el
   clustering ya operan sobre la lista visible, sin coste adicional). La vista
   "oficina" añade la animación de estados (8.2) sobre los mismos nodos `agent`.
5. **El `EdgesPainter` y el modelo de edges** son compartidos: las aristas del
   tablero (dependencia/bloqueo), del grafo `.md` (backlinks) y de la oficina
   (edge del grafo LangGraph) son `CanvaEdge`s con `from/to`.

## Consecuencias

**Positivas:**
- El LOD, clustering y benchmark de 8.6 sirven para todos los dominios desde el
  día uno (10k nodos @ ~3 ms/frame ya probado).
- Una superficie unificada (estilo Termius): el usuario no salta entre "canva de
  notas" y "canva de agentes"; son la misma hoja con filtros.
- La oficina, el tablero y las notas conviven: un agente-empleado puede tener su
  tarjeta de tarea, su nota `.md` y su sesión en el mismo workspace.
- Menos código: un solo motor, painter de edges, drag y store.

**Negativas / a vigilar:**
- El render por tipo exige un **dispatcher polimórfico** (card por
  `CanvaNodeType`) — mantenerlo simple (la vista genérica del LOD cubre los
  tipos sin card).
- Riesgo de **sobrecarga visual** al mezclar dominios → mitigado con las vistas
  (filtros por defecto razonables por documento).
- La UX de interacción (drag vs tap vs long-press) debe ser consistente entre
  tipos: el `CanvaView` define los gestos y cada tipo decide qué acción ejecuta
  el tap.

## Alternativas descartadas

| Alternativa | Por qué |
|---|---|
| **Un canva por dominio** (canva-md, canva-agentes, canva-oficina) | Código duplicado, LOD/clustering/benchmark por reimplementar, UX fragmentada, y rompe la visión "el canva ES el tablero/oficina" |
| **Un solo canva sin workspaces ni vistas** | Todo mezclado en una hoja → desorden; no soporta multi-empresa en paralelo (requiere separación por workspace) |
| **Reutilizar `ProjectGraphScreen` como canva** | Es un grafo de fuerza dirigida (otra semántica de layout); el canva es de posición libre/drag. Pueden convivir (grafo = vista del proyecto, canva = superficie de trabajo), pero no sustituirse |

## Referencias

- `docs/SDDs/SDD-121-etapa86-canva-lod.md` (motor: culling + clusters + benchmark).
- `docs/SDDs/SDD-112-canva-ideas-md.md` (Etapa 4: notas `.md` + backlinks en el canva).
- `docs/SDDs/SDD-115-empresa-autonoma-crewai-langgraph.md` (visión oficina/tablero).
- `docs/SUPER_PLAN.md` (Etapa 8.2: canva = espejo del grafo; 8.6: LOD).
- `packages/canva_core/` (`CanvaNode`, `CanvaNodeType`, `CanvaEdge`, `CanvaState`, `CanvaCuller`, `CanvaClusterer`).
