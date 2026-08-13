import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'ssh_service.dart';

/// Token efímero de proxy SSH: valor aleatorio + host + expiración. Nunca se
/// reutiliza más allá de su TTL y solo vale para un host.
class ProxyToken {
  final String value;
  final String hostId;
  final DateTime expiresAt;

  const ProxyToken(
      {required this.value, required this.hostId, required this.expiresAt});

  bool get expired => DateTime.now().isAfter(expiresAt);
}

class ProxyTokenStore {
  final Duration ttl;
  final Random _rng = Random.secure();
  final Map<String, ProxyToken> _issued = {};

  ProxyTokenStore({this.ttl = const Duration(minutes: 5)});

  ProxyToken issue(String hostId) {
    final bytes = List<int>.generate(32, (_) => _rng.nextInt(256));
    final value = base64UrlEncode(bytes);
    final token = ProxyToken(
      value: value,
      hostId: hostId,
      expiresAt: DateTime.now().add(ttl),
    );
    _issued[value] = token;
    return token;
  }

  bool validate(String token, String hostId) {
    final t = _issued[token];
    if (t == null) return false;
    if (t.expired) {
      _issued.remove(token);
      return false;
    }
    if (t.hostId != hostId) return false;
    return true;
  }
}

/// Canal bidireccional de un forward SSH: SOLO texto. La llave nunca viaja
/// por aquí — el `SshHost` con `keyPem` vive en el proceso del hub.
class SshForward {
  final SSHSession _shell;
  final StreamController<String> _output = StreamController<String>();

  /// Construye el forward sobre una sesión ya abierta (hub o tests).
  SshForward.forSession(SSHSession shell) : _shell = shell {
    _shell.stdout.listen((d) => _output.add(String.fromCharCodes(d)));
    _shell.stderr.listen((d) => _output.add(String.fromCharCodes(d)));
    _shell.done.then((_) => _output.close());
  }

  Stream<String> get output => _output.stream;

  void write(String text) {
    _shell.write(Uint8List.fromList(text.codeUnits));
  }

  Future<void> close() async {
    _shell.close();
    await _output.close();
  }
}

/// Abre forwards SSH por token efímero. El hub inyecta aquí sus hosts (con las
/// llaves) — el cliente solo obtiene el `SshForward` de texto.
class SshProxyService {
  final SshService sshService;
  final Map<String, SshHost> hosts;
  final ProxyTokenStore tokens;

  SshProxyService({
    required this.sshService,
    required this.hosts,
    ProxyTokenStore? tokens,
  }) : tokens = tokens ?? ProxyTokenStore();

  /// Valida el token y abre la sesión del host. Lanza si el token es inválido/
  /// expirado o el host no existe.
  Future<SshForward> openForward(String hostId, String token) async {
    final host = hosts[hostId];
    if (host == null) {
      throw StateError('Host desconocido: $hostId');
    }
    if (!tokens.validate(token, hostId)) {
      throw StateError('Token inválido o expirado para $hostId');
    }
    final shell = await sshService.connectShell(host);
    return SshForward.forSession(shell);
  }
}
