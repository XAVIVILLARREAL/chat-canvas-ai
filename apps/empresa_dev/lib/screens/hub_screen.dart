import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ssh_core/sync_snapshot.dart';
import 'package:warp_core/warp_core.dart';
import '../services/hub_server.dart';
import '../services/sync_client.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_panel.dart';

class HubScreen extends StatefulWidget {
  final Future<SyncSnapshot> Function() getSnapshot;

  /// Warp-mode sync (8.5): el hub exporta snippets en su snapshot y el cliente
  /// los mergea (LWW por updatedAt) en el store local.
  final SnippetStore? snippetStore;

  const HubScreen({super.key, required this.getSnapshot, this.snippetStore});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

enum _Mode { idle, hub, client }

class _HubScreenState extends State<HubScreen> {
  _Mode _mode = _Mode.idle;
  HubServer? _server;
  SyncClient? _client;
  final _tokenController = TextEditingController(text: '');
  final _urlController = TextEditingController(text: '100.x.y.z:8170');
  String _status = 'Elige un modo';
  String? _hubIp;
  int? _hubPort;
  StreamSubscription<SyncSnapshot>? _sub;

  @override
  void dispose() {
    _server?.stop();
    _client?.disconnect();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _startHub() async {
    final token = _tokenController.text.trim();
    if (token.length < 8) {
      setState(() => _status = 'El token debe tener al menos 8 caracteres');
      return;
    }
    final server = HubServer();
    await server.start(token: token, bindIp: '0.0.0.0', port: 8170);
    final snap = await widget.getSnapshot();
    snap.snippets.addAll(await widget.snippetStore?.exportRecords() ?? const []);
    server.updateSnapshot(snap);

    _sub = server.onChange.listen((s) {
      if (mounted) setState(() => _status = 'Snapshot versión ${s.version} propagada');
    });

    setState(() {
      _mode = _Mode.hub;
      _server = server;
      _hubPort = server.port;
      _hubIp = _guessHubIp();
      _status = 'Hub activo';
    });
  }

  String _guessHubIp() {
    // En producción se muestra la IP de Tailscale configurada; placeholder simple.
    return '0.0.0.0';
  }

  Future<void> _connectClient() async {
    var url = _urlController.text.trim();
    final token = _tokenController.text.trim();
    if (!url.startsWith('http')) url = 'http://$url';
    if (token.isEmpty) {
      setState(() => _status = 'Pega el token del hub');
      return;
    }
    final client = SyncClient();
    setState(() => _status = 'Conectando a $url…');
    final ok = await client.connect(url, token);
    if (!ok) {
      setState(() {
        _mode = _Mode.idle;
        _status = 'No se pudo conectar al hub';
      });
      return;
    }
    _sub = client.onRemote.listen((s) {
      widget.snippetStore?.mergeRecords(s.snippets);
      if (mounted) {
        setState(() {
          _status = 'Sincronizado: versión ${s.version}, ${s.hosts.length} hosts, ${s.nodes.length} nodos, ${s.snippets.length} snippets';
        });
      }
    });
    setState(() {
      _mode = _Mode.client;
      _client = client;
      _status = 'Conectado al hub (versión ${client.snapshot?.version ?? '?'})';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: const Text('Hub de sincronización', style: TextStyle(fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassPanel(
            glow: AppColors.neonCyan,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cell_tower, color: AppColors.neonCyan, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'El celular como servidor',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Sincroniza hosts, canva y sesiones entre tus dispositivos vía Tailscale.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tokenController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Token de emparejamiento',
              hintText: 'mínimo 8 caracteres',
            ),
          ),
          if (_mode != _Mode.hub) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'IP del hub (solo cliente)',
                hintText: '100.x.y.z:8170',
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _mode == _Mode.hub ? null : _startHub,
                  icon: const Icon(Icons.cell_tower),
                  label: const Text('Ser el hub (celular)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _mode == _Mode.client ? null : _connectClient,
                  icon: const Icon(Icons.sync),
                  label: const Text('Conectar como cliente (laptop)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _StatusCard(mode: _mode, status: _status, port: _hubPort),
        ],
      ),
    );
  }

  String get ip {
    return _hubIp ?? '0.0.0.0';
  }
}

/// Tarjeta de estado del hub con luz de color según el modo.
class _StatusCard extends StatelessWidget {
  final _Mode mode;
  final String status;
  final int? port;

  const _StatusCard({required this.mode, required this.status, this.port});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (mode) {
      _Mode.hub => (Icons.cell_tower, AppColors.neonGreen, 'SERVIDOR'),
      _Mode.client => (Icons.sync, AppColors.neonCyan, 'CLIENTE'),
      _Mode.idle => (Icons.power_settings_new, AppColors.textFaint, 'SIN CONEXIÓN'),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: mode == _Mode.idle
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 22,
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                ),
                child: Icon(icon, color: color, size: 15),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1)),
            ],
          ),
          const SizedBox(height: 10),
          Text(status,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
          if (mode == _Mode.hub && port != null) ...[
            const SizedBox(height: 8),
            Text('Hub escuchando en: 0.0.0.0:$port',
                style: const TextStyle(
                    color: AppColors.neonCyan, fontFamily: 'monospace')),
          ],
        ],
      ),
    );
  }
}
