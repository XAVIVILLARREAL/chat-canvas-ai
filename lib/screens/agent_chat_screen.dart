import 'dart:async';

import 'package:flutter/material.dart';
import '../models/agent.dart';
import '../services/agent_detector.dart';
import '../services/agent_runner.dart';
import '../services/evidence_store.dart';
import '../services/voice_service.dart';
import '../widgets/agent_state_badge.dart';
import '../widgets/voice_buttons.dart';
import 'evidence_screen.dart';

class AgentChatScreen extends StatefulWidget {
  final AgentSession session;
  final Future<void> Function(List<AgentSession>) store;
  final AgentRunner runner;
  final EvidenceStore? evidenceStore;
  final SpeechToTextVoice? stt;
  final TextToSpeechVoice? tts;

  const AgentChatScreen({
    super.key,
    required this.session,
    required this.store,
    required this.runner,
    this.evidenceStore,
    this.stt,
    this.tts,
  });

  @override
  State<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends State<AgentChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late AgentSession _session;
  bool _running = false;
  StreamSubscription<AgentRunLine>? _sub;
  AgentDetection _detection = const AgentDetection(AgentState.idle, null);
  final AgentDetector _detector = AgentDetector();

  @override
  void initState() {
    super.initState();
    _session = widget.session;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _running) return;
    _input.clear();
    setState(() => _running = true);

    final userMsg = AgentMessage(role: AgentRole.user, text: text, at: DateTime.now());
    _session = _session.copyWith(messages: [..._session.messages, userMsg]);
    await widget.store([_session]);

    final assistant = AgentMessage(
      role: AgentRole.assistant,
      text: '',
      at: DateTime.now(),
    );
    final buffer = StringBuffer();
    _sub = widget.runner.run(text).listen(
          (line) {
            buffer.write(line.content);
            if (line.isError) {
              setState(() {
                _session = _session.copyWith(
                  messages: [
                    ..._session.messages.where((m) => m != assistant),
                    AgentMessage(
                      role: AgentRole.error,
                      text: line.content,
                      at: DateTime.now(),
                    ),
                  ],
                );
              });
            } else {
              setState(() {
                _session = _session.copyWith(
                  messages: [
                    ..._session.messages.where((m) => m != assistant),
                    AgentMessage(
                      role: AgentRole.assistant,
                      text: line.content,
                      at: DateTime.now(),
                    ),
                  ],
                );
                _detection = _detector.detect(buffer.toString());
              });
            }
            _scrollToBottom();
          },
          onDone: () {
            _finish(buffer.toString());
          },
          onError: (e) {
            setState(() {
              _session = _session.copyWith(
                messages: [
                  ..._session.messages.where((m) => m != assistant),
                  AgentMessage(
                    role: AgentRole.error,
                    text: 'opencode no encontrado: $e',
                    at: DateTime.now(),
                  ),
                ],
              );
            });
            _finish(null);
          },
        );
  }

  Future<void> _finish(String? finalText) async {
    setState(() {
      if (finalText != null && finalText.trim().isNotEmpty) {
        final alreadyShown =
            _session.messages.any((m) => m.text == finalText.trim());
        if (!alreadyShown) {
          _session = _session.copyWith(
            messages: [
              ..._session.messages.where((m) =>
                  m.role != AgentRole.assistant || m.text != finalText),
              AgentMessage(
                role: AgentRole.assistant,
                text: finalText.trim(),
                at: DateTime.now(),
              ),
            ],
          );
        }
      }
      _running = false;
    });
    await widget.store([_session]);
    if (finalText != null && finalText.trim().isNotEmpty) {
      final store = widget.evidenceStore;
      if (store != null) {
        final prompt =
            _session.messages.lastWhere((m) => m.role == AgentRole.user).text;
        try {
          await store.save(_session, prompt: prompt);
        } catch (_) {}
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.smart_toy, color: Colors.purpleAccent, size: 20),
            const SizedBox(width: 8),
            Text('Agente ${_session.agentName}', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 12),
            AgentStateBadge(state: _detection.state),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined, color: Colors.white70, size: 20),
            tooltip: 'Evidencia',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EvidenceScreen(
                    store: widget.evidenceStore ?? EvidenceStore(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _session.messages.length,
              itemBuilder: (ctx, i) => _MessageBubble(
                message: _session.messages[i],
                tts: widget.tts,
              ),
            ),
          ),
          if (_running)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Pensando…', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            color: const Color(0xFF0F172A),
            child: Row(
              children: [
                VoiceMicButton(
                  stt: widget.stt ?? NativeStt(),
                  onTranscript: (t) {
                    if (t != null && t.isNotEmpty) _input.text = t;
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _input,
                    enabled: !_running,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Pregúntale al agente…',
                      hintStyle: TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _running ? null : _send,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AgentMessage message;
  final TextToSpeechVoice? tts;

  const _MessageBubble({required this.message, this.tts});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AgentRole.user;
    final isError = message.role == AgentRole.error;
    final color = isError
        ? const Color(0xFF7F1D1D)
        : isUser
            ? const Color(0xFF0EA5E9)
            : const Color(0xFF1E293B);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isError ? 0.6 : 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: SelectableText(
                message.text,
                style: TextStyle(
                  color: isError ? Colors.redAccent.shade100 : Colors.white,
                  fontSize: 13,
                  fontFamily: isUser ? null : 'monospace',
                  height: 1.4,
                ),
              ),
            ),
            if (!isUser && !isError && tts != null && message.text.trim().isNotEmpty)
              SpeakerButton(tts: tts!, text: message.text, compact: true),
          ],
        ),
      ),
    );
  }
}