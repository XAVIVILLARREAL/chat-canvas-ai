import 'package:dartssh2/dartssh2.dart';

class SshHost {
  final String host;
  final int port;
  final String username;
  final String password;
  final String name;

  SshHost({
    required this.host,
    this.port = 22,
    required this.username,
    this.password = '',
    required this.name,
  });
}

class SshService {
  SSHClient? _client;

  Future<SSHSession> connectShell(SshHost host) async {
    await disconnect();

    final socket = await SSHSocket.connect(host.host, host.port);
    _client = SSHClient(
      socket,
      username: host.username,
      onPasswordRequest: () => host.password,
      // TODO(hub): verificar host key contra known_hosts (Fase 1.4)
      disableHostkeyVerification: true,
    );

    await _client!.authenticated;

    final shell = await _client!.shell();
    return shell;
  }

  Future<void> disconnect() async {
    _client?.close();
    _client = null;
  }
}
