# PRD — Canvas AI

> **Producto:** herramienta de IA generalista — multi-agente, visual, local-first (BYOK) + nube de pago 24/7.
> **Estado:** v1.0 · 2026-08-25 · Base de decisiones: [ADR-006](./ADRs/ADR-006-vision-hibrida-local-nube.md)
> **Regla de medición:** toda feature se define por su **resultado medible** con la suite humana de Playwright (clicks + teclado, `@core` y móvil 375/desktop 1440). "Compila" no es una feature.

---

## 1 · Para quién es (personas)

| Persona | Quién es | Dolor | Qué valora | JTBD (job to be done) |
|---|---|---|---|---|
| **Dev builder** | Dev que usa agentes de IA (Cursor/Claude Code) pero quiere orquestar varios | Contexto fragmentado entre terminales, chats y editores | Control del contexto, costo, resultados verificables | "Cuando construyo software, quiero delegar tareas a varios agentes y ver el resultado verificable en un solo lugar, sin cambiar de herramienta" |
| **Power user no-código** | Persona que automatiza (n8n/Activepieces/Zapier) sin ser dev | Configurar automatizaciones requiere YAML/flujos complejos | Simplicidad visual, reutilización, precio | "Cuando necesito automatizar un proceso, quiero armarlo visualmente con piezas reutilizables (skills) y que corra sin supervisión" |
| **Suscriptor 24/7** | Pequeño equipo/emprendedor que quiere agentes trabajando continuamente | Sus agentes mueren al cerrar la laptop | Persistencia, continuidad, evidencia | "Cuando cierro mi laptop, quiero que mis agentes sigan trabajando y encontrar la evidencia al volver" |
| **Privacy-first** | Usuario que no quiere mandar su código/contexto a terceros | Desconfianza de nubes ajenas | Local, offline, dueño de sus datos | "Cuando trabajo con datos sensibles, quiero que TODO corra en mi máquina y mis keys vivan conmigo" |

## 2 · Las 4 vistas y su JTBD (producto)

| Vista | JTBD del usuario | ¿Por qué existe (problema que mata)? |
|---|---|---|
| **Chat con sesiones** | "Gestiono conversaciones persistentes con agentes y veo el costo en vivo" | Sin sesiones persistentes, el contexto se pierde cada vez |
| **Control Room (canvas)** | "Veo de un vistazo qué agentes/sesiones están vivos, trabajando o bloqueados" | Sin mapa, pierdes el estado global de tu trabajo |
| **Skills (.md)** | "Creo una receta reutilizable con personalidad y la uso/probo sin YAML" | Re-hacer el mismo prompt una y otra vez |
| **Canvas de Automatización** | "Armo flujos multi-runtime visualmente y veo resultados verificables" | n8n/Activepieces limitan el lenguaje y la evidencia |
| **Segundo Cerebro** | "Navego y planeo mis documentos como un mapa, con IA que me audita" | La doc vive dispersa y nadie la lee |

## 3 · Features → Resultado medible (Playwright humano)

> Cada fila es una feature de producto. **Resultado = criterio de aceptación operado como humano** (clicks + teclado, video en `evidence/`, móvil+desktop). El `Gate` enlaza la fase del plan maestro.

### MVP-1 — Base operativa (4-6 sem)
| ID | Feature | Resultado medible (Playwright humano) | Gate |
|---|---|---|---|
| F1 | Chat con sesiones persistentes | Creo sesión → escribo "hola" → streaming aparece → cierro/reabro la app → la sesión sigue con historial completo | Gate A |
| F2 | BYOK (trae tu API key) | Pego mi key de DeepSeek/OpenRouter en 1 pantalla → envío mensaje real → badge de costo sube con tokens | Gate C |
| F3 | Slash commands | Escribo `/agent qa` → el avatar QA aparece en la sesión y responde solo él | Gate A |
| F4 | Editor de código integrado | El agente crea un archivo → aparece en el árbol → lo abro, lo edito, se persiste | Gate B |
| F5 | Medidor de contexto | Abro el medidor en una sesión real → desglose por fuente visible → ajusto límite → el siguiente request lo refleja | Gate A |
| F6 | Onboarding <5 min | Usuario nuevo → primer agente trabajando ante sus ojos sin leer docs (cronometrado) | T.ONB |

### MVP-2 — Memoria + Skills + Resultados (6-8 sem)
| ID | Feature | Resultado medible (Playwright humano) | Gate |
|---|---|---|---|
| F7 | Skills `.md` con personalidad | Creo skill desde cero (solo clicks+tecleo) → nace con avatar/emoji/bio → lo pruebo en el laboratorio | Gate E |
| F8 | Memoria entre sesiones | Pregunto "¿cómo manejamos auth?" en sesión nueva → la decisión guardada aparece citada | Gate D |
| F9 | Motor de pruebas con evidencia | Agente implementa → tests corren → bloque verde test-por-test en el canva → apruebo → done | Gate H |
| F10 | Kanban de resultados | Activo "trabaja 4 horas" con 15 tareas → vuelvo → tablero con 12 verdes, 2 en revisión, 1 bloqueada, evidencia clicable | KR |
| F11 | Human-Tweak Lock | Edito una línea a mano → el agente no la sobreescribe y el candado aparece en el gutter | Gate D |

### MVP-3 — Automatización + Multi-dispositivo (8-12 sem)
| ID | Feature | Resultado medible (Playwright humano) | Gate |
|---|---|---|---|
| F12 | Canvas de automatización multi-runtime | Armo un flujo visual (trigger→llm→code→output) → compilo → se ejecuta → resultado en el nodo output | Gate F |
| F13 | Modo nube 24/7 (suscripción) | Cierro la app → reabro en otro dispositivo → la sesión siguió trabajando con evidencia nueva | N.7 |
| F14 | Sync multi-dispositivo | Creo una skill en desktop → aparece en el móvil → la edito en ambos → resuelvo el conflicto eligiendo | L.2 |
| F15 | GitHub nativo | Hago feature→commit→push→PR sin terminal, con diff revisable por hunks | M.3 |
| F16 | Marketplace de skills | Exporto un skill a bundle firmado → lo importo en otra instalación → funciona 1-click | O.1 |

## 4 · Métrica norte y medición de producto

- **North-star:** *sesiones que terminan en ENTREGA* (evidencia de resultado aceptada por el humano).
- **Activación:** primer agente completa una tarea E2E en la primera sesión.
- **Retención:** sesiones reanudadas en los 7 días posteriores a la primera.
- **Eventos instrumentados desde v0:** `session.created`, `agent.invoked`, `skill.created`, `task.completed`, `session.exported`, `nube.subscribed`. Detalle en [`PRODUCT-METRICS.md`](./PRODUCT-METRICS.md).
- **Telemetría:** OPT-IN anónima (nunca contenido ni contexto); en local-first se recopila en el dispositivo y el usuario decide si la exporta.

## 5 · No hacemos (anti-scope explícito)

- No somos una "empresa autónoma" con empleados IA (eliminado, ADR-006).
- No vendemos tokens — **BYOK** siempre (local gratis, nube cobra hosting/24/7, no el LLM).
- La nube **nunca es gratuita** para todo el mundo; local siempre es gratis.
- Voz/3D/VR/dopamina/Consejo de Expertos → **post-v1** (Q6, permanecen en el plan marcados).
- No cobramos por resultado en v1 (solo tras >70% success-rate medido, SDD-010).

## 6 · Funciones añadidas tras revisión de producto (F17-F28)

> Análisis completo con decisiones (agregar/post-v1/rechazadas): [FEATURE-BACKLOG](./FEATURE-BACKLOG.md). Resumen de lo que ENTRA al plan:

| ID | Función | Resultado medible (Playwright humano) | Gate |
|---|---|---|---|
| F17 | Tools web nativas (`web_search`/`web_fetch`) | Pido "investiga X" → el agente cita 2+ fuentes con links | C.8 |
| F18 | Visión multimodal | Adjunto screenshot con bug → el agente lo corrige en código | C.9 |
| F19 | Comparador A/B de modelos | Mismo prompt → 2 respuestas lado a lado → elijo la mejor | A.10 |
| F20 | Compartir entrega pública | Genero link read-only → se abre sin cuenta → revocable | O.4 |
| F21 | Puentes WhatsApp/Telegram/Discord + **Agente Supervisor** | Escribo por Telegram al Supervisor → "¿en qué anda la sesión auth?" responde estado REAL; "pausa la de scraping" → confirmo → pausada | N.8+N.9 |
| F22 | Captura rápida global (hotkey SO) | Hotkey → mini-ventana → tarea enviada → notificación al done | S.3 |
| F23 | Dashboard personal uso/costos | Abro dashboard → costo por proyecto/día + top skills reales | N.5b |
| F24 | Forecast de costo pre-envío | Antes de enviar veo "≈ tokens ≈ $" del modelo elegido | A.7b |
| F25 | Importar desde ChatGPT/Claude | Importo JSON exportado → sesiones reconstruidas locales | A.0b |
| F26 | Papelera + restaurar | Elimino sesión → papelera → restauro intacta | A.2b |
| F27 | Perfiles BYOK (trabajo/personal) | Cambio perfil → providers y keys conmutan por proyecto | G.1b |
| F28 | Export sesión a PDF/Markdown | Exporto sesión → reporte compartible con rungs + resultado | A.6b |
| F37 | Cola de mensajes durante streaming | Escribo 2 mensajes mientras responde → cola editable → auto-envío FIFO al quedar libre | A.4b |
| F38 | Hooks de ciclo de vida (PreToolUse/PostToolUse/Stop) | Configuro hook que bloquea `rm -rf` → el agente lo intenta → bloqueado ANTES de ejecutar | C.11 |
| F39 | Presencia e indicadores en vivo | Agente trabajando → typing/working visible <1s; veo qué humanos están en la sesión | A.12 |
| F40 | Reacciones 👍/❌ en mensajes | Reacciono a una respuesta → rung en event_stream → dashboard refleja el feedback | A.12 |

## 7 · Riesgos de producto (top 5)

1. **Costo LLM descontrolado** → guardrail por sesión/día desde MVP-1 + badge en vivo.
2. **El sandbox no convence** (código del agente) → frontera documentada en el modelo de amenazas + demo de aislamiento.
3. **Skills demasiado complejos de crear** → editor visual + plantillas + "ceremonia de creación".
4. **La nube 24/7 no justifica el precio** → free-tier de nube con límites + valor visible (digest + evidencia).
5. **Abandono post-primera-sesión** → onboarding <5 min + proyecto ejemplo incluido + métrica de activación instrumentada.
