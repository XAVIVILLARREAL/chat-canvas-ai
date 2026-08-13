import 'package:test/test.dart';
import 'package:agent_core/office_state.dart';

void main() {
  group('StatusNotifier', () {
    test('notifica a los listeners al cambiar', () {
      final n = StatusNotifier<int>(1);
      var seen = <int>[];
      n.addListener(() => seen.add(n.value));
      n.value = 2;
      n.value = 3;
      expect(seen, [2, 3]);
    });

    test('set con el mismo valor no notifica', () {
      final n = StatusNotifier<int>(1);
      var calls = 0;
      n.addListener(() => calls++);
      n.value = 1;
      expect(calls, 0);
    });

    test('removeListener y dispose', () {
      final n = StatusNotifier<int>(1);
      var calls = 0;
      void l() => calls++;
      n.addListener(l);
      n.removeListener(l);
      n.value = 2;
      expect(calls, 0);
      n.dispose();
      expect(n.listeners, 0);
    });
  });

  group('AgentRuntimeStatus', () {
    test('update cambia estado y registra la transición', () {
      final a = AgentRuntimeStatus('dev', 'Desarrollador');
      expect(a.state, OfficeState.idle);
      a.update(OfficeState.working);
      expect(a.state, OfficeState.working);
      expect(a.lastTransition.state, OfficeState.working);
      expect(a.lastTransition.at, isA<DateTime>());
    });

    test('update con el mismo estado no registra transición', () {
      final a = AgentRuntimeStatus('dev', 'Desarrollador');
      a.update(OfficeState.working);
      a.update(OfficeState.working);
      expect(a.transitions.length, 1);
    });

    test('toJson/fromJson round-trip', () {
      final a = AgentRuntimeStatus('qa', 'QA')
        ..update(OfficeState.blocked);
      final back = AgentRuntimeStatus.fromJson(a.toJson());
      expect(back.agentId, 'qa');
      expect(back.state, OfficeState.blocked);
      expect(back.transitions.length, a.transitions.length);
    });
  });

  group('OfficeStatusSource', () {
    test('contrato: statuses notificable + start/stop', () async {
      final source = SimulatedOffice();
      final seen = <Map<String, AgentRuntimeStatus>>[];
      source.statuses.addListener(() => seen.add(source.statuses.value));
      source.start();
      await Future<void>.delayed(Duration.zero);
      expect(seen, isNotEmpty, reason: 'start emite el estado inicial');
      source.step();
      expect(seen.length, greaterThanOrEqualTo(2));
      source.stop();
    });
  });
}
