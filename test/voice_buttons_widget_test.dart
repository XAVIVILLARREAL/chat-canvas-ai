import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/services/voice_service.dart';
import 'package:empresa_dev/widgets/voice_buttons.dart';

class FakeStt extends SpeechToTextVoice {
  String? next;
  bool started = false;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String?> listenOnce() async {
    started = true;
    return next;
  }

  @override
  Future<void> stop() async {}
}

class FakeTts extends TextToSpeechVoice {
  String? lastSpoken;

  @override
  Future<bool> isVoiceInstalled() async => true;

  @override
  Future<void> speak(String text) async => lastSpoken = text;

  @override
  Future<void> stop() async {}
}

void main() {
  testWidgets('el micrófono inserta la transcripción en el input', (tester) async {
    final stt = FakeStt()..next = 'hola agente';
    final controller = TextEditingController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TextField(controller: controller),
            VoiceMicButton(stt: stt, onTranscript: (t) {
              if (t != null) controller.text = t;
            }),
          ],
        ),
      ),
    ));

    await tester.longPress(find.byType(VoiceMicButton));
    await tester.pump();

    expect(controller.text, 'hola agente');
  });

  testWidgets('el altavoz llama a speak con el texto de la burbuja', (tester) async {
    final tts = FakeTts();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SpeakerButton(tts: tts, text: 'respuesta del agente'),
      ),
    ));

    await tester.tap(find.byType(SpeakerButton));
    await tester.pump();

    expect(tts.lastSpoken, 'respuesta del agente');
  });
}