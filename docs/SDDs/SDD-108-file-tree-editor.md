# SDD — Etapa 3: File tree + editor de código (sin IA)

> **Proyecto:** empresa_dev — Etapa 3 del SUPER_PLAN.
> **Fecha:** 2026-08. **Estado:** ✅ Implementado (gate de fase casi cerrado; falta el dogfood manual).

## Resultado (2026-08)

- `lib/services/project_service.dart`: `ProjectService` local — `list` (ignora `.git`/`build`/`node_modules`/`.dart_tool`/`.idea`, dirs primero), `read`/`write` con detección y conservación de encoding (UTF-8, UTF-8+BOM, UTF-16 LE/BE), `isBinary` (bytes nulos, handle cerrado). I/O síncrono para compatibilidad con widget tests (FakeAsync).
- `lib/services/remote_project_service.dart`: `RemoteProjectService` sobre `SftpService` (list/read/write contra el host conectado).
- `lib/screens/project_tree_screen.dart`: árbol con `ExpansionTile` lazy, iconos/colores por extensión, aviso de binario, click → editor.
- `lib/screens/code_editor_screen.dart`: editor monospace dark, estado Guardado/Modificado/Guardando/Error, Ctrl+S + botón guardar, conserva encoding.
- Canva: menú "Abrir proyecto" (file_picker v11, API estática `FilePicker.getDirectoryPath()`), desktop-only.
- Tests: `test/project_service_test.dart` (6 unit), `test/project_tree_widget_test.dart` (3 widget: árbol→editor, modificar→Ctrl+S→disco, binario), `test/remote_project_service_test.dart` (3 unit con fake SFTP). Suite 44 unit/widget verdes, `flutter analyze` 0 issues, build Windows OK.

## Gate de la fase (per SUPER_PLAN)

- [x] Unit: service de proyecto (listar, abrir, guardar con encoding correcto); parser de árbol.
- [x] Widget: árbol → click → editor abre contenido; modificar → guardar → reabrir conserva el cambio.
- [ ] Integration SFTP: editar archivo remoto y verificar hash local == remoto (manual, requiere host conectado).
- [ ] **Dogfood:** este repo se abre, edita y guarda desde la propia app (2 sesiones seguidas sin fallos) — manual.

## Objetivo

El canva pasa de "hosts" a "proyectos": poder **abrir un proyecto local** (o remoto vía SFTP), **navegar su árbol de archivos** y **editar archivos planos** (`.md`, `.dart`, `.py`, `.json`, …) con guardado. Es la base del IDE visual de vibecoding (Etapas 4–7): sin editor, no hay nada que conectar al agente.

## Alcance (esta fase)

- `ProjectService` (local): abrir carpeta (por diálogo `file_picker` o ruta directa), listar árbol (`Directory.list` recursivo con límite de profundidad/ignorados), leer y guardar archivos con encoding detectado (UTF-8/UTF-16/BOM).
- `RemoteProjectService` (SFTP): las mismas operaciones contra el host conectado, reutilizando `SftpService` existente.
- `ProjectTreeScreen`: árbol de archivos (expansión lazy, iconos por extensión, tamaño/fecha), click → abre editor.
- `CodeEditorScreen`: editor plano (`TextField` monospace multilinea, dark) con título, guardar (Ctrl+S + botón), indicador "modificado/sin guardar", mensaje de guardado. Preview `.md` (render simple en texto; Markdown real llega en Etapa 4).
- Integración en canva: desde el menú del canva → "Abrir proyecto" → la pantalla de proyecto se abre encima; los nodos siguen intactos.
- SFTP: botón en el editor "Guardar en remoto" (si hay host conectado) — el guardado local y el push remoto son dos acciones separadas y visibles.

## Fuera de alcance

- Markdown con preview real (render Markdown, backlinks, `[[links]]`) → Etapa 4.
- Editor con sintaxis coloreada (Monaco/CodeMirror) → se evalúa en Etapa 6 (vibecoding) si hace falta.
- Vim/teclas avanzadas, autocompletado, múltiples tabs (solo un archivo a la vez).
- Dogfood gate (abrir/editar/guardar este repo desde la app) → gate de cierre de la fase.

## Flujo (caso feliz)

1. Canva → menú "Abrir proyecto" → selector de carpeta → `ProjectTreeScreen`.
2. Click en `lib/main.dart` → `CodeEditorScreen` con el contenido, marcado "sin modificar".
3. El usuario edita → barra muestra "Modificado". Ctrl+S → se escribe a disco → "Guardado HH:MM".
4. Click en `docs/PLAN.md` → igual, se abre el `.md` plano.
5. Con host SFTP conectado: el árbol remoto abre igual; el editor muestra "Guardar local" y "Guardar remoto".

### Casos límite

- Archivo binario (imagen, zip) → aviso "no se puede editar, es binario" (detectado por bytes nulos).
- Archivo grande (> 2 MB) → se abre en modo lectura (aviso).
- Encoding UTF-16/BOM → se decodifica y al guardar se conserva BOM si estaba.
- Guardar falla (permisos) → mensaje de error, el contenido NO se pierde.
- Carpeta sin permisos de listar → árbol muestra error en ese nodo, no rompe la app.

## Contratos

### Servicios

```dart
class ProjectService {
  final String root;                       // ruta de la carpeta del proyecto
  Future<List<FileNode>> list(String dir, {int depth});   // lazy por nivel
  Future<String> read(String path);        // decodifica encoding + BOM
  Future<void> write(String path, String content);        // conserva BOM si existía
  bool isBinary(String path);              // heurística bytes nulos
}

class FileNode {
  final String name;
  final String path;
  final bool isDir;
  final int size;
  final DateTime modified;
}

class RemoteProjectService {
  final SftpService sftp;                  // reutiliza la conexión existente
  Future<List<FileNode>> list(String dir);
  Future<String> read(String path);
  Future<void> write(String path, String content);
}
```

### Pantallas

- `ProjectTreeScreen(root, {RemoteProjectService? remote})`: `ExpansionTile` por directorio (carga bajo demanda), iconos por extensión (`.dart` azul, `.md` gris, `.json` ámbar…), `ListTile` al hacer click.
- `CodeEditorScreen(path, {RemoteProjectService? remote, String? remotePath})`: `TextField` multilinea monospace (≈14px, tema dark), AppBar con ruta + estado (modificado/guardado) + botones Guardar / Guardar remoto / Volver.

## Tests (TDD)

- `test/project_service_test.dart` (unit, con carpeta temp real):
  - list ignora `.git`, `build/`, `node_modules/`; ordena dirs primero.
  - read detecta UTF-8, UTF-16 y BOM; isBinary con bytes nulos.
  - write conserva BOM; escribir y releer devuelve lo mismo.
- `test/project_tree_widget_test.dart` (widget, con ProjectService fake apuntando a carpeta temp):
  - árbol renderiza archivos; click en archivo → editor con contenido.
  - editor: editar → marca "Modificado"; Ctrl+S → guarda en disco (verificable) y muestra "Guardado".
  - binario → diálogo de aviso.
- `test/remote_project_service_test.dart` (unit con SftpService fake): list/read/write delegan en el SFTP con rutas compuestas correctamente.

## Gate de la fase (per SUPER_PLAN)

- [ ] Unit: service de proyecto (listar, abrir, guardar con encoding correcto); parser de árbol.
- [ ] Widget: árbol → click → editor abre contenido; modificar → guardar → reabrir conserva el cambio.
- [ ] Integration SFTP: editar archivo remoto y verificar hash local == remoto (se hace con el SFTP real en la prueba manual final).
- [ ] **Dogfood:** este repo se abre, edita y guarda desde la propia app (2 sesiones seguidas sin fallos).