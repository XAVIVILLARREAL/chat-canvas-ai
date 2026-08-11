import 'dart:io';

import 'package:flutter/material.dart';
import 'services/ssh_service.dart';
import 'services/canva_store.dart';
import 'services/sessions_store.dart';
import 'package:ssh_core/sync_snapshot.dart';
import 'screens/canva_screen.dart';
import 'screens/tabs_screen.dart';
import 'screens/hub_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/neon_backdrop.dart';

void main() {
  runApp(const EmpresaDevApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class EmpresaDevApp extends StatelessWidget {
  const EmpresaDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Empresa Dev',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: buildFuturisticTheme(),
      home: const NeonBackdrop(child: HostsScreen()),
    );
  }
}

class HostsScreen extends StatefulWidget {
  const HostsScreen({super.key});

  @override
  State<HostsScreen> createState() => _HostsScreenState();
}

class _HostsScreenState extends State<HostsScreen> {
  final SshService _service = SshService();
  final SessionsStore _sessionsStore = SessionsStore();
  String _view = 'tabs'; // 'tabs' | 'canva'
  final List<SshHost> _hosts = [
    SshHost(
      name: 'pve',
      host: '100.101.69.79', // Tailscale — alcanzable desde cualquier lugar
      port: 22,
      username: 'root',
      password: '',
      authType: SshAuthType.key,
      keyPem: _readLocalTestKey(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _sessionsStore.load().then((_) {
      if (mounted) setState(() => _view = _sessionsStore.lastTab);
    });
  }

  // Para pruebas locales en Windows: lee la llave instalada en pve.
  // En producción se importa/genera desde la UI (Fase 1.2).
  static String? _readLocalTestKey() {
    try {
      final f = File('test/fixtures/app_test_key');
      if (f.existsSync()) return f.readAsStringSync();
    } catch (_) {}
    return null;
  }

  Future<void> _addHost() async {
    final result = await showDialog<SshHost>(
      context: context,
      builder: (ctx) => const _HostFormDialog(),
    );
    if (result != null) {
      setState(() => _hosts.add(result));
    }
  }

  Future<SyncSnapshot> _buildSnapshot() async {
    final canva = await CanvaStore().load();
    return SyncSnapshot(
      version: 1,
      hosts: _hosts
          .map((h) => HostRecord(
                id: h.name,
                name: h.name,
                host: h.host,
                port: h.port,
                username: h.username,
                authType: h.authType.name,
              ))
          .toList(),
      nodes: canva.nodes,
      edges: canva.edges,
      sessions: [],
    );
  }

  void _openHub() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HubScreen(getSnapshot: () async => _buildSnapshot()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        child: Image(
                          image: AssetImage('assets/logo/logo.png'),
                          width: 30,
                          height: 30,
                        ),
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Empresa Dev', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('Terminal SSH · supervitaminas', style: TextStyle(fontSize: 12, color: Colors.white54)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.cell_tower, color: Colors.greenAccent),
                  onPressed: _openHub,
                  tooltip: 'Hub de sync',
                ),
              ],
            ),
          ),
          // Conmutador de vista: Tabs | Canva
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'tabs',
                        label: Text('Tabs'),
                        icon: Icon(Icons.tab, size: 16),
                      ),
                      ButtonSegment(
                        value: 'canva',
                        label: Text('Canva'),
                        icon: Icon(Icons.layers, size: 16),
                      ),
                    ],
                    selected: {_view},
                    onSelectionChanged: (sel) {
                      final v = sel.first;
                      setState(() => _view = v);
                      _sessionsStore.setLastTab(v);
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(const Color(0xFF1E293B)),
                      foregroundColor: const WidgetStatePropertyAll(Colors.white),
                      side: WidgetStatePropertyAll(const BorderSide(color: Color(0xFF334155))),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _view == 'canva'
                ? CanvaScreen(
                    hosts: _hosts,
                    sshService: _service,
                    store: CanvaStore(),
                  )
                : TabsScreen(
                    hosts: _hosts,
                    sshService: _service,
                    store: _sessionsStore,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHost,
        backgroundColor: Colors.lightBlueAccent,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HostFormDialog extends StatefulWidget {
  const _HostFormDialog();

  @override
  State<_HostFormDialog> createState() => _HostFormDialogState();
}

class _HostFormDialogState extends State<_HostFormDialog> {
  final _name = TextEditingController(text: 'pve');
  final _host = TextEditingController(text: '100.101.69.79');
  final _port = TextEditingController(text: '22');
  final _user = TextEditingController(text: 'root');
  final _password = TextEditingController();
  final _keyPem = TextEditingController();
  bool _useKey = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text('Agregar host', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre', labelStyle: TextStyle(color: Colors.white54)),
              style: const TextStyle(color: Colors.white)),
            TextField(controller: _host, decoration: const InputDecoration(labelText: 'Host / IP', labelStyle: TextStyle(color: Colors.white54)),
              style: const TextStyle(color: Colors.white)),
            TextField(controller: _port, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Puerto', labelStyle: TextStyle(color: Colors.white54)),
              style: const TextStyle(color: Colors.white)),
            TextField(controller: _user, decoration: const InputDecoration(labelText: 'Usuario', labelStyle: TextStyle(color: Colors.white54)),
              style: const TextStyle(color: Colors.white)),
            SwitchListTile(
              value: _useKey,
              onChanged: (v) => setState(() => _useKey = v),
              title: const Text('Usar llave', style: TextStyle(color: Colors.white54, fontSize: 14)),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            if (_useKey)
              TextField(controller: _keyPem,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Llave privada (PEM)', labelStyle: TextStyle(color: Colors.white54), hintText: '-----BEGIN OPENSSH PRIVATE KEY-----', hintStyle: TextStyle(color: Colors.white24)),
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 11))
            else
              TextField(controller: _password, obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: Colors.white54)),
                style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
        FilledButton(
          onPressed: () {
            final port = int.tryParse(_port.text) ?? 22;
            Navigator.pop(context, SshHost(
              name: _name.text,
              host: _host.text,
              port: port,
              username: _user.text,
              password: _password.text,
              authType: _useKey ? SshAuthType.key : SshAuthType.password,
              keyPem: _useKey ? _keyPem.text : null,
            ));
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.lightBlueAccent, foregroundColor: Colors.black),
          child: const Text('Conectar'),
        ),
      ],
    );
  }
}
