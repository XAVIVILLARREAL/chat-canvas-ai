# PLAN K — Etapa 11: Voz (STT/TTS)

> [← Maestro](./README.md) · [← PLAN J](./plan-j-grafo3d-repomap.md) · [PLAN L →](./plan-l-sync-cowork.md)
> Depende de: Etapas 1-5. ADR-003 del repo (Web Speech API + Edge TTS).

**Entregable:** hablas con tus agentes; te responden con voz natural en español; y el sistema **sabe cuándo molestarte** (patrón Grok Bot).

<a id="k1"></a>
### K.1 — TTS de respuestas
- Edge TTS vía WebSocket (gratis, natural): voces `es-MX-DaliaNeural`/`es-MX-JorgeNeural` configurables por agente
- Botón play en cada mensaje + auto-play opcional; cola de reproducción si llegan varios
- **Pruebas:** Unit cliente WS + caché de audio por hash(texto+voz). E2E con mock WS: botón aparece, cola ordena

<a id="k2"></a>
### K.2 — STT dictado
- Web Speech API (nativa del webview) en el composer: botón micrófono → dictado → transcripción editable antes de enviar
- Fallback claro si el navegador no soporta (Chromium ok)
- **Pruebas:** E2E con mock del API: "dictado" inserta texto, editar y enviar funciona

<a id="k3"></a>
### K.3 — Sonidos de estado + política de interrupción ("sabe cuándo molestar")
- Notificaciones sonoras por evento del EventBus ([C·C.1](./plan-c-reasonix-deepseek.md#c1)): agente bloqueado, esperando aprobación ([A·A.4](./plan-a-chat-codex.md#a4)), tarea lista para revisión ([H·H.4](./plan-h-motor-pruebas.md#h4))
- **Política de interrupción por severidad** (patrón Grok Bot): bloqueos/aprobaciones/peligro → interrumpen AHORA; progreso normal → se agrupa en digest silencioso consultable
- Volumen/on-off POR TIPO en settings ([A·A.6](./plan-a-chat-codex.md#a6)); respeta prefers-reduced-motion análogo (modo silencio)
- **Pruebas:** E2E: mock eventos → sonido correcto por tipo (spy Audio); evento menor NO suena pero aparece en digest; toggles persisten

## 🚪 GATE K (demo verificable)

Demo hablada real: dicto por voz "crea un skill QA" → se envía → el agente trabaja en silencio (sin ruido) → suena alerta SOLO al pedir aprobación → apruebo → la respuesta final se reproduce con voz Dalia. Todo sin tocar teclado salvo aprobar. Video con audio + suites humanas.

---
[← Maestro](./README.md) · [← PLAN J](./plan-j-grafo3d-repomap.md) · [PLAN L →](./plan-l-sync-cowork.md)
