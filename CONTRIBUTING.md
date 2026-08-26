# Contributing — Canvas AI

Gracias por querer aportar. Este repo usa un flujo **spec-driven** estricto: cada feature nace de un SDD, se implementa con TDD y se cierra con su gate humano de Playwright.

## Cómo contribuir

1. **Lee antes de tocar:** [`AGENTS.md`](./AGENTS.md) · [`docs/INDEX.md`](./docs/INDEX.md) · [`docs/SDDs/SDD-001-plan-base/README.md`](./docs/SDDs/SDD-001-plan-base/README.md).
2. **Abre un issue** (usa las plantillas) o toma uno existente.
3. **Feature nueva ⇒ mini-SDD:** antes de código, un doc corto (qué/pró por qué/contrato/pruebas) en `docs/SDDs/`. No se acepta código sin SDD para features.
4. **TDD:** primero el test que falla, después el código que lo pasa. Toda UI se prueba como humano (clicks+teclado, móvil 375 + desktop 1440).
5. **PR:** descríbelo con la plantilla; pasa `pnpm check:all` + `pnpm test` + `cargo test`; adjunta el gate humano si toca UI.

## Reglas duras

- **No rompas gates:** si tu cambio toca UI, la suite humana de esa zona debe quedar verde.
- **i18n:** nunca strings hardcodeadas; usa el diccionario ([plan-i18n](./docs/SDDs/SDD-001-plan-base/plan-i18n.md)).
- **Sin deuda nueva:** 0 TODOs; biome limpio en tus archivos (la deuda preexistente no es excusa para añadir más).
- **Sin "empresa autónoma":** ese concepto fue eliminado (ADR-006) — no lo reintroduzcas.
- **Secretos:** jamás commits de keys; BYOK siempre por keychain/vault.

## Flujo de una feature (checklist)

- [ ] mini-SDD en `docs/SDDs/`
- [ ] fase(s) en la `MATRIZ` (fase sin fila NO se construye)
- [ ] tests unit/integration en cargo/vitest
- [ ] E2E humano Playwright (móvil+desktop) + video en `evidence/`
- [ ] `pnpm check:all` + `pnpm test` + `cargo test` verdes
- [ ] CHANGELOG + ESTADO actualizados
- [ ] commit semántico + push

## Entorno

Ver [`docs/DEV-ENVIRONMENT.md`](./docs/DEV-ENVIRONMENT.md) (3 comandos y estás corriendo).
