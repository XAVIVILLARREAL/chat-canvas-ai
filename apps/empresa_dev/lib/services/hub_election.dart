import 'dart:async';

/// Rol de un nodo en la elección del hub (Etapa 8.3).
enum HubRole { idle, hub, standby, candidate }

/// Elección de hub con heartbeat + prioridad + takeover (failover).
///
/// Lógica pura y testeable: el reloj se inyecta ([now]), la batería se consulta
/// por callback ([lowBattery]). El transporte (Tailscale/hub WS) lo cablea
/// [HubElectionService].
///
/// Reglas:
/// - `standby` recibe heartbeats del hub actual; si pasa [hubTimeout] sin uno,
///   pasa a `candidate` y, tras la ventana de elección, a `hub` (takeover).
/// - Entre candidatos gana el de mayor [priority] (pve siempre encendido > phone).
/// - Si el hub declara batería baja ([lowBattery]) cede a `standby` para que
///   otro nodo tome el rol.
class HubElection {
  final String nodeId;
  final int priority;
  final Duration heartbeatInterval;
  final Duration hubTimeout;
  final Duration electionWindow;
  final DateTime Function() now;
  final bool Function() lowBattery;

  HubRole _role = HubRole.idle;
  DateTime _lastHubBeat;
  DateTime? _electionStarted;

  /// Notificado en cada transición de rol.
  void Function(HubRole role)? onRoleChange;

  HubElection({
    required this.nodeId,
    required this.priority,
    required this.now,
    required this.heartbeatInterval,
    required this.hubTimeout,
    this.electionWindow = const Duration(seconds: 3),
    bool Function()? lowBattery,
  })  : lowBattery = lowBattery ?? (() => false),
        _lastHubBeat = now();

  HubRole get role => _role;

  void _setRole(HubRole next) {
    if (next == _role) return;
    _role = next;
    onRoleChange?.call(next);
  }

  /// Llegó un heartbeat del hub actual (o de un candidato mejor).
  /// [fromId] y [priority] identifican al emisor.
  void onHeartbeat(String fromId, {required int priority}) {
    final t = now();
    if (t.isBefore(_lastHubBeat)) return; // desordenado: ignorar
    _lastHubBeat = t;

    // Recibir un heartbeat me convierte en observador (standby).
    if (_role == HubRole.idle) {
      _setRole(HubRole.standby);
    }

    // Si soy candidato y llega un heartbeat de prioridad mayor o igual,
    // reconozco al otro como hub y me mantengo standby.
    if (_role == HubRole.candidate && priority >= this.priority) {
      _setRole(HubRole.standby);
    } else if (_role == HubRole.hub && fromId != nodeId) {
      // otro nodo late siendo hub → perdí el rol
      _setRole(HubRole.standby);
    }
  }

  /// Se llama periódicamente (service): evalúa timeout y batería.
  void tick() {
    final t = now();

    // El hub con batería baja cede el rol.
    if (_role == HubRole.hub && lowBattery()) {
      _setRole(HubRole.standby);
      return;
    }

    switch (_role) {
      case HubRole.idle:
        _setRole(HubRole.standby);
        break;
      case HubRole.standby:
        if (t.difference(_lastHubBeat) > hubTimeout) {
          _setRole(HubRole.candidate);
          _electionStarted = t;
        }
        break;
      case HubRole.candidate:
        if (t.difference(_lastHubBeat) <= hubTimeout) {
          // El hub volvió a latir → vuelvo a standby.
          _setRole(HubRole.standby);
        } else if (_electionStarted != null &&
            t.difference(_electionStarted!) >= electionWindow) {
          _setRole(HubRole.hub);
          _lastHubBeat = t; // me convierto en fuente de heartbeat
        }
        break;
      case HubRole.hub:
        _lastHubBeat = t; // me auto-mantengo latiendo
        break;
    }
  }

  /// Envío de heartbeat del propio nodo (llamado por el service).
  void beat() {
    if (_role == HubRole.hub || _role == HubRole.candidate) {
      _lastHubBeat = now();
    }
  }
}

/// Contrato de transporte para los heartbeats (WS/Tailscale en producción;
/// fake en tests).
abstract class ElectionTransport {
  /// Envía un heartbeat de [nodeId] con [priority].
  void sendHeartbeat(String nodeId, int priority);

  /// Stream de heartbeats recibidos: (fromId, priority).
  Stream<(String, int)> get onHeartbeat;
}

/// Cablea el [HubElection] con un temporizador real y un transporte.
class HubElectionService {
  final HubElection election;
  final ElectionTransport transport;
  final Duration beatInterval;
  Timer? _timer;

  HubElectionService({
    required this.election,
    required this.transport,
    this.beatInterval = const Duration(seconds: 5),
  }) {
    transport.onHeartbeat.listen((hb) {
      election.onHeartbeat(hb.$1, priority: hb.$2);
    });
  }

  void start() {
    _timer ??= Timer.periodic(beatInterval, (_) {
      election.tick();
      election.beat();
      transport.sendHeartbeat(election.nodeId, election.priority);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
