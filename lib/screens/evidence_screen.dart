import 'dart:io';

import 'package:flutter/material.dart';
import '../services/evidence_store.dart';

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
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
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
                  padding: const EdgeInsets.all(12),
                  itemCount: _records.length,
                  itemBuilder: (ctx, i) {
                    final r = _records[i];
                    return Card(
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.description, color: Colors.purpleAccent),
                        title: Text(r.prompt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 13)),
                        subtitle: Text('${r.agentName} · ${r.at.toString().substring(0, 16)}',
                            style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.folder_open, color: Colors.white54, size: 18),
                          onPressed: () => _openInFolder(r),
                          tooltip: 'Abrir carpeta',
                        ),
                        onTap: () => _openRecord(r),
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
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Text(record.agentName, style: const TextStyle(fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          content,
          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
        ),
      ),
    );
  }
}