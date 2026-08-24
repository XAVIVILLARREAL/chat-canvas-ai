# PLAN V — Visual GrokBot: la capa social de mensajería (transversal)

> [← Maestro](./README.md) · Transversal: V.0 desde A.1/A.4 (chat-first) · V.1–V.2 con F.0/G.7 · V.3 con N.6 · V.4 con G.6/U.5
> Fuente: análisis visual de Grok Bot (xAI/Cursor, ago-2026) — app estilo mensajería (iMessage), NO un dashboard de agentes. Verificado con docs oficiales de x.ai + reviews hands-on (investigación 2026-08-24). Lo funcional ya está minado en [SDD-004](../SDD-004-analisis-grokbot.md) y [SDD-012](../SDD-012-multi-agent-grokbot-patterns.md) — ESTE plan captura SOLO lo visual.
> **Regla: COMPLEMENTA, no quita nada.** Codex sigue siendo la referencia de paneles/diffs ([A·A.4], [PLAN B]); GrokBot se convierte en la referencia de la capa SOCIAL/mensajería. El chat es la superficie primaria; los paneles/canva son el detalle que se abre DESDE el hilo.

**Entregable:** la app SE SIENTE como mensajería (desks + identidad por avatar + actividad inline + group chat vivo), sin perder nada de lo ya planeado (paneles Lovable, canva oficina, diffs, motor de pruebas).

## La idea central (verificada)

- Grok Bot NO es un dashboard de agentes: es una **app de mensajería** donde cada bot es un **"desk"** (puesto de trabajo) en la sidebar — una fila por bot, estilo iMessage.
- **"The icon is who. The skill is the method. The routine is the clock."** — el avatar (forma geométrica + color) es IDENTIDAD; el estado es una capa SEPARADA y explícita.
- Todo lo que el bot hace (tools, archivos, preguntas, aprobaciones) aparece **INLINE en el hilo**, junto a los mensajes normales — no en paneles separados.

## Fases

<a id="v0"></a>
### V.0 — Chat-first AppShell: la app es mensajería (con [A·A.1])
- La sidebar izquierda es una lista de **desks** (una fila por bot/proyecto con su última actividad), no un dashboard: la conversación es la vista por defecto y todo empieza en el chat
- El chat es la superficie PRIMARIA ([A·A.4] conserva las 2 perillas y cards); los paneles Lovable y el canva son vistas de detalle que se abren DESDE el hilo y vuelven sin perder el contexto
- Burbujas de chat limpias y legibles (estilo mensajería), separación visual clara entre mensajes humanos y de agentes
- **Pruebas:** E2E HUMANA: un usuario nuevo entiende "esto es un chat con mi equipo" en <30s (primer clic = escribir); navega de la conversación a un panel y vuelve sin perder el hilo; mobile 375 sin roturas (RESPONSIVE TOTAL)

<a id="v1"></a>
### V.1 — Identidad por avatar geométrico + estados en 2 capas (con [F·F.0]/[G·G.7])
- **Avatar geométrico único por agente**: forma (triángulo/hexágono/círculo/rectángulo/nube/puntos) + color de identidad por defecto — el color NO es estado, es QUIÉN; los avatares IA generados de [G·G.7] conviven (el geométrico es el fallback determinista) — aplica también a los expertos del [Consejo](../SDD-005-plan-intermedio.md#vi5) (cada auditor se VE como especialista con su color de departamento)
- **Capa de estado separada y explícita**: puntos animados rebotando = trabajando · icono "needs attention" (pregunta/aprobación/handoff) · badge azul = no leído · marca en la fila = desk activo
- Edición de identidad desde el chat (header → agent settings): name, title, description, avatar, notifications — complementa [G·G.7] y [F·F.2] (nodos)
- **Pruebas:** E2E HUMANA: identificar de un vistazo cuál agente trabaja, cuál espera aprobación y cuál tiene no-leído (sin leer texto); editar el perfil desde el chat y ver el cambio reflejado en sidebar + canva + group chat; caída de IA → avatar geométrico determinista

<a id="v2"></a>
### V.2 — Actividad INLINE en el hilo (complementa [A·A.4]/[B·B.4])
- Tools ejecutadas, archivos creados, diffs y resultados aparecen **dentro del hilo** junto a los mensajes (no solo en paneles); el panel es el zoom, el hilo es el flujo
- **Aprobaciones como opciones numeradas inline**: "¿Dónde guardo el rate-limiter? ▸ 1. Redis · 2. En memoria · 3. Valkey" — un tap responde; complementa las cards de tool-call de [A·A.4] · **el mismo patrón lo usa el Consejo de Expertos** ([SDD-005 VI.6](../SDD-005-plan-intermedio.md#vi6): radio-cards de opciones con contexto citado) — UNA primitiva de opciones para aprobaciones Y auditorías
- Glifos de estado compactos en el hilo: `⋅` trabajando · `◇` idle · `◆` esperando aprobación
- **Pruebas:** E2E HUMANA: responder una aprobación de opciones numeradas con UN tap; el archivo creado por el bot se ve inline y se abre con un click ([B·B.4]); el hilo muestra el flujo completo sin depender de abrir paneles

<a id="v3"></a>
### V.3 — Group chat de bots visual (complementa [N·N.6])
- Nuevo chat → seleccionar 2–6 bots → grupo con nombre generado (editable)
- `@` menciona un bot · `@everyone` · si escribes normal, los bots deciden quién responde (identidad por mensaje: avatar geométrico + nombre)
- **Handoffs visibles en la conversación**: mensajes bot→grupo (text-only) pasan ownership; tú lees como espectador e intervienes solo en judgment calls
- Presencia y typing indicators por bot (🟢 trabaja · 💤 idle · "Dev-A está escribiendo…")
- **Pruebas:** E2E HUMANA: crear grupo de 3 agentes y verlos coordinar con handoffs en vivo e identidades claras; @mencionar a uno y que solo ese responda; observar como espectador sin intervenir y luego intervenir en un judgment call

<a id="v4"></a>
### V.4 — Rutinas visibles + notificaciones persistentes (complementa [G·G.6]/[K·K.3]/[U·U.5])
- **Follow-along con indicador visible**: al grabar una rutina ([G·G.6]) el bot muestra "te estoy siguiendo" (puntos + etiqueta); al terminar propone el skill editable y lo lista en el perfil del bot — "skill = cómo · routine = cuándo"
- **Notificaciones persistentes por bot**: badge de no-leído en sidebar Y dock que NO desaparece al enfocar la app (solo al leer); respeta la política de interrupción [K·K.3] y el digest silencioso [U·U.5]
- **Digests como mensajes del bot** en el hilo (scoreboard diario/semanal del PM), no como pantallas separadas
- **Pruebas:** E2E HUMANA: grabo "preparar release" viendo el indicador de seguimiento; el badge de no-leído persiste hasta que abro el hilo (aunque la app esté enfocada); el digest del lunes llega como mensaje del PM con su identidad

## 🚪 GATE V (transversal — se certifica con los gates F, N y U)

Demo: abro la app y SE VE mensajería (desks en la sidebar), creo un grupo de 3 bots que coordinan con handoffs visibles, respondo una aprobación de opciones numeradas con UN tap, grabo una rutina con indicador de seguimiento y el badge de no-leído persiste hasta leer. **Nada de lo anterior se perdió** (paneles, canva, diffs, motor de pruebas siguen accesibles desde el hilo). Suite humana ampliada verde.

---
[← Maestro](./README.md)
