import 'package:flutter/material.dart';
import 'services/ssh_service.dart';
import 'services/sftp_service.dart';
import 'screens/terminal_screen.dart';
import 'screens/sftp_screen.dart';

void main() {
  runApp(const EmpresaDevApp());
}

class EmpresaDevApp extends StatelessWidget {
  const EmpresaDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Empresa Dev',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0EA5E9),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const HostsScreen(),
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
  final List<SshHost> _hosts = [
    SshHost(
      name: 'pve',
      host: '192.168.100.200',
      port: 22,
      username: 'root',
      password: '',
    ),
  ];

  Future<void> _addHost() async {
    final result = await showDialog<SshHost>(
      context: context,
      builder: (ctx) => const _HostFormDialog(),
    );
    if (result != null) {
      setState(() => _hosts.add(result));
    }
  }

  void _connect(SshHost host) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TerminalScreen(host: host, service: _service),
      ),
    );
  }

  void _openSftp(SshHost host) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SftpScreen(host: host, sftp: SftpService(_service)),
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
            child: const Row(
              children: [
                Icon(Icons.terminal, color: Colors.lightBlueAccent, size: 28),
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
          Expanded(
            child: _hosts.isEmpty
                ? const Center(child: Text('Sin hosts. Agrega uno con +', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: _hosts.length,
                    itemBuilder: (ctx, i) {
                      final h = _hosts[i];
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.folder_open, color: Colors.amber, size: 20),
                                onPressed: () => _openSftp(h),
                                tooltip: 'SFTP',
                              ),
                              FilledButton(
                                onPressed: () => _connect(h),
                                style: FilledButton.styleFrom(backgroundColor: Colors.lightBlueAccent, foregroundColor: Colors.black),
                                child: const Text('Conectar'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
