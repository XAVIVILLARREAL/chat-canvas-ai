# PLAN K — Etapa 11: Voz (STT/TTS)

> [← Maestro](./README.md) · [← PLAN J](./plan-j-grafo3d-repomap.md) · [PLAN L →](./plan-l-sync-cowork.md)
> Depende de: Etapas 1-5. ADR-003 del repo (Web Speech API + Edge TTS).
> **Decisión v3.8 (ratificada)**: K.1 (TTS) y K.2 (STT) se MOVIERON al [Plan Intermedio](../SDD-005-plan-intermedio.md) (las consume la Control Room); **K.3 se queda en base** por ser transversal (política de interrupción que usan U.5, V.4 e I).

**Entregable (base):** el sistema **sabe cuándo molestarte** (política de interrupción por severidad, patrón Grok Bot). La voz TTS/STT llega en el intermedio con la Control Room.

<a id="k1"></a>
### K.1 — TTS de respuestas (MOVIDO al Plan Intermedio — [SDD-005](../SDD-005-plan-intermedio.md))
- **Decisión v3.8**: se construye en el intermedio junto a CR (Control Room) — la Control Room es quien lo consume (escuchar resúmenes, TTS de digests)
- Edge TTS vía WebSocket (gratis, natural): voces `es-MX-DaliaNeural`/`es-MX-JorgeNeural` configurables por agente · botón play por mensaje + cola
- **Pruebas:** Unit cliente WS + caché de audio por hash(texto+voz). E2E con mock WS: botón aparece, cola ordena

<a id="k2"></a>
### K.2 — STT dictado (MOVIDO al Plan Intermedio — [SDD-005](../SDD-005-plan-intermedio.md))
- **Decisión v3.8**: se construye en el intermedio — el push-to-talk de CR.3 (órdenes maestras por voz) es su consumidor principal
- Web Speech API (nativa del webview) en el composer: botón micrófono → dictado → transcripción editable antes de enviar
- **Pruebas:** E2E con mock del API: "dictado" inserta texto, editar y enviar funciona

<a id="k3"></a>
### K.3 — Sonidos de estado + política de interrupción ("sabe cuándo molestar")
- Notificaciones sonoras por evento del EventBus ([C·C.1](./plan-c-reasonix-deepseek.md#c1)): agente bloqueado, esperando aprobación ([A·A.4](./plan-a-chat-codex.md#a4)), tarea lista para revisión ([H·H.4](./plan-h-motor-pruebas.md#h4))
- **Política de interrupción por severidad** (patrón Grok Bot): bloqueos/aprobaciones/peligro → interrumpen AHORA; progreso normal → se agrupa en digest silencioso consultable
- Volumen/on-off POR TIPO en settings ([A·A.6](./plan-a-chat-codex.md#a6)); respeta prefers-reduced-motion análogo (modo silencio)
- **Pruebas:** E2E: mock eventos → sonido correcto por tipo (spy Audio); evento menor NO suena pero aparece en digest; toggles persisten

## 🚪 GATE K (parcial, base)

Política de interrupción verificada: un agente bloqueado y una aprobación pendiente interrumpen AHORA con el sonido correcto por tipo; el progreso normal NO suena y se agrupa en digest silencioso ([U·U.5]); toggles por tipo persisten; modo silencio respeta prefers-reduced-motion. La demo hablada completa (dictado + TTS Dalia) se cierra en el intermedio con CR. Suites humanas verdes.

---
[← Maestro](./README.md) · [← PLAN J](./plan-j-grafo3d-repomap.md) · [PLAN L →](./plan-l-sync-cowork.md)
