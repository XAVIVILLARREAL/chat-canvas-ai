import 'package:test/test.dart';
import 'package:agent_core/agent.dart';
import 'package:agent_core/agent_detector.dart';

void main() {
  test('AgentDetection clasifica blocked con el matcher de opencode', () {
    const output = 'Enter password: ********\n  [submit]';
    final detection = AgentDetector().detect(output);
    expect(detection.state, AgentState.blocked);
  });

  test('AgentMessage serializa round-trip', () {
    final m = AgentMessage(role: AgentRole.user, text: 'hola', at: DateTime(2026, 1, 1));
    final back = AgentMessage.fromJson(m.toJson());
    expect(back.text, 'hola');
    expect(back.role, AgentRole.user);
  });
}
