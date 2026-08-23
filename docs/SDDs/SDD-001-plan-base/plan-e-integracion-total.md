# PLAN E — Integración total, robustez y cierre

> [← Maestro](./README.md) · [← PLAN D](./plan-d-memoria-v3code.md)
> Depende de: A+B+C+D completos con sus gates.

**Entregable:** la base completa demostrada como humano, a prueba de fallos, responsiva, cerrada con tag.

## Fases

### E.1 — E2E punta a punta REAL (key DeepSeek de prueba)
Flujo completo como humano, un solo test largo:
crear proyecto → pedir feature → ver streaming + archivos aparecer + preview vivo → dar feedback en diff → agente corrige → aprobar → **reiniciar app** → verificar memoria (Ledger + cita de decisión) → costo final visible

- **Pruebas:** Playwright browser-mode completo + video evidencia en `evidence/`

### E.2 — Chaos / robustez transversal
| Escenario | Recuperación esperada |
|---|---|
| Red caída (mock 500/timeout) | Error claro + retry manual; sin freeze |
| Key inválida | Mensaje accionable; sesión no se pierde |
| `kill -9` al proceso reasonix serve | Auto-restart del provider ([C·C.3](./plan-c-reasonix-deepseek.md#c3)) |
| Cancelar tarea en cada fase | Estado consistente, rung parcial en Ledger |
| Doble instancia de la app | single-instance plugin enfoca la existente |
| Prompt gigante (>contexto) | `/compact` o aviso; nunca crash |

- **Pruebas:** suite chaos automatizada, todos con recuperación verificada

### E.3 — Pulido responsive + performance + cierre
- Responsive final: 375 / 768 / 1440 (checklist RESPONSIVE.md del repo)
- Performance: React Compiler activo auditado, virtualización en listas >50 items, sin layout thrash en streaming
- Calidad: knip limpio, contraste AA, foco visible, prefers-reduced-motion respetado
- Docs finales: ESTADO/CHANGELOG/INDEX actualizados, screenshots actualizados

## 🚪 GATE E = Definition of Done del Plan Base

```bash
pnpm check:all && pnpm test && cargo test --manifest-path src-tauri/Cargo.toml && pnpm test:e2e:chromium
```

- [ ] Todas las suites verdes
- [ ] Video demo E.1 completo en `evidence/`
- [ ] Chaos E.2 con 6/6 recuperaciones verificadas
- [ ] Responsive verificado en las 3 vistas
- [ ] Docs auto-gestión al día
- [ ] Tag git: `plan-base-v0.1`

---
[← Maestro](./README.md) · [← PLAN D](./plan-d-memoria-v3code.md)
