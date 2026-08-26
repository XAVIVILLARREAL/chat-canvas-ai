# WORKFLOW-AGENTICO — Loop iterativo + sub-agentes en paralelo + debug en tiempo real

> **Producto:** Canvas AI · **Estado:** v1.0 · 2026-08-25 · **Regla** (AGENTS.md): cada fase corre este loop. Máx 5 ciclos antes de escalar.
> Objetivo: resultados funcionales, no "código que compila". Eficiencia = análisis en paralelo, no esperar a fallar.

## 1 · El loop por fase (obligatorio)

```
┌─ ANALYZE ─┐ 5 sub-agentes EN PARALELO (spec · tests · riesgo · seguridad · UX)
└────┬──────┘
     ▼
┌─ DECIDE ─┐ síntesis → slice (código + tests a crear) + criterios de aceptación
└────┬──────┘
     ▼
┌─ MODIFY ─┐ implementar TDD (test humano primero, luego código)
└────┬──────┘
     ▼
┌─ TEST ─┐ Playwright humano CLI (clicks+teclado) + captura consola/red/HTTP≥400
└────┬──────┘
     ▼
┌─ ITERATE ─┐ corregir con la evidencia en vivo · repetir TEST (máx 5 ciclos)
└────┬──────┘
     ▼
┌─ DECIDE ─┐ gate cerrado (video en evidence/) o escalar (dividir slice / pedir ayuda)
└──────────┘
```

## 2 · Los 5 sub-agentes de análisis (por fase y por cambio grande)

| Ángulo | Qué busca | Entregable |
|---|---|---|
| **Spec** | ¿El SDD/fase cumple el PRD? ¿contrato claro? | gaps del diseño |
| **Tests** | ¿Cada botón/función tiene su fila en COVERAGE-GUI? ¿el test humano es operable? | lista de tests a crear |
| **Riesgo** | ¿Se rompe algo ya verde? ¿acoplamientos? | blast-radius + mitigaciones |
| **Seguridad** | ¿BYOK/sandbox/i18n/RLS/secretos comprometidos? | checklist T.SEC sobre el cambio |
| **UX** | ¿flujo operado como persona? ¿estados vacío/error/offline? | gaps de UX-STANDARDS |

**Síntesis:** un agente coordinador fusiona los 5 en un plan del slice. Nada se implementa sin la síntesis.

## 3 · Debug en tiempo real (no "revisar después")

1. Correr la suite humana en vivo: `pnpm test:e2e:human` (o `--grep` la fase).
2. En el fallo, abrir el video/screenshot de `evidence/` + consola/red del test (`console.error`, `pageerror`, `requestfailed`, HTTP ≥ 400).
3. Corregir el código Y el test juntos; re-correr al instante.
4. Un fallo intermitente = cuarentena de flaky ([H·H.8](./SDDs/SDD-001-plan-base/plan-h-motor-pruebas.md)) — no "pasar por alto".
5. Móvil 375 y desktop 1440 SIEMPRE (la suite humana ya lo hace).

## 4 · Cuándo usar sub-agentes en paralelo (en TODO el plan)

- **Por fase** del [EJECUCION-ORDEN](./EJECUCION-ORDEN.md): antes de implementar cada slice.
- **Gates:** antes de cerrar un gate, los 5 ángulos auditan la evidencia.
- **Cambios grandes / refactors:** análisis de impacto antes de tocar.
- **Post-mortems:** 5 ángulos analizan el incidente en paralelo → síntesis de causa raíz.
- **Revisión de PRs:** cada PR pasa los 5 ángulos (no solo "compila").

## 5 · Definición de "done" (resultado funcional)

Una fase está **done** cuando, y solo cuando:
1. Suite humana Playwright **verde** (clicks+teclado, móvil+desktop) con **video** en `evidence/`.
2. El resultado funcional es visible: la feature **hace** lo que dice (no "está implementada").
3. Fila(s) de [COVERAGE-GUI](./COVERAGE-GUI.md) en `✅`.
4. `pnpm check:all` + `pnpm test` + `cargo test` verdes · sin deuda nueva (biome/0 TODOs).
5. CHANGELOG + ESTADO actualizados · commit semántico.

**Compilar NO es done. "El test pasa" sin operar la UI NO es done.**

## 6 · Métricas del loop

- Ciclos por fase (objetivo ≤ 2) · tiempo a primer gate · % de fases cerradas a la primera.
- Estas métricas van al [PRODUCT-METRICS](./PRODUCT-METRICS.md) (calidad de proceso).
