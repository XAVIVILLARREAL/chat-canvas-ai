import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ssh_core/sync_snapshot.dart';
import '../services/hub_server.dart';
import '../services/sync_client.dart';

class HubScreen extends StatefulWidget {
  final Future<SyncSnapshot> Function() getSnapshot;

  const HubScreen({super.key, required this.getSnapshot});

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
      if (mounted) {
        setState(() {
          _status = 'Sincronizado: versión ${s.version}, ${s.hosts.length} hosts, ${s.nodes.length} nodos';
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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text('Hub de sincronización', style: TextStyle(fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'El celular como servidor. Sincroniza hosts, canva y sesiones entre tus dispositivos vía Tailscale.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tokenController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Token de emparejamiento',
              labelStyle: TextStyle(color: Colors.white54),
              border: OutlineInputBorder(),
            ),
          ),
          if (_mode != _Mode.hub) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'IP del hub (solo cliente)',
                labelStyle: TextStyle(color: Colors.white54),
                hintText: '100.x.y.z:8170',
                border: OutlineInputBorder(),
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
                  style: FilledButton.styleFrom(backgroundColor: Colors.lightBlueAccent, foregroundColor: Colors.black),
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
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.lightBlueAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _mode == _Mode.hub
                          ? Icons.cell_tower
                          : _mode == _Mode.client
                              ? Icons.sync
                              : Icons.power_settings_new,
                      color: _mode == _Mode.idle ? Colors.grey : Colors.greenAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text('Estado', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_status, style: const TextStyle(color: Colors.white, fontSize: 13)),
                if (_mode == _Mode.hub && _hubPort != null) ...[
                  const SizedBox(height: 8),
                  Text('Hub escuchando en: 0.0.0.0:$_hubPort',
                      style: const TextStyle(color: Colors.lightBlueAccent, fontFamily: 'monospace')),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get ip {
    return _hubIp ?? '0.0.0.0';
  }
}
