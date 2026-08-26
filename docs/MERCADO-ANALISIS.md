# MERCADO-ANALISIS — Investigación de alto valor (2026-08-25)

> Fuentes: comparativas 2026 de Cursor vs Windsurf vs Cline vs Roo Code vs Devin vs Copilot (AppScale, StackFYI, MasterPrompting, DEV, Nesyona) + docs oficiales OpenCode ([opencode.ai](https://opencode.ai)). Objetivo: detectar funciones de alto valor que faltan en el plan.

## 1 · Lo que el mercado considera "table stakes" en 2026

| Capacidad | Estado en nuestro plan |
|---|---|
| Agent mode multi-file | ✅ Etapa 6/7 (canvas + motor de pruebas) |
| Human-in-the-loop approvals | ✅ V.2 + hunks B.7 (mejor que la media) |
| BYOK + cualquier modelo | ✅ BYOK universal (C.7, mejor que Cursor/Windsurf) |
| Local models (Ollama) offline | ✅ C.6 |
| MCP servers | ✅ Plan P (centro MCP) |
| Session persistence/reanudar | ✅ Etapa 2 |
| Checkpoint & revert de sesión | ✅ D.3 scrubber + H.9b snapshots (paridad con OpenCode v1.17) |
| Share session links | ✅ O.4 (acabamos de agregarla) |
| Multi-session paralelo | ✅ N.1 |
| Detección de agente estancado ("doom loop") | ✅ I.2 |
| Live preview | ✅ B.3 |
| Rules files por proyecto | 🟡 skills cubren; falta IMPORTAR formatos del mercado |
| Browser automation del agente | ❌ **FALTANTE** (Cline lo tiene nativo) |
| LSP integration (diagnósticos reales al contexto) | ❌ **FALTANTE** (OpenCode lo carga automático) |
| Task intake desde apps externas | 🟡 puentes N.8 (Telegram/WA/Discord); falta Slack |
| Tab-autocomplete inline (FIM) | ❌ Post-v1 honesto: requiere infra FIM propia |

## 2 · Decisiones (agregar al plan)

| # | Función | Por qué (dato de mercado) | Fase nueva |
|---|---|---|---|
| **F33** | **Browser automation** del agente (navegar/click/screenshot en sandbox) | "No other tool has this level" — es EL diferenciador de Cline para devops/web; habilita 'entra al staging y dime qué está roto' | **C.10** |
| **F34** | **LSP integration**: diagnósticos reales del lenguaje alimentan al agente | OpenCode lo hace automático ("loads the right LSPs"); errores de compilador reales > adivinación | **B.10** |
| **F35** | **Importar rules files del mercado** (`.cursorrules`, `.clinerules`, `CLAUDE.md`, `.windsurfrules` → skills) | Migración sin fricción: los usuarios ya tienen reglas escritas; hook de adquisición como F25 | **G.3b** |
| **F36** | **Slack** en puentes de mensajería | Devin cobra $500/mo parcialmente por esto; intake de tareas desde donde trabaja el equipo | N.8 (ampliación canal) |
| — | Tab-autocomplete FIM | POST-V1: requiere entrenamiento/integración FIM; no bloquea nada (pair con extensión si se desea, patrón Cline) | backlog |

## 3 · Confirmaciones (lo que ya hacemos bien — validación de mercado)

1. **BYOK total** = la posición ganadora de coste/control (Cline gana ahí; nosotros además local-first).
2. **Evidencia verificable + aprobaciones** = exactamente hacia dónde fue el mercado (human-in-the-loop es tendencia #1).
3. **Sandbox + seguridad por defecto** (nuestro THREAT-MODEL) — Devin lo cobra a $500/mo.
4. **Skills `.md` compatibles mentalidad OpenCode** (SKILL.md ≈ nuestra receta; añadir import facilita adopción).

## 4 · Impacto en el plan

- **MATRIZ:** +3 fases (C.10, B.10, G.3b) → **165 fases** · N.8 ampliado con Slack.
- **COVERAGE-GUI:** filas nuevas para browser-tool e import-rules (UI interactiva).
- Detalle de implementación por función: ver filas de la MATRIZ y [FEATURE-BACKLOG](./FEATURE-BACKLOG.md).
