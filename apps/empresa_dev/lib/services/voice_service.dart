import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Abstracción del reconocimiento de voz (STT). En tests se inyectan fakes.
abstract class SpeechToTextVoice {
  Future<bool> isAvailable();
  Future<String?> listenOnce();
  Future<void> stop();
}

/// Abstracción de síntesis de voz (TTS). En tests se inyectan fakes.
abstract class TextToSpeechVoice {
  Future<bool> isVoiceInstalled();
  Future<void> speak(String text);
  Future<void> stop();
}

/// Implementación SAPI nativa de Windows vía package:speech_to_text.
class NativeStt implements SpeechToTextVoice {
  final SpeechToText _speech = SpeechToText();
  bool _ready = false;

  @override
  Future<bool> isAvailable() async {
    if (_ready) return true;
    _ready = await _speech.initialize();
    return _ready;
  }

  @override
  Future<String?> listenOnce() async {
    if (!await isAvailable()) return null;
    String? transcript;
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        final t = result.recognizedWords.trim();
        if (result.finalResult && t.isNotEmpty) transcript = t;
      },
    );
    // Espera a que el usuario deje de hablar (o corta a los 5s si no hay audio).
    await Future.delayed(const Duration(seconds: 5));
    await _speech.stop();
    return transcript;
  }

  @override
  Future<void> stop() async {
    if (_ready) await _speech.stop();
  }
}

/// Implementación TTS con la voz nativa de Windows via package:flutter_tts.
class NativeTts implements TextToSpeechVoice {
  final FlutterTts _tts = FlutterTts();
  bool? _hasVoices;

  @override
  Future<bool> isVoiceInstalled() async {
    if (_hasVoices != null) return _hasVoices!;
    try {
      final voices = await _tts.getVoices;
      _hasVoices = voices is List && voices.isNotEmpty;
    } catch (_) {
      _hasVoices = false;
    }
    return _hasVoices!;
  }

  @override
  Future<void> speak(String text) async {
    if (!await isVoiceInstalled()) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}