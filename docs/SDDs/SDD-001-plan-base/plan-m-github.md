# PLAN M — Etapa 13: GitHub nativo

> [← Maestro](./README.md) · [← PLAN L](./plan-l-sync-cowork.md) · [PLAN N →](./plan-n-empresas-autonomas.md)
> Depende de: base 1-5. ADR-004 del repo. Git en Rust: gitoxide (lectura) + CLI git (operaciones complejas) detrás de trait GitService.

**Entregable:** todo el ciclo git/GitHub desde la app, sin terminal — pensado para que los AGENTES también lo operen.

<a id="m1"></a>
### M.1 — Auth + repos
- OAuth Device Flow (ideal para Tauri desktop): token en SQLite cifrado ([A·A.3](./plan-a-chat-codex.md#a3)), scopes repo/workflow/read:user; listado/filtro/búsqueda de repos; clonar shallow a workspace ([B·B.1](./plan-b-sidepanels-lovable.md#b1))
- **Pruebas:** Integration con GitHub real (cuenta de prueba): device flow completo, clone real. Mock server para CI

<a id="m2"></a>
### M.2 — Ciclo git diario
- Status visual por archivo, stage/unstage, commit con mensaje, branch create/switch/merge simple, pull --rebase, push; detección conflictos → UI diff 3-vías guiada (Monaco DiffEditor)
- **Pruebas:** Integration git real en repo fixture: flujo completo feliz + conflicto resuelto por UI

<a id="m3"></a>
### M.3 — PRs e Issues + memoria commiteada
- Crear PR desde rama actual (título/body autogenerado desde rungs del Ledger [D·D.1](./plan-d-memoria-v3code.md#d1)); listar/comentar/cerrar issues; **export decisions** del Workspace Knowledge como `DECISIONS.md` en el repo (patrón codevira: memoria visible en git para cualquier otro agente externo)
- **Pruebas:** Integration API GitHub: PR creado con body correcto; issue comentado. E2E humano: ciclo feature→commit→push→PR sin terminal

## 🚪 GATE M

Demo completa: login GitHub → clono un repo real → agente implementa feature ([H](./plan-h-motor-pruebas.md#h3)) → review automático ([I·I.1](./plan-i-revision-superposiciones.md#i1)) → commit + push desde UI → PR abierto con resumen generado de las decisiones de la sesión. Video + suites verdes.

---
[← Maestro](./README.md) · [← PLAN L](./plan-l-sync-cowork.md) · [PLAN N →](./plan-n-empresas-autonomas.md)
