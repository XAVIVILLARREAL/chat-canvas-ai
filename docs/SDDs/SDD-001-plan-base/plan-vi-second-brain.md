# PLAN VI — Segundo Cerebro (Grafo de archivos del proyecto)

> [← PLAN H](./plan-h-motor-pruebas.md) · [← Maestro](./README.md)
> Referencia: Obsidian Graph View, Karpathy's "second brain" concept, V3Code memory
> **Este plan reemplaza el antiguo "Canvas de Planeación" del SDD-005.** Ahora vive en el sidepanel.

**Entregable:** Una vista estilo Obsidian en el **sidepanel** de Canvas AI — el "segundo cerebro" donde navegas los archivos del proyecto como un grafo vivo, los editas con ayuda de IA, y haces planeación directamente desde el grafo.

---

## Qué construimos

Un **sidepanel derecho** que muestra los archivos del proyecto (.md, ADRs, planes, código) como un grafo interactivo — inspirado en Obsidian Graph View pero integrado nativamente en Canvas AI. No es una ventana separada: es una vista colapsable del sidepanel que se abre al lado del chat o del canvas.

**Casos de uso:**
- "Quiero ver cómo se conectan los documentos de mi proyecto"
- "Quiero editar este plan.md con ayuda de la IA"
- "Quiero crear un nuevo ADR basado en los que ya existen"
- "Quiero hacer planeación visual de las etapas del proyecto"

---

## Fases

### VI.1 — Modelo de datos de documentos

Tabla `documents` en SQLite:

```sql
CREATE TABLE documents (
  id TEXT PRIMARY KEY,
  path TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  summary TEXT,
  tags TEXT[],           -- tags del frontmatter o auto-detectados
  content_hash TEXT,     -- para detectar cambios
  embeddings BLOB,       -- SQLiteVec, vector del contenido
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  human_touched BOOLEAN DEFAULT FALSE  -- editado por humano (no por IA)
);
```

Tabla `document_edges`:

```sql
CREATE TABLE document_edges (
  source_id TEXT REFERENCES documents(id),
  target_id TEXT REFERENCES documents(id),
  edge_type TEXT,  -- 'wiki_link', 'heading_ref', 'tag_overlap', 'ai_suggested'
  weight REAL DEFAULT 1.0,
  PRIMARY KEY (source_id, target_id, edge_type)
);
```

- Watcher de archivos: detecta .md nuevos/cambiados del workspace (tokio fs watcher en Rust)
- Indexador: extrae enlaces wiki-style `[[enlace]]` y headings H2/H3 → edges del grafo
- FTS5 para búsqueda full-text sobre contenido de documentos
- Embeddings vectoriales (SQLiteVec) para búsqueda semántica

**Pruebas:** Cargo test parser de enlaces. Integration: crear/editar/borrar doc actualiza grafo.

---

### VI.2 — Layout IA del grafo

El grafo se auto-organiza inteligentemente:

- **Clustering automático**: por carpeta (docs/, src/, tests/), por tags, o por similitud de contenido (embeddings)
- **Posiciones calculadas y PERSISTIDAS** en `documents.spatial_meta` (SpatialMeta del plan base)
- **Force-directed al abrir**: el grafo se estabiliza solo, pero posiciones humanas se respetan
- **Cluster labels**: etiquetas flotantes por cluster (estilo Obsidian)
- **Fisión/fusión visual**: clusters se expanden/contraen al hacer zoom

**Pruebas:** Unit: clustering determinista (mismo input → mismo output). E2E: arrastrar nodo → recargar → posición conservada.

---

### VI.3 — Canvas interactivo (Render estilo Obsidian)

Nodos y edges en un canvas ReactFlow dedicado (reutiliza el mismo motor que el Control Room):

- **Nodos-tarjeta**: título + tags (badges) + resumen corto (1 línea) + icono de tipo (md, adr, plan, code)
- **Edges curvos**: Bezier suaves, coloreados por tipo de relación (wiki-link = azul, tag = gris, ai-suggested = púrpura punteado)
- **Zoom/pan fluido**: minimap en esquina inferior derecha
- **Búsqueda fuzzy**: barra arriba del grafo, ilumina subgrafo relevante (el resto se apaga)
- **Hover**: tooltip con preview del documento (primeras 5 líneas renderizadas)
- **Click**: abre el documento en el editor de markdown (Ver VI.4)
- **Look premium**: liquid-glass en los nodos, sombras difuminadas, animaciones de entrada suave

**Pruebas:** E2E: navegar grafo grande (>200 docs) sin jank. Performance: 60fps con 500 nodos.

---

### VI.4 — Edición humano+IA (Markdown inline)

El sidepanel tiene un **modo editor** que se abre al hacer click en un nodo del grafo:

- **Editor de markdown** embebido (Monaco o CodeMirror con soporte MD)
- **Syntax highlighting** para MD, frontmatter YAML, code blocks
- **Preview renderizado** lado a lado (split view o toggle)
- **Ayuda de IA integrada**:
  - Seleccionar texto → "mejorar", "resumir", "expandir", "reformatear"
  - `/plan` → la IA analiza el documento y propone estructura de etapas
  - `/link` → la IA sugiere documentos relacionados y crea enlaces `[[...]]`
  - `/review` → la IA audita el documento y sugiere mejoras (con diff previo)
- **Planeación asistida**:
  - Crear nodos-tipo ETAPA/FASE/PLAN desde el editor
  - "reordena estas secciones", "propón una estructura para X"
  - Siempre con **diff previo aceptable** por el humano (nunca auto-aplica)
- **Cambios humanos** marcan el nodo como `human_touched` (distinto de cambios IA)

**Pruebas:** Integration: síntesis crea doc nuevo + edges. E2E humano: editar → guardar → grafo actualiza.

---

### VI.5 — Consejo de Expertos (skills auditores visuales)

Skills que **auditan tu plan/diseño** y hacen preguntas para definir lo indefinido. Viven en un panel derecho del sidepanel.

**Roster inicial (5 expertos precargados):**

| Expert | Enfoque | Qué audita |
|---|---|---|
| 🔐 Ciberseguridad | Threat modeling | Auth, permisos, datos sensibles, inyección |
| 🎨 Frontend | UX/UI, performance | Componentes, accesibilidad, bundle size, animaciones |
| 🏗️ Infraestructura | Deploy, Docker, CI/CD | Escalabilidad, costos, monitoreo, errores |
| 📈 Escalabilidad | Performance, concurrencia | Queries N+1, cache, memory leaks, latencia |
| 🧭 Arquitectura | Decisiones de diseño | acoplamiento, testabilidad, deuda técnica |

Cada experto es un **skill estándar** con:
- **Tool-gating READ-only**: solo puede leer documents/knowledge, nunca modificar
- **Identidad viva**: avatar generado por IA, emoji-firma, mini-bio (del Plan G)
- **Invocación desde el grafo**: seleccionas nodo(s) → click derecho → "Auditar con… [experto]"

**Panel derecho "Consejo":**
- Inbox de cards animadas por experto (1 card = 1 pregunta)
- Cada card tiene: contexto citado del documento + opciones clicables
- Los expertos trabajan **EN PARALELO** (no secuencial)
- Respuesta del humano = rung DECISION en el Decision Ledger + diff aplicado al .md
- Cards-debate cuando dos expertos recomiendan opuestos (el humano decide)

**Pruebas:** E2E: convoco 2 expertos → preguntas llegan en paralelo → respondo → diffs aplicados al .md → grafo actualiza.

---

### VI.6 — Discovery Hub (explorador de repos)

Panel inferior del sidepanel (sección colapsable "Discovery"):

- **Explorador GitHub**: buscar repos por nombre, descripción, topic, lenguaje
- **Repo Scout** (skill IA): sugiere repos relevantes según el contexto del proyecto actual
- **Acciones sobre un repo encontrado**:
  - Agregar como referencia → crea nodo en el grafo con link al repo
  - Clonar al workspace → descarga y indexa los .md del repo
  - Copiar URL
- **Preview inline**: README renderizado + estructura de archivos (tree)
- **Historial de búsquedas** persistido por proyecto

**Pruebas:** E2E: buscar "react table" → preview de README → agregar como referencia → nodo aparece en grafo con edges a docs relacionados.

---

## 🚪 GATE VI (demo verificable)

Abro el sidepanel → selecciono "Grafo" → veo los archivos de ESTE proyecto como nodos → veo clusters reales (docs/, SDDs/, src/) → busco "kanban" → solo ese subgrafo brilla → hago click en SDD-005 → se abre en el editor de MD → edito un título → guardo → el nodo en el grafo se actualiza → la IA me sugiere 2 documentos relacionados → creo enlaces `[[...]]` → los edges aparecen.

Convoco al Consejo de Expertos → selecciono "Arquitectura" → el experto me hace 3 preguntas sobre el plan → respondo con clicks → se aplican diffs al .md → veo el diff antes de aceptar.

Abro Discovery Hub → busco "hermes-agent" → veo el README → agrego como referencia → nuevo nodo aparece en el grafo conectado a mis docs de arquitectura.

Suite humana verde.

---

## Dependencias

- **Etapa 4** (Memoria): Decision Ledger para registrar rungs de edición
- **Etapa 8** (Editor de código): editor MD embebido (Monaco/CodeMirror)
- **Etapa 5** (Skills): para los 5 expertos auditores
- **Plan D** (workspace knowledge): FTS5 y embeddings para búsqueda

---

[← Maestro](./README.md)
