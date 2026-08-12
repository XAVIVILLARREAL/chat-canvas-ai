import 'dart:io';

import 'package:flutter/material.dart';
import '../services/evidence_store.dart';
import '../theme/app_theme.dart';
import '../widgets/neon_card.dart';

class EvidenceScreen extends StatefulWidget {
  final EvidenceStore store;

  const EvidenceScreen({super.key, required this.store});

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  List<EvidenceRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await widget.store.list();
    if (!mounted) return;
    setState(() {
      _records = r;
      _loading = false;
    });
  }

  void _openRecord(EvidenceRecord r) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _EvidenceReader(record: r)),
    );
  }

  void _openInFolder(EvidenceRecord r) {
    if (!Platform.isWindows) return;
    Process.start('explorer', ['/select,', r.path]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: const Text('Evidencia', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(
                  child: Text('Sin evidencia todavía.\nHabla con un agente en el canva.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: _records.length,
                  itemBuilder: (ctx, i) {
                    final r = _records[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: NeonCard(
                        onTap: () => _openRecord(r),
                        glow: AppColors.neonViolet,
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadii.input),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.neonViolet,
                                  AppColors.neonCyan,
                                ],
                              ),
                            ),
                            child: const Icon(Icons.description,
                                color: Colors.white, size: 18),
                          ),
                          title: Text(r.prompt,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                          subtitle: Text(
                              '${r.agentName} · ${r.at.toString().substring(0, 16)}',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11)),
                          trailing: IconButton(
                            icon: const Icon(Icons.folder_open,
                                color: Colors.white54, size: 18),
                            onPressed: () => _openInFolder(r),
                            tooltip: 'Abrir carpeta',
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _EvidenceReader extends StatelessWidget {
  final EvidenceRecord record;

  const _EvidenceReader({required this.record});

  @override
  Widget build(BuildContext context) {
    String content = '';
    try {
      content = File(record.path).readAsStringSync();
    } catch (_) {}
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: Text(record.agentName, style: const TextStyle(fontSize: 16)),
      ),
      body: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgPanel,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.border),
        ),
        child: SingleChildScrollView(
          child: SelectableText(
            content,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
          ),
        ),
      ),
    );
  }
}