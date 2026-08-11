import 'package:flutter/material.dart';
import '../services/voice_service.dart';

/// Botón de micrófono: al mantenerlo pulsado graba, al soltar entrega la
/// transcripción por [onTranscript].
class VoiceMicButton extends StatefulWidget {
  final SpeechToTextVoice stt;
  final ValueChanged<String?> onTranscript;

  const VoiceMicButton({super.key, required this.stt, required this.onTranscript});

  @override
  State<VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends State<VoiceMicButton> {
  bool _recording = false;

  Future<void> _start() async {
    setState(() => _recording = true);
    final text = await widget.stt.listenOnce();
    if (mounted) {
      widget.onTranscript(text);
      setState(() => _recording = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _start(),
      onLongPressEnd: (_) async {
        widget.stt.stop();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _recording ? Colors.redAccent : Colors.white12,
        ),
        child: Icon(
          _recording ? Icons.mic : Icons.mic_none,
          color: _recording ? Colors.white : Colors.white70,
          size: 22,
        ),
      ),
    );
  }
}

/// Botón de altavoz: lee [text] con el TTS.
class SpeakerButton extends StatelessWidget {
  final TextToSpeechVoice tts;
  final String text;
  final bool compact;

  const SpeakerButton({super.key, required this.tts, required this.text, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.volume_up, color: Colors.white38, size: 16),
      tooltip: 'Leer en voz alta',
      onPressed: () => tts.speak(text),
      visualDensity: compact ? VisualDensity.compact : null,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 24),
    );
  }
}