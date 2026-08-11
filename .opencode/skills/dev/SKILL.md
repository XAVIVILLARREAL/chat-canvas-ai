---
name: dev
description: Guía de desarrollo por fases del proyecto Empresa Dev. Usa cuando haya que implementar o continuar features, saber qué fase sigue, buscar el plan o sus pruebas de comprobación (gates), o iniciar una sesión de trabajo. Trigger: "dev", "super plan", "plan", "siguiente fase", "implementar", "gate", "probar", "progreso".
---

# Skill dev — Desarrollo por fases con pruebas de comprobación

Este proyecto se trabaja **por fases**, nunca a saltos. Cada fase del `docs/SUPER_PLAN.md` tiene su **gate** (pruebas de comprobación). Cero código sin seguir esta rutina.

## 1. Saber dónde estamos

1. Leer `docs/SUPER_PLAN.md` (fuente de verdad del plan, fases y gates).
2. Leer `AGENTS.md` (reglas obligatorias de trabajo).
3. Determinar la fase/gate pendiente. Si el usuario pide algo que no es la fase actual, señalar el desvío antes de codificar.
4. Marcar el avance en las checklists del plan (`- [ ]` → `- [x]`) conforme se cumpla.

## 2. Rutina obligatoria por feature

1. **SDD primero:** escribir el diseño en `docs/SDDs/SDD-<next>-<nombre>.md` (objetivo, flujo, contratos, tests) antes de tocar código.
2. **TDD:** escribir primero el test que falla (`test/<feature>_test.dart`), después el código que lo pasa.
3. **CI local al cerrar la feature:**
   ```powershell
   flutter analyze
   flutter test --exclude-tags integration
   ```
4. **Comandos maestros** solo si la fase lo pide: `dart run tool/hub_smoke.dart` y builds (ver AGENTS.md → Build Commands).
5. Los tests que requieren red/llave van con `@Tags(['integration'])` (fixture `test/fixtures/app_test_key`) y **no** corren en CI.

## 3. Cerrar una fase (gate)

- [ ] Todos los checkboxes de la fase en `SUPER_PLAN.md` cumplidos.
- [ ] Suite completa verde (analyze + unit/widget).
- [ ] Pruebas de comprobación de la fase ejecutadas y evidenciadas (captura/log).
- [ ] Probado en ≥ 2 plataformas (Android + desktop) — Definition of Done.
- [ ] Commit de cierre de fase con la evidencia adjunta.

La fase **no se cierra sin su gate**. Si un gate depende de algo externo (dispositivos, red, publicación), dejar la fase en `❌ pendiente` en SUPER_PLAN y continuar con lo que no bloquee.

## 4. Dogfood

Varias fases exigen **dogfood**: este mismo proyecto usado desde la app (editar el repo, definir skills, implementar features vía vibecoding). Cuando aplique, registrarlo explícitamente como evidencia del gate en el commit.

## 5. Fases en una línea

| Fase | Qué es | Gate clave |
|---|---|---|
| Etapa 1 | Cierre + publicación del terminal | E2E 2 plataformas + batería + publicado |
| Etapa 2 | Agentes IA en el canva (legacy) | Nodo agente + voz + evidencia `.md` |
| Etapa 3 | File tree + editor | Editar este repo desde la app |
| Etapa 4 | Canva de ideas + `.md` | Mapa de `docs/` navegable |
| Etapa 4b | Gestor visual de skills + laboratorio | 3 skills del repo creadas y aprobadas en el laboratorio |
| Etapa 5 | Grafo 2D → 3D | 5.000 nodos a 30fps |
| Etapa 6 | Vibecoding | Una feature real hecha 100% vía agente |
| Etapa 7 | SDD++ + Playwright E2E | E2E web automático por PR |