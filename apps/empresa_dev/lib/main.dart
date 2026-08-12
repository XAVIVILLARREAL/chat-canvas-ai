import 'dart:io';

import 'package:flutter/material.dart';
import 'services/ssh_service.dart';
import 'services/canva_store.dart';
import 'services/e2e_flags.dart';
import 'services/sessions_store.dart';
import 'package:ssh_core/sync_snapshot.dart';
import 'screens/canva_screen.dart';
import 'screens/tabs_screen.dart';
import 'screens/hub_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/glass_panel.dart';
import 'widgets/neon_backdrop.dart';
import 'widgets/neon_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ensureE2ESemantics();
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
    final result = await showNeonDialog<SshHost>(
      context: context,
      glow: AppColors.neonCyan,
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            // Conmutador de vista: Tabs | Canva
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
      ),
      floatingActionButton: _NeonFab(onPressed: _addHost),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        radius: AppRadii.card,
        glow: AppColors.neonCyan,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.input),
                gradient: AppGradients.hostAvatar,
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                boxShadow: AppGlow.cyan(strength: 0.4, blur: 16),
              ),
              clipBehavior: Clip.antiAlias,
              child: const Image(
                image: AssetImage('assets/logo/logo.png'),
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => AppGradients.neon.createShader(bounds),
                    child: const Text(
                      'Empresa Dev',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Text(
                    'Terminal SSH · supervitaminas',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ),
            _HubPill(onTap: _openHub),
          ],
        ),
      ),
    );
  }
}

/// Píldora de acceso al hub de sincronización con luz de estado.
class _HubPill extends StatelessWidget {
  final VoidCallback onTap;

  const _HubPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Hub de sync',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: AppColors.neonGreen.withValues(alpha: 0.08),
              border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.35)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulseDot(),
                SizedBox(width: 6),
                Text('Hub',
                    style: TextStyle(
                        color: AppColors.neonGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Punto verde animado (pulso suave) indicando que el hub está disponible.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.neonGreen,
          boxShadow: AppGlow.green(strength: 0.7, blur: 8),
        ),
      ),
    );
  }
}

/// FAB de cristal con gradiente neón y glow.
class _NeonFab extends StatelessWidget {
  final VoidCallback onPressed;

  const _NeonFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.neon,
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonCyan.withValues(alpha: 0.45),
                blurRadius: 20,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: AppColors.neonViolet.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Color(0xFF062A33), size: 30),
        ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.input),
                gradient: AppGradients.hostAvatar,
                boxShadow: AppGlow.cyan(strength: 0.35, blur: 14),
              ),
              child: const Icon(Icons.dns, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Agregar host',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre')),
        const SizedBox(height: 12),
        TextField(controller: _host, decoration: const InputDecoration(labelText: 'Host / IP')),
        const SizedBox(height: 12),
        TextField(
          controller: _port,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Puerto'),
        ),
        const SizedBox(height: 12),
        TextField(controller: _user, decoration: const InputDecoration(labelText: 'Usuario')),
        SwitchListTile(
          value: _useKey,
          onChanged: (v) => setState(() => _useKey = v),
          title: const Text('Usar llave', style: TextStyle(fontSize: 14)),
          subtitle: const Text('PEM privado (recomendado)', style: TextStyle(fontSize: 11, color: Colors.white38)),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        if (_useKey)
          TextField(
            controller: _keyPem,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Llave privada (PEM)',
              hintText: '-----BEGIN OPENSSH PRIVATE KEY-----',
              hintStyle: TextStyle(color: Colors.white24),
            ),
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
          )
        else
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
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
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Conectar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
