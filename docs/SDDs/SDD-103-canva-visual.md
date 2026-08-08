# SDD — Fase 1.3: Canva visual (mapa de infraestructura)

> **Proyecto:** empresa_dev — Fase 1.3 del ROADMAP.
> **Fecha:** 2026-08. **Estado:** En implementación.

## Objetivo

El **diferenciador del producto**: un canva infinito donde cada nodo es un **host SSH**, una **nota**, o un **contenedor**. Es el mapa visual de tu infraestructura. Click en un nodo host → abre el terminal. Las conexiones entre hosts dibujan la topología.

## Alcance (este slice)

- **Canva infinito** (zoom/pan) con `InteractiveViewer`.
- **Nodos**: host SSH (conecta a terminal), nota (texto), contenedor (agrupa).
- **Arrastrar** nodos y guardar posición.
- **Conexiones** (flechas/líneas) entre hosts para topología.
- **Persistencia** local del canva (nodos, posición, conexiones).
- Navegación: desde la lista de hosts se abre el canva y viceversa.

## Fuera de alcance

- Agentes IA como nodos (Etapa 2).
- Hub de sync (Fase 1.4) — el canva se sincronizará entonces.
- Redimensión de nodos, conexiones interactivas avanzadas.

## Flujo (caso feliz)

1. Desde la pantalla de hosts, toca "Canva" → se abre el canva infinito.
2. Menú "Añadir": agrega nodo host (elige un host guardado) o nota.
3. Arrastra los nodos para organizar el mapa.
4. Conecta dos hosts (botón conectar → toca origen y destino) → flecha.
5. Click en un nodo host → se abre el terminal conectado a ese host.
6. Todo se guarda al cerrar; al reabrir, el canva conserva posición.

### Casos límite

- Canva vacío → hint "añade nodos".
- Nodo host sin conexión válida → error al intentar abrir terminal.
- Zoom excesivo → límites min/max.

## Contratos

### Modelos

```dart
enum CanvaNodeType { host, note, container }

class CanvaNode {
  String id;
  CanvaNodeType type;
  Offset position; // x, y
  String label;      // nombre del host o texto de nota
  String? hostId;    // id del SshHost si type == host
  Color color;
}

class CanvaEdge {
  String id;
  String fromNodeId;
  String toNodeId;
}
```

### CanvaStore

```dart
Future<CanvaState> load();
Future<void> save(CanvaState state);
```

## Datos

- Persistencia: **JSON local** (archivo en el directorio de la app). SQLite llega con el hub (Fase 1.4).
- Clave: `canva_state.json`.

## Errores

| Error | Manejo |
|---|---|
| No se puede guardar | mostrar snackbar "no se pudo guardar" |
| Nodo host sin hostId | al click, error "host no configurado" |

## Tests

- **Unit (modelos):** CanvaNode se serializa/deserializa a JSON (host y nota).
- **Unit (CanvaStore):** save + load roundtrip preserva nodos, posición y edges.
- **Widget:** CanvaScreen renderiza nodos; arrastrar actualiza posición.

## Verificación de UI (gate Fase 1.3)

1. Abrir canva → ver nodo de pve (host).
2. Añadir una nota → aparece en el canva.
3. Arrastrar nodos → se mueven.
4. Conectar pve ↔ nota → flecha visible.
5. Click en nodo host pve → abre terminal y conecta.
6. Cerrar/reabrir app → canva conserva nodos y posición.
7. Capturas de cada paso como evidencia.

## Definition of Done

- [ ] `flutter analyze` 0 issues.
- [ ] Tests unitarios verdes.
- [ ] Widget test del canva.
- [ ] Prueba manual: canva + click host → terminal conecta.
- [ ] Persistencia verificada al reabrir.
- [ ] Gate 1.3 documentado en ROADMAP.
