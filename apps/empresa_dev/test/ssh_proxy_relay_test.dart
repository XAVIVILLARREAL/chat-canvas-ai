import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:dartssh2/src/ssh_channel.dart' show SSHChannel, SSHChannelController;
import 'package:empresa_dev/services/hub_server.dart';
import 'package:empresa_dev/services/ssh_proxy.dart';
import 'package:empresa_dev/services/ssh_proxy_client.dart';
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

void main() {
  const hubToken = 'token-de-prueba-largo';

  late HubServer hub;
  late _FakeSession session;

  setUp(() async {
    session = _FakeSession();
    hub = HubServer()
      ..proxy = SshProxyService(
        sshService: _FakeService(session),
        hosts: {'pve': SshHost(name: 'pve', host: '127.0.0.1', username: 'root')},
      );
    await hub.start(token: hubToken, bindIp: '127.0.0.1', port: 0);
  });

  tearDown(() async {
    await hub.stop();
  });

  Future<WebSocket> connectWs() =>
      WebSocket.connect('ws://127.0.0.1:${hub.port}/ws',
          headers: {'Authorization': 'Bearer $hubToken'});

  test('relay: open con token válido → opened + write/data', () async {
    final t = hub.proxy!.tokens.issue('pve');

    final ws = await connectWs();
    final msgs = <Map<String, dynamic>>[];
    ws.listen((d) => msgs.add(jsonDecode(d as String) as Map<String, dynamic>));

    ws.add(jsonEncode(
        {'type': 'ssh', 'action': 'open', 'hostId': 'pve', 'token': t.value}));
    await _waitUntil(() => msgs.any((m) => m['action'] == 'opened'));

    ws.add(jsonEncode(
        {'type': 'ssh', 'action': 'write', 'hostId': 'pve', 'data': 'ls -la'}));
    await _waitUntil(() => session.written.isNotEmpty);
    expect(session.written, ['ls -la']);
    expect(session.written.any((w) => w.contains('BEGIN')), isFalse,
        reason: 'la llave nunca viaja por el proxy');

    session.emit('root@pve:~#');
    await _waitUntil(() => msgs.any((m) => m['action'] == 'data'));
    expect(msgs.any((m) =>
        m['action'] == 'data' && (m['data'] as String).contains('root')), isTrue);

    ws.add(jsonEncode({'type': 'ssh', 'action': 'close', 'hostId': 'pve'}));
    await ws.close();
  });

  test('relay: token inválido → error', () async {
    final ws = await connectWs();
    final msgs = <Map<String, dynamic>>[];
    ws.listen((d) => msgs.add(jsonDecode(d as String) as Map<String, dynamic>));
    ws.add(jsonEncode(
        {'type': 'ssh', 'action': 'open', 'hostId': 'pve', 'token': 'mala'}));
    await _waitUntil(() => msgs.any((m) => m['action'] == 'error'));
    await ws.close();
  });

  test('SshProxyClient abre y relaya contra el hub real', () async {
    final t = hub.proxy!.tokens.issue('pve');

    final client = SshProxyClient();
    expect(await client.connect('http://127.0.0.1:${hub.port}', hubToken), isTrue);
    final data = <String>[];
    client.output.listen(data.add);
    expect(await client.open('pve', t.value), isTrue, reason: 'opened');

    client.write('uptime');
    await _waitUntil(() => session.written.isNotEmpty);
    expect(session.written, ['uptime']);

    session.emit(' 12:00:00 up 3 days');
    await _waitUntil(() => data.any((d) => d.contains('up 3 days')));
    expect(data.any((d) => d.contains('up 3 days')), isTrue);

    await client.close();
  });
}

Future<void> _waitUntil(bool Function() cond,
    {Duration timeout = const Duration(seconds: 5)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!cond() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  expect(cond(), isTrue, reason: 'condición no se cumplió a tiempo');
}
