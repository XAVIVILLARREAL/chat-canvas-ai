# COVERAGE-GUI — Cobertura 100%: cada botón/función/feature con su prueba Playwright humano

> **Producto:** Canvas AI · **Estado:** v1.0 · 2026-08-25 · **REGLA DURA** (AGENTS.md): sin prueba humana → la feature NO existe.
> Método de ejecución: [WORKFLOW-AGENTICO](./WORKFLOW-AGENTICO.md) · Suite humana: `pnpm test:e2e:human` (clicks+teclado, móvil 375 + desktop 1440, video en `evidence/`).

## Cómo leer esta tabla

- Cada fila = **un elemento interactivo** (botón, input, shortcut, menú, dropdown, nodo del canvas, comando).
- `Test` = id del spec Playwright humano (creado en `e2e/human/tests/<feature>.spec.ts`).
- Estado: `⬜` no escrito · `🟡` escrito, sin gate · `✅` suite verde + video.
- **Una fila nueva de UI sin su test = PR rechazado.** Se marca en el PR template.

## MVP-1 — Base operativa

| Vista | Elemento interactivo | Acción (clicks+teclado) | Test | Estado |
|---|---|---|---|---|
| AppShell | BottomNav móvil / Sidebar desktop | navegar entre 6 tabs | `appshell.spec.ts` | ⬜ |
| AppShell | Toggle sidebar | abrir/cerrar panel | `appshell.spec.ts` | ⬜ |
| Proyectos | Tarjeta proyecto | crear/cambiar/borrar proyecto | `proyectos.spec.ts` | ⬜ |
| Sesiones | Botón "Nueva sesión" | crear sesión | `chat.spec.ts` | ⬜ |
| Sesiones | Sidebar de sesiones | buscar, filtrar, archivar, renombrar, duplicar | `chat.spec.ts` | ⬜ |
| Chat | Input de mensaje | escribir + Enter (streaming) | `chat.spec.ts` | ⬜ |
| Chat | Slash commands `/agent /skill /run /compact /help` | invocar y ver efecto | `chat.spec.ts` | ⬜ |
| Chat | Botón copiar código | copiar bloque | `chat.spec.ts` | ⬜ |
| Chat | Tool-call render | aprobar/rechazar tool-call | `chat.spec.ts` | ⬜ |
| Chat | Diff por hunks | aprobar hunk 1, rechazar hunk 2 | `chat.spec.ts` | ⬜ |
| Chat | Rama de edición ‹/› | editar mensaje y navegar alternativas | `chat.spec.ts` | ⬜ |
| Chat | Memory Rail / scrubber | navegar rungs | `chat.spec.ts` | ⬜ |
| Chat | Medidor de contexto | abrir, ver desglose, ajustar límite | `contexto.spec.ts` | ⬜ |
| Chat | Widget de costo | ver badge por mensaje/sesión | `chat.spec.ts` | ⬜ |
| Config | Panel 2 públicos (no-programador / JSON) | cambiar ajustes, override por proyecto | `config.spec.ts` | ⬜ |
| Config | Conectar provider BYOK | pegar key, validar, probar | `providers.spec.ts` | ⬜ |
| Encargo | Modo encargo | pedir tarea sin prompt, recibir evidencia | `encargo.spec.ts` | ⬜ |
| Resume | Reanudar sesión interrumpida | cerrar y reabrir, continuar fluido | `chat.spec.ts` | ⬜ |
| Editor | File explorer | abrir/crear/editar archivo | `editor.spec.ts` | ⬜ |
| Editor | Live preview sandboxed | agente escribe HTML → preview <2s | `editor.spec.ts` | ⬜ |
| Editor | Fast apply | archivo grande escribiéndose en vivo | `editor.spec.ts` | ⬜ |
| Onboarding | Primer arranque guiado | nuevo usuario → primer agente <5 min | `onboarding.spec.ts` | ⬜ |
| Backup | Export/import workspace | backup completo ida y vuelta | `backup.spec.ts` | ⬜ |
| i18n | Selector de idioma | cambiar es→de→pt sin recargar, fallback en | `i18n.spec.ts` | ⬜ |

## MVP-2 — Memoria + Skills + Resultados

| Vista | Elemento interactivo | Acción | Test | Estado |
|---|---|---|---|---|
| Skills | CRUD skill (editor visual) | crear/editar/duplicar/eliminar solo con clicks | `skills.spec.ts` | ⬜ |
| Skills | Ceremonia de creación | guardar skill → overlay nacimiento + avatar | `skills.spec.ts` | ⬜ |
| Skills | Laboratorio sandbox | probar skill contra input, ver costo | `skills.spec.ts` | ⬜ |
| Skills | Tool-gating | skill QA no puede escribir (bloqueado) | `skills.spec.ts` | ⬜ |
| Skills | Rutinas "follow along" | grabar N pasos → skill propuesto | `skills.spec.ts` | ⬜ |
| Memoria | Knowledge / decisiones | preguntar y ver la decisión citada | `memoria.spec.ts` | ⬜ |
| Memoria | Human-Tweak Lock | editar línea a mano → candado, no sobreescribe | `memoria.spec.ts` | ⬜ |
| Pruebas | Resultado en canvas | agente implementa → tests verdes → aprobar | `pruebas.spec.ts` | ⬜ |
| Kanban | Drag tarea todo→doing→done | arrastrar tarjetas + persistencia | `kanban.spec.ts` | ⬜ |
| Kanban | Bloques animados de tests | test por test llenándose (rojo pulsante en fallo) | `kanban.spec.ts` | ⬜ |
| Kanban | Vista evidencia por etapa | click en card → timeline de rungs | `kanban.spec.ts` | ⬜ |
| Oficina | Canva ReactFlow | arrastrar nodo, conectar 2 nodos, zoom rueda/pinch | `oficina.spec.ts` | ⬜ |
| Oficina | Command Palette ⌘K | 3 letras + Enter ejecuta acción | `oficina.spec.ts` | ⬜ |
| Oficina | Nodos-agente vivos | crear agente → nodo aparece con estado | `oficina.spec.ts` | ⬜ |

## MVP-3 — Automatización + Nube + Mercado

| Vista | Elemento interactivo | Acción | Test | Estado |
|---|---|---|---|---|
| Canvas auto | Nodos 8 tipos + deploy-spec | armar flujo visual → compilar → ejecutar | `automatizacion.spec.ts` | ⬜ |
| Canvas auto | Conectores (HTTP/MCP/Cron) | configurar conector y disparar | `automatizacion.spec.ts` | ⬜ |
| Nube | Login/registro | cuenta → sesión → logout | `nube.spec.ts` | ⬜ |
| Nube | Modo 24/7 | cerrar app → reabrir en otro dispositivo con evidencia | `nube.spec.ts` | ⬜ |
| Nube | Límites de tier | free tocando muro → mensaje upgrade | `nube.spec.ts` | ⬜ |
| Sync | Multi-dispositivo | editar en desktop → aparece en móvil → resolver conflicto | `sync.spec.ts` | ⬜ |
| GitHub | Ciclo git sin terminal | feature→commit→push→PR + diff por hunks | `github.spec.ts` | ⬜ |
| Marketplace | Export/import bundle | firmar skill → importar en otra instalación | `marketplace.spec.ts` | ⬜ |
| Backup nube | GDPR export/erasure | export completo / borrado por tenant | `gdpr.spec.ts` | ⬜ |

## Funciones añadidas (F17-F28 — [FEATURE-BACKLOG](./FEATURE-BACKLOG.md))

| Vista | Elemento interactivo | Acción (clicks+teclado) | Test | Estado |
|---|---|---|---|---|
| Chat | Botón comparador A/B | mismo prompt → 2 respuestas lado a lado → elegir ganadora | `comparador.spec.ts` | ⬜ |
| Chat | Adjuntar imagen/PDF | screenshot con bug → agente corrige en código | `vision.spec.ts` | ⬜ |
| Chat | Forecast de costo pre-envío | ver "≈ tokens ≈ $" antes de Enter | `chat.spec.ts` | ⬜ |
| Chat | Importar historial ChatGPT/Claude | importar JSON → sesiones reconstruidas | `import.spec.ts` | ⬜ |
| Chat | Export sesión a PDF/MD | exportar → reporte compartible con rungs | `export.spec.ts` | ⬜ |
| Entrega | Compartir link público | generar link read-only + expiración + revocar | `share.spec.ts` | ⬜ |
| Mensajería | Puente Telegram/WhatsApp/Discord | escribir por Telegram → agente responde (nube) | `mensajeria.spec.ts` | ⬜ |
| Supervisor | Configurar Agente Supervisor | elegir skill supervisor + canal + presupuesto por canal | `supervisor.spec.ts` | ⬜ |
| Supervisor | Órdenes maestras vía chat | "¿en qué anda la sesión X?" → estado real; "pausa Y" → confirmación numerada → pausada | `supervisor.spec.ts` | ⬜ |
| Supervisor | Crear sesión por orden | "crea sesión para el login fix" → creada y visible en Control Room | `supervisor.spec.ts` | ⬜ |
| Dashboard | Vista uso/costos personal | costo por proyecto/día, top skills, entregas | `dashboard.spec.ts` | ⬜ |
| Desktop | Quick capture global (hotkey SO) | hotkey → mini-ventana → tarea → notificación done | `quickcapture.spec.ts` | ⬜ |
| Papelera | Ver borrados + restaurar | eliminar sesión → papelera → restaurar intacta | `papelera.spec.ts` | ⬜ |
| Providers | Perfiles BYOK (trabajo/personal) | cambiar perfil → providers conmutan por proyecto | `providers.spec.ts` | ⬜ |
| Rutinas | Rutinas programadas visibles | "cada lunes 9am ejecuta X" visible/gestionable + historial de corridas | `rutinas.spec.ts` | ⬜ |
| Chat | Cola de mensajes durante streaming | escribo 2 mientras responde → cola editable/reordenable → auto-envío FIFO; pausa y reanudo | `cola.spec.ts` | ⬜ |
| Chat | Presencia e indicadores en vivo | typing/working del agente <1s tras evento; presencia de humanos en sesión | `presencia.spec.ts` | ⬜ |
| Chat | Reacciones 👍/❌ en mensajes | reaccionar → rung en event_stream → dashboard refleja feedback | `reacciones.spec.ts` | ⬜ |
| Config | Hooks de ciclo de vida | configuro PreToolUse bloqueo + PostToolUse format en 1 pantalla; se ejecutan solos | `hooks.spec.ts` | ⬜ |
| Browser tool | Navegación del agente (sandbox) | "entra al staging y dime qué está roto" → navega/click/captura y reporta | `browsertool.spec.ts` | ⬜ |
| Editor | Diagnósticos LSP al agente | error de tipos real llega solo al agente → corrige → desaparece | `lsp.spec.ts` | ⬜ |
| Skills | Import de rules files (.cursorrules/CLAUDE.md) | pego CLAUDE.md real → skill nativo funciona; inválido → accionable | `import-rules.spec.ts` | ⬜ |
| Sesiones/Skills | Pin/favoritos | fijar arriba, orden manual persiste tras reinicio | `pins.spec.ts` | ⬜ |
| AppShell | Modo enfoque (zen) | ocultar paneles → solo chat/canvas; Esc sale; estado no se pierde | `zen.spec.ts` | ⬜ |
| Listas | Acciones masivas | multi-selección → archivar/borrar/mover varias a la vez | `masivo.spec.ts` | ⬜ |
| Rutinas | Rutinas programadas visibles | "cada lunes 9am ejecuta X" visible/gestionable + historial de corridas | `rutinas.spec.ts` | ⬜ |

## Reglas

1. **Toda fila es obligatoria.** Un elemento interactivo nuevo añade su fila en el mismo PR.
2. **El gate de fase exige sus filas `✅`.** (Regla MATRIZ + EJECUCION-ORDEN).
3. Los tests se escriben **antes/igual que** el código (TDD humano): fallan → implementar → verdes.
4. **Debug en tiempo real:** si un test falla, correr en vivo y capturar consola/red, no adivinar.

## Suites existentes del scaffold (mantener/expandir — ya en `e2e/human/tests/`)

| Vista | Elemento interactivo | Acción (clicks+teclado) | Test | Estado |
|---|---|---|---|---|
| Temas | Toggle dark/light (header + Config) | cambio instantáneo sin recargar; persiste tras reinicio; modo system sigue al OS | `temas.spec.ts` | 🟡 |
| i18n | Selector de idioma (header + Config) | es↔en sin recargar; fallback a en; persiste | `idioma.spec.ts` | 🟡 |
| Boot | Arranque de la app | abrir app → título visible, layout sin roturas | `boot.spec.ts` | 🟡 |
| Agentes | Card de agente | crear agente → card → click → detalle → seleccionar/deseleccionar | `create-agent.spec.ts` | 🟡 |
| Teclado | Navegación 100% teclado | Tab/Enter/Escape, foco visible | `keyboard-nav.spec.ts` | 🟡 |
| Responsive | Misma app en 375/1440 | navegación humana en móvil y desktop | `responsive-human.spec.ts` | 🟡 |

## Generar una fila nueva

```markdown
| <Vista> | <elemento> | <acción humano> | `<feature>.spec.ts` | ⬜ |
```
Cada fila nace en el mini-SDD de la feature y se completa en su gate.
