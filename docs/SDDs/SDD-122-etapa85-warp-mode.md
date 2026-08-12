# SDD-122 — Etapa 8.5: Warp-mode — historial por host + búsqueda fuzzy + sugerencias

> **Proyecto:** empresa_dev — Etapa 8.5 del SUPER_PLAN (cola de innovación).
> **Fecha:** 2026-08-12. **Estado: ✅ 8.5.1 + 8.5.2 + 8.5.3 (local) completados** (24 unit warp_core + 7 widget). Sync LWW de snippets por el hub pendiente.

## Objetivo

El terminal es "pelado": sin historial persistente por host, sin búsqueda, sin
snippets. Termius/`warp` cobran por esto. Con un store local por host (sin red,
sin LLM) conseguimos el 80% del valor: **repetir un comando de ayer aparece en 2
pulsaciones** (gate del SUPER_PLAN 8.5).

Partes (SUPER_PLAN 8.5):
- Store de historial por host + búsqueda fuzzy (Ctrl+R custom).
- Snippets sincronizados (tabla nueva + sync LWW/CRDT). → **slice posterior**.
- Sugerencias inline sobre el prompt del terminal.

**Nota de captura:** xterm.dart 4.0.0 NO expone `onCommand`; pero el input del
usuario viaja por `Terminal.onOutput` (lo que el emulador envía al shell). Un
`CommandLineTracker` consume ese stream y emite líneas completas al pulsar Enter.

## Arquitectura (reglas monorepo)

- **`packages/warp_core`** (Dart puro, sin Flutter): `CommandLineTracker`
  (buffer+cursor, emite comandos completos ante `\r`, maneja backspace,
  secuencias ANSI no imprimibles), `CommandHistoryStore` (por host, JSON,
  dedupe consecutivo, cap 500, timestamps) y `FuzzyFinder` (subsecuencia +
  scoring: bonus consecutivo/inicio-palabra + recencia).
- **App** (`terminal_screen.dart`): captura vía `_onOutput` → tracker →
  historyStore.add; **Ctrl+R** → overlay de búsqueda fuzzy (TextField + lista;
  ↑/↓ navegan, Enter ejecuta, Esc cierra); **sugerencia inline** (barra sobre el
  TerminalView con el mejor match + Tab para aceptar); botón snippets (slice
  posterior).

## Slices (TDD, test rojo primero)

### 8.5.1 — `packages/warp_core`: tracker + store + fuzzy (unit)

```dart
class CommandLineTracker {
  CommandLineTracker({void Function(String line)? onCommand});
  void feed(String input);   // stream del onOutput del terminal
  String? get currentLine;
  void reset();
}

class CommandHistoryStore {
  CommandHistoryStore({Directory? dir});  // dir == null → memoria (tests)
  Future<void> add(String host, String command);
  List<CommandRecord> forHost(String host);
  Future<List<CommandRecord>> search(String host, String query);
  Future<void> remove(String host, String command);
  Future<void> clear(String host);
}

class CommandRecord {
  final String command; final DateTime at;
}

class FuzzyFinder {
  FuzzyFinder({this.fuzzy = true});
  List<FuzzyMatch> rank(List<CommandRecord> records, String query);
}
class FuzzyMatch { final CommandRecord record; final double score; }
```

- Tracker: `feed('ls ')` + `feed(' -la\r')` → onCommand('ls -la'); backspace
  (`\x7f`) borra; flechas ↑/↓/←/→ (`\x1b[A`…) no contaminan el buffer;
  `\x03` (Ctrl-C) resetea la línea; UTF-8 multibyte se conserva.
- Store: add/dedupe/cap/order; persistencia JSON round-trip; `dir == null` en
  memoria (sin IO en unit tests).
- Fuzzy: query 'sv' rankea 'ssh server' sobre 'killall'; subsecuencia no
  contigua puntúa menos que contigua; recencia desempata; query vacía →
  más reciente primero.

### 8.5.2 — terminal_screen: captura + Ctrl+R + sugerencia inline (widget)

- `_onOutput` → tracker; Enter → historyStore.add(host, línea) (solo si
  conectado y línea no vacía).
- Ctrl+R (hardwareKeyboardOnly, desktop): overlay de cristal con TextField
  autofocus + lista de `FuzzyFinder` del host; ↑/↓ mueven selección, Enter
  ejecuta `_shell.write(línea + '\r')`, Esc/Tap-fuera cierra. Sin red.
- Sugerencia inline: con el input actual, `search(host, current)` top-1 → barra
  fina sobre el TerminalView: `Tab ⏎ <comando>` → Tab acepta (envía el resto).
  Solo cuando el match difiere del buffer actual y hay ≥ 1.
- Snippets: fuera de este slice (SDD 8.5.3).

**Tests widget:** tracker captura 'ls -la' del stream; Ctrl+R abre overlay y
fuzzy lista el comando histórico; Enter envía la línea al shell (mock shell);
Tab acepta la sugerencia; los tests existentes del terminal pasan intactos.

### 8.5.3 — Snippets + sync

- [x] Store de snippets por host (`SnippetStore` en warp_core: CRUD + JSON) + UI
  en el terminal (botón ⚡ → hoja de cristal: tap inserta el comando en el
  prompt, borrar, crear con nombre+texto). *(2 tests widget)*
- [ ] Sincronización vía sync LWW por el hub (tabla nueva) — depende de la
  infraestructura de sync existente.

## Contratos de integración

```dart
// terminal_screen.dart
_terminal.onOutput = (data) {
  _shell?.write(Uint8List.fromList(utf8.encode(data)));  // comportamiento actual
  _tracker.feed(data);                                    // captura comandos
};
// Ctrl+R overlay: Stack sobre el TerminalView
// Sugerencia: barra sobre el TerminalView
```

## Notas de implementación

- `CommandHistoryStore` con `dir == null` = memoria (patrón usado en
  vibecoding_core para tests); en la app se construye con el directorio de
  `path_provider` (o `EMPRESA_DEV_REPO` no aplica aquí).
- El overlay y la barra de sugerencia usan glassmorphism neón (AGENTS.md):
  `showNeonDialog`/paneles con `AppColors.bgGlass` + borde de luz.
- El tracker debe ignorar secuencias ANSI (p.ej. `\x1b[...`) y Ctrl-C.
- La captura SOLO aplica cuando hay shell conectado; en host local (sin SSH)
  el terminal de xterm igual funciona y se captura igual (host = nombre).

## Gate (SUPER_PLAN 8.5)

- [x] Store de historial por host + búsqueda fuzzy (Ctrl+R custom) (8.5.1–2).
- [ ] Snippets sincronizados (tabla nueva + sync CRDT/LWW) (8.5.3 — slice posterior).
- [x] Sugerencias inline sobre el prompt del terminal (8.5.2).
- [ ] Gate: repetir un comando de ayer → aparece en 2 pulsaciones de Ctrl+R (manual).

## Notas de cierre (2026-08-12)

- xterm.dart 4.0.0 no expone `onCommand`; el input del usuario viaja por
  `Terminal.onOutput`. El `CommandLineTracker` lo consume (buffer + Enter,
  backspace, Ctrl-C/U, secuencias ANSI ignoradas, rune-safe) y emite líneas.
- Captura condicionada a shell conectado (`_shell != null`), keyed por
  `host.name`.
- Ctrl+R (búsqueda) y Ctrl+Shift+R (reconectar) — el orden de chequeo importa
  (shift primero).
- Sugerencia inline: si el match es prefijo → envía el tail (completa la línea);
  si no → Ctrl-U + reescribe. Actualiza el tracker para mantener consistencia.
- Test del overlay: `tester.testTextInput.receiveAction(TextInputAction.done)`
  es la vía confiable para disparar `onSubmitted` (el `sendKeyEvent(enter)` no
  lo dispara en el camino de teclado físico).
- El fake de `SSHSession` importa rutas internas de dartssh2
  (`package:dartssh2/src/ssh_channel.dart` — `SSHChannel`/`SSHChannelController`
  no se exportan por la librería principal).
