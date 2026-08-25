# PLAN F — Canvas de Automatización + Kanban de Resultados

> [← PLAN E](./plan-e-integracion-total.md) · [← Maestro](./README.md) · [PLAN G →](./plan-g-skills-lab.md)
> Referencia primaria: ERP Docker Compose AI Canvas (FlowsApp) — deploy-spec, node types, compiler
> Referencia: n8n/Activepieces (UX visual), Hermes Agent (agent orchestration)
> **KR (Kanban de Resultados)** es una pantalla secundaria de este plan — no vive por separado.

**Entregable:** Visual workflow builder para automatizaciones + vista Kanban evidencia-first donde se ve el progreso de tareas con evidencia real (tests, diffs, costo).

---

## Qué construimos

Un canvas donde se **dibujan** automatizaciones que ejecutan agentes de IA:
- Arrastrar nodos (LLM, agent, tool, code, trigger) y conectarlos
- Cada nodo es un paso en un flujo
- El flujo se ejecuta con lógica real (condiciones, loops, paralelismo)
- Multi-runtime: cada nodo puede ser Python, TypeScript, Go, Bash, o SQL
- **No es n8n**: es código nativo, no JavaScript limitado
- **No es un editor de workflows simple**: es un orquestador de agentes

---

## Fases

### F.1 — Node Type Registry

Basado en el AI Canvas del ERP (8 tipos existentes):

| Tipo | Función | Runtime |
|---|---|---|
| **LLM** | Llamada a modelo de IA | API (DeepSeek, OpenAI, Ollama) |
| **Agent** | Sub-agente con rol y herramientas | ACP (Hermes) |
| **Tool** | Herramienta externa (MCP, HTTP, file) | MCP stdio/HTTP/SSE |
| **Code** | Código custom del usuario | Python/TS/Go/Bash/SQL |
| **Trigger** | Evento de inicio (cron, HTTP, manual, file watch) | Runtime del trigger |
| **Condition** | Bifurcación lógica (if/else) | Evaluación en runtime |
| **Transform** | Transformación de datos (map, filter, merge) | Runtime del nodo |
| **Output** | Resultado final (file, HTTP response, notification) | Runtime del output |

Cada tipo tiene:
- `component`: React component para el canvas (nodo visual)
- `executor`: función Rust/TS que ejecuta el nodo
- `schema`: Zod schema para configuración
- `icon`: Lucide icon
- `color`: color en el canvas

**Pruebas:** Unit: registry carga todos los tipos. E2E: arrastrar cada tipo al canvas.

---

### F.2 — Deploy-spec Universal

Contrato TypeScript que todo nodo debe cumplir:

```typescript
interface NodeDeploySpec {
  type: string;
  config: Record<string, unknown>;
  inputs: string[];    // nombres de inputs esperados
  outputs: string[];   // nombres de outputs producidos
  runtime: 'python' | 'typescript' | 'go' | 'bash' | 'sql';
  timeout: number;     // ms
  retries: number;
  onError: 'stop' | 'skip' | 'retry' | 'escalate';
}
```

El canvas compiler lee el grafo visual y genera un `DeploymentPlan`:
- Topological sort de nodos
- Paralelización de nodos sin dependencias
- Asignación de runtimes
- Generación de código ejecutable

**Pruebas:** Cargo test: grafo → deployment plan. Verificar topological sort correcto.

---

### F.3 — Canvas Compiler

Convierte el grafo visual en ejecución:

1. **Parse**: leer nodos y edges del canvas
2. **Validate**: verificar que todos los inputs están conectados, tipos compatibles
3. **Optimize**: paralelizar nodos independientes
4. **Compile**: generar código ejecutable (o plan de ejecución interpretado)
5. **Deploy**: enviar al worker para ejecución

Modos:
- **Diseño**: solo visualización, sin ejecución
- **Ejecución**: nodos se iluminan según estado (pending → running → done/error)
- **Debug**: paso a paso, inspeccionar outputs de cada nodo

**Pruebas:** E2E: crear flujo de 3 nodos, compilar, ejecutar, verificar outputs.

---

### F.4 — Workflow-as-code Codec

Serialización/deserialización de workflows:

- **Export**: canvas → JSON (nodos, edges, config, metadata)
- **Import**: JSON → canvas reconstruido
- **Versionado**: cada guardado crea una versión (diff visual entre versiones)
- **Share**: export como `.canvas-ai-flow` (zip con JSON + assets)
- **Template**: workflows pre-construidos que se pueden clonar y modificar

Formato JSON:
```json
{
  "version": "1.0",
  "nodes": [...],
  "edges": [...],
  "config": {...},
  "metadata": {
    "name": "Mi automatización",
    "description": "...",
    "author": "...",
    "tags": [...]
  }
}
```

**Pruebas:** Cargo test: serialize → deserialize → mismo resultado. E2E: export → import → canvas idéntico.

---

### F.5 — Conectores

Nodos que se conectan al exterior:

| Conector | Tipo | Ejemplo de uso |
|---|---|---|
| **HTTP** | Request/response | Llamar APIs externas |
| **WebSocket** | Bidireccional | Datos en tiempo real |
| **MCP Server** | stdio/HTTP/SSE | Herramientas de IA |
| **Cron** | Programado | Tareas periódicas |
| **File Watch** | Evento | Reaccionar a cambios de archivo |
| **Email** | IMAP/SMTP | Procesar emails |
| **Database** | SQL directo | Queries a PostgreSQL/SQLite |

Cada conector tiene retry, timeout, y circuit breaker.

**Pruebas:** Unit: cada conector con mock. Integration: flujo real con conector HTTP.

---

### F.6 — Historial de ejecuciones

Cada ejecución del canvas se registra:
- Timestamp de inicio/fin
- Estado de cada nodo (pending/running/done/error/skipped)
- Outputs de cada nodo
- Logs
- Costo total (tokens, USD, tiempo)
- Retry count
- Error messages

Vista de historial:
- Timeline de ejecuciones
- Click en ejecución → ver estado de cada nodo
- Re-ejecutar con los mismos inputs
- Comparar ejecuciones (diff)

**Pruebas:** E2E: ejecutar flujo, verificar historial, re-ejecutar.

---

### F.7 — VR-ready Canvas

Todo el canvas se diseña para VR:

- **Coordenadas 3D**: nodos tienen x, y, z (z = profundidad para capas)
- **1 unidad = 1 metro**: tamaños proporcionales, no absolutos
- **Sin absolute CSS**: todo usa el sistema de coordenadas de ReactFlow
- **`vr={{}}` preparado**: ReactFlow tiene soporte VR futuro
- **Animaciones GPU-friendly**: solo transform y opacity
- **Capas de profundidad**: nodos base (z=0), edges (z=0.1), overlays (z=0.5)
- **Colores WCAG AAA**: contraste suficiente para AR

**Pruebas:** Visual: canvas renderiza correctamente en diferentes tamaños de ventana.

---

## KR — Vista Kanban de Resultados (pantalla secundaria)

> **KR es una vista del Canvas de Automatización**, no una ventana separada. Se accede desde un tab/toggle dentro de la misma vista de Oficina.

### KR.1 — Tablero de resultados

Columnas: **objetivo → en-curso → verificado → entregado**

- Cards = tareas con evidencia: mini-gráfica de tests, contador de criterios ✓, costo USD, duración
- Filtros por agente, estado, proyecto
- Cada card muestra el nodo de automatización asociado (si existe)

**Pruebas:** Unit: estados de card. E2E: tarea avanza columnas con eventos reales.

---

### KR.2 — Bloques animados de pruebas

Al correr tests:
- Bloque de la card se **llena verde test-por-test** (animación progresiva)
- Fallo → bloque **rojo pulsante** + diff clicable
- Animación de **"batería completada"** al pasar todos los tests
- Sonido diferenciado (opcional, respeta configuración)

**Pruebas:** Parser de resultados → eventos UI. E2E con mock runner.

---

### KR.3 — Modo autonomía prolongada

Botón **"trabaja X horas"**:
- Cola de tareas se consume sola (el agente toma decisiones)
- Kanban muestra progreso en vivo (cards se mueven entre columnas)
- Digest cada N tareas (resumen automático de qué se hizo)
- **Límite de costo configurable** (corte seguro — el agente se detiene al llegar al tope)
- Notificación al humano cuando termina o cuando necesita decisión

**Pruebas:** Integration: cola mock → consumo ordenado + corte por presupuesto.

---

### KR.4 — Vista evidencia por etapa

Click en card → panel lateral con **timeline de rungs** de ESA tarea:
- plan → diffs → tests → review
- Thumbnails de screenshots cuando existan
- Costo total de la tarea (tokens + USD)
- Expandir/colver rungs individuales

**Pruebas:** E2E humano: recorrer evidencia completa sin salir del kanban.

---

### KR.5 — Filtros y salud del board

- Filtrar por agente / etapa / estado-de-tests
- Indicadores de **estancamiento** (tarea >X horas sin cambio → badge amarillo)
- Indicador de **tests flaky** (cuarentena — tests que pasan/fallen intermitentemente)
- Resumen del board: total tareas, % completado, costo total, tiempo promedio

**Pruebas:** E2E: filtros combinados; card estancada muestra badge.

---

## 🚪 GATE F (demo verificable)

**Canvas de automatización:** abro Canvas AI → voy al canvas de automatización → arrastro un nodo LLM → le configuro el prompt → arrastro un nodo Code (Python) → conecto LLM → Code → arrastro un nodo Output → conecto todo → le doy Execute → veo los nodos iluminarse en orden → el output aparece en el nodo final → guardo el flujo → lo exporto como JSON → lo importo de nuevo → el canvas se reconstruye idéntico.

**Kanban:** activo "trabaja 4 horas" con 15 tareas → me alejo → vuelvo: tablero muestra bloques verdes animados de tests, 12 entregadas, 2 en revisión, 1 bloqueada con causa. Abro evidencia de cualquiera y todo está ahí.

Suite humana verde.

---

[← PLAN E](./plan-e-integracion-total.md) · [← Maestro](./README.md) · [PLAN G →](./plan-g-skills-lab.md)
