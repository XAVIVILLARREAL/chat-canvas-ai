# PLAN P — Etapa transversal: Centro MCP (visual, para programadores Y no-programadores)

> [← Maestro](./README.md) · **Se ejecuta tras el Gate B** (necesita AppShell+stores), en paralelo con C/D; alimenta a G (gating), I y N (tools de agentes)
> Promueve a fase activa los ítems 484–500 del [torneo SDD-003](../SDD-003-torneo-500-ideas.md). Complementa O.2 (nuestro cerebro EXPUESTO vía MCP): este plan es el lado CLIENTE — conectar herramientas externas.

**Entregable:** cualquier persona conecta servidores MCP a sus agentes en minutos: el programador pega su JSON/TOML, el no-programador instala tarjetas 1-click. Los agentes ganan superpoderes externos con permisos y auditoría.

<a id="p1"></a>
### P.1 — Cliente MCP core (Rust)
- Cliente MCP spec vigente: stdio + HTTP/SSE, lifecycle (initialize/tools/list/call), streaming
- Registro de servers por proyecto/global en SQLite; estado (connected/error/disabled) persistente
- **Herencia con decisión del usuario** ([A·A.0](./plan-a-chat-codex.md#a0)): server GLOBAL disponible en todos los proyectos (cada uno puede desactivarlo) o LOCAL solo-de-ese-proyecto — igual filosofía que skills ([G·G.1](./plan-g-skills-lab.md#g1))
- Llamadas tool SIEMPRE pasan por el gating del skill/rol ([G·G.2](./plan-g-skills-lab.md#g2)) y quedan en rungs auditables ([D·D.1](./plan-d-memoria-v3code.md#d1))
- **Pruebas:** Cargo test contra fixture-server MCP local (stdio): list/call/stream. Timeout + kill limpio

<a id="p2"></a>
### P.2 — Centro MCP visual (doble público)
- **Vista no-programador**: galería de TARJETAS ("GitHub — gestiona PRs e issues", "Postgres — consulta tu base") con botón **Conectar**, wizard paso-a-paso en lenguaje humano, estados claros (✓ conectado · ⚠ necesita token · ✕ error con qué hacer)
- **Vista programador**: editor JSON/TOML crudo con validación Zod live, import directo desde configs existentes (`claude_desktop_config.json`, `.cursor/mcp.json`, `reasonix.toml`) con detección automática
- Panel de SALUD por server: latencia, última llamada, tools expuestas, tasa de error; toggle activar/desactivar sin borrar
- Explorador de TOOLS del server: nombre + descripción traducida a lenguaje simple + "probar" sandbox antes de dársela a un agente
- **Pruebas:** E2E humano dual: (a) no-programador conecta server popular solo con clicks y entiende errores; (b) programador pega JSON complejo y ve validación inmediata

<a id="p3"></a>
### P.3 — Seguridad y control de llamadas externas
- Tokens/secrets de cada server cifrados ([A·A.3](./plan-a-chat-codex.md#a3)) y JAMÁS visibles al webview
- Scopes por server: read-only / write / admin — asignables por skill y por agente; confirmación humana obligatoria para tools marcadas destructivas
- Rate-limit y presupuesto de coste POR SERVER externo; logs completos de cada llamada (args redacted opcional)
- Kill-switch por server (corta llamadas en curso) y global
- **Pruebas:** Cargo test enforcement scopes + rate limit. Chaos: server que devuelve basura → circuit breaker aísla sin tumbrar agentes

<a id="p4"></a>
### P.4 — Plantillas 1-click y descubrimiento
- Catálogo curado embebido de servers populares verificados (github, filesystem, postgres, browser, slack…) con instrucciones humanas de obtención de token
- Actualización del catálogo sin actualizar la app (archivo firmado remoto/local)
- Cada plantilla declara: qué habilita, riesgos, permisos sugeridos por rol
- **Pruebas:** Unit schema plantilla. E2E humano: instalar "GitHub" desde cero hasta primer tool-call exitoso <5 min sin leer docs

## 🚪 GATE P (demo verificable)

Demo doble: (1) persona NO técnica instala el server de GitHub desde una tarjeta, da un token, y su agente QA lista issues reales — sin tocar JSON. (2) Programador importa su `mcp.json` de Cursor con 6 servers, ve salud de todos, apaga uno roto, y su agente dev usa los demás en la misma tarea. Suite humana ampliada verde.

---
[← Maestro](./README.md)
