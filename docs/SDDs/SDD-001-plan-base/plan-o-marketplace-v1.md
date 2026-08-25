# PLAN O — Etapa 15: Marketplace + Release v1.0

> [← Maestro](./README.md) · [← PLAN N](./plan-n-orchestration.md)
> Depende de: Etapa 14. Cierra el roadmap hacia la visión completa (marketplace del AGENTS.md original).

**Entregable:** empresas, skills y plantillas se empaquetan y comparten; release 1.0 pulido.

<a id="o1"></a>
### O.1 — Bundles `.canvas-ai-bundle`
- Empaquetador: empresa (roles+skills+plantillas de tareas) → paquete firmado (hash+manifest) importable 1-click en otra instalación; skills exportables individualmente a todos los dialectos ([G·G.3](./plan-g-skills-lab.md#g3))
- **Pruebas:** Cargo test roundtrip export→import idempotente; firma verificada; import malicioso rechazado (validación manifest)

<a id="o2"></a>
### O.2 — MCP público del cerebro (patrón V3Code/Zed)
- Servidor MCP que expone hacia FUERA las capacidades internas: búsqueda en memoria ([D·D.5](./plan-d-memoria-v3code.md#d5)), repo-map ([J·J.2](./plan-j-grafo3d-repomap.md#j2)), skills compilados, decisiones gobernadas
- Cualquier agente externo (Claude Code, Cursor, Reasonix de otro proyecto) conecta y gana el mismo cerebro — Canvas AI como infraestructura, no solo app
- Autenticación por token local; herramientas read-only por defecto
- **Pruebas:** Integration real: Claude Code conectado al MCP responde preguntas del workspace usando nuestro grafo. Snapshot tests de tools

<a id="o3"></a>
### O.3 — Release v1.0
- Pulido transversal: suite humana completa punta-a-punta de TODAS las features · performance (arranque <3s, canva 60fps) · docs usuario + arquitectura al día · instaladores Windows/macOS/Linux via CI (tauri build multi-target) · tag `v1.0.0`
- **Pruebas:** Checklist DoD gigante: todas las suites humanas históricas re-corridas en las 3 vistas; builds CI verdes; demo documental final

## 🚪 GATE O — v1.0

Instalador descargado desde CI corre en una máquina limpia: creo empresa desde bundle de terceros, la opero con voz, veo su oficina animada, entrego un proyecto real con PR. **La fábrica visual de empresas de desarrollo es realidad.**

---
[← Maestro](./README.md) · [← PLAN N](./plan-n-orchestration.md)
