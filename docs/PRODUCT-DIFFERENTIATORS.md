# PRODUCT-DIFFERENTIATORS — Lo que hace a Canvas AI "increíble" (no perderlo)

> **Producto:** Canvas AI · **Estado:** v1.0 · 2026-08-25
> Este documento nombra los **7 diferenciadores** que hacen a Canvas AI memorable. Cada fase del plan existe para sostener uno de ellos — si una fase no alimenta ninguno, se re-prioriza.

## 1 · Evidence-first delivery (la mayor ventaja competitiva)
El agente **no dice "listo"**: entrega evidencia verificable (diff aprobable + tests verdes + artefacto) y el humano **acepta o rechaza**. El resultado es binario y auditable — es la única ventaja de mercado para cobrar por resultado (SDD-010) y la métrica norte.
> Sustenta: Plan H (motor de pruebas), Kanban KR, "sesiones que terminan en ENTREGA".

## 2 · Memory Rail + Time-Scrubber (memoria con raíces)
Cada sesión tiene un **rail de rungs** (prompt→fase→diff→test→decisión) y un **scrubber temporal** para rebobinar la sesión a cualquier punto. No es "historial": es *reproducibilidad* de qué pasó, por qué, y cuánto costó.
> Sustenta: Etapa 4 (memoria D), event_stream, replay.

## 3 · Local-first + BYOK (privacidad como producto)
Tu código, tus prompts y **tu API key** nunca salen de tu máquina en el plan gratuito. "Tus datos nunca salen" es el pitch (T.BIZ). Offline total con Ollama. La nube es un extra de pago, no la condición de uso.
> Sustenta: ADR-006, THREAT-MODEL, plan-c C.6.

## 4 · Skills como personajes vivos (.md con alma)
Un skill no es un YAML: es un **documento `.md` con nombre, personalidad, cara animada, emoji y bio**, que se materializa como agente/expert/proceso/flujo. Crear uno es una **ceremonia**, no un formulario. El marketplace vende personajes, no archivos.
> Sustenta: Etapa 5 (G), CONTRATO-SKILL, ceremonia de creación, marketplace O.

## 5 · Canvas multi-runtime que compila a código real
No es "arrastrar cajas" como n8n: el canvas es un **compilador** a código ejecutable en Python/TS/Go/Bash/SQL con deploy-spec universal. La visualización es el editor; el código es el producto.
> Sustenta: Etapa 6 (F), canvas compiler, multi-runtime.

## 6 · El agente muestra su trabajo (Shadow Workspace)
Antes de presentar un cambio, el agente lo **pre-ejecuta silenciosamente** (linter/compilador) y solo muestra código que pasa. El humano ve el trabajo *bien hecho*, no el proceso a medias.
> Sustenta: H.5 (shadow workspace), B.5 (fast apply).

## 7 · Humano en el centro, IA como empleado visible (no caja negra)
Todo lo que hace la IA es **visible, auditable y pausable** (Human-Tweak Lock, diffs por hunks, cancelación, guardrail de costo en vivo). El usuario nunca siente que "la IA lo decide todo por detrás".
> Sustenta: A.4/A.7, Human-Tweak Lock, badge de costo, circuit breaker.

---

## Cómo se protege cada uno en el plan

| Diferenciador | No debe morir en | Es el "sí" de |
|---|---|---|
| Evidence-first | la niebla de las 137 fases | Gate H + KR + norte |
| Memory Rail | una feature "nice to have" | Etapa 4 es núcleo de MVP-2 |
| Local-first+BYOK | el marketing | ADR-006 es regla dura |
| Skills-personaje | un CRUD más | ceremonia + marketplace |
| Canvas compiler | un canvas decorativo | Etapa 6 (F) en MVP-3 |
| Shadow workspace | un optimización | H.5 es gate |
| Humano en el centro | una opción | Human-Tweak Lock + presupuestos |

## Regla del producto

> **Si una feature no alimenta al menos uno de estos 7, se mueve a backlog.** El "increíble" es que TODOS los 7 estén presentes en el v1, no que haya 137 fases.
