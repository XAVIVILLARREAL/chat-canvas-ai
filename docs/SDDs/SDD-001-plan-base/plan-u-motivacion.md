# PLAN U — Sistema de Progreso Dopaminérgico (motivación por logros reales)

> [← Maestro](./README.md) · Transversal desde [F·F.0](./plan-f-canva-oficina.md#f0) · Filosofía: la dopamina la genera el PROGRESO VERIFICABLE (tests que pasan, criterios cumplidos, entregas reales) — nunca actividad vacía ni dark patterns.

## El principio neuro-psicológico

El cerebro libera dopamina en la **anticipación y el logro de metas visibles**, no en la recompensa aleatoria. Nuestra interfaz convierte cada proceso de desarrollo en una **escalera de micro-victorias visibles**:

```
token fluye → test pasa (tick+sonido) → criterio ✓ (pop) → tarjeta vuela a DONE
→ GATE cerrado (confetti) → nivel de agente sube → recap semanal épico
```

Cada evento ES real y verificable (viene del EventBus/Ledger) — la interfaz solo lo celebra.

## Configuración de intensidad (respeta al usuario)

`Apagado / Sutil / Normal / Festivo` — global o por proyecto ([A·A.6](./plan-a-chat-codex.md#a6)). Todo respeta `prefers-reduced-motion` y modo silencio ([K·K.3](./plan-k-voz.md#k3)).

| Fase | Contenido | Pruebas |
|---|---|---|
| **U.1 Primitivas dopaminérgicas** en [F·F.0](./plan-f-canva-oficina.md#f0): componente `ProgressRing`, `MilestonePop` (criterio ✓ con pop+tick sonoro), `CelebrationOverlay` escalable (3 tamaños: pulse/burst/festivo), `StreakFlame`, `LevelBadge`, sound-pack (tick/chime/fanfarria) con volúmenes separados | Unit componentes + settings intensidad. Snapshot visual de los 3 tamaños |
| **U.2 Micro-feedback en ejecución**: test pasa → tick verde animado en la card ([KR·KR.2](./plan-kr-kanban-resultados.md#kr2)); criterio de aceptación cumplido → MilestonePop; tool-call exitoso → pulso sutil en el nodo-agente del canva ([F·F.2](./plan-f-canva-oficina.md#f2)); streaming activo → barra de "energía" del agente | Integration: eventos reales del EventBus disparan la animación correcta. E2E: mock runner 10 tests → 10 ticks ordenados |
| **U.3 Celebraciones de hito**: tarea DONE → tarjeta vuela a columna con trail; **GATE cerrado → burst festivo** con resumen ("3 planes, 47 tests ✓, $0.31"); **empresa entrega proyecto → overlay festivo completo** con stats de la carrera | E2E humano: completar tarea/gate/proyecto dispara el tamaño correcto de celebración; intensidad Apagada = cero animaciones |
| **U.4 Progresión y niveles**: XP por resultados verificados (tarea aprobada, test nuevo, PR mergeado) → **proyecto sube de nivel** (desbloquea nada funcional — solo identidad visual) · **agentes suben de nivel** (badge+evolución sutil del avatar) · **racha de construcción** (días con entregas) · **Recap semanal estilo Wrapped**: "construiste X, Y tests pasaron, ahorraste ~Z horas" compartible | Unit XP rules (solo resultados verificados dan XP — actividad vacía NO). E2E: racha se rompe honestamente sin entrega; recap generado del Ledger |
| **U.5 Tuning responsable**: A/B interno de intensidades sobre retención propia (telemetría opt-in [T·T.BIZ](./plan-t-excelencia.md#tbiz)); **anti-patrones PROHIBIDOS**: notificaciones falsas de logro, rachas que culpan, timers de urgencia artificiales, comparación pública entre usuarios sin consentimiento | Revisión documentada contra checklist de dark-patterns; métrica norte = "sesiones que terminan en entrega", no "tiempo en app" |

## 🚪 GATE U (demo verificable)

Demo emocional: sesión de trabajo de 20 minutos donde SE VEA la escalera completa — tokens fluyendo, ticks de tests, pops de criterios, tarjetas volando, gate con confeti, agente subiendo de nivel — y el recap semanal final generándose del Ledger real. Con intensidad Apagada, la MISMA sesión es sobria y profesional. Video comparativo + suites verdes.

---
[← Maestro](./README.md)
