# SDD-010 — Modelo de Negocio: Local-first gratis + Nube SaaS de pago, Monetización y Growth

> Fecha: 2026-08-24 · Actualizado: 2026-08-25 (ratificado por [ADR-006](./ADRs/ADR-006-vision-hibrida-local-nube.md)) · Estado: **Aprobado (dirección)** · Método: 3 investigaciones paralelas (outcome-pricing · growth devtools · datos previos de hosting/costos SDD-008)
> Complementa [PLAN T·T.BIZ](./plan-t-excelencia.md#tbiz).

## 1 · MODELO HÍBRIDO (ADR-006) — local-first gratis + nube de pago

| Escenario | Qué corre dónde | Costo | Por qué existe |
|---|---|---|---|
| **A · Local-first (PRODUCTO BASE)** | App Tauri + agentes + Ollama en TU máquina; BYOK (tu API key en el keychain del OS) | **Gratis** | Privacidad, offline, dueño de tus datos — el producto principal |
| **B · Nube 24/7 (SaaS multi-tenant, DE PAGO)** | Agentes corriendo en NUESTROS workers Linux 24/7; Postgres+RLS por tenant; BYOK cifrada por tenant | **Suscripción** ($29-149/mes) | "Mis agentes trabajan aunque cierre la app" + sync multi-dispositivo |
| **C · Servidor propio (power-user)** | Backend en TU Linux/docker | Gratis (self-host) | Control total para quien lo quiera operar |

**El mismo codebase sirve los 3** (crates `core`+`server`+shell): lo único que cambia es dónde apunta el cliente y si se cobra. **Regla de negocio: la nube solo la paga quien la usa.**

## 2 · TAURI vs WEB — resuelto por ADR-006

| | Escenario A (local-first) | Escenario B (nube de pago) | Escenario C (self-host) |
|---|---|---|---|
| **Tauri desktop** | ✅✅ PRODUCTO PRINCIPAL (local-first, gratis, BYOK) | 🟡 Cliente ligero opcional | — |
| **Web-first** | 🟡 SPA servida por gateway en modo lectura/ligero | ✅✅ ÓPTIMO — conversión máxima, cero fricción | ✅ Ideal — navegador apunta a tu servidor |
| **CLI ligero** | ✅ Para power-users (patrón Devin/Claude Code) | ✅ Opcional | ✅ Opcional |

**VEREDICTO ratificado (ADR-006, Q1):** **local-first es el producto principal** (Tauri + SQLite, gratis, BYOK). La nube es un **SKU de pago** (suscripción, multi-tenant, workers 24/7). La web es la misma SPA servida por el gateway para el modo nube.

## 3 · MONETIZACIÓN — los 3 modelos con datos reales

### Modelo 1 · Open-core + Managed Hosting (nube gestionada) — **EL MOTOR PRINCIPAL**
Validado por: n8n ($40M ARR, valuación $5.2B), Supabase, PostHog, GitLab.
- Core open-source (MIT/Apache) self-host gratis ilimitado → comunidad + confianza + distribución
- **Cobramos por alojar en NUESTROS servidores**: costo real nuestro $16-110/mes por tenant ([PLAN S·S1](./plan-s-despliegue-costos.md#s--1--hosting-por-etapas-con-costos-reales)) → precio $29-149/mes por tier = **margen 60-80%**
- Free tier diseñado para chocar muro de proyecto serio (limitar amplitud/historial, no solo rate-limit)
- Conversión: patrón Windsurf free-bottom-up → equipos → enterprise

### Modelo 2 · Pay-per-results (outcome-based) — **ARMA DE DIFERENCIACIÓN, no motor inicial**
Datos duros: Intercom Fin $100M ARR a $0.99/resolución (NRR 112→146%) PERO con definición expansiva controlada por el vendedor · Sierra $200M ARR a ~$1.50/resolución pero contratos opacos $150K+/año · **Devin abandonó outcome puro** (42% de PRs mergeados = revenue erraticísimo; cada éxito arrastra ~2 intentos fallidos de tokens) · Salesforce Agentforce $2/conversación FRACASÓ ($900/día prohibitivo) → pivotó a créditos.
- **Nuestra ventaja única del mercado**: los tests E2E son el ÁRBITRO OBJETIVO del resultado ("software entregado + suite verde" es binario, no interpretable) — elimina la disputa #1 que mata a otros
- **Cuándo activarlo**: SOLO cuando success-rate >70% medido en producción, y solo en entregas binariamente verificables, preciado ≥3-4× costo marginal percentil-95, con mínimo mensual (patrón Fin floor $49)
- Hasta entonces: fórmula Bessemer — fee base = 2× costo de entrega estimado + paquete créditos

### Modelo 3 · Licencia enterprise (seats/on-prem) — **para después del product-market fit**
Harvey: $1,200-2,000+/abogado/mes SIN outcome (cuando el valor percibido es altísimo, ni arriesgan margen) · tendencia enterprise real: acuerdos ILIMITADOS anuales (Adecco-Agentforce) porque CIOs odian variable impredecible · SSO/audit/on-prem como features Business

### ✅ RECOMENDACIÓN POR ETAPA
| Etapa | Modelo |
|---|---|
| Pre-PMF | Open-core + subscription simple por tenant + créditos visibles (Bessemer) |
| PMF (>70% success-rate medido) | + outcome-premium opcional en entregas binariamente verificables |
| Enterprise | + licencias on-prem ilimitadas anuales + SSO/compliance pack |

## 4 · GROWTH — la secuencia ganadora (casos medidos)

**El hallazgo #1**: nuestro OUTPUT ES FILMABLE — oficina animada con agentes trabajando + apps construyéndose en vivo = el "demo primitive" que hizo explotar a Lovable/Bolt. **KPI growth norte: % de usuarios nuevos que COMPARTEN/exportan un artefacto en su primera sesión.**

| Fase | Acciones (de casos reales) |
|---|---|
| **0→1K** (meses 0-4) | Quickstart <10 min que funciona a la primera · self-host 1-comando (`docker run`) · primeros 10-20 usuarios A MANO · evento-clave instrumentado ("primer agente completa tarea E2E") · build-in-public YA (X+blog; audiencia tarda 6-12 meses) · MCP server en los 7 registros (~30 min, superficie permanente) |
| **1K→50K** (meses 4-18) | Show HN sábado, título "Show HN: Yo hice… [número]", SIN la palabra "AI" (-33% portada), repo MIT visible (re-lanzar en cada release — patrón n8n: 4 hits en 6 años, HN supera PH 20× en tráfico) · video corto demo-first TikTok/Shorts (Lovable: 25M views en UN Short) · micro-influencers $5-15K/test SOLO cuando activation >5% · **monetizar aquí** con pricing self-serve transparente (PostHog: pricing transparente AUMENTÓ crecimiento) |
| **50K+** (meses 18+) | SEO marca + GEO (que LLMs citen la tool) · enterprise motion encima del PLG (Windsurf: free→800K devs→350 enterprise) · **ser infraestructura default de otros builders** (Supabase lo hizo siendo backend de Lovable/Bolt/v0) |

**Errores fatales documentados**: construir antes que distribuir · free sin diseño de muro · influencers antes de activation (94% fallo B2B primerizo) · DevRel antes de posicionamiento · quickstart roto (docs SON el landing) · métricas de vanidad.

## 5 · EXIT paths verificados (2025-2026)

| Path | Caso | Números |
|---|---|---|
| Venta integral | Cognition compra Windsurf restante | ARR $82M + 350 enterprise |
| Acqui-license (tech+equipo, compañía viva) | Google pagó **$2.4B** por Windsurf tech+talento | Reverse-acquihire récord |
| Independencia | Cursor rechazó OpenAI; $500M→$9.9B→reportado $60B | Múltiplos pico 30-75× ARR forward |
| Validación del modelo outcome | Salesforce compró Intercom/Fin en 2026 | Outcome-based validado por incumbente |

Los compradores pagan por: **ARR creciente × usuarios activos × talento**, en ese orden. Maximiza ambas opciones manteniendo ARR auditable y retención enterprise >120%.

---
[← Maestro](./README.md)
