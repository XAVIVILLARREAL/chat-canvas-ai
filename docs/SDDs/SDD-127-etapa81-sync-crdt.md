# SDD-127 — Etapa 8.1: Sync CRDT para el canva

> **Proyecto:** empresa_dev — Etapa 8.1 del SUPER_PLAN (cola de innovación).
> **Fecha:** 2026-08-12. **Estado: ✅ evaluación + núcleo + migración del sync** (gate de convergencia en hub real). Doc persistente por cliente = seguimiento.

## Objetivo

El sync actual es snapshot + last-write-wins por `version`: ediciones simultáneas
en 2 dispositivos pierden trabajo. Con un **CRDT** el canva converge solo, por
deltas, sin autoridad central y con offline-first real.

Gate SUPER_PLAN 8.1: *"2 dispositivos offline, editan, reconectan → el canva
converge sin conflicto"*.

## Evaluación (spike)

| Librería | Veredicto |
|---|---|
| `ydart` 0.0.1 (binding de Yrs/Rust) | ❌ **Descartada**: 6 descargas/semana, uploader no verificado, sin mantenimiento visible |
| `crdt` 5.1.3 (Dart nativo, HLC — Hybrid Logical Clock) | ✅ **Elegida**: Dart puro, `MapCrdt` storage-agnostic (ephemeral), `crdt_sync` turnkey, Apache-2.0, 1.9k descargas, en producción (Libra, 1M+ installs) |
| CRDT propio (OR-Set + LWW-register) | 🟡 Opción B si se quiere cero dependencias; más código a mantener. Se descarta por ahora |

**Decisión:** usar `crdt` (`MapCrdt` con HLC) para el canva. HLC resuelve
conflictos por `(timestamp, actor)`: "delete vs edit" = valor más nuevo gana;
"ediciones a nodos distintos" = ambas sobreviven.

## Arquitectura

- **`packages/crdt_core`** (Dart puro): `CanvaCrdt` — adaptador de `CanvaState`
  a `MapCrdt` (schema `['canva']`). Cada nodo/edge es un registro
  `node:<id>` / `edge:<id>` con su JSON; el borrado se representa como
  `{'__deleted': true}` (HLC decide delete-vs-edit). API:
  - `CanvaCrdt.fromState(CanvaState, {actor})`
  - `void putNode(CanvaNode)`, `putEdge`, `deleteNode(id)`, `deleteEdge(id)`
  - `void merge(CanvaCrdt other)` (vía `getChangeset`)
  - `CanvaState toState()`
- **App (seguimiento):** migrar el sync del canva (CanvaStore/hub) a usar
  `CanvaCrdt` en vez del snapshot LWW; `crdt_sync` opcional para el transporte.

## Slice (TDD)

### 8.1.1 — `crdt_core` (unit, sin red)

- Round-trip `CanvaState → CanvaCrdt → CanvaState` preserva nodos y edges.
- **Concurrencia (gate):** base común; dispositivo A añade nodo X y B añade Y;
  `A.merge(B)` → ambos sobreviven.
- Conflicto al mismo registro: A pone label "x" y B "y" → converge a uno solo
  (determinista).
- Delete vs edit: borrar con timestamp más nuevo gana; un edit más nuevo que el
  delete lo revive (HLC).
- Merge idempotente y conmutativo (merge en cualquier orden → mismo estado).

## Gate

- [x] 2 estados divergentes convergen sin pérdida (unit, gate 8.1).
- [x] `dart analyze` 0 + tests del package verdes (8) + app (191, incl. hub localhost).
- [x] Migración del sync del canva: `/api/apply` converge vía `CrdtSyncCanva`.
- [ ] Gate manual con Tailscale (2 dispositivos reales).

## Notas de cierre

- `MapCrdt` de `crdt` aplica `put`/`merge` en **microtask** (async) → el adaptador
  expone `seed()`/`putNode()`/`merge()` como `Future` y los tests `await`ean; no
  hay lectura síncrona sin haber esperado.
- El borrado es `put(key, null, isDeleted: true)`; `getMap` excluye los borrados.
- El HLC de `crdt` genera nodeId aleatorio por instancia: en un conflicto delete
  vs edit con el MISMO timestamp, gana el de nodeId mayor (no determinista).
  Para un borrado determinista, avanzar el reloj local antes (put previo).
- `changesetJson()` serializa el Hlc a string; `mergeChangesetJson()` lo
  re-parsea (`parseCrdtChangeset`). `SyncSnapshot.canvaCrdt` lo transporta opaco.
- El cliente aún siembra un doc fresco por push (LWW por nodo en el hub); el doc
  CRDT persistente por dispositivo (para deltas reales offline) es seguimiento.
