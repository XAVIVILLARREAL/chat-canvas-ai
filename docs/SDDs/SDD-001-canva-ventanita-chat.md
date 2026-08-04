# SDD — Slice vertical: Canva + Ventanita + Chat "hola"

> **Proyecto:** empresa-desarrollo-autonoma — Etapa 1, primer slice vertical (FUNDACION §8).
> **Fecha:** 2026-08-02. **Estado:** Pendiente de implementar.

## Objetivo

Validar todo el stack (front + server + túnel + CI) con el camino más corto posible: un **canva infinito** donde se puede **insertar una ventanita de agente**, y al hacer clic se abre una **ventana de chat** que habla con el servidor Hono y recibe una respuesta "hola" por streaming (SSE). Después se crece: voz, evidencia, fork de opencode.

## Alcance (slice vertical)

- Monorepo pnpm: `apps/web` + `apps/server` + `packages/ui` (vacio inicial) + `packages/config`.
- **apps/web:** canva con React Flow, nodos personalizados (caja/nota + **ventanita de agente**), panel lateral de inserción, click → abre modal de chat.
- **apps/server:** Hono con `/api/health` y `/api/chat` (POST, respuesta "hola" con streaming SSE).
- **Canva:** persistencia en `localStorage` (Etapa 1; SQLite llega con sesiones reales).
- **CI:** typecheck + lint + test + build (GitHub Actions).
- **Túnel:** servido en `https://empresa-dev.xtremediagnostics.com` (puerto 7688).

## Fuera de alcance (siguientes slices)

- Fork de opencode conectado (sesiones reales en directorios) — Fase 2.
- Voz STT/TTS — Fase 3.
- Screenshots de evidencia por prompt — Fase 4.
- SQLite/Postgres real, kanban, LangGraph, multi-ventanita persistida en servidor.

## Flujo (caso feliz)

1. Usuario abre `apps/web` → ve el canva vacío con barra de herramientas.
2. Arrastra (o click en menú) una **ventanita de agente** al canva → aparece el nodo con mini-UI.
3. Click en la ventanita → se abre el **modal de chat** sobre el canva (mobile: pantalla completa).
4. Escribe "hola" → POST `/api/chat` → el servidor responde con streaming SSE: `"hola desde Hono"`.
5. Los tokens aparecen en el chat en vivo.
6. Cierra el modal → la ventanita vuelve a su posición en el canva.

### Casos límite

- **Carga lenta / servidor caído:** el chat muestra estado "conectando" y error con reintento.
- **SSE no soportado:** fallback a respuesta JSON única.
- **Canva vacío:** muestra hint "arrastra nodos desde la izquierda".
- **Responsive:** en móvil el canva se navega con un dedo; el modal de chat es full-screen.
- **Múltiples ventanitas:** cada ventanita es un nodo independiente con su propio id; el chat abre la del clic.

## Contratos

### POST `/api/chat`

```
Request:  { message: string }
Response: SSE stream
  data: { id: "1", content: "hola desde Hono" }
  ...
  data: [DONE]
```

### GET `/api/health`

```
Response: { status: "ok", uptime: number }
```

### Tipos compartidos (packages/config o apps/server)

```ts
type ChatChunk = { id: string; content: string };
type Health = { status: "ok"; uptime: number };
```

## Datos

- **Canva (localStorage):** `{ nodes: Node[], edges: Edge[] }` con el estado de React Flow. Clave `empresa-canva-v1`.
- **Sesión de chat:** en memoria (componente). Sin persistencia en este slice.

## Errores

| Error | Manejo |
|---|---|
| `/api/chat` 500 | mostrar error en el chat + botón reintentar |
| servidor caído | estado "conectando" → error con reintento (backoff) |
| SSE cortado | reconectar automáticamente (2 intentos) |

## Tests

- **Unit (apps/server):** `GET /api/health` → 200 `status ok`. `POST /api/chat` → devuelve chunk "hola".
- **Unit (apps/web):** el canva renderiza; insertar ventanita agrega nodo; click abre modal.
- **Smoke (Playwright, fase UI Tester):** `apps/web` carga, insertar ventanita, escribir "hola", ver respuesta.

## Verificación de UI (que probará el UI Tester con Chrome headless)

1. Abrir `http://localhost:7688` → canva visible, sin errores de consola.
2. Insertar ventanita de agente → el nodo aparece en el canva.
3. Click en la ventanita → el modal de chat se abre.
4. Escribir "hola" → aparece "hola desde Hono" en el chat.
5. Captura de pantalla de cada paso como evidencia.

## Definition of Done (este slice)

- [ ] Monorepo con `apps/web` + `apps/server` corriendo localmente.
- [ ] Canva inserta ventanita y abre chat.
- [ ] Chat responde "hola desde Hono" con streaming.
- [ ] CI verde (typecheck + lint + test + build).
- [ ] UI verificado en Chrome headless con capturas (servido en 7688 / túnel).
