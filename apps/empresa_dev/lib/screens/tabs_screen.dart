import 'package:flutter/material.dart';
import 'package:ssh_core/session.dart';
import '../services/sessions_store.dart';
import '../services/ssh_service.dart';
import '../services/sftp_service.dart';
import 'terminal_screen.dart';
import 'sftp_screen.dart';

class TabsScreen extends StatefulWidget {
  final List<SshHost> hosts;
  final SshService sshService;
  final SessionsStore store;

  const TabsScreen({
    super.key,
    required this.hosts,
    required this.sshService,
    required this.store,
  });

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  List<DevSession> get _sessions => widget.store.sessions;

  Future<void> _openTerminal(SshHost host, DevSession session) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TerminalScreen(host: host, service: widget.sshService),
      ),
    );
  }

  /// Conexión SSH en un solo toque: crea la sesión si hace falta y abre el
  /// terminal directo. Es el flujo principal para el usuario.
  Future<void> _connectToHost(SshHost host) async {
    var session = _sessions.firstWhere(
      (s) => s.hostId == host.name && s.open,
      orElse: () => DevSession(id: '', title: '', hostId: ''),
    );
    if (session.id.isEmpty) {
      await widget.store.addSession(host.name, host.name);
      if (!mounted) return;
      setState(() {});
      session = _sessions.firstWhere((s) => s.hostId == host.name);
    }
    await _openTerminal(host, session);
  }

  Future<void> _openSftp(SshHost host) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SftpScreen(host: host, sftp: SftpService(widget.sshService)),
      ),
    );
  }

  Future<void> _closeSession(DevSession s) async {
    await widget.store.removeSession(s.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          // Barra de pestañas (sesiones abiertas)
          if (_sessions.isNotEmpty) _buildTabBar(),
          // Lista de hosts
          Expanded(child: _buildHostList()),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 44,
      color: const Color(0xFF0B1220),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: _sessions.length,
        itemBuilder: (ctx, i) {
          final s = _sessions[i];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Material(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.terminal, size: 14, color: Colors.lightBlueAccent),
                      const SizedBox(width: 6),
                      Text(s.title, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _closeSession(s),
                        child: const Icon(Icons.close, size: 14, color: Colors.white38),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHostList() {
    if (widget.hosts.isEmpty) {
      return const Center(child: Text('Sin hosts. Agrega uno.', style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: widget.hosts.length,
      itemBuilder: (ctx, i) {
        final h = widget.hosts[i];
        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.lightBlueAccent,
              foregroundColor: Colors.black,
              child: Icon(Icons.dns),
            ),
            title: Text(h.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text('${h.username}@${h.host}:${h.port}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () => _connectToHost(h),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.terminal, color: Colors.greenAccent, size: 20),
                  onPressed: () => _connectToHost(h),
                  tooltip: 'Conectar por SSH',
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open, color: Colors.amber, size: 20),
                  onPressed: () => _openSftp(h),
                  tooltip: 'SFTP',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
