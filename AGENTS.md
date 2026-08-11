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
3. **CI día 1:** `melos analyze` + `melos test` + build multiplataforma. La app: `flutter analyze` + `flutter test --exclude-tags integration` desde `apps/empresa_dev`.
4. **Gate por fase:** cada fase del ROADMAP tiene su verificación (ver `docs/ROADMAP.md`). Una fase no se cierra sin pasar su gate.
5. **Tests de integración SSH:** en `test/ssh_integration_test.dart`, tag `integration`, requieren red + llave (`test/fixtures/app_test_key`), no corren en CI.
6. **Definition of Done:** CI verde + probado en al menos 2 plataformas (Android + desktop) + gate de la fase cumplido.
7. Máx 3 intentos por error antes de escalar al humano.

## Arquitectura MONOREPO (OBLIGATORIA)

Este proyecto es un **monorepo formal orquestado con Melos**. La estructura es ley; no se viola.

```
empresa-desarrollo-autonoma/
├── apps/
│   └── empresa_dev/        # ÚNICA app Flutter (capa de UI). Su pubspec es `empresa_dev`.
├── packages/               # Librerías puras Dart (sin Flutter salvo que se justifique)
│   ├── ssh_core/           # SshHost, DevSession, SyncSnapshot, HostRecord
│   ├── canva_core/         # CanvaNode/CanvaState, CanvasNode/CanvasNodeId/NodeKind
│   └── agent_core/         # AgentMessage, AgentDetector, manifiestos (portados de herdr)
├── empresa_autonoma/       # (reservado) servicio Python: CrewAI + LangGraph (orquestación)
├── melos.yaml              # Orquestación: bootstrap, analyze, test, build
├── skills/                 # (reservado) packs de skills versionados con el código
├── reference/              # (reservado) repos externos como submodulos: buzz, herdr
└── copia.md                # Plan de qué copiar de buzz/herdr
```

### Reglas obligatorias (incumplirlas = revertir el PR)

1. **La app NUNCA importa por ruta relativa hacia un package.** Todo módulo
   reutilizable vive en `packages/*` y se importa por nombre: `package:ssh_core/...`.
2. **Dirección de dependencias:** `apps/*` → `packages/*`. Los packages NUNCA
   importan desde `apps/` ni desde otro package que dependa de ellos (sin ciclos).
3. **Todo código nuevo reutilizable va a un package**, no a `lib/` de la app.
   - Modelos, lógica SSH, detección de agentes, sync → packages.
   - Solo UI (screens, widgets), stores con `path_provider`, y estado Riverpod
     viven en `apps/empresa_dev/lib`.
4. **Los packages son Dart puro** (sin Flutter) salvo justificación en el SDD.
   Si un modelo necesita Flutter, primero cuestiona el diseño.
5. **No commits en la raíz que mezclen packages.** Cada package con su propio
   pubspec, analysis_options y tests. `melos bootstrap` enlaza todo.
6. **skills/ y reference/**: skills versionadas en el repo; repos externos
   (buzz, herdr) SOLO como submodulos en `reference/`, jamás copiados crudos a `lib/`.
7. **`melos analyze` y `melos test` deben pasar** antes de terminar una tarea.

### Comandos

```bash
melos bootstrap        # pub get de todos los packages (tras clonar o cambiar pubspec)
melos analyze          # dart analyze en todos los packages
melos test             # dart test en todos los packages
cd apps/empresa_dev && flutter test --exclude-tags integration   # tests de la app
cd apps/empresa_dev && flutter build windows --release           # build desktop
```

### Al mover código a un package

1. `git mv` (conserva historial).
2. Arregla imports: `package:<nombre>_core/...`.
3. Si `lib/canva.dart` exporta varios archivos, usa `export` en la entrada pública.
4. Agrega `test/<package>_test.dart` y corre `dart test` dentro del package.
5. Corre `melos analyze` — debe quedar en 0 issues en el package.

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
| Orquestación de agentes | CrewAI (Python) |
| Grafos de estado | LangGraph (Python) |

## Identidad visual — GLASSMORPHISM NEÓN (OBLIGATORIO)

> **Directiva de estilo del proyecto.** Toda interfaz nueva o retocada debe seguir
> este lenguaje visual: **cristal, luz y futuro IA**. Nada de paneles planos ni
> grises sordos. La app debe sentirse como un sistema de inteligencia artificial
> autónoma de la siguiente era de la programación.

### Principios de diseño

1. **Glassmorphism de cristal** — paneles translúcidos (`Colors.white` con
   alpha ~0.05–0.10), `BackdropFilter` + `ImageFilter.blur` como capa base,
   bordes redondeados grandes (16–24), y un borde de 1px luminoso
   (`gradient` blanco con alpha alto en la esquina superior → transparente).
2. **Contornos de luz (light edges)** — el borde superior de cada "cristal"
   lleva un gradiente sutil blanco/cian (simula luz entrando por arriba).
3. **Neón sutil** — acentos neón cian (`#22D3EE`), violeta (`#A855F7`) y verde
   (accent existente) SOLO en contornos, glows y elementos de foco. Nunca
   saturar el contenido.
4. **Glow (resplandor)** — sombras de color (`BoxShadow` con color cian/violeta
   y `blurRadius` alto) en el borde de los elementos activos/importantes, no en
   todo.
5. **Píxeles / tech-grid** — fondo con grid sutil de puntos o línea fina
   (como una cuadrícula de holograma), opacidad muy baja (~3–5%).
6. **Animaciones fluidas** — transiciones de 200–350ms con `Curves.easeOutCubic`
   o `Curves.elasticOut` para entradas destacadas. Nada de saltos bruscos.
7. **Profundidad por capas** — fondos oscuros (`#0F172A` base) con cristales
   encima; cada capa de UI (panel → tarjeta → diálogo) un poco más brillante.

### Paleta de luz (token semilla)

| Token | Color | Uso |
|---|---|---|
| `bg-base` | `#0F172A` | Fondo base (slate 900) |
| `bg-glass` | `white 5–10%` | Paneles de cristal |
| `neon-cyan` | `#22D3EE` | Luz principal, focus, contornos |
| `neon-violet` | `#A855F7` | Agentes IA, acentos secundarios |
| `neon-green` | `#4ADE80` | Conectado / éxito / hosts activos |
| `edge-light` | `white → transparent` | Borde superior de cristales |

### Reglas de implementación

1. **Crea widgets reutilizables** de cristal (`GlassPanel`, `NeonCard`) en
   `apps/empresa_dev/lib/widgets/` en vez de repetir `BackdropFilter` a mano.
2. Los **diálogos, modales y paneles laterales** deben ser de cristal con borde
   de luz (nunca `AlertDialog`/`Card` planos por defecto).
3. El **canva** y las **tarjetas de host/agente** llevan glow neón al estar
   activos/conectados.
4. **Performance:** `BackdropFilter` es costoso — usarlo en paneles que cambian
   poco; evitar en listas con scroll infinito. Los glows usan `BoxShadow`
   normales, no `BackdropFilter`.
5. `melos analyze` + tests en verde después de cualquier cambio visual.

### Anti-patterns (prohibido)

- ❌ Fondo sólido gris oscuro sin textura ni cristal.
- ❌ Bordes negros/duros sin luz.
- ❌ Neón sobresaturado en el contenido (solo contornos y foco).
- ❌ Animaciones de 1s+ o `easeIn` lento que ralentiza la app.
- ❌ Copiar estilos de Material por defecto sin adaptar.

## Visión — EMPRESA AUTÓNOMA DE DESARROLLO (CrewAI + LangGraph)

> **Estado:** visión rectora de Etapa 2+ y del largo plazo. La meta no es una app
> con agentes: es **una oficina de desarrollo que trabaja sola**, con agentes
> especializados como empleados, coordinados por grafos de estado y con una vista
> animada estilo juego para "ver a la empresa trabajar".

### La idea rectora

Construir **una empresa de desarrollo autónoma** donde cada agente es un rol de
oficina (producto, arquitecto, dev, QA, devops, revisores, PM) que:

- Trabaja sobre **tareas reales del repo** (issues, PRs, features, bugs).
- Se coordina con los demás mediante **CrewAI** (formación de crews y
  colaboración entre roles) **+ LangGraph** (grafos de estado state-of-the-art:
  control explícito, loops, human-in-the-loop, persistencia y reanudación).
- Se visualiza como una **oficina animada estilo juego**: cada agente es un
  "personaje" en un espacio, con estados visibles (trabajando, bloqueado,
  esperando aprobación), y el canva de la app es la ventana a esa oficina.

### Stack de orquestación (OBJETIVO para la empresa autónoma)

| Capa | Elección | Por qué |
|---|---|---|
| Orquestación de agentes | **CrewAI** | Roles tipo "empleado", crews, colaboración declarativa |
| Grafos de flujo/estado | **LangGraph** | State-of-the-art: control fino, loops, human-in-the-loop, checkpoints |
| Runtimes de agentes | opencode, Claude Code, Codex, etc. | Cada empleado puede correr en el runtime que mejor haga el rol |
| Vista "oficina" | Flutter (canva + animaciones) | La UI actual ES la oficina; los nodos-agente se vuelven personajes |

### Reglas para esta visión

1. **La orquestación vive en un servicio propio** (nuevo directorio/servicio,
   sugerido `empresa_autonoma/` como repo/servicio Python con CrewAI+LangGraph),
   NO dentro de la app Flutter. La app solo lo controla/observa.
2. **CrewAI define QUIÉN trabaja** (roles, crews, delegación).
   **LangGraph define CÓMO fluye el trabajo** (estado, transiciones, gates).
3. **Human-in-the-loop:** todo cambio que afecte al repo (merge, deploy, gasto)
   requiere aprobación explícita en la app (nodo de aprobación en el grafo).
4. **Persistencia de estado:** el grafo debe poder pausarse/reanudarse
   (checkpoints de LangGraph); la "empresa" no muere si se apaga la máquina.
5. **Observabilidad primero:** cada agente publica su estado al canva (estilo
   `agent_core`). La UI es espejo del grafo, no el cerebro.
6. **Pruebas:** los grafos se prueban headless (`LangGraph` testable, sin LLM
   en CI salvo integraciones marcadas). La app come su propia comida.

### Plan (ver `docs/SDDs/SDD-115-empresa-autonoma-crewai-langgraph.md`)

- **Fase 0 — Fundación:** servicio Python `empresa_autonoma/` con CrewAI +
  LangGraph, grafo "plan → implementar → revisar → merge" con un agente dev.
- **Fase 1 — Crews:** roles (producto, dev, QA, devops) y delegación; cada
  agente es un nodo en el canva.
- **Fase 2 — Oficina animada:** vista estilo juego en la app (personajes,
  estados animados con el lenguaje visual glassmorphism neón).
- **Fase 3 — Integración repo:** leer issues/PRs, hacer ramas, PRs reales,
  todo con aprobación humana.
- **Fase 4 — Autonomía supervisada:** la empresa ejecuta tareas end-to-end con
  gates de aprobación y trazabilidad.

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

## Build Commands

- **CI:** `flutter analyze` (0 issues) + `flutter test --exclude-tags integration`.
- **Integration (requiere red/llaves):** `flutter test --tags integration` — `sync_integration_test.dart` falla sin Tailscale activa (esperado); `agent_integration_test.dart` prueba el agente real con opencode.
- **APK:** `flutter build apk --debug --no-tree-shake-icons`.
- **Windows (manual, VS 2026):** Flutter hardcodea VS 16 2019; workaround con cmake/MSBuild manuales:
  ```powershell
  $env:PATH = "C:\tools\nuget;$env:PATH"   # necesario desde flutter_tts (restaura paquetes NuGet)
  & "C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" -G "Visual Studio 17 2022" -A x64 -S "windows" -B "build\windows\x64" -DCMAKE_INSTALL_PREFIX="$((Get-Location).Path)\build\windows\x64\runner\Debug"
  & "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" "build\windows\x64\empresa_dev.sln" /p:Configuration=Debug /p:Platform=x64
  ```
  - Si `build\windows\x64` se borra, hay que re-pasar `-DCMAKE_INSTALL_PREFIX` (default: `C:\Program Files\empresa_dev` → falla sin admin).
  - Avast/Defender puede bloquear el `.exe` de Debug (LNK1104): matar el proceso o excluir la carpeta del proyecto.
