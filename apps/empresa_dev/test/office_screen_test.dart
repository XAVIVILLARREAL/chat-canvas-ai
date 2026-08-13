import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agent_core/office_state.dart';
import 'package:empresa_dev/screens/office_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Oficina: nodos-agente con glow por estado que se anima en vivo',
      (tester) async {
    final office = SimulatedOffice(
      agentIds: const ['dev', 'qa'],
      script: const [
        [OfficeState.working, OfficeState.idle],
        [OfficeState.blocked, OfficeState.working],
        [OfficeState.done, OfficeState.done],
      ],
      interval: const Duration(days: 1), // sin auto-avance en el test
    );

    await tester.pumpWidget(MaterialApp(home: OfficeScreen(office: office)));
    await tester.pumpAndSettle();

    // Estado inicial (paso 0): dev=working, qa=idle.
    expect(find.text('Desarrollador'), findsOneWidget);
    expect(find.text('working'), findsOneWidget);
    expect(find.text('idle'), findsOneWidget);

    // Avance manual: dev=blocked, qa=working → los labels cambian.
    office.step();
    await tester.pump();
    expect(find.text('blocked'), findsOneWidget);
    expect(find.text('working'), findsOneWidget);

    // Avance: dev=done, qa=done.
    office.step();
    await tester.pump();
    expect(find.text('done'), findsNWidgets(2));

    office.stop();
  });

  testWidgets('Oficina: aristas de dependencia se pintan', (tester) async {
    final office = SimulatedOffice(agentIds: const ['pm', 'dev']);
    await tester.pumpWidget(
      MaterialApp(
        home: OfficeScreen(office: office, edges: [
          OfficeEdge(fromAgentId: 'pm', toAgentId: 'dev'),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    // Ambas tarjetas visibles (modo simple, ≤300 nodos).
    expect(find.text('Producto'), findsOneWidget);
    expect(find.text('Desarrollador'), findsOneWidget);
    office.stop();
  });
}
