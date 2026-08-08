# PIPELINE — Flujo para desarrollar proyectos completos

Cómo se lleva un proyecto de **idea → producción** dentro de la app, con SDD, TDD y verificación de UI en navegador real.

## Fases

```
FASE 0       FASE 1          FASE 2         FASE 3             FASE 4
Idea ──►   Spec/Arquitectura ──► Fundación ──► Features ──►    Producción
prompt      SDD + ADRs +      scaffold +    ticket a ticket   merge + deploy
(voz/texto) plan de tickets   CI + setup    (con UI Test      + verificación
            (aprueba humano)  del browser   en navegador)     en vivo
```

## Fase 0 — Captura de la idea

- Entrada: texto o voz en la app.
- El **Project Lead** reformula con preguntas claras antes de planear.
- Salida: `SPEC.md` (qué, para quién, qué NO hace).

## Fase 1 — Spec + Arquitectura (hito humano)

- **Arquitecto**: stack, estructura, DB, APIs, ADRs.
- **Project Lead**: descompone en tickets con dependencias y prioridades.
- **QA**: estrategia de tests + qué flujos verificará el UI Tester.
- ⚠️ **Aprobación humana aquí.** La decisión más cara de revertir.

## Fase 2 — Fundación

- Scaffold inicial (sin features).
- **CI desde el día 1**: typecheck → lint → tests → build.
- **Setup del navegador de pruebas**: Chrome + Chrome DevTools MCP conectado al dev server (que el UI Tester ya pueda abrir la app y tomar capturas).
- Primer PR: "CI + navegador conectado + un test trivial verde".

> 💡 **Regla:** el CI y el navegador de pruebas se configuran **antes** de las features. Si la verificación no existía cuando se escribió el código, ese código ya es sospechoso.

## Fase 3 — Features (el bucle principal)

Cada feature sigue el flujo del tablero:

1. Project Lead crea ticket + **SDD** (con casos y flujos a verificar).
2. QA define los tests (TDD: primero el test, después el código).
3. Implementador desarrolla en su rama.
4. CI corre las puertas → error real devuelto al agente (máx 3 intentos → escala).
5. **UI Tester abre Chrome real y prueba la feature como humano** → capturas + veredicto.
6. Reviewer aprueba (diff + capturas) o pide cambios.
7. Merge con CI verde + "UI verificado".

**Orden de los tickets:** por dependencias y valor. Los tickets "spike" (investigar algo arriesgado) preceden a las features que dependen de eso.

## Fase 4 — Producción

- Merge final + tag/release.
- Deploy a **staging automático**; producción solo con aprobación humana.
- **Post-deploy: verificación en vivo** — el UI Tester navega el sitio desplegado (healthcheck + flujos principales + consola) y reporta con capturas.
- Cada bug → ticket de Bug Hunter con test de regresión + caso de UI.

## Artefactos del pipeline (auditables)

| Artefacto | Contenido | Para quién |
|---|---|---|
| `SPEC.md` | Qué se construye | Humano / cliente |
| `SDD.md` | Cómo funciona cada feature (diseño detallado) | Implementador + QA + UI Tester |
| `ADRs/` | Decisiones de arquitectura y por qué | Arquitecto + agentes futuros |
| Tickets | Tareas con DoD | Kanban |
| PRs | Cambios + tests + revisión | CI + Reviewer |
| **Capturas de UI** | Evidencia visual de cada feature verificada | Reviewer + humano |
| `CHANGELOG.md` | Qué cambió entre versiones | Cliente |
| Reporte de hitos | Entregado + pendiente | Humano |

## SDD — Software Design Document (diseño por feature)

El puente entre la spec ("qué") y el código ("cómo"). **Sin él, el implementador y el UI Tester adivinan.**

### Jerarquía

```
SPEC.md       →  ¿Qué construimos?      (alto nivel)
ADRs/         →  ¿Por qué decidimos así? (arquitectura)
SDD.md        →  ¿Cómo funciona cada feature?  (diseño detallado)
Tickets       →  ¿Qué tarea hago ahora?  (una pieza del SDD)
Código + tests →  La implementación del SDD
```

### Qué contiene un SDD (1–2 páginas por feature)

- **Objetivo**: qué problema resuelve (en una frase).
- **Flujo**: pasos del caso feliz + casos límite (loading, error, vacío, responsive).
- **Contratos**: entradas/salidas de funciones o endpoints.
- **Datos**: esquema o campos que se crean/cambian.
- **Errores**: qué puede fallar y cómo se maneja.
- **Tests**: casos que cubre el QA (semilla del TDD).
- **Verificación de UI**: los flujos concretos que el UI Tester probará en el navegador.

### Reglas

- Se escribe **antes** de implementar; se actualiza en el mismo PR que cambia el comportamiento.
- Si el SDD crece >2 páginas → dividir la feature.
- Los agentes consultan `SPEC + ADRs + SDD` antes de tocar código; si no existe, lo piden/crean.
- El SDD es el **contrato del UI Tester**: lo que no esté en el SDD no se verifica automáticamente.

### TDD como complemento

El SDD define *qué* testear; el **TDD** define el orden: **primero el test que falla → después el código que lo pasa**. Convierte la especificación en verificación automática.

## Cuándo se considera "terminado" un proyecto

- [ ] Todos los tickets cerrados con CI verde.
- [ ] **Todas las features verificadas en navegador real** con capturas.
- [ ] E2E del flujo principal verificado de punta a punta (como humano).
- [ ] Reviewer aprobó todo el diff acumulado.
- [ ] Deploy en staging verificado (UI post-deploy); producción aprobado por humano.
- [ ] Docs, SDDs y ADRs actualizados.

## Escalamiento

Cada **proyecto** es una instancia del pipeline: un kanban propio, el mismo equipo de agentes, y la misma verificación. La app web los administra a todos — primero para ti, después como producto para otros.
