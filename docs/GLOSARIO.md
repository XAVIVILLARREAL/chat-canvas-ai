# GLOSARIO — Terminología canónica de Canvas AI

> **Producto:** Canvas AI · **Estado:** v1.0 · 2026-08-25
> Usar estos términos SIEMPRE con este significado en docs, código y commits. Un término = un concepto.

| Término | Definición |
|---|---|
| **Sesión** | Conversación/proyecto/tarea persistente con agentes; unidad de contexto, costo y memoria. Tabla `sessions`. |
| **Skill** | Documento `.md` (frontmatter + receta) con personalidad, nombre y cara animada; se materializa como agente/expert/proceso/flujo ([CONTRATO-SKILL](./CONTRATO-SKILL.md)). |
| **Rung** | Evento inmutable del `event_stream` (PROMPT, PHASE, DIFF, TEST_RESULT, DECISION, ESCALATION, DELIVERY). Es el "peldaño" del historial auditado. |
| **Entrega (delivery)** | Resultado aceptado por el humano (diff aprobado, tests verdes, artefacto, PR). Es la **métrica norte**. |
| **Gate** | Cierre verificable de una fase/MVP: suite humana Playwright verde (clicks+teclado, móvil+desktop) + video en `evidence/` + check:all. Sin gate no se avanza. |
| **Slice** | Subdivisión de una fase cuando excede ~1 sesión IA (~200-400 líneas o 1 flujo UI); tiene mini-gate propio (SDD-002). |
| **BYOK** | "Bring Your Own Key": el usuario trae su propia API key de LLM. Local → keychain del OS; nube → cifrada por tenant. |
| **Memory Rail** | Franja vertical con los rungs de la sesión; base del Time-Scrubber (replay). |
| **Time-Scrubber** | Control para rebobinar la sesión a cualquier punto de su historial de rungs. |
| **Deploy-spec** | Contrato TypeScript que describe un nodo del canvas para su ejecución multi-runtime. |
| **Shadow Workspace** | Pre-ejecución silenciosa (linter/compilador) de un cambio antes de mostrarlo al humano. |
| **Human-Tweak Lock** | Protección inmutable: código editado a mano no se sobreescribe por el agente. |
| **Provider** | Registro BYOK de un proveedor LLM (OpenAI/Anthropic/OpenRouter/DeepSeek/Ollama…) en la tabla `providers`. |
| **Circuit breaker** | Mecanismo por proveedor: 429/timeout/5xx → fallback controlado sin tumbar el chat. |
| **event_stream** | Ledger append-only de rungs; fuente de auditoría, telemetría y replay. |
| **DoR (Definition of Ready)** | Checklist para INICIAR una fase (tiene spec, fila en MATRIZ, fila en COVERAGE-GUI, contrato de pruebas). |
| **DoD (Definition of Done)** | Checklist para CERRAR una fase (suites verdes, video, sin deuda, docs al día). |
| **North-star** | Métrica principal: *sesiones que terminan en ENTREGA*. |
| **Proyecto** | Unidad de aislamiento de datos (`project_id` en toda tabla); en nube = tenant con RLS. |
| **Control Room** | Vista canvas global de sesiones/agentes (post-v1, Q6). |
| **Segundo Cerebro** | Grafo de documentos del workspace estilo Obsidian (plan-vi). |
| **Sandbox** | Contenedor Linux aislado donde corre código de agentes (red off, límites fijos). |

## Anti-glosario (términos que NO usar)

| No usar | Usar en su lugar | Por qué |
|---|---|---|
| Empresa autónoma / empleados IA / equipos de agentes | sesiones · skills · agentes · proyectos | eliminado (ADR-006) |
| Tenants (en local) | proyectos | tenant solo en nube |
| "compila / está implementado" | entrega / gate verde / done funcional | compilar NO es done |
| Chatbot | agente en sesión | es un entorno de trabajo |
