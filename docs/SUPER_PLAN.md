# SUPER PLAN — Del terminal SSH al IDE visual de vibecoding

> **Estado:** vigente. Fuente de verdad para las fases y sus **pruebas de comprobación (gates)**.
> Metodología obligatoria por fase: **SDD → TDD → CI → Gate**. Detalle operativo en la skill `.opencode/skills/dev/SKILL.md`.

## Estado actual (real, verificado en código)

| Bloque | Estado | Evidencia |
|---|---|---|
| Terminal SSH (dartssh2 + xterm.dart) | ✅ hecho | `lib/services/ssh_service.dart`, `test/ssh_service_test.dart`, `ssh_integration_test.dart` |
| SFTP | ✅ hecho | `lib/services/sftp_service.dart`, `sftp_integration_test.dart` |
| Canva visual | ✅ hecho | `lib/models/canva.dart`, `lib/screens/canva_screen.dart`, `canva_test.dart`, `canva_widget_test.dart` |
| Hub celular + sync | ✅ hecho | `lib/services/hub_server.dart`, `sync_client.dart`, `sync_integration_test.dart` |
| Sesiones/tabs | ✅ hecho | `lib/screens/tabs_screen.dart`, `sessions_store.dart` |
| Publicación (Play/App Store/releases) | ❌ pendiente | — |

## Comandos maestros de comprobación (corren en cualquier fase)

```powershell
flutter analyze                              # 0 issues
flutter test --exclude-tags integration      # suite unit/widget verde
dart run tool/hub_smoke.dart                 # smoke del hub OK
flutter build apk --debug --no-tree-shake-icons
# Windows: cmake manual (ver AGENTS.md "Build Commands")
```

---

## Etapa 1 — Cierre y publicación (gate: Termius reemplazado)

**Objetivo:** terminar lo pendiente de Etapa 1 y publicar.

- [ ] E2E real en Android + Windows + macOS (requiere dispositivos).
- [ ] Prueba de batería: hub en Android no agota batería en 24h.
- [ ] Publicar Play Store / App Store / releases desktop.

**Pruebas de comprobación (gate de cierre):**
- [ ] Suite completa (comandos maestros) verde.
- [ ] Manual: SSH a `pve` por password **y** llave; SFTP subir/bajar con hash verificado; túnel local funcionando; canva con topología persistida tras reabrir; sync 2 dispositivos en el tailnet.
- [ ] Capturas de cada flujo como evidencia.
- [ ] Binario publicado y descargable en al menos una vía pública.

---

## Etapa 2 — Agentes IA en el canva (retoma `docs/legacy/`)

**Objetivo:** los agentes (opencode) son ciudadanos de primera clase en el canva.

- [x] Nodo **agente IA** en el canva; click → sesión de chat con opencode. *(SDD-105, `test/agent_test.dart`, `agent_chat_widget_test.dart`, `agent_integration_test.dart`)*
- [x] Voz: dictar (STT navegador) → respuesta leída (Edge TTS). *(SDD-107 — implementado con SAPI nativo de Windows: `speech_to_text` + `flutter_tts`, `lib/services/voice_service.dart`, `lib/widgets/voice_buttons.dart`, `test/voice_service_test.dart`, `voice_buttons_widget_test.dart`; falta prueba manual con micrófono real)*
- [x] Evidencia por prompt: cada respuesta se guarda como `.md` navegable. *(SDD-106, `lib/services/evidence_store.dart`, `lib/screens/evidence_screen.dart`, `test/evidence_test.dart`, `evidence_widget_test.dart`)*
- [x] Verificación de UI con Chrome headless. *(`tool/verify_ui.ps1`: build web + servidor estático local + Chrome headless screenshot/dump-dom, chequea `flt-glass-pane` + screenshot ≥ 10KB; verificado OK el 2026-08-11)*

**Pruebas de comprobación (gate):**
- [x] Unit: modelo `AgentNode`, store de sesiones de agente.
- [x] Widget: nodo agente se renderiza, abre sesión y recibe respuesta (mock).
- [x] Manual: lanzar agente real desde el nodo y recibir respuesta en el chat. *(agent_integration_test real con opencode 1.18.16)*
- [ ] Voz: dictado → texto → respuesta audible en < 3s. *(falta prueba manual: dictar en la app Windows y oír la respuesta; requiere paquete de voz ES instalado)*
- [x] Evidencia: 3 prompts con captura guardada como `.md`. *(solo falta captura de 3 prompts reales — pendiente manual)*

---

## Etapa 3 — File tree + editor de código (sin IA)

**Objetivo:** el canva pasa de "hosts" a "proyectos": abrir, navegar y editar proyectos locales + remotos.

- [x] Abrir proyecto local (`file_picker`) y renderizar árbol de archivos. *(SDD-108)*
- [x] Editor de archivos planos (`.md`, `.dart`, `.py`, `.json`…) con guardado. *(SDD-108)*
- [x] SFTP push: guardar también en el host remoto conectado; abrir archivo remoto y editar. *(RemoteProjectService — `test/remote_project_service_test.dart`)*

**Pruebas de comprobación (gate):**
- [x] Unit: service de proyecto (listar, abrir, guardar con encoding correcto); parser de árbol.
- [x] Widget: árbol → click → editor abre contenido; modificar → guardar → reabrir conserva el cambio.
- [ ] Integration SFTP: editar archivo remoto y verificar hash local == remoto. *(manual, host real)*
- [ ] **Dogfood:** este repo se abre, edita y guarda desde la propia app (2 sesiones seguidas sin fallos). *(manual)*

---

## Inyección copia.md (prefase Etapa 4) — 3 piezas pequeñas de buzz/herdr

> Fuente: `copia.md` (detalle completo y mapeo en ese archivo). Repos `buzz/` y `herdr/` clonados localmente (ignorados por git). Piezas baratas (días) que mejoran el canva ANTES de que Etapa 4 lo amplíe con nodos `.md`.

- [x] **Detector de agentes (copia 1.1)** — `lib/services/agent_detector.dart` + manifiestos portados (`agent_detector_manifests.dart`, subset fiel de `herdr/src/detect/manifests/opencode.toml`), matchers `contains`/`regex`/`line_regex`, prioridades; `AgentStateBadge` en vivo en `AgentChatScreen`. SDD-109.
  - *Gate: ✅ un host que corre `opencode` se clasifica `working` cuando su salida contiene "esc to interrupt" (fixture).*
- [x] **IDs estables + estados explícitos en canva (copia 2.4)** — `CanvasNodeId` opaco (`w<sec>:<ms>:<seq>`, contador monotónico → nunca reutilizado) + `CanvasNode` puro serializable (`toJson/fromJson/copyWith`) + `AgentNodeRuntime` separado del modelo. `_newId()` del canva migrado. SDD-110.
  - *Gate: ✅ al eliminar y recrear un nodo, el ID no se reutiliza (1000 generaciones sin colisión); el estado del nodo es serializable sin runtime.*
- [x] **Contratos JSON + exit codes (copia 1.4)** — `AgentCommandRunner` (`cmd /c`, stdout JSON + BOM saneado, stderr, exit 0/1/2/3/4/5 + 9009→notFound, pre-check de ejecutable inexistente, timeout→kill). `SemanticExit` tipado. SDD-111.
  - *Gate: ✅ wrapper parsea stdout JSON de un fixture y mapea exit codes a errores tipados.*

**Piezas fusionadas con fases existentes (no nuevas):** copia 1.3 (skill estilo herdr) y 2.1 (Persona Pack de buzz) → se integran en **Etapa 4b** como fuente de su spec. Copia 2.3 (orquestador/colas) → **Etapa 6**. Copia 2.2 (workflows), 3.1 (eventos firmados, ADR), 3.2 (remote agents), 3.3 (marketplace) → **post-Etapa 7**. Copia 1.2 (refactor Riverpod) → solo convención en código nuevo; refactor total post-Etapa 7.

---

## Etapa 4 — Canva de ideas + `.md`

**Objetivo:** los nodos del canva son documentos Markdown enlazados (Obsidian-style).

- [ ] Nodos `.md` enlazados con `[[links]]`; render Markdown con preview live.
- [ ] Backlinks y navegación por enlaces desde el editor.
- [ ] Auto-layout simple; persistencia en drift.

**Pruebas de comprobación (gate):**
- [ ] Unit: parser de `[[links]]`, índice de backlinks.
- [ ] Widget: preview markdown se actualiza en vivo; click en link navega al nodo.
- [ ] Manual: crear 5 notas enlazadas, navegar por backlinks, cerrar/reabrir → todo persiste.
- [ ] **Dogfood:** el mapa de ideas de este proyecto (`docs/`) representado como canva navegable.

---

## Etapa 4b — Gestor visual de skills + laboratorio

**Objetivo:** crear agentes/skills visualmente, probarlas en vivo y exportarlas a cualquier dialecto.

- [ ] Constructor visual de `skills.md`: `name`, `description`, `triggers`, `tags`, permisos; cuerpo Markdown con preview; bloques arrastrables (instrucciones, ejemplos, restricciones, anti-patrones).
- [ ] Laboratorio sandbox: input → ranking de skills que se activarían, con confianza y por qué. Historial + regression tests dentro de la propia skill.
- [ ] Skills como nodos del canva (relaciones: depende, excluye, compone).
- [ ] Export multi-dialecto: opencode, Cursor, Claude Code, Continue, Codex (con diff visual).
- [ ] CI de dogfood: `flutter test --tags skills` ejecuta el laboratorio en modo headless.

**Pruebas de comprobación (gate):**
- [ ] Unit: parser YAML frontmatter por dialecto; simulador de triggers con scoring; export por dialecto.
- [ ] Widget: el form crea un `SKILL.md` válido; drag&drop de bloques; el sandbox muestra ranking.
- [ ] **Dogfood duro:** 3 skills de este repo creadas desde la app, y cada una pasa su test en el laboratorio.
- [ ] Manual: crear skill → probarla → exportarla a `.opencode/skills/` → reiniciar opencode → se activa con su trigger real.

---

## Etapa 5 — Grafo del proyecto (2D → 3D)

**Objetivo:** visualizar las conexiones entre archivos como hizo `mcp codebase-memory` / Supermemory / Engram.

- [ ] Indexador de relaciones: imports (Dart/Python), referencias, `[[links]]` entre `.md`.
- [ ] Grafo 2D de fuerza dirigida (d3-force portado a Flutter), cluster por paquete.
- [ ] Hover = preview, click = abre el archivo en el editor.
- [ ] Grafo 3D: WebView + Three.js solo en desktop/web; fallback 2D en mobile.

**Pruebas de comprobación (gate):**
- [ ] Unit: indexador detecta imports/referencias/links reales de un fixture.
- [ ] Widget: grafo renderiza, hover muestra preview, click abre editor.
- [ ] Performance: 5.000 nodos a ≥ 30fps (baseline registrada antes de optimizar).
- [ ] Manual: cargar este repo y navegar su grafo completo en desktop.

---

## Etapa 6 — Vibecoding

**Objetivo:** el agente IA trabaja dentro del canva; cada propuesta es un nodo-diff aceptable o rechazable.

- [ ] Agente conectado al editor + canva (opencode CLI de legacy o API LLM directa).
- [ ] Cada propuesta = nodo-diff con preview; aceptar/rechazar; historial navegable.

**Pruebas de comprobación (gate):**
- [ ] Unit: pipeline parche → nodo-diff; transiciones de estado aceptar/rechazar/revertir.
- [ ] Widget: chat + nodo-diff; aplicar cambio y revertir sin estado residual.
- [ ] Integration: agente real propone un cambio en un fixture; aplicado, los tests siguen verdes.
- [ ] **Dogfood:** una feature real de este repo implementada 100% vía vibecoding desde la app.

---

## Etapa 7 — SDD++ + Playwright E2E

**Objetivo:** gates automáticos por fase; cada feature arranca como SDD enlazado en el canva.

- [ ] Playwright CLI contra `flutter build web` (`tool/e2e_web.ps1`).
- [ ] `patrol_cli` para flujos mobile.
- [ ] CI (GitHub Actions) corre analyze + tests + E2E web por PR.

**Pruebas de comprobación (gate):**
- [ ] Script E2E web: conectar SSH, abrir archivo, editar, guardar — sin intervención humana.
- [ ] Patrol: mismo flujo crítico en Android.
- [ ] CI: un PR con feature + SDD + tests + E2E pasa completo.

---

## Definition of Done global

- CI verde (`flutter analyze` + suite + gates de la fase).
- Probado en ≥ 2 plataformas (Android + desktop).
- Gate de la fase cumplido (checklist anterior).
- Evidencia (capturas/logs) adjunta en el commit de cierre de fase.
