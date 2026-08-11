@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:empresa_dev/services/agent_runner.dart';

/// Prueba de integración real: ejecuta opencode CLI y verifica que responde.
/// No corre en CI (requiere opencode instalado en el sistema).
void main() {
  group('OpenCodeAgentRunner (integración real)', () {
    test('ejecuta un prompt contra opencode y recibe respuesta', () async {
      final runner = OpenCodeAgentRunner();
      final lines = <AgentRunLine>[];
      await for (final line in runner.run('Responde únicamente con: HOLA_AGENTE_OK')) {
        lines.add(line);
      }
      final output = lines.map((l) => l.content).join('\n');
      expect(output, contains('HOLA_AGENTE_OK'));
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}