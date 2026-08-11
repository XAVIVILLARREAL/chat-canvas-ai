# SDD — Etapa 2, slice 3: Evidencia por prompt (.md navegable)

> **Proyecto:** empresa_dev — Etapa 2 del SUPER_PLAN.
> **Fecha:** 2026-08. **Estado:** ✅ Implementado (gate de slice cerrado; pendiente evidencia manual de 3 prompts reales).

## Resultado (2026-08)

- `lib/services/evidence_store.dart`: formato `{fecha}_{hora}_{agente}.md` en `<Documentos>/evidencia/` (I/O síncrono para compatibilidad con widget tests; root por `USERPROFILE\Documents`, sin path_provider). Sufijo `_1`, `_2` si existe. `list()` devuelve registros descendentes con `prompt` extraído del propio `.md`.
- `lib/screens/evidence_screen.dart`: lista con icono + agente/fecha; click → lector `SelectableText`; carpeta con `explorer /select,`.
- `AgentChatScreen`: `evidenceStore` opcional; al `_finish` guarda evidencia si hay respuesta (sin bloquear UI); botón de evidencia en el AppBar.
- `CanvaScreen` pasa `EvidenceStore()` al chat.
- Tests: `test/evidence_test.dart` (4 unit) + `test/evidence_widget_test.dart` (2 widget: guarda al terminar, botón abre lista). CI: `flutter analyze` 0 issues, 26 unit/widget verdes, build Windows OK. `agent_integration_test` verde. Los 2 fallos de `sync_integration_test` son pre-existentes (hub Tailscale no alcanzable en este entorno).

## Gate de slice

- [x] Unit: `EvidenceStore` formatea, guarda, no escribe sin respuesta, lista descendente con prompt real.
- [x] Widget: responder al agente escribe el `.md`; botón evidencia navega a la lista.
- [ ] Manual: 3 prompts reales en la app → 3 `.md` en Documentos/evidencia/ (queda para la prueba manual final de Etapa 2).

## Objetivo

Cada interacción con un agente IA queda registrada como un **documento Markdown navegable** desde la app y el filesystem: prompt + respuesta + metadatos. Es la "evidencia por prompt" del plan original y la base del dogfood (los SDDs y notas del proyecto enlazados al canva en Etapa 4).

## Alcance (este slice)

- `EvidenceStore`: guarda cada conversación del chat del agente como `.md` en `getApplicationDocumentsDirectory()/evidencia/`.
- Formato del archivo:
  ```markdown
  # Agente {agentName} — {fecha hora}

  **Sesión:** {id} · **Prompt:** {prompt} · **Fecha:** {ISO}

  ## Prompt

  > {prompt}

  ## Respuesta

  {respuesta del asistente}
  ```
- `EvidenceScreen`: lista los `.md` guardados (nombre, fecha), click → lector con `SelectableText` y botón "Abrir en carpeta" (desktop: `Process.start('explorer', ['/select,', path])`).
- Integración en `AgentChatScreen`: al terminar una respuesta del agente, se escribe el archivo automáticamente (sin bloquear la UI).

## Fuera de alcance

- Voz (STT + Edge TTS) → slice 2, lo guardamos como pendiente de Etapa 2.
- Verificación UI con Chrome headless → slice 4.
- Enlace automático al canva → Etapa 4.

## Flujo (caso feliz)

1. Chat del agente: prompt → respuesta completa.
2. `onDone` del runner → `EvidenceStore.save(session, prompt)` escribe `evidencia/2026-08-10_213000_dev.md`.
3. Desde "Evidencia" (icono en el AppBar del chat o entrada en el menú principal) se listan y abren.

### Casos límite

- Respuesta vacía o error → no se genera evidencia (o se genera con estado error, decidimos: se genera solo si hay texto de asistente).
- Falta espacio/escritura → se ignora en silencio (como resto de stores).
- Archivo existente con mismo timestamp → se sufija `_1`, `_2`.

## Contratos

```dart
class EvidenceRecord {
  final String path;
  final String agentName;
  final String prompt;
  final DateTime at;
}

class EvidenceStore {
  EvidenceStore({Directory? baseDir});        // test: dir inyectable; prod: docs dir
  Future<List<EvidenceRecord>> list();        // lee directorio evidencia/, parsea frontmatter-lite del nombre
  Future<String> save(AgentSession session, String prompt); // escribe .md, devuelve path
  String formatName(DateTime at, String agentName);         // '2026-08-10_213000_dev.md'
}
```

## Tests

- **Unit:** `formatName` con timestamp; `save` escribe el archivo con prompt+respuesta dentro; `list` devuelve registros en orden descendente.
- **Widget:** `EvidenceScreen` renderiza la lista de un dir temp y navega al lector.
- **Widget:** `AgentChatScreen` completa una respuesta con runner fake → genera archivo de evidencia.

## Verificación de UI (gate slice)

1. En el chat: pregunta al agente → al terminar, existe `evidencia/<timestamp>_dev.md` con el contenido.
2. Pantalla Evidencia lista el archivo → click → se lee el contenido.
3. Botón "abrir carpeta" funciona en desktop.

## Definition of Done

- [ ] `flutter analyze` 0 issues.
- [ ] Tests unit/widget verdes.
- [ ] Evidencia generada y navegable en la app.
- [ ] Slice marcado como hecho en SUPER_PLAN.