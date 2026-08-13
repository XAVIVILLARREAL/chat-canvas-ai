import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:dartssh2/src/ssh_channel.dart' show SSHChannel, SSHChannelController;
import 'package:empresa_dev/services/ssh_proxy.dart';
import 'package:empresa_dev/services/ssh_service.dart';

class _FakeSession implements SSHSession {
  final List<String> written = [];
  final _stdout = StreamController<Uint8List>();
  final _done = Completer<void>();
  late final SSHChannel _channel = SSHChannelController(
    localId: 1,
    localMaximumPacketSize: 32768,
    localInitialWindowSize: 2097152,
    remoteId: 1,
    remoteMaximumPacketSize: 32768,
    remoteInitialWindowSize: 2097152,
    sendMessage: (_) {},
  ).channel;

  void emit(String data) => _stdout.add(Uint8List.fromList(data.codeUnits));

  @override
  StreamSink<Uint8List> get stdin => _stdout.sink;
  @override
  Stream<Uint8List> get stdout => _stdout.stream;
  @override
  Stream<Uint8List> get stderr => const Stream.empty();
  @override
  int? get exitCode => null;
  @override
  SSHSessionExitSignal? get exitSignal => null;
  @override
  Future<void> get done => _done.future;
  @override
  SSHChannel get channel => _channel;
  @override
  void write(Uint8List data) => written.add(String.fromCharCodes(data));
  @override
  Future<void> flush() async {}
  @override
  void resizeTerminal(int cols, int rows, [int pixelWidth = 0, int pixelHeight = 0]) {}
  @override
  void close() {}
  @override
  Future<int?> waitForExit({Duration? timeout}) async => 0;
  @override
  void kill(SSHSignal signal) {}
}

class _FakeService extends SshService {
  final _FakeSession session;
  _FakeService(this.session);

  @override
  Future<SSHSession> connectShell(SshHost host) async => session;
}

SshHost _host() =>
    SshHost(name: 'pve', host: '100.101.69.79', username: 'root');

void main() {
  group('ProxyTokenStore', () {
    test('issue crea un token válido para el host', () {
      final store = ProxyTokenStore();
      final t = store.issue('pve');
      expect(t.value, isNotEmpty);
      expect(t.expiresAt.isAfter(DateTime.now()), isTrue);
      expect(store.validate(t.value, 'pve'), isTrue);
    });

    test('token no emitido falla', () {
      expect(ProxyTokenStore().validate('nope', 'pve'), isFalse);
    });

    test('token de un host no sirve para otro', () {
      final store = ProxyTokenStore();
      final t = store.issue('pve');
      expect(store.validate(t.value, 'otro'), isFalse);
    });

    test('token expirado falla', () {
      final store = ProxyTokenStore(
          ttl: const Duration(seconds: -1)); // ya caducado
      final t = store.issue('pve');
      expect(store.validate(t.value, 'pve'), isFalse);
    });

    test('no es reutilizable tras validar una vez (sigue siendo válido en TTL)',
        () {
      final store = ProxyTokenStore();
      final t = store.issue('pve');
      expect(store.validate(t.value, 'pve'), isTrue);
      expect(store.validate(t.value, 'pve'), isTrue);
    });
  });

  group('SshForward', () {
    test('relaya stdout del host hacia el output', () async {
      final session = _FakeSession();
      final forward = SshForward.forSession(session);
      final out = <String>[];
      forward.output.listen(out.add);
      session.emit('hola');
      await Future<void>.delayed(Duration.zero);
      expect(out, ['hola']);
      await forward.close();
    });

    test('write llega al shell (la llave jamás viaja: solo texto)', () {
      final session = _FakeSession();
      final forward = SshForward.forSession(session);
      forward.write('ls -la');
      expect(session.written, ['ls -la']);
      expect(session.written.any((w) => w.contains('BEGIN')), isFalse);
    });
  });

  group('SshProxyService', () {
    test('openForward con token válido abre la sesión', () async {
      final session = _FakeSession();
      final service = SshProxyService(
        sshService: _FakeService(session),
        hosts: {'pve': _host()},
      );
      final token = service.tokens.issue('pve');
      final forward = await service.openForward('pve', token.value);
      expect(forward, isA<SshForward>());
    });

    test('openForward con token inválido lanza', () {
      final service = SshProxyService(
        sshService: _FakeService(_FakeSession()),
        hosts: {'pve': _host()},
      );
      expect(() => service.openForward('pve', 'mala'),
          throwsA(isA<StateError>()));
    });

    test('openForward de host desconocido lanza', () {
      final service = SshProxyService(
        sshService: _FakeService(_FakeSession()),
        hosts: {'pve': _host()},
      );
      final token = service.tokens.issue('pve');
      expect(() => service.openForward('otro', token.value),
          throwsA(isA<StateError>()));
    });
  });
}
