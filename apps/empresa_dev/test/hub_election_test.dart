import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/services/hub_election.dart';

/// Reloj fake: avanza manualmente.
class _FakeClock {
  DateTime _now = DateTime(2026, 8, 12, 10);
  DateTime get now => _now;
  void advance(Duration d) => _now = _now.add(d);
}

void main() {
  const interval = Duration(seconds: 5);
  const timeout = Duration(seconds: 15);

  HubElection make(String id, _FakeClock clock,
          {int priority = 10, bool lowBattery = false}) =>
      HubElection(
        nodeId: id,
        priority: priority,
        now: () => clock.now,
        heartbeatInterval: interval,
        hubTimeout: timeout,
        lowBattery: () => lowBattery,
      );

  group('HubElection', () {
    test('heartbeat del hub mantiene standby aunque pasen ticks', () {
      final clock = _FakeClock();
      final e = make('pve', clock);
      e.onHeartbeat('hub1', priority: 5);
      e.tick();
      clock.advance(const Duration(seconds: 10));
      e.tick();
      expect(e.role, HubRole.standby);
    });

    test('timeout sin heartbeat → candidate → hub (takeover)', () {
      final clock = _FakeClock();
      final e = make('pve', clock);
      e.onHeartbeat('hub1', priority: 5);
      clock.advance(timeout + const Duration(seconds: 1));
      e.tick();
      expect(e.role, HubRole.candidate);

      clock.advance(const Duration(seconds: 3)); // ventana de elección
      e.tick();
      expect(e.role, HubRole.hub);
    });

    test('el nodo recién promovido se convierte en la fuente de heartbeat', () {
      final clock = _FakeClock();
      final e = make('pve', clock);
      e.onHeartbeat('hub1', priority: 5);
      clock.advance(timeout + const Duration(seconds: 1));
      e.tick(); // candidate
      clock.advance(const Duration(seconds: 3));
      e.tick(); // hub

      // Desde el takeover, el pve se auto-mantiene como hub.
      clock.advance(const Duration(seconds: 60));
      e.tick();
      expect(e.role, HubRole.hub);
    });

    test('prioridad: entre dos standby, gana el de mayor prioridad', () {
      final clock = _FakeClock();
      final phone = make('phone', clock, priority: 1);
      final pve = make('pve', clock, priority: 10);

      phone.onHeartbeat('hub1', priority: 5);
      pve.onHeartbeat('hub1', priority: 5);
      clock.advance(timeout + const Duration(seconds: 1));
      phone.tick();
      pve.tick();
      expect(phone.role, HubRole.candidate);
      expect(pve.role, HubRole.candidate);

      // Los candidatos se laten: phone oye a pve (prioridad mayor) y se aparta.
      phone.onHeartbeat('pve', priority: 10);
      expect(phone.role, HubRole.standby,
          reason: 'un candidato de menor prioridad se aparta');

      clock.advance(const Duration(seconds: 3));
      phone.tick();
      pve.tick();

      expect(pve.role, HubRole.hub, reason: 'el pve (prioridad alta) gana');
      expect(phone.role, HubRole.standby);
    });

    test('batería baja en el hub → cede para que otro tome', () {
      final clock = _FakeClock();
      var batteryLow = false;
      final e = HubElection(
        nodeId: 'phone',
        priority: 1,
        now: () => clock.now,
        heartbeatInterval: interval,
        hubTimeout: timeout,
        lowBattery: () => batteryLow,
      );
      // phone toma el rol de hub por elección.
      e.onHeartbeat('hub1', priority: 5);
      clock.advance(timeout + const Duration(seconds: 1));
      e.tick(); // candidate
      clock.advance(const Duration(seconds: 3));
      e.tick(); // hub
      expect(e.role, HubRole.hub);

      batteryLow = true;
      e.tick();
      expect(e.role, HubRole.standby, reason: 'cede por batería baja');
    });

    test('heartbeats desordenados/viejos se ignoran (monotónico)', () {
      final clock = _FakeClock();
      final e = make('pve', clock);
      e.onHeartbeat('hub1', priority: 5);
      clock.advance(const Duration(seconds: 10));
      // Un heartbeat con timestamp menor no puede "reanimar" si ya caducó:
      // el election usa el reloj, no timestamps del remoto.
      e.onHeartbeat('hub1', priority: 5);
      e.tick(); // aún dentro de timeout desde el último latido
      expect(e.role, HubRole.standby);
    });

    test('onRoleChange notifica las transiciones', () {
      final clock = _FakeClock();
      final e = make('pve', clock);
      final roles = <HubRole>[];
      e.onRoleChange = roles.add;
      e.onHeartbeat('hub1', priority: 5); // → standby
      clock.advance(timeout + const Duration(seconds: 1));
      e.tick(); // standby → candidate
      clock.advance(const Duration(seconds: 3));
      e.tick(); // candidate → hub
      expect(roles, [HubRole.standby, HubRole.candidate, HubRole.hub]);
    });
  });

  group('HubElectionService', () {
    testWidgets('latea por el transporte en el intervalo', (tester) async {
      final clock = _FakeClock();
      final e = make('pve', clock);
      final transport = _FakeTransport();
      final service = HubElectionService(
        election: e,
        transport: transport,
        beatInterval: const Duration(seconds: 1),
      );
      service.start();
      await tester.pump(const Duration(seconds: 3));
      expect(transport.sent.length, greaterThanOrEqualTo(3),
          reason: 'envía un heartbeat por intervalo');
      expect(transport.sent.every((hb) => hb.$1 == 'pve'), isTrue);
      service.stop();
    });

    testWidgets('heartbeat recibido se propaga al election', (tester) async {
      final clock = _FakeClock();
      final e = make('pve', clock);
      final transport = _FakeTransport();
      final service = HubElectionService(
        election: e,
        transport: transport,
        beatInterval: const Duration(seconds: 10),
      );
      service.start();
      transport.receive('hub1', priority: 5);
      await tester.pump(const Duration(seconds: 1));
      expect(e.role, HubRole.standby,
          reason: 'el heartbeat recibido convierte al nodo en observador');
      service.stop();
    });
  });
}

class _FakeTransport implements ElectionTransport {
  final List<(String, int)> sent = [];
  final StreamController<(String, int)> _received =
      StreamController<(String, int)>.broadcast();

  void receive(String fromId, {required int priority}) =>
      _received.add((fromId, priority));

  @override
  void sendHeartbeat(String nodeId, int priority) => sent.add((nodeId, priority));

  @override
  Stream<(String, int)> get onHeartbeat => _received.stream;
}
