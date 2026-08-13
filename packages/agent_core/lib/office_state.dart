/// Estado de la oficina (Etapa 8.2): agentes-empleados con estados visibles,
/// alineados al task lifecycle de A2A (ADR-003). Dart puro, sin Flutter.
library;

import 'dart:async';

/// Listenable mínimo en Dart puro (sustituto de ValueNotifier sin Flutter).
class StatusNotifier<T> {
  T _value;

  T get value => _value;

  final Set<void Function()> _listeners = {};

  StatusNotifier(this._value);

  set value(T v) {
    if (identical(v, _value)) return;
    _value = v;
    for (final l in List.of(_listeners)) {
      l();
    }
  }

  void addListener(void Function() l) => _listeners.add(l);

  void removeListener(void Function() l) => _listeners.remove(l);

  int get listeners => _listeners.length;

  void dispose() => _listeners.clear();
}

/// Estados de la oficina (visión empresa autónoma / SUPER_PLAN 8.2).
enum OfficeState { idle, working, blocked, waitingApproval, done, failed }

/// Una transición de estado registrada (auditoría del nodo-agente).
class AgentTransition {
  final OfficeState state;
  final DateTime at;

  const AgentTransition(this.state, this.at);
}

/// Estado en vivo de un agente-empleado: id + rol + estado + historial corto
/// de transiciones. Mutable (la fuente de estados lo actualiza).
class AgentRuntimeStatus {
  final String agentId;
  final String label;
  OfficeState _state;
  final List<AgentTransition> _transitions = [];

  AgentRuntimeStatus(this.agentId, this.label,
      [OfficeState state = OfficeState.idle])
      : _state = state;

  OfficeState get state => _state;

  List<AgentTransition> get transitions => List.unmodifiable(_transitions);

  AgentTransition get lastTransition => _transitions.isEmpty
      ? AgentTransition(_state, DateTime.fromMillisecondsSinceEpoch(0))
      : _transitions.last;

  /// Cambia de estado (no-op si es el mismo) y registra la transición.
  void update(OfficeState next) {
    if (next == _state) return;
    _state = next;
    _transitions.add(AgentTransition(next, DateTime.now()));
  }

  Map<String, Object?> toJson() => {
        'agentId': agentId,
        'label': label,
        'state': _state.name,
        'transitions': [
          for (final t in _transitions)
            {'state': t.state.name, 'at': t.at.toIso8601String()},
        ],
      };

  factory AgentRuntimeStatus.fromJson(Map<String, Object?> j) {
    final a = AgentRuntimeStatus(
      j['agentId'] as String,
      j['label'] as String? ?? '',
    );
    a._state =
        OfficeState.values.byName(j['state'] as String? ?? 'idle');
    a._transitions.addAll([
      for (final t in (j['transitions'] as List? ?? []))
        AgentTransition(
          OfficeState.values.byName((t as Map)['state'] as String),
          DateTime.parse((t)['at'] as String),
        ),
    ]);
    return a;
  }
}

/// Fuente de estados de la oficina. La implementación real (seguimiento,
/// SDD-124 8.2.3) leerá el estado del grafo LangGraph por WebSocket
/// (hub → `empresa_autonoma/server.py`); la simulación es para demo/tests.
abstract class OfficeStatusSource {
  StatusNotifier<Map<String, AgentRuntimeStatus>> get statuses;

  void start();

  void stop();
}

/// Fuente simulada: recorre una secuencia guionada de estados por agente con un
/// temporizador. Reutilizable (demo, tests) sin el backend Python.
class SimulatedOffice implements OfficeStatusSource {
  final List<String> agentIds;
  final List<List<OfficeState>> script;
  final Duration interval;

  @override
  final StatusNotifier<Map<String, AgentRuntimeStatus>> statuses =
      StatusNotifier(const {});
  Timer? _timer;
  int _step = 0;

  SimulatedOffice({
    List<String>? agentIds,
    List<List<OfficeState>>? script,
    this.interval = const Duration(milliseconds: 300),
  })  : agentIds = agentIds ?? const ['dev', 'qa', 'devops'],
        script = script ?? defaultScript();

  /// Secuencia por defecto: dev hace working→blocked→working→done, qa en
  /// paralelo, devops avanza más lento.
  static List<List<OfficeState>> defaultScript() => const [
        [OfficeState.working, OfficeState.idle, OfficeState.idle],
        [OfficeState.blocked, OfficeState.working, OfficeState.idle],
        [
          OfficeState.working,
          OfficeState.waitingApproval,
          OfficeState.working
        ],
        [OfficeState.done, OfficeState.done, OfficeState.blocked],
      ];

  static String _labelFor(String id) => switch (id) {
        'dev' => 'Desarrollador',
        'qa' => 'QA',
        'devops' => 'DevOps',
        'pm' => 'Producto',
        _ => id,
      };

  @override
  void start() {
    if (_timer != null) return;
    _apply(0);
    _timer = Timer.periodic(interval, (_) => step());
  }

  /// Avanza un paso de la secuencia (manual o por el temporizador).
  void step() {
    _step = (_step + 1) % script.length;
    _apply(_step);
  }

  void _apply(int stepIdx) {
    final map = <String, AgentRuntimeStatus>{};
    for (var i = 0; i < agentIds.length; i++) {
      final id = agentIds[i];
      final a = statuses.value[id] ??
          AgentRuntimeStatus(id, _labelFor(id));
      final next = script[stepIdx][i];
      if (a.state != next) a.update(next);
      map[id] = a;
    }
    statuses.value = map;
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
