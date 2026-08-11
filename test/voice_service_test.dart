import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/services/voice_service.dart';

class FakeStt extends SpeechToTextVoice {
  String? next;
  bool stopped = false;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String?> listenOnce() async => next;

  @override
  Future<void> stop() async => stopped = true;
}

class FakeTts extends TextToSpeechVoice {
  final List<String> spoken = [];
  bool available = true;

  @override
  Future<bool> isVoiceInstalled() async => available;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}
}

void main() {
  group('VoiceService (fakes)', () {
    test('listenOnce devuelve la transcripción del motor', () async {
      final stt = FakeStt()..next = 'hola agente';
      expect(await stt.listenOnce(), 'hola agente');
    });

    test('taller: listenOnce devuelve null sin transcripción', () async {
      final stt = FakeStt()..next = null;
      expect(await stt.listenOnce(), isNull);
    });

    test('speak acumula el texto leído', () async {
      final tts = FakeTts();
      await tts.speak('respuesta uno');
      await tts.speak('respuesta dos');
      expect(tts.spoken, ['respuesta uno', 'respuesta dos']);
    });

    test('isAvailable del STT y TTS refleja el motor', () async {
      final stt = FakeStt();
      final tts = FakeTts();
      expect(await stt.isAvailable(), isTrue);
      expect(await tts.isVoiceInstalled(), isTrue);

      tts.available = false;
      expect(await tts.isVoiceInstalled(), isFalse);
    });
  });
}