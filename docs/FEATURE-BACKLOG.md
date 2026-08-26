# FEATURE-BACKLOG — Análisis de funciones del producto (qué agregar y qué no)

> **Producto:** Canvas AI · **Estado:** v1.0 · 2026-08-25 · Método: revisión contra competidores (Cursor/Cline/n8n/Lovable/ChatGPT) y los 7 [diferenciadores](./PRODUCT-DIFFERENTIATORS.md).
> **Regla:** una función entra al plan solo si alimenta un diferenciador o la métrica norte. Las rechazadas quedan documentadas con el porqué (anti-scope explícito).

## 1 · Escala de decisión

**AGREGAR** = fase nueva o ampliación en la MATRIZ · **POST-V1** = backlog marcado · **RECHAZADA** = no hacer (razón).

---

## 2 · AGREGAR al plan (aprobadas — 12 funciones)

| # | Función | Qué es | Por qué gana | Diferenciador | Dónde cae |
|---|---|---|---|---|---|
| F17 | **Tools web nativas** (`web_search` + `web_fetch`) | El agente investiga en internet sin configurar nada (allowlist de dominios, caché, robots) | Hoy requiere montar un MCP browser; nativo = agentes que investigan de fábrica | Evidence-first (investiga y cita fuentes) | **C.8** (Etapa 3) |
| F18 | **Visión multimodal** (imágenes/PDF) | Adjuntas screenshot → "arregla este bug de UI"; PDFs → resumen/extracción | Los bugs de UI se reportan con capturas; multimodal es tabla de juego 2026 | Humano en el centro (reporta como humano) | **C.9** (Etapa 3) |
| F19 | **Comparador A/B de modelos** | Mismo prompt → 2 modelos lado a lado → eliges la mejor respuesta (y el router aprende tu preferencia) | Confianza + ahorro: eliges modelo con evidencia, no por marketing | Evidence-first | **A.10** (Etapa 1) |
| F20 | **Compartir entrega pública (link read-only)** | Link firmado con expiración a una entrega/artefacto — se abre sin cuenta | Alimenta el KPI de growth de SDD-010 ("% que comparten artefacto en sesión 1") — ¡hoy no existe la función de compartir! | Evidence-first (comparte evidencia) | **O.4** (Etapa 15) |
| F21 | **Puentes de mensajería + Agente Supervisor** | WhatsApp/Telegram/Discord atendidos por un **Agente Supervisor** (chief-of-staff GrokBot/Hermes) con visibilidad de TODOS los proyectos y sesiones del Control Room: consulta estado, pausa/reanuda, crea sesiones y reporta con evidencia — confirmación numerada en acciones destructivas | Killer feature del tier Pro: tus agentes te alcanzan donde estás; el Supervisor es tu mayordomo | Humano en el centro + Evidence-first | **N.8 + N.9** (Etapa 14, nube) |
| F22 | **Captura rápida global** (hotkey del SO) | Hotkey global → mini-ventana → tarea al agente → notificación al terminar | Capturar ideas/tareas sin cambiar de app | Humano en el centro | **S.5** (Transversal S, desktop) |
| F23 | **Dashboard personal de uso/costos** | Vista usuario: costo por proyecto/día, top skills, entregas, tendencia | El costo visible genera confianza y control (BYOK) | Humano en el centro | **N.5b** (amplía tracking) |
| F24 | **Forecast de costo pre-envío** | Antes de enviar: "≈ 3.4k tokens ≈ $0.011 con deepseek-chat" | Sorpresa-cero en la factura; refuerza BYOK | Humano en el centro | **A.7b** (amplía widget costo) |
| F25 | **Importar desde ChatGPT/Claude** | Importar historial exportado (JSON) → sesiones locales | Hook de adquisición: migrar es 1 click, empezar de cero duele | Memory Rail (tu historia vive aquí) | **A.0b** (onboarding) |
| F26 | **Papelera + restaurar** | UI sobre el soft-delete del schema: ver borrados, restaurar | "No pierdes nada" — profesional básico | Local-first (dueño de tus datos) | **A.2b** (persistencia) |
| F27 | **Perfiles BYOK** (trabajo/personal) | Grupos de providers conmutables; cada proyecto usa su perfil | Separar contextos sin duplicar keys | BYOK seguro | **G.1b** (skills/providers) |
| F28 | **Export sesión a PDF/Markdown** | Reporte compartible/imprimible de una sesión (rungs + resultado) | Entregables para clientes/jefes sin acceso a la app | Evidence-first | **A.11** (persistencia) |

### Detalle de implementación (resumen)

- **F17 C.8**: `web_fetch` con render opcional (readability), caché LRU local, allowlist editable por proyecto; `web_search` vía API del provider si soporta, si no DuckDuckGo/Jina reader. Chaos: dominio bloqueado → error accionable.
- **F18 C.9**: adjuntos ya existen (A.3); falta pipeline multimodal: detección de capacidad del provider, downscale de imágenes, extracción de texto de PDF (local), fallback claro si el modelo no soporta visión.
- **F19 A.10**: UI split-view con 2 streams paralelos, botón "elegir esta"; rung DECISION con la preferencia → router aprende ([C·C.2]).
- **F20 O.4**: link `https://share.chat-canvas.ai/<id>` (nube) o HTML estático exportado (local); expiración + revocación; watermark "generado con Canvas AI".
- **F21 N.8**: webhook entrante por canal (Telegram bot API / WhatsApp Cloud API / Discord bot), auth 1:1 con cuenta, rate-limit, respuestas con streaming resumido + link a evidencia.
- **F22 quick capture**: Tauri global-shortcut (plugin ya está en tauri.conf) → ventana flotante → cola local → notificación al terminar.
- **F23/F24**: proyecciones del `event_stream` — cero tablas nuevas.

## 3 · Micro-mejoras aprobadas (F29-F32 — pequeñas, alto pulido)

| # | Mejora | Qué es | Dónde cae |
|---|---|---|---|
| F29 | **Pin/favoritos** de sesiones y skills | Fijar arriba lo que más usas (icono pin, orden manual) | A.2 sidebar |
| F30 | **Modo enfoque (zen)** | Ocultar paneles, solo chat/canvas a pantalla completa; Esc sale | A.1 AppShell |
| F31 | **Acciones masivas** | Multi-selección en listas: archivar/borrar/mover varias a la vez | A.2 + papelera |
| F32 | **Rutinas programadas visibles** | El cron del canvas se ve/gestiona desde UI ("cada lunes 9am ejecuta skill X") con historial | F.4 triggers + G.6 |

> Todas viajan dentro de fases existentes (sin filas MATRIZ nuevas); sus elementos interactivos SÍ añaden fila en [COVERAGE-GUI](./COVERAGE-GUI.md).

## 4 · POST-V1 (backlog marcado, no bloquea)

| Función | Por qué espera |
|---|---|
| Extensión de navegador (enviar selección/página al agente) | Esfuerzo alto, canal aparte; el quick capture cubre el 80% |
| Integraciones email/calendario/Notion nativas | Cubierto parcialmente vía MCP (P.4 plantillas 1-click) |
| Colaboración multi-cursor tiempo real | L.3 Co-Work ya cubre la parte CRDT |
| Fine-tuning local de modelos | No es el producto; Ollama cubre modelos especializados |
| Plantillas de proyecto en marketplace | Skills + bundles ya cubren; ampliar después |
| Modo presentación de entregas | Bonito, no core |

## 5 · RECHAZADAS (con razón — anti-scope)

| Función | Razón del rechazo |
|---|---|
| Chat social entre usuarios / feed público | No es un chatbot social; es una herramienta de trabajo |
| Cuenta obligatoria en local | Mata el pitch local-first (AUTH) |
| Cobrar por tokens | Vendemos hosting/24-7, nunca tokens (BYOK, PRD §5) |
| Editor de video/imagen generativa | Out of scope; los skills pueden invocar tools externas vía MCP |
| Sincronización P2P blockchain | Complejidad sin beneficio demostrado; sync servidor cubre |

## 6 · Impacto en el plan

- **MATRIZ:** +12 fases (A.10, C.8, C.9, N.8, O.4 + A.0b, A.2b, A.7b, A.11, G.1b, N.5b, S.5) → total **161 fases** — **las 12 funciones tienen fila con sus pruebas** (regla: fase sin fila NO se construye).
- **COVERAGE-GUI:** +12 filas (una por función con UI) → 64 elementos.
- **PRD:** funciones F17-F28 añadidas a la tabla de features por MVP.
- **Loop:** cada función se implementa con el [WORKFLOW-AGENTICO](./WORKFLOW-AGENTICO.md) (ANALYZE 5 sub-agentes → TDD humano → debug en vivo → iterar) y su "done" = resultado funcional en video.
