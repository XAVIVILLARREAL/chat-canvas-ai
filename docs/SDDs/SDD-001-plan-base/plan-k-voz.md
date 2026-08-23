# PLAN K — Etapa 11: Voz (STT/TTS)

> [← Maestro](./README.md) · [← PLAN J](./plan-j-grafo3d-repomap.md) · [PLAN L →](./plan-l-sync-cowork.md)
> Depende de: Etapas 1-5. ADR-003 del repo (Web Speech API + Edge TTS).

**Entregable:** hablas con tus agentes; te responden con voz natural en español; sonidos de estado cuando algo necesita atención.

| Fase | Contenido | Pruebas |
|---|---|---|
| K.1 **TTS de respuestas** | Edge TTS vía WebSocket (gratis, natural): voces `es-MX-DaliaNeural`/`es-MX-JorgeNeural` configurables por agente; botón play en cada mensaje + auto-play opcional; cola de reproducción si llegan varios | Unit cliente WS + caché de audio por hash(texto+voz). E2E con mock WS: botón aparece, cola ordena |
| K.2 **STT dictado** | Web Speech API (nativa del webview) en el composer: botón micrófono → dictado → transcripción editable antes de enviar; fallback claro si el navegador no soporta (Chromium ok) | E2E con mock del API: "dictado" inserta texto, editar y enviar funciona |
| K.3 **Sonidos de estado** | Notificaciones sonoras por evento del EventBus ([C·C.1](./plan-c-reasonix-deepseek.md#c1)): agente bloqueado, esperando aprobación ([A·A.4](./plan-a-chat-codex.md#a4)), tarea lista para revisión ([H·H.4](./plan-h-motor-pruebas.md#h4)); volumen/on-off por tipo en settings; respeta prefers-reduced-motion análogo (modo silencio) | E2E: mock eventos → sonido correcto por tipo (spy Audio); toggles persisten |

## 🚪 GATE K

Demo hablada real: dicto por voz "crea un skill QA" → se envía → el agente trabaja → suena alerta de aprobación pendiente → apruebo → la respuesta final se reproduce con voz Dalia. Todo sin tocar teclado salvo aprobar. Video con audio + suites humanas.

---
[← Maestro](./README.md) · [← PLAN J](./plan-j-grafo3d-repomap.md) · [PLAN L →](./plan-l-sync-cowork.md)
