import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vibecoding_core/vibecoding_core.dart';
import '../services/vibecoding_service.dart';
import '../services/vibecoding_store.dart';
import '../theme/app_theme.dart';
import '../widgets/diff_preview.dart';

/// Vibecoding: el agente IA trabaja sobre el proyecto [projectPath]; cada
/// propuesta es un nodo-diff con Aceptar/Rechazar/Revertir y feedback.
/// El historial persiste en [store] (por defecto, disco local).
class VibecodingScreen extends StatefulWidget {
  final String projectPath;
  final AgentRunner? runner;
  final VibecodingStore? store;

  const VibecodingScreen({
    super.key,
    required this.projectPath,
    this.runner,
    this.store,
  });

  @override
  State<VibecodingScreen> createState() => _VibecodingScreenState();
}

class _VibecodingScreenState extends State<VibecodingScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<PatchProposal> _proposals = [];
  late final VibecodingPipeline _pipeline;
  late final AgentRunner _runner;
  late final VibecodingStore _store;
  bool _proposing = false;

  String get _projectName {
    final parts = widget.projectPath
        .replaceAll('\\', '/')
        .split('/')
        .where((s) => s.isNotEmpty);
    return parts.isEmpty ? widget.projectPath : parts.last;
  }

  @override
  void initState() {
    super.initState();
    _pipeline = VibecodingPipeline();
    _runner = widget.runner ?? AgentCommandRunnerAdapter();
    _store = widget.store ?? VibecodingStore();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final saved = await _store.load();
    if (!mounted) return;
    setState(() => _proposals.addAll(saved));
  }

  /// Persiste el historial tras cada mutación (proponer/aceptar/…).
  Future<void> _persist() => _store.save(_proposals);

  @override
  void dispose() {
    _pipeline.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _snack(String text, {bool ok = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        text,
        style: TextStyle(
          color: ok ? AppColors.neonGreen : Colors.redAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
    ));
  }

  Future<void> _propose() async {
    final prompt = _input.text.trim();
    if (prompt.isEmpty || _proposing) return;
    setState(() => _proposing = true);
    try {
      final proposal = await _pipeline.propose(
        prompt: prompt,
        repoPath: widget.projectPath,
        runner: _runner,
      );
      if (!mounted) return;
      setState(() {
        _input.clear();
        _proposals.insert(0, proposal);
      });
      unawaited(_persist());
      _snack('Propuesta generada (${proposal.edits.length} archivos)');
      _scrollToTop();
    } catch (e) {
      if (!mounted) return;
      _snack('$e', ok: false);
    } finally {
      if (mounted) setState(() => _proposing = false);
    }
  }

  Future<void> _apply(PatchProposal p) async {
    try {
      await _pipeline.applyProposal(p);
      if (!mounted) return;
      setState(() {});
      unawaited(_persist());
      _snack('Cambios aplicados');
    } catch (e) {
      if (!mounted) return;
      setState(() {});
      _snack('No se pudo aplicar: $e', ok: false);
    }
  }

  Future<void> _reject(PatchProposal p) async {
    await _pipeline.rejectProposal(p);
    if (!mounted) return;
    setState(() {});
    unawaited(_persist());
    _snack('Propuesta rechazada');
  }

  Future<void> _revert(PatchProposal p) async {
    try {
      await _pipeline.revertProposal(p);
      if (!mounted) return;
      setState(() {});
      unawaited(_persist());
      _snack('Cambios revertidos');
    } catch (e) {
      if (!mounted) return;
      setState(() {});
      _snack('No se pudo revertir: $e', ok: false);
    }
  }

  void _scrollToTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: const Text('Vibecoding'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                _projectName,
                style: const TextStyle(
                  color: AppColors.neonCyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('vibe-input'),
                    controller: _input,
                    enabled: !_proposing,
                    onSubmitted: (_) => _propose(),
                    decoration: const InputDecoration(
                      labelText: 'Prompt para el agente',
                      hintText: 'Ej: "añade un test para X en lib/…"',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  key: const Key('vibe-propose'),
                  onPressed: _proposing ? null : _propose,
                  child: _proposing
                      ? const SizedBox(
                          key: Key('vibe-loading'),
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Proponer'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _proposals.isEmpty
                ? const Center(
                    child: Text(
                      'Sin propuestas aún — escribe un prompt y deja que el '
                      'agente trabaje sobre el proyecto.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _proposals.length,
                    itemBuilder: (context, i) {
                      final p = _proposals[i];
                      return DiffPreview(
                        proposal: p,
                        onAccept: () => _apply(p),
                        onReject: () => _reject(p),
                        onRevert: () => _revert(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}