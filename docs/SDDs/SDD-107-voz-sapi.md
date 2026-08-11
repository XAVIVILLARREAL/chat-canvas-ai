# SDD — Etapa 2, slice 2: Voz (STT + TTS con SAPI nativo de Windows)

> **Proyecto:** empresa_dev — Etapa 2 del SUPER_PLAN.
> **Fecha:** 2026-08. **Estado:** ✅ Implementado (gate de slice cerrado; falta prueba manual con micrófono/vox real).
> **Decisión (ADR-004):** voz 100% local con SAPI nativo de Windows — `speech_to_text` (STT) + `flutter_tts` (TTS). Sin red, sin servidor, latencia mínima. La transcripción siempre queda como texto en la sesión (la voz nunca reemplaza el registro escrito).

## Resultado (2026-08)

- `lib/services/voice_service.dart`: `SpeechToTextVoice` / `TextToSpeechVoice` (abstracciones inyectables) + `NativeStt` (package:speech_to_text, SAPI) y `NativeTts` (package:flutter_tts, SAPI; `speak` corta la lectura previa; `isVoiceInstalled` cacheado).
- `lib/widgets/voice_buttons.dart`: `VoiceMicButton` (long-press graba → transcripción al input, animación roja) y `SpeakerButton` (lee la burbuja).
- `AgentChatScreen`: micrófono junto al input (transcripción editable antes de enviar) + altavoz en burbujas del asistente; `stt`/`tts` inyectables.
- Build: `flutter_tts` requiere **nuget.exe** (`C:\tools\nuget\nuget.exe`) y CMake con `-DCMAKE_INSTALL_PREFIX=build\windows\x64\runner\Debug`.
- Tests: `test/voice_service_test.dart` (4 unit con fakes) + `test/voice_buttons_widget_test.dart` (2 widget). Suite total 32 unit/widget verdes, `flutter analyze` 0 issues, build Windows OK.

## Gate del slice

- [x] Unit: fakes de STT/TTS devuelven transcripción y cortan lectura; `isAvailable` correcto.
- [x] Widget: botón micrófono inserta texto; botón altavoz dispara el TTS del texto correcto.
- [ ] Manual (Windows real): dictar "hola" → aparece en el input → responder "que tal" → 🔊 lo lee. *(requiere paquete de voz español instalado en Windows)*
- [x] Manual: `flutter analyze` 0 issues + suite tests verde + build Windows OK.

## Objetivo

Poder **dictar un prompt por voz** en el chat del agente y que la respuesta del agente **se lea en voz alta**, sin salir de la app. Los motores son los nativos de Windows (Speech Recognition + Speech Synthesizer vía SAPI), por lo que funciona offline y sin enviar audio a terceros.

## Alcance (este slice)

- `VoiceService` (abstracción) con dos implementaciones:
  - `SpeechToTextVoiceService` (STT): envuelve `package:speech_to_text` → devuelve la transcripción del dictado.
  - `TextToSpeechVoiceService` (TTS): envuelve `package:flutter_tts` → reproduce el texto de la respuesta.
- Botón **🎤** en el input del `AgentChatScreen`: al mantenerlo / al pulsarlo, graba; al soltar, transcribe y lo inserta en el campo de texto (el usuario puede editarlo antes de enviar).
- Botón **🔊** en cada burbuja de respuesta del asistente: lee el texto en voz alta.
- Indicadores visuales: micrófono activo (rojo/animado) mientras graba; TTS con tope si ya está hablando (stop en curso → reinicia).
- On/off global de voz en ajustes del chat (icono de altavoz tachado si el sistema no tiene voxes instaladas).
- Si el SO no tiene paquete de voz instalado (SAPI vacío), el micrófono se muestra pero al usarlo da feedback claro y no rompe el chat.

## Fuera de alcance

- Voz en Android/iOS (window nativo es desktop; el nodo agente sigue siendo desktop-only de todas formas).
- Streaming de audio por WebSocket o hub (no es necesario: SAPI es local).
- Voz "sin abrir la ventanita" desde el canva (mini-hilo de voz en el nodo) → posible siguiente slice.
- Whisper / motores de terceros.

## Flujo (caso feliz)

1. El usuario pulsa el 🎤 del chat del agente → comienza el reconocimiento (SAPI).
2. Dicta: "¿cuánto tardó el build?" → suelta el botón → la transcripción "+¿cuánto tardó el build?+" aparece en el input, editable.
3. Envía (Enter o botón) → el prompt se procesa como siempre (runner opencode).
4. La respuesta llega al chat → el usuario pulsa 🔊 en la burbuja → `flutter_tts` la lee con la vox instalada.

### Casos límite

- No hay vox/micrófono instalado → SnackBar/indicador "Voz no disponible" y el campo de texto sigue funcionando.
- El usuario pulsa 🔊 mientras otra lectura está en curso → se corta y empieza la nueva.
- Transcripción vacía → no se inserta nada en el input.
- `flutter_tts` falla (API cambiante) → fallback silencioso: no se rompe la UI, se loguea.

## Contratos

### Servicio

```dart
abstract class VoiceService {
  Future<bool> isAvailable();        // SAPI activo + voxes/paquete instalados
}

/// STT: devuelve el texto dictado (o null si no se reconoció nada).
abstract class SpeechToTextVoice {
  Future<VoiceAvailability> initialize();
  Future<String?> listenOnce();      // graba ~1 frase, devuelve transcripción
  Future<void> stop();
}

/// TTS: lee un texto por voz.
abstract class TextToSpeechVoice {
  Future<bool> isVoiceInstalled();
  Future<void> speak(String text);
  Future<void> stop();
}
```

### Widgets

- `VoiceMicButton`: botón que mantiene-pulsado para grabar (gesture `onLongPressStart`/`onLongPressEnd`) con animación de "grabando" en rojo. Callbacks `onTranscript(String?)`.
- `SpeakerButton`: icono 🔊 que llama a `speak()` con la burbuja de texto; muestra estado "reproduciendo" (icono cambia a 🕸/volumen-off mientras habla).

### Ubicación

- `lib/services/voice_service.dart` (abstracciones + fábrica `VoiceServiceFactory` para inyectar fakes).
- `lib/widgets/voice_buttons.dart` (`VoiceMicButton`, `SpeakerButton`).
- Integración en `lib/screens/agent_chat_screen.dart` (fila de botones junto al input; botón en burbujas del asistente).

## Tests (TDD) — `test/voice_service_test.dart`, `test/voice_buttons_widget_test.dart`

- Unit (con fakes): `listenOnce` devuelve lo que el motor devuelve; `speak` corta la lectura previa; disponibilidad = SAPI con voxes.
- Widget: el 🎤 inserta la transcripción en el input; el 🔊 llama a `speak` con el texto de la burbuja (mock del servicio); sin vox → se muestra el aviso pero el chat funciona.

## Gate del slice

- [ ] Unit: fakes de STT/TTS devuelven transcripción y cortan lectura; `isAvailable` correcto.
- [ ] Widget: botón micrófono inserta texto; botón altavoz dispara el TTS del texto correcto.
- [ ] Manual (Windows real): dictar "hola" → aparece en el input → responder "que tal" → 🔊 lo lee. *(requiere paquete de voz español instalado en Windows)*
- [ ] Manual: `flutter analyze` 0 issues + suite tests verde + build Windows OK.