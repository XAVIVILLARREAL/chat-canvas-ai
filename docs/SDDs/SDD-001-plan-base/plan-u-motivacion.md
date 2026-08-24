# PLAN U v2 — Sistema Dopaminérgico Completo (motivación, juice y flow)

> [← Maestro](./README.md) · Transversal desde [F·F.0](./plan-f-canva-oficina.md#f0) · v2 tras investigación profunda: Duolingo/game-design/juice/flow (sub-agente 1) + gamificación devtools (sub-agente 2).
> **Filosofía intacta:** la dopamina la genera PROGRESO VERIFICABLE del Ledger — nunca actividad vacía ni dark patterns.

## Fundamento científico aplicado

- **Error de predicción de Schultz**: la dopamina dispara cuando el outcome SUPERA lo esperado → variar celebraciones, nunca repetir secuencia idéntica
- **Aversión a la pérdida calibrada** (Kahneman): funciona si es acotada a una sesión y perdonable — jamás acumulativa ni humillante
- **SDT (autonomía+competencia+relación)** presentes SIMULTÁNEAMENTE: recompensas mal diseñadas CORROEN motivación intrínseca (meta-análisis Deci, 128 estudios)
- **Flow de Csikszentmihalyi**: reto calibrado + metas claras + feedback inmediato; las interrupciones triviales son el anti-patrón #1
- **Test ético de incertidumbre**: "¿el usuario mantendría el mecanismo activo si entendiera exactamente cómo opera?" — drops cosméticos transparentes sí; loot-boxes ocultos jamás

## Configuración global: intensidad `Apagado / Sutil / Normal / Festivo` por scope ([A·A.6](./plan-a-chat-codex.md#a6)) · respeta `prefers-reduced-motion` y silencio ([K·K.3](./plan-k-voz.md#k3))

---

<a id="u1"></a>
### U.1 — Primitivas dopaminérgicas + JUICE calibrado (en [F·F.0](./plan-f-canva-oficina.md#f0))
- Componentes: `ProgressRing`, `MilestonePop`, `CelebrationOverlay` (pulse/burst/festivo), `StreakFlame`, `LevelBadge`, `HeatmapAnual`, sound-pack
- **JUICE checklist obligatorio por acción core** ("Juice it or lose it"): ¿micro-hit-stop 100ms? ¿squash&stretch de card? ¿partículas que COMUNICAN estado? ¿flash blanco breve? ¿sonido en capas? ¿screenshake sutil rojo solo en fallo?
- **Física ponderada estilo Linear**: cards de Kanban con masa/inercia al arrastrar, columnas que hacen sitio con springs, snap ease-out — medido: −28% fricción percibida (NASA-TLX)
- **Celebraciones de 1.2s con VARIANTES aleatorias**: nunca la misma secuencia dos veces seguidas (error de predicción = más dopamina)
- **Sonido con teoría musical** (patrón tuta): éxito = arpegio ascendente Do mayor (consonante, resolución); error = tritono descendente cuadrado; warning = segunda mayor · chime DISTINTO por tipo de evento (commit≠test≠deploy, patrón Claudio) · mute-cuando-la-app-tiene-foco + cooldown global anti-spam
- Colores semánticos estrictos SIEMPRE acompañados de glifo redundante (✔ ✖ ⚠) — accesibilidad integrada
- **Pruebas GUI:** snapshot visual por primitiva × 3 intensidades · E2E: misma acción dos veces seguidas → variantes distintas · audio spy verifica arpegio en éxito y tritono en fallo · toggle mute silencia todo sin romper flujo

<a id="u2"></a>
### U.2 — Micro-feedback en ejecución (cada segundo cuenta)
- Test pasa → tick verde animado en su bloque ([KR·KR.2](./plan-kr-kanban-resultados.md#kr2)); criterio cumplido → MilestonePop; tool-call exitoso → pulso sutil del nodo-agente
- **Worklog que colapsa al éxito** (patrón clack taskLog): durante ejecución muestra pasos verbosos; al terminar bien colapsa a "✔ 14 pasos completados"; expandible SOLO si falló o bajo demanda — el log sucio permanente mata la satisfacción
- **La barra AVANZA aunque la tarea falle** (Duolingo): progreso parcial real (pasos completados, tokens invertidos) nunca se estanca — el reintento se siente continuación, no reinicio
- **% de contexto/coste consumido visible junto a cada tarea** (Cursor): confianza en tiempo real
- **Pruebas GUI:** E2E: mock runner 10 tests → 10 ticks ordenados + worklog colapsa a una línea verde al éxito · tarea fallida a 70% conserva barra avanzada · contador $ visible subiendo durante stream

<a id="u3"></a>
### U.3 — Celebraciones escalonadas, gated y con cofres funcionales
- Escala Duolingo verificada: micro-logro = toast/toast-transform 300ms (**success-button: el check se dibuja solo dentro de la propia card + mini-confetti local**, jamás toast genérico) · milestone semanal = burst · hito mayor = overlay festivo completo
- **Milestones GATED a rareza real** (primer deploy, build #100, primer PR mergeado por un agente, venta #1) — el día común recibe solo tick-up; la RAREZA hace que la celebración registre como evento verdadero (+1.7% retención D7 medido en Duolingo al rediseñar UNA animación)
- **Cofre de milestone con recompensa FUNCIONAL**: créditos de tokens, plantilla premium, slot extra de agente — la recompensa invierte en hacer la siguiente acción mejor (core loop completo: acción→feedback→recompensa→expansión; sin inversión el loop se rompe)
- **Screenshot/demo adjunta por el agente** al terminar tarea: apruebas viendo el RESULTADO, no el diff crudo (Cursor 3) — conecta con [H](./plan-h-motor-pruebas.md#h3)
- **Easter egg raro y barato**: venta #1000 → confetti pixelado sobre la oficina (identidad, no infantil si es escaso)
- **Pruebas GUI:** E2E humano: hito menor NO dispara overlay; hito gated SÍ con cofre abrible cuyo contenido es funcional · screenshot adjunta visible en la evidencia de la card · dos hitos iguales seguidos → animaciones diferentes

<a id="u4"></a>
### U.4 — Progresión honesta: niveles, rachas-perdonables y heatmap
- XP SOLO por resultados verificados (tarea aprobada, test nuevo, PR mergeado, flaky eliminado, MTTR reducido — **premiar fiabilidad, jamás volumen fakeable**)
- **Agente que CRECE sin castigo** (patrón Finch): nivel/accesorios evolucionan por logros (gorra "ventas del mes"); si está inactivo solo DEJA de crecer, jamás se deteriora; **la mascota JAMÁS habla** (regla Octocat — sus reportes llegan por canales serios)
- **Racha de operación autónoma con ESCUDO-perdón**: días consecutivos operando; un "commit-shield" ganado por tareas completadas salva automáticamente un día perdido — elimina la ansiedad que mata el hábito manteniendo el motor
- **Heatmap anual estilo GitHub** (NO contador): perdona el reinicio visualmente, intensidad RELATIVA al máximo histórico propio (competencia contigo mismo, cero tóxica)
- **Ligas internas opcionales**: pools pequeños (~30) entre proyectos propios del tenant por entregas mergeadas; top gana créditos, bottom recibe nudge constructivo — nunca público, nunca humillación
- **Recap semanal estilo Wrapped** generado del Ledger: "construiste X, Y tests pasaron, ahorraste ~Z horas"
- **Pruebas GUI:** Unit XP/fiabilidad. E2E: escudo consume automáticamente el día hueco conservando racha · heatmap pinta relativo al propio máximo · recap generado íntegramente de rungs reales

<a id="u5"></a>
### U.5 — Flow-protection y anti-spinner (el hallazgo más importante)
- **El spinner mata retención a los ~12 segundos** y "esperando a que termine" es lenguaje de abandono → todo run largo vive en un **INBOX de resultados**: duradero (ID sobrevive sesiones), notificable (push al terminar, jamás polling), **result-over-progress** (la vista primaria lista OUTCOMES: "PR de auth refactor listo", no transcripts)
- **Estado SIEMPRE accionable** (Vercel popover): cada card en cualquier estado ofrece su acción posible (ver log / aprobar / inspeccionar diff) — jamás estado muerto
- **Notificación idle perfecta** (AgentsRoom): estructura fija [qué hizo] + [qué necesita de ti] + [botón respuesta rápida] — "respondiste tres notificaciones como tres mensajes y amanecieron dos features listas"
- **Modo FLOW-PROTECTION**: agrupa interrupciones triviales de los agentes y preséntalas en batch al cierre del bloque humano — jamás toast por paso trivial (anti-patrón #1 de flow)
- **Aprobaciones agrupadas en lote** (lección Copilot: 7 aprobaciones frustan; Cursor: 1) — interrupt() múltiple = UNA decisión
- Checkpoints NOMBRADOS y revertibles desde hover en la tarjeta (Windsurf)
- **Session Insights post-mortem** (Devin): timeline verde-roja (valor entregado vs obstáculos superados) + prompt mejorado sugerido — hace tangible el trabajo invisible y justifica su costo USD
- **Pruebas GUI:** E2E: run de 20 min → usuario cierra app → vuelve → inbox lista outcome + push recibido · 5 interrupciones triviales agrupadas en 1 batch al final del bloque · hover card muestra checkpoint reversible

<a id="u6"></a>
### U.6 — Glanceables fuera de la app (widget de 2 DATOS, patrón Duolingo)
- Widget de bandeja/desktop con EXACTAMENTE 2 datos: **"¿la empresa operó hoy sola?" (✓/pendiente) + racha de días de operación autónoma** — nada más; el gerente-IA se pone "ansioso" visual cerca del fin de jornada si hay tareas sin cerrar (urgencia progresiva honesta)
- Promocionar el widget justo DESPUÉS de una entrega (momento de máxima buena voluntad — táctica Duolingo medida)
- Badge embebible SVG del estado de la empresa (para compartir con clientes/inversores)
- **Pruebas GUI:** E2E desktop: widget refleja operación del día en vivo; expresión cambia según cercanía de cierre de jornada; badge SVG regenera con datos correctos

<a id="u7"></a>
### U.7 — Onboarding emocional: el unboxing (Arc/Raycast)
- Primer arranque <2 min con little-wins inmediatos: elegir color produce resultado visual instantáneo (Arc) · el onboarding CONFIGURA cosas reales (Raycast): meta diaria, conectar cerebro ([C·C.6/C.7](./plan-c-reasonix-deepseek.md#c6)), crear primer agente — sales con producto configurado a tu gusto
- **Demo de 90 segundos = PRODUCCIÓN real**: en el arranque inicial un agente completa una micro-tarea real ante tus ojos en la oficina (genera tu primer reporte) — lo que practicaste es uso real instantáneo
- Remate: **tarjeta de FUNDADOR** personalizada (nombre tenant + fecha + logo generado) — momento compartible
- Oficina vacía primera vez = **siluetas fantasma de los puestos** + CTA "Crea tu primer empleado IA" (empty-state motivador, no vacío triste)
- **Pruebas GUI:** E2E humano completo cronometrado: nuevo usuario → agente trabajando ante sus ojos ≤90s → tarjeta fundador emitida · cada paso deja valor persistente real

<a id="u8"></a>
### U.8 — Anti-dark-patterns (vigilado por [U.9])
- Drops variables: SOLO cosméticos, probabilidades PUBLICADAS, opt-out total, jamás atados a funcionalidad core ni dinero
- Nunca: logros falsos, culpa de rachas, timers de urgencia artificiales, comparación pública sin consentimiento, infinite-scroll compulsivo
- Regla oro SDT: toda mecánica debe alimentar autonomía+competencia+relación a la vez; si corroe alguna, se elimina
- Métrica norte: **sesiones que terminan en ENTREGA** (jamás "tiempo en app")

## 🚪 GATE U (demo verificable — se certifica en cada release con [PLAN T·T.QA](./plan-t-excelencia.md#tqa))

Demo emocional cronometrada: sesión donde SE VEA la escalera completa (tokens→ticks→pops→vuelos→confetti gated→cofre funcional→nivel de agente→heatmap creciendo) + demo del lado sobrio con intensidad Apagado + demo flow-protection agrupando 5 interrupciones + widget tray actualizándose + inbox de resultados con push. Video comparativo + suites humanas ampliadas verdes.

---
[← Maestro](./README.md)
