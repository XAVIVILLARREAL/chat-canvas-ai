# ACEPTACIÓN FINAL — Protocolo humano completo antes de v1.0

> **Producto:** Canvas AI · **Estado:** v1.0 · 2026-08-25
> Se ejecuta **completo** antes de cada tag (O.3 / [LAUNCH-CHECKLIST](./LAUNCH-CHECKLIST.md) §1). Es la [COVERAGE-GUI](./COVERAGE-GUI.md) al 100% + un walkthrough continuo operado como persona, grabado en video.
> Herramienta: Playwright CLI modo humano (`pnpm test:e2e:human`) — clicks con intención, tecleo carácter a carácter, pausas de pensamiento, scroll de rueda, teclado real ([SDD-002](./SDDs/SDD-002-testing-spec-driven.md)).

## 0 · Condiciones previas (DoR de la aceptación)

- [ ] COVERAGE-GUI: **todas las filas ✅** (0 ⬜/🟡)
- [ ] `node scripts/check-coverage.mjs` OK · `pnpm check:all` + `pnpm test` + `cargo test` verdes
- [ ] Builds desktop (3 SO) + Android + server Linux desplegado (staging)
- [ ] Datos reales de prueba cargados (proyecto demo + skills + historial importado)
- [ ] **Provider LLM real a $0**: OpenRouter `:free` (ox-alpha free) configurado — los recorridos con LLM corren REALES sin costo ([DEV-ENVIRONMENT](./DEV-ENVIRONMENT.md))

## 1 · Walkthrough continuo (una sola sesión humana, en este orden)

| # | Recorrido | Qué se demuestra (resultado funcional) |
|---|---|---|
| 1 | **Primer arranque** | Onboarding <5 min → primer agente trabajando ante mis ojos (sin docs) |
| 2 | **BYOK** | Pego key → validada → mensaje real con streaming → forecast ≈$ antes de enviar coincide |
| 3 | **Chat** | Sesión nueva → prompt → streaming → slash commands → medidor → costo por mensaje → rama ‹/› → /compact |
| 4 | **Comparador A/B** | Mismo prompt 2 modelos → elijo ganadora → router aprende preferencia |
| 5 | **Tools web** | "Investiga X" → cita 2+ fuentes; dominio bloqueado → accionable |
| 6 | **Visión** | Screenshot con bug plantado → agente corrige en código |
| 7 | **Editor** | Archivo creado aparece en árbol → edito → preview vivo <2s → fast apply fluido → error de consola → corregido |
| 8 | **Memoria** | Sesión nueva: "¿cómo manejamos auth?" → decisión citada; Human-Tweak Lock respeta mi línea; scrubber rebobina |
| 9 | **Skills** | Creo skill solo con clicks → nace con avatar/emoji/bio → laboratorio → tool-gating bloquea QA → rutina grabada se re-ejecuta |
| 10 | **Perfiles BYOK** | Cambio trabajo↔personal → keys/providers conmutan por proyecto |
| 11 | **Pruebas+Kanban** | Doy criterios → agente implementa → sandbox corre tests → verde animado → apruebo → done con evidencia; autonomía "4h" con corte por presupuesto |
| 12 | **Automatización** | Armo flujo visual multi-runtime → compilo → ejecuto → output correcto |
| 13 | **Nube 24/7** | Cierro laptop → abro en otro dispositivo → agentes trabajaron; digest + evidencia nueva |
| 14 | **Sync** | Edito skill en desktop → aparece en móvil → conflicto resuelto eligiendo |
| 15 | **Supervisor por Telegram** | "¿en qué anda auth?" estado real · "pausa scraping" confirmación numerada · "crea sesión login fix" → visible en Control Room |
| 16 | **GitHub** | feature→commit→push→PR sin terminal, diff por hunks |
| 17 | **Marketplace+Share** | Export bundle firmado → importo en instalación limpia → 1-click; link público abre sin cuenta y revoca |
| 18 | **Papelera/Export/Backup** | Restauro desde papelera; export sesión PDF/MD; backup integral ida y vuelta |
| 19 | **Dashboard** | Costos por proyecto/día reales, top skills, entregas — todo del event_stream |
| 20 | **Offline+i18n+a11y** | Sin internet sigue operando (banner+outbox); cambio a alemán sin recargar; navegación 100% teclado |

## 2 · Reglas de ejecución

1. **Una sola toma continua** por recorrido (cortes permitidos entre bloques, no dentro).
2. Todo fallo → **debug en vivo** (consola/red/video), corrección, re-run del bloque completo.
3. Máx 5 iteraciones por bloque; si no cierra, NO se lanza (escalación).
4. Móvil 375 **y** desktop 1440: los recorridos 1-12 y 20 completos en ambos.
5. Video completo + screenshots por paso → `evidence/acceptance/<tag>/`.

## 3 · Criterio de aprobación

- [ ] 20/20 recorridos verdes en móvil y desktop
- [ ] 0 errores de consola sin explicar · 0 requests fallidos sin manejo
- [ ] North-star demostrada en video: una sesión termina en ENTREGA aceptada
- [ ] Firmas: implementador + revisor (segundo par de ojos opera el recorrido 15 y 20)
