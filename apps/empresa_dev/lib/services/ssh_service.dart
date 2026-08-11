import 'package:dartssh2/dartssh2.dart';

enum SshAuthType { password, key }

class SshHost {
  final String host;
  final int port;
  final String username;
  final String password;
  final String name;
  final SshAuthType authType;
  final String? keyPem;
  final String? folder;
  final String? color;

  SshHost({
    required this.host,
    this.port = 22,
    required this.username,
    this.password = '',
    required this.name,
    this.authType = SshAuthType.password,
    this.keyPem,
    this.folder,
    this.color,
  });

  SshHost copyWith({
    String? host,
    int? port,
    String? username,
    String? password,
    String? name,
    SshAuthType? authType,
    String? keyPem,
    String? folder,
    String? color,
  }) {
    return SshHost(
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      name: name ?? this.name,
      authType: authType ?? this.authType,
      keyPem: keyPem ?? this.keyPem,
      folder: folder ?? this.folder,
      color: color ?? this.color,
    );
  }
}

class SshService {
  SSHClient? _client;
  SSHClient? get client => _client;

  Future<SSHClient> connect(SshHost host, {String? keyPem, String? passphrase}) async {
    await disconnect();

    final socket = await SSHSocket.connect(host.host, host.port);
    final identities = <SSHKeyPair>[];
    final pem = keyPem ?? host.keyPem;
    if (pem != null && pem.trim().isNotEmpty) {
      identities.addAll(SSHKeyPair.fromPem(pem, passphrase));
    }

    _client = SSHClient(
      socket,
      username: host.username,
      onPasswordRequest: () => host.password,
      identities: identities.isNotEmpty ? identities : null,
      disableHostkeyVerification: true,
    );

    await _client!.authenticated;
    return _client!;
  }

  Future<SSHSession> connectShell(SshHost host) async {
    final client = await connect(host);
    return client.shell();
  }

  Future<SftpClient?> connectSftp(SshHost host) async {
    final client = await connect(host);
    try {
      return await client.sftp();
    } catch (_) {
      return null;
    }
  }

  Future<void> disconnect() async {
    _client?.close();
    _client = null;
  }
}
