# AGENTS.md — Empresa Dev (terminal SSH Flutter con supervitaminas)

Guía de trabajo para los agentes (incluido este) en este proyecto. Léela antes de tocar código.

## Qué es este proyecto

Un **reemplazo de Termius multiplataforma** hecho en **Flutter**: terminal SSH/SFTP real (dartssh2 + xterm.dart), un **canva visual** donde cada cuadrito es un host SSH / nota / (agente IA en Etapa 2), y el **celular como hub de sincronización global vía Tailscale**.

- **Idea rectora:** *Termius open source + supervitaminas: un canva donde cada nodo es un servidor o un agente IA, con el celular como hub de sincronización.*
- **Documentación:** `docs/PLAN.md`, `PRODUCTO.md`, `ARQUITECTURA.md`, `ROADMAP.md`, `ETAPA1.md`, `FUNDACION.md`, `ADRs/`.
- **Plan maestro:** `docs/SUPER_PLAN.md` — fases con gates. La skill `dev` (`.opencode/skills/dev/`) obliga a trabajar por fases con sus pruebas de comprobación; actívala al empezar cualquier tarea de desarrollo.
- **Etapa 2 (plan anterior):** archivada en `docs/legacy/` — agentes IA (opencode), voz, evidencia. No se toca hasta terminar la Etapa 1.

## Reglas obligatorias de trabajo

1. **SDD por feature — antes de implementar.** Escribe el diseño (objetivo, flujo, contratos, tests) antes de tocar código.
2. **TDD:** primero el test que falla, después el código que lo pasa.
3. **CI día 1:** `flutter analyze` + `flutter test --exclude-tags integration` + build multiplataforma.
4. **Gate por fase:** cada fase del ROADMAP tiene su verificación (ver `docs/ROADMAP.md`). Una fase no se cierra sin pasar su gate.
5. **Tests de integración SSH:** en `test/ssh_integration_test.dart`, tag `integration`, requieren red + llave (`test/fixtures/app_test_key`), no corren en CI.
6. **Definition of Done:** CI verde + probado en al menos 2 plataformas (Android + desktop) + gate de la fase cumplido.
7. Máx 3 intentos por error antes de escalar al humano.

## Decisiones de arquitectura (ADRs)

- **Framework: Flutter** (no React Native). SSH/SFTP con **dartssh2**; terminal con **xterm.dart**. → `ADR-001`.
- **Celular como hub**: servidor embebido (dart:io) + **Tailscale** para sync global. → `ADR-002`.
- **DB local:** SQLite (drift) en cada dispositivo; el hub es la autoridad.
- **La conexión SSH es directa** del dispositivo al servidor; el hub sincroniza config/estado.

## Stack

| Capa | Elección |
|---|---|
| Framework | Flutter (Material 3) |
| SSH/SFTP | dartssh2 |
| Terminal | xterm.dart |
| Canva | Flutter (InteractiveViewer + nodos custom) |
| Hub server | dart:io (HttpServer + WebSocket) |
| Sync | Tailscale |
| DB | SQLite (drift) |
| Estado | Riverpod |
| Secretos | flutter_secure_storage |

## Etapa 1 (lo primero)

Terminal SSH funcional en Flutter: conectar a `pve` (192.168.100.200 o 100.101.69.79 Tailscale), ver un shell en xterm.dart. Detalle en `docs/ETAPA1.md`.

## Convenios

- Commits en español, cortos y con contexto ("feat:", "fix:", "docs:", "chore:").
- El código Flutter vive en el monorepo (apps/ para la app Flutter).
- El repo se mantiene en `/opt/empresa-desarrollo-autonoma` en el servidor pve.

## Horizonte (post-Etapa 1 y post-Etapa 2) — IDE visual de vibecoding

> **Estado:** exploración. NO se implementa hasta cerrar Etapa 1 (terminal SSH) **y** Etapa 2 (legacy, agentes IA). Documentar para no perder la idea; rediscutir cuando llegue el momento.

### Idea rectora (nivel macro)

Evolucionar el "Termius + canva" hacia un **IDE visual centrado en vibecoding**:

- **Canva mental:** nodos = archivos `.md`, ideas, tareas, fragmentos de código, hosts SSH, sesiones.
- **Vista de proyecto local:** árbol de archivos, edición in-place, sincronización opcional vía SFTP al host remoto conectado.
- **Vibecoding:** agente IA embebido (opencode CLI en legacy, o API LLM) que propone cambios desde el chat; cada propuesta = nodo-diff en el canva con preview y aceptar/rechazar.
- **Viz 3D del grafo de archivos:** las relaciones (imports, referencias, calls, links entre `.md`) se renderizan como un grafo 3D interactivo estilo `mcp codebase-memory`, Supermemory, Engram. Cluster por paquete, hover = preview, click = abre el archivo.
- **SDD++:** cada feature arranca como doc `.md` enlazado en el canva; gates de fase verificados con **Playwright CLI** contra el build Flutter Web (más `patrol_cli` para mobile).
- **Gestor visual de skills + laboratorio:** constructor visual de `skills.md` (form + drag-and-drop + preview Markdown) y un laboratorio sandbox donde se prueban skills contra inputs reales, viendo qué se activaría y por qué. **Dogfood:** este mismo proyecto se define sus propias skills desde la app.

### Gestor visual de skills + laboratorio (sub-idea)

Un **constructor visual de `skills.md`** + un **laboratorio para probarlas en vivo**, tratados como ciudadanos de primera clase:

- **Editor visual de skills:** formulario para `name`, `description`, `location`, `triggers` (palabras clave), `tags`, permisos. Cuerpo Markdown con preview live. Bloques arrastrables (instrucciones, ejemplos, restricciones, anti-patrones).
- **Laboratorio de skills:** sandbox donde escribes una pregunta/comando y ves qué skills se activarían, en qué orden, con qué confianza. Historial de pruebas, regression tests guardados como `.md` dentro de la propia skill.
- **Skills como nodos del canva:** cada skill = nodo; las relaciones (dependencias, exclusiones, composición, "requiere X para activarse") = aristas. El grafo de skills convive con el grafo de archivos en la viz 3D de Etapa 5.
- **Dogfood obligatorio:** CI gate que rechaza una skill si no pasa su test en el laboratorio. Este proyecto se define sus propias skills desde la app → la app come su propia comida.
- **Multi-plataforma / multi-dialecto:** los skills tienen variantes por agente (opencode, Cursor, Claude Code, Continue, Codex). El laboratorio normaliza y muestra diff entre dialectos; el editor exporta al dialecto destino.
- **Bonus de marketing:** es la captura de pantalla perfecta — *"crea tus agentes sin escribir YAML a mano, pruébalos en vivo, mira la red de skills en 3D"*.

### Viabilidad técnica (por pieza)

| Pieza | Cómo | Riesgo |
|---|---|---|
| Editor de código | `flutter_code_editor` o WebView + Monaco | Bajo–Medio |
| File tree local + SFTP | `file_picker` + `path` + `dartssh2` SFTP ya presente | Bajo |
| Canva mental 2D | Flutter `InteractiveViewer` + nodos custom (ya en stack) | Bajo |
| **Grafo 3D** | `flutter_scene` (experimental) **o WebView + Three.js** ← recomendado | **Alto** |
| Vibecoding IA | opencode CLI (legacy) o API LLM directa | Medio |
| Gestor visual de skills | form + drag-and-drop + editor Markdown + preview | Bajo |
| Laboratorio de skills | sandbox local: input → simulación de triggers → ranking con confianza | Medio |
| Multi-dialecto de skills | parser YAML frontmatter por dialecto + diff visual | Bajo–Medio |
| Dogfood CI de skills | ejecutor headless del laboratorio en `flutter test --tags skills` | Bajo |
| E2E con Playwright CLI | contra `flutter build web` + `pwsh` Playwright | Bajo |
| E2E mobile | `patrol_cli` (ya hay skill) | Bajo |

### Riesgos macro

1. **3D en Flutter es el talón de Aquiles.** `flutter_scene` está verde. Decisión a tomar: ¿grafо 3D nativo Flutter (lento de madurar) o WebView con Three.js (rápido pero introduce un motor web dentro de la app)?
2. **Hacer un IDE completo es otro producto.** Hay que decidir si esto *reemplaza* VS Code + Remote SSH o lo *complementa*. Mi instinto: complementa, no reemplaza.
3. **Scope creep mortal.** Los IDEs visuales con IA mueren por ambicionar todo a la vez. Por eso abajo se parte en 4–5 etapas con gates.
4. **Rendimiento del canva con miles de nodos** (Markdown, archivos, conexiones). Necesita LOD, clustering, culling, virtualización.

### Etapas propuestas (tentativas, sujetas a redefinición)

- **Etapa 3 — File tree + editor básico (sin IA):** abrir proyecto local, navegar, editar `.md` y `.dart`/`.py`/etc., guardar.
- **Etapa 4 — Canva de ideas + `.md`:** los nodos son documentos Markdown enlazados entre sí; render Markdown con preview; backlinks estilo Obsidian.
- **Etapa 4b — Gestor visual de skills + laboratorio:** constructor visual de `skills.md`, sandbox para probar activación, skills como nodos del canva. **Gate:** una skill se mergea solo si pasa sus tests en el laboratorio (dogfood activo).
- **Etapa 5 — Grafo del proyecto:** primero 2D (fuerza dirigida tipo d3-force portado a Flutter), luego 3D en WebView con Three.js solo en desktop/web.
- **Etapa 6 — Vibecoding:** agente IA conectado al editor y al canva; cada cambio = nodo-diff; historial navegable.
- **Etapa 7 — SDD++ + Playwright E2E:** SDD riguroso, verificación E2E automática con Playwright CLI por feature.

### Regla mientras tanto

**Cero código de esto hasta cerrar Etapa 1.** Cuando Etapa 1 esté verde, re-evaluar con el equipo si (a) esta visión sigue vigente, (b) el "Termius + supervitaminas" original sigue siendo el núcleo, o (c) pivotamos. La historia de los IDEs visuales dice que el scope mata más proyectos que la falta de features.
