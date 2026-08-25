# PLAN B — Editor de Código + Live Preview

> [← PLAN A](./plan-a-chat-codex.md) · [← Maestro](./README.md) · [PLAN C →](./plan-c-reasonix-deepseek.md)
> Referencia: VS Code (editor), Lovable (live preview), Cursor (AI integration)

**Entregable:** Editor de código completo dentro de la app, con file explorer, syntax highlight, live preview, e integración directa con el chat.

---

## Qué construimos

Un editor que permite trabajar con código **sin salir de Canvas AI**:
- File explorer para navegar el proyecto
- Editor con syntax highlight multi-lenguaje
- Live preview de apps web (React, Next.js, etc.)
- Integración con el chat: seleccionar código → preguntar al agente
- Terminal integrada (embebida, no full terminal)

---

## Fases

### B.1 — File Explorer

Sidebar de archivos:
- Árbol de directorios (lazy loading para proyectos grandes)
- Iconos por tipo de archivo (iconos de Lucide)
- Búsqueda por nombre (fuzzy match)
- Acciones: crear archivo/carpeta, renombrar, eliminar, duplicar
- Drag & drop para reordenar
- Indicadores: modificado (dot), nuevo (badge), conflicto (warning)
- Filtros: archivos modificados, archivos del proyecto, archivos ignorados (.gitignore)

**Pruebas:** E2E: navegar proyecto, crear archivo, renombrar, eliminar.

---

### B.2 — Editor de código

Embebido via `@monaco-editor/react` o CodeMirror 6:
- Syntax highlight multi-lenguaje (TypeScript, Python, Rust, Go, SQL, etc.)
- Múltiples tabs (archivos abiertos)
- Búsqueda y reemplazo (regex soportado)
- Auto-guardado configurable (timeout o al perder foco)
- Indicador de línea/columna
- Minimap (opcional, configurable)
- Keybindings estándar (Ctrl+S guardar, Ctrl+Z undo, etc.)
- Folding de código
- Bracket matching
- Autocompletado básico (monaco nativo)

**Pruebas:** E2E: abrir archivo, editar, guardar, verificar persistencia.

---

### B.3 — Live Preview

Panel de preview alongside (split view horizontal o vertical):
- iframe sandboxed para apps web
- Hot reload (watcher del directorio del proyecto)
- Control: refresh, zoom, mobile/desktop toggle
- URL bar (navegar dentro del preview)
- Console output integrado (errores del iframe)
- Responsive toggle (375px, 768px, 1024px, 1440px)

**Stack para preview:**
- Vite dev server embebido (para proyectos Vite/React)
- iframe con srcdoc para snippets estáticos
- WebSocket para HMR

**Pruebas:** E2E: crear proyecto React mínimo, preview muestra la app, hot reload funciona.

---

### B.4 — Integración con el chat

El editor y el chat se comunican:
- **Seleccionar código → preguntar**: selection en el editor → se inyecta como contexto en el chat
- **Diff view**: cuando el agente propone un cambio, se muestra un diff side-by-side en el editor
- **Apply diff**: el agente genera un diff → el usuario aprueba → se aplica al archivo
- **Code actions**: botón flotante sobre selección → "Preguntar al agente", "Explicar", "Refactorizar"
- **Chat sobre archivo**: panel contextual que muestra el archivo actual y permite preguntar sobre él

**Pruebas:** E2E: seleccionar código, preguntar al agente, verificar contexto injectado.

---

### B.5 — Terminal embebida

Terminal ligera integrada:
- Shell del sistema (bash/zsh/powershell según plataforma)
- Output colapsable desde el chat (cuando el agente ejecuta comandos)
- Historial de comandos
- Auto-complete básico
- No es una terminal full — es para comandos rápidos del proyecto

**Pruebas:** E2E: ejecutar `ls`, verificar output, historial funciona.

---

### B.6 — Gestión de proyectos

Vista de proyecto:
- Abrir carpeta del sistema como proyecto
- Proyectos recientes (sidebar)
- .canvas-aiignore (similar a .gitignore)
- Configuración por proyecto (en `.canvas-ai/config.json`)
- Snapshot del proyecto (guardar estado completo)

**Pruebas:** E2E: abrir proyecto, verificar file explorer, cerrar y reabrir.

---

## 🚪 GATE B (demo verificable)

Abro Canvas AI → abro un proyecto React existente → veo el file explorer → abro un archivo → edito y guardo → el live preview se actualiza → selecciono código y pregunto al agente → el agente responde con un diff → aprobo el diff → se aplica → ejecuto un comando en la terminal → funciona. Suite humana verde.

---

[← PLAN A](./plan-a-chat-codex.md) · [← Maestro](./README.md) · [PLAN C →](./plan-c-reasonix-deepseek.md)
