import 'package:flutter/material.dart';
import 'package:ssh_core/session.dart';
import '../services/sessions_store.dart';
import '../services/ssh_service.dart';
import '../services/sftp_service.dart';
import '../theme/app_theme.dart';
import '../widgets/neon_card.dart';
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
      backgroundColor: AppColors.bgDeep,
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
      height: 46,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        itemCount: _sessions.length,
        itemBuilder: (ctx, i) {
          final s = _sessions[i];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Material(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(AppRadii.chip),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadii.chip),
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.neonGreen.withValues(alpha: 0.15),
                        ),
                        child: const Icon(Icons.terminal,
                            size: 10, color: AppColors.neonGreen),
                      ),
                      const SizedBox(width: 6),
                      Text(s.title,
                          style: const TextStyle(color: Colors.white, fontSize: 12)),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _closeSession(s),
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(Icons.close, size: 14, color: Colors.white38),
                        ),
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgPanel,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.dns_outlined,
                  color: AppColors.textFaint, size: 34),
            ),
            const SizedBox(height: 16),
            const Text('Sin hosts todavía',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Toca + para agregar tu primer servidor',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 96),
      itemCount: widget.hosts.length,
      itemBuilder: (ctx, i) {
        final h = widget.hosts[i];
        final hasSession = _sessions.any((s) => s.hostId == h.name && s.open);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: NeonCard(
            onTap: () => _connectToHost(h),
            glow: hasSession ? AppColors.neonGreen : null,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.hostAvatar,
                  boxShadow: AppGlow.cyan(strength: 0.35, blur: 14),
                ),
                child: const Icon(Icons.dns, color: Colors.white, size: 22),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(h.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  if (hasSession)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.neonGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: AppColors.neonGreen.withValues(alpha: 0.4)),
                      ),
                      child: const Text('activa',
                          style: TextStyle(
                              color: AppColors.neonGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('${h.username}@${h.host}:${h.port}',
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontFamily: 'monospace')),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QuickAction(
                    icon: Icons.terminal,
                    color: AppColors.neonGreen,
                    tooltip: 'Conectar por SSH',
                    onTap: () => _connectToHost(h),
                  ),
                  _QuickAction(
                    icon: Icons.folder_open,
                    color: AppColors.neonAmber,
                    tooltip: 'SFTP',
                    onTap: () => _openSftp(h),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Botón de acción rápida compacto con hover y glow al pasar el cursor.
class _QuickAction extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _hovered ? 0.2 : 0.08),
          borderRadius: BorderRadius.circular(AppRadii.input),
          border: Border.all(color: widget.color.withValues(alpha: _hovered ? 0.6 : 0.25)),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadii.input),
          child: Tooltip(
            message: widget.tooltip,
            child: Icon(widget.icon, color: widget.color, size: 19),
          ),
        ),
      ),
    );
  }
}
