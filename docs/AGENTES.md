# AGENTES — Roles del sistema (nodos LangGraph)

Cada rol es un **nodo del grafo LangGraph** (un perfil con prompt, herramientas y reglas). Todos giran alrededor de una regla común: **nada se cierra sin verificación en un navegador real**.

## Roles centrales

| Rol | Responsabilidad | Herramientas clave | Regla de oro |
|---|---|---|---|
| **Project Lead** | Descompone la idea en tickets + SDDs, ordena dependencias, gestiona bloqueos | lectura, plan, tablero | No escribe código de features; coordina |
| **Arquitecto** | Define stack, estructura, ADRs, contratos | lectura, docs | Toda decisión estructural se registra en un ADR |
| **Implementador Full-Stack** | Ejecuta tickets de código | fs, shell, node, git | Un ticket terminado = CI verde + UI verificado |
| **QA / Test Engineer** | Escribe tests (TDD), casos límite, semilla del SDD | fs, shell (test runner) | El código sin test de su feature NO se mergea |
| **UI Tester** ⭐ | **Prueba la interfaz en Chrome real como un humano** | **Chrome DevTools MCP** (navegar, clic, escribir, eval, console, screenshots) | Ninguna feature de UI se cierra sin capturas de evidencia |
| **Revisor (Reviewer)** | Revisa diffs + capturas: calidad, regresiones, deuda | lectura, git diff, capturas | Aprueba solo si es correcto, no por presión |
| **Bug Hunter** | Reproduce bugs en el navegador, corrige, test de regresión | fs, shell, Chrome DevTools MCP | Todo bug arreglado lleva test de regresión + verificación en UI |
| **Refactor** | Mejora código sin cambiar comportamiento | fs, shell (tests) | Se valida con tests existentes + UI check |
| **DB Wizard** | Migraciones, índices, queries | shell (psql/sqlite), fs | Toda migración es reversible y versionada |
| **UI Designer** | Implementa interfaces y UX | fs, build, Chrome DevTools MCP | Respeta el design system; se valida en pantalla real |

## El UI Tester en detalle (el rol que define el producto)

Es el agente que hace lo que un humano haría para "probar la app", usando **Chrome DevTools MCP**:

```
1. Lanza la app en desarrollo (dev server).
2. Navega a la feature a verificar (según el SDD).
3. Ejecuta el flujo esperado como humano: clic, escribir, scroll, esperar.
4. En cada paso: verifica estado, lee consola (errores JS/warnings),
   revisa red (requests fallidas), inspecciona el DOM.
5. Toma capturas de pantalla de cada paso → evidencia.
6. Compara el resultado con lo que dice el SDD.
   ✓ todo bien → adjunta capturas al PR y lo marca "UI verificado"
   ✗ algo mal → devuelve al implementador: paso, error de consola, captura
```

**Siempre con ojos de humano:** si el flujo no tiene clic claro, si hay un botón roto, si la consola grita errores, o si la captura "se ve mal" → eso es un bug para el implementador, no un "aproximadamente ok".

## Jerarquía y comunicación

```
        Project Lead (coordina, no dicta código)
        /    |        \
   Arquitecto   QA/Test   Reviewer
        \      |        /        ← se comunican vía: ticket + SDD + PR + capturas
         Implementadores (Full-Stack, Bug Hunter, Refactor, DB, UI)
                │
                ▼
          UI Tester (Chrome DevTools MCP)  ← verifica el resultado de TODOS
```

**Regla de comunicación:** los agentes **no se hablan en vivo**. Se comunican por artefactos: el ticket + SDD describen qué hacer, el PR muestra qué se hizo, el CI y las **capturas del UI Tester** prueban que funciona, el Reviewer dictamina. Auditable y sin caos.

## Handoffs

1. **Project Lead → Implementador**: ticket con SDD y DoD.
2. **Implementador → CI**: rama + PR.
3. **CI → Implementador**: pasa o devuelve el error exacto (typecheck/lint/tests).
4. **Implementador → UI Tester**: "listo, verifica la UI".
5. **UI Tester → PR**: capturas + veredicto "UI verificado" o bug con evidencia.
6. **Reviewer → Merge/Implementador**: aprueba (con capturas) o pide cambios.

## Perfiles extra (fase 2, ver ROADMAP)

- **Agente de Investigación**: resuelve dudas de API/stack consultando docs/web antes de implementar.
- **Agente DevOps**: gestiona CI/CD, deploys, infraestructura.
- **Agente de Producto**: traduce requisitos del cliente a SPEC + aceptación.

## Definition of Done (DoD) — un ticket se cierra solo si:

- [ ] Código implementado en rama propia.
- [ ] Typecheck pasa.
- [ ] Lint pasa.
- [ ] Tests pasan (incluye tests nuevos; TDD si cambió comportamiento).
- [ ] **UI verificado en navegador real** (Chrome DevTools MCP) con **capturas de evidencia** adjuntas.
- [ ] Consola sin errores JS y red sin requests fallidas en los flujos probados.
- [ ] Reviewer aprobó el diff + las capturas.
- [ ] (Si aplica) ADR, SDD o documentación actualizada.
- [ ] (Si es hito) aprobación humana.
