# PLAN T — Excelencia transversal: Seguridad profesional, A11Y/i18n, Onboarding, Calidad continua y Comercial

> [← Maestro](./README.md) · Transversal: T.SEC/T.QA corren desde Etapa 1 en paralelo; T.ONB/T.A11Y crecen con cada ventana; T.BIZ cierra antes de v1.0.
> Promueve a fases activas los ítems de seguridad (C21), accesibilidad (C22), onboarding/docs (C23) y negocio (461+) del [torneo SDD-003](../SDD-003-torneo-500-ideas.md) que la auditoría final detectó como huecos.

**Entregable:** el producto no solo funciona — es SEGURO por diseño, USABLE por cualquier persona e idioma, MEDIBLE en calidad continua, y LEGALMENTE comercializable.

<a id="tsec"></a>
### T.SEC — Seguridad profesional (desde Etapa 1)
- Tokens/API keys en **keyring del OS** (`keyring` crate) con fallback a SQLite cifrado AES-GCM; jamás plano
- **CSP estricta** del webview + sanitización de Markdown renderizado + links externos con noopener+confirmación
- Rate-limit local de acciones del agente; scanner de secretos ANTES de enviar contexto a proveedores ([C·C.7](./plan-c-reasonix-deepseek.md#c7))
- Supply-chain: dependencias pineadas con checksums · `cargo-audit` + `cargo-deny` + SBOM (cyclonedx) en CI · test suite anti path-traversal ya exigida en B/H
- Modelo de amenazas documentado por capa (gateway/sandbox/cliente) + `security.txt`
- **Pruebas:** CI falla si cargo-audit encuentra CVE crítico. Integration: intento de XSS vía respuesta del agente → neutralizado. Suite path-traversal completa verde

<a id="ta11y"></a>
### T.A11Y + i18n — usable por cualquiera, en su idioma
- **i18n central es/en** desde el primer componente (strings NUNCA hardcodeadas); español default
- Contraste AA verificado automatizado + foco visible siempre + targets ≥44px móvil + `prefers-reduced-motion` global + aria-live polite en streaming del chat
- axe-core en los E2E funcionales (falla CI si hay violación seria) · navegación 100% teclado ya exigida por suite humana
- **Pruebas:** axe-core gate en CI. E2E humano dual idioma. Auditoría contraste en cada tema ([F·F.0](./plan-f-canva-oficina.md#f0))

<a id="tonb"></a>
### T.ONB — Onboarding que convierte
- **Primera corrida guiada** (3 pasos, skipeable): crear proyecto → conectar cerebro (Ollama/key) → primer encargo
- **Proyecto ejemplo incluido y funcional** para probar todo sin miedo
- Empty-states educativos en cada ventana (las 4 ventanas enseñan qué harán); tooltips progresivos según uso; cheatsheet ⌘K/
- Diagnóstico exportable para soporte (sin datos sensibles)
- **Pruebas:** E2E humano: usuario nuevo → primer agente trabajando <5 min sin documentación externa

<a id="tqa"></a>
### T.QA — Calidad continua (anti-deuda-técnica activa)
- **Budgets de rendimiento en CI**: tamaño de bundles, tiempo de arranque medido, canva 60fps check — regresión = build rojo
- Cobertura mínima por crate/módulo como gate configurable
- Flaky-quarantine automática ([H·H.8](./plan-h-motor-pruebas.md#h8)) aplicada también a suites humanas
- Revisión trimestral de deuda: knip + clippy pedantic + auditoría de TODOs (deben ser cero o documentados)
- **Pruebas:** pipelines con gates activos; dashboard de tendencia (no instantánea)

<a id="tbiz"></a>
### T.BIZ — Comercial y legal (antes de v1.0)
- **Licencia elegida y documentada** (recomendación: core MIT/Apache-2.0 + features Pro bajo licencia comercial — open-core) con matriz qué-es-gratis
- **ToS + Privacy Policy** generados y versionados (local-first ayuda: "tus datos nunca salen" es el pitch)
- Pricing tiers flaggeados en código desde v1 (Free / Pro / Teams) aunque el pago llegue después
- Telemetría OPT-IN anónima (nunca contenido) para decisiones de producto
- Página Acerca-de con licenses/atribuciones completas
- **Pruebas:** flags verificados; bundle Free no incluye código Pro compilado; docs legales revisadas

## 🚪 GATE T (transversal, se re-certifica en cada release)

Checklist vivo: cargo-audit/deny limpios · axe-core verde · i18n sin strings duras (script lo verifica) · onboarding <5min medido · budgets de perf respetados · licencia+legal publicados. Se ejecuta completo antes de cada tag.

---
[← Maestro](./README.md)
