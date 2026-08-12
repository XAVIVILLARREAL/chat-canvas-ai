import 'package:flutter/material.dart';
import 'package:vibecoding_core/vibecoding_core.dart';
import '../services/vibecoding_store.dart';
import '../theme/app_theme.dart';
import '../widgets/diff_preview.dart';

/// Nodo-diff del canva: carga la propuesta [proposalId] del historial y
/// permite Aceptar/Rechazar/Revertir (mismos cambios quedan persistidos).
class ProposalNodeScreen extends StatefulWidget {
  final String proposalId;
  final VibecodingStore store;

  const ProposalNodeScreen({
    super.key,
    required this.proposalId,
    required this.store,
  });

  @override
  State<ProposalNodeScreen> createState() => _ProposalNodeScreenState();
}

class _ProposalNodeScreenState extends State<ProposalNodeScreen> {
  PatchProposal? _proposal;
  bool _loading = true;
  late final VibecodingPipeline _pipeline;

  @override
  void initState() {
    super.initState();
    _pipeline = VibecodingPipeline();
    _load();
  }

  @override
  void dispose() {
    _pipeline.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final saved = await widget.store.load();
    if (!mounted) return;
    setState(() {
      _proposal = saved.where((p) => p.id == widget.proposalId).firstOrNull;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    final p = _proposal;
    if (p == null) return;
    final saved = await widget.store.load();
    final idx = saved.indexWhere((x) => x.id == p.id);
    if (idx >= 0) {
      saved[idx] = p;
      await widget.store.save(saved);
    } else {
      await widget.store.save([...saved, p]);
    }
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

  Future<void> _apply() async {
    final p = _proposal!;
    try {
      await _pipeline.applyProposal(p);
    } catch (e) {
      if (!mounted) return;
      setState(() {});
      await _persist();
      _snack('No se pudo aplicar: $e', ok: false);
      return;
    }
    if (!mounted) return;
    setState(() {});
    await _persist();
    _snack('Cambios aplicados');
  }

  Future<void> _reject() async {
    final p = _proposal!;
    await _pipeline.rejectProposal(p);
    if (!mounted) return;
    setState(() {});
    await _persist();
    _snack('Propuesta rechazada');
  }

  Future<void> _revert() async {
    final p = _proposal!;
    try {
      await _pipeline.revertProposal(p);
    } catch (e) {
      if (!mounted) return;
      setState(() {});
      await _persist();
      _snack('No se pudo revertir: $e', ok: false);
      return;
    }
    if (!mounted) return;
    setState(() {});
    await _persist();
    _snack('Cambios revertidos');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(title: const Text('Nodo-diff · vibecoding')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _proposal == null
              ? const Center(
                  child: Text(
                    'Propuesta no encontrada en el historial.',
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    DiffPreview(
                      proposal: _proposal!,
                      onAccept: _apply,
                      onReject: _reject,
                      onRevert: _revert,
                    ),
                  ],
                ),
    );
  }
}
