# TARJETAS-ETAPA-0 — Fases de la Fundación en formato canónico

> **Producto:** Canvas AI · **Estado:** v1.0 · 2026-08-25 · Formato: [SDD-002 §Tarjeta de Fase](./SDDs/SDD-002-testing-spec-driven.md)
> Contrato técnico: [SCHEMA-MAESTRO](./SCHEMA-MAESTRO.md) · Ejecución: [ETAPA-0-IMPLEMENTACION](./ETAPA-0-IMPLEMENTACION.md) · Loop: [WORKFLOW-AGENTICO](./WORKFLOW-AGENTICO.md)

---

### Tarjeta 0.1 — Migraciones + repos SQLite
**Resultado esperado (observable):** reinicio el server y los datos SIGUEN ahí; CRUD de sesiones/mensajes funciona filtrado por proyecto.
**Pruebas:**
- [U] Unit: validadores de schema, tipos de dominio ↔ columnas
- [I] Integration: migración up/down/up idempotente en SQLite; repos CRUD por `project_id`; roundtrip mensaje completo
- [E] N/A (sin UI aún — razón: fase de infraestructura)
- [H] N/A (razón: ídem; el gate es cargo test + script de humo documentado)
**Gate:** `cargo test` verde + datos sobreviven reinicio del server + migraciones versionadas en repo.
**Riesgos:** acoplamiento de tipos specta↔SQL; drift SQLite/Postgres. · **Estimación:** 6-8 h
**Dependencias:** ninguna. · **DoD:** estándar.

---

### Tarjeta 0.2 — Postgres + RLS fail-closed
**Resultado esperado:** mismo código corre contra Postgres; un tenant jamás ve datos de otro incluso con SQL directo.
**Pruebas:**
- [U] Unit: builder de consultas con tenant obligatorio (rechaza query sin tenant)
- [I] Integration: 2 tenants → aislamiento verificado por SQL directo; RLS sin fallback abierto
- [E]/[H] N/A (infra)
**Gate:** Compose levanta Postgres → tests de aislamiento verdes → drill: borrar tenant deja 0 filas.
**Riesgos:** políticas RLS mal escritas (fail-open) → revisión cruzada + chaos. · **Estimación:** 6-8 h
**Dependencias:** 0.1. · **DoD:** estándar.

---

### Tarjeta 0.3 — event_stream inmutable + eventos de producto
**Resultado esperado:** toda acción relevante queda como rung append-only; intentar UPDATE/DELETE falla.
**Pruebas:**
- [U] Unit: taxonomía de rungs (tipos válidos), helper emitEvent
- [I] Integration: trigger rechaza UPDATE/DELETE; seed project→session→message→rung; eventos de producto emitidos al crear datos
- [E]/[H] N/A (infra)
**Gate:** ledger inmutable probado + consulta de rungs por sesión ordenada.
**Riesgos:** volumen de eventos → índices por sesión/fecha. · **Estimación:** 4-6 h
**Dependencias:** 0.1. · **DoD:** estándar.

---

### Tarjeta 0.4 — Secretos BYOK + vault
**Resultado esperado:** pego mi API key → queda cifrada; la app la usa para llamar al provider; jamás aparece en claro en disco ni logs.
**Pruebas:**
- [U] Unit: envelope AES-GCM cifra/descifra; key incorrecta falla
- [I] Integration: keyring del OS guarda/recupera; vault por tenant (nube); dump de SQLite sin claves en claro; scanner redacta keys pegadas en chat
- [E] E2E funcional: flujo "conectar provider" con mock
- [H] Humana: pegar key → "conectado ✅" → ningún momento donde la key sea visible
**Gate:** BYOK end-to-end local + threat-model checkboxes de secretos.
**Riesgos:** keychain no disponible en Linux headless → fallback documentado. · **Estimación:** 6-8 h
**Dependencias:** 0.1. · **DoD:** estándar.

---

### Tarjeta 0.5 — Frontera del sandbox Linux
**Resultado esperado:** código de agente corre en contenedor Ubuntu sin red, con límites fijos; se mata limpio por timeout.
**Pruebas:**
- [U] Unit: generador de config del contenedor (límites/red/mounts)
- [I] Integration: spawn/kill/timeout con fixture; red denegada verificada; chaos: kill -9 a mitad → recuperación con estado consistente
- [E]/[H] N/A (infra; demo grabada como evidencia)
**Gate:** sandbox provable: script que intenta salir a red desde el contenedor y FALLA + límites respetados.
**Riesgos:** Docker no disponible en algunas máquinas → fallback WASM documentado. · **Estimación:** 8-10 h
**Dependencias:** 0.1. · **DoD:** estándar.

---

### Tarjeta 0.6 — OpenAPI del gateway + tipos generados
**Resultado esperado:** `docs/openapi.yml` generado desde el dominio Rust; el frontend compila contra tipos generados (cero tipos manuales duplicados).
**Pruebas:**
- [U] Unit: exporta specta sin errores
- [I] Integration: openapi-typescript genera y `pnpm typecheck` pasa consumiendo esos tipos
- [E]/[H] N/A (artefacto)
**Gate:** OpenAPI en repo + frontend compilando con tipos generados.
**Riesgos:** drift specta↔axum → check en CI. · **Estimación:** 4-6 h
**Dependencias:** 0.1. · **DoD:** estándar.

---

### Tarjeta 0.7 — i18n infraestructura
**Resultado esperado:** la UI muestra textos del diccionario; cambio idioma sin recargar; clave faltante → fallback inglés sin romper.
**Pruebas:**
- [U] Unit: hook useI18n (t, fallback, pluralización ICU)
- [I] Integration: detección de locale + persistencia de preferencia
- [E] E2E: cambiar idioma en Config actualiza la UI
- [H] Humana: recorridos es/en/de sobre pantallas existentes
**Gate:** script CI i18n-check verde (0 claves faltantes) + recorrido dual idioma.
**Riesgos:** strings duras heredadas del scaffold → barrido + regla lint. · **Estimación:** 6-8 h
**Dependencias:** 0.1. · **DoD:** estándar + filas COVERAGE-GUI (i18n).

---

### Tarjeta 0.8 — Cierre M0 (Gate 0)
**Resultado esperado:** demo continua: server reinicia sin perder datos → ledger inmutable → key cifrada segura → sandbox provable → OpenAPI publicado → UI multilenguaje.
**Pruebas:**
- [I] Suite completa Etapa 0 re-corrida
- [H] Video del gate: operador ejecuta el guion completo (≤10 min) sin cortes
**Gate:** **Milestone M0** firmado — la base técnica es real.
**Estimación:** 2-3 h (guion + video).
**Dependencias:** 0.1–0.7. · **DoD:** estándar + evidencia en `evidence/m0/`.

---

**Total Etapa 0: ~42-56 h** (dentro de las 15-20 h estimadas solo si se paralelizan slices con sub-agentes; ajustar MVP-ROADMAP si excede).

> ⚠️ Nota de coherencia: la estimación original de Etapa 0 era 15-20 h; con el detalle por tarjeta el rango realista es **42-56 h secuenciales** o ~25-35 h paralelizando 0.2/0.4/0.5/0.6/0.7 tras 0.1+0.3. Actualizar [MVP-ROADMAP](./MVP-ROADMAP.md) si al cerrar 0.1 sigue desviado.
