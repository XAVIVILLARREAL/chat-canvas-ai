/// Tiempo relativo compacto en español: "hace 5m", "hace 1h", "hace 3d".
library;

/// Devuelve la distancia entre [from] y [now] en formato compacto.
///
/// - `< 60 minutos` -> `hace Xm` (floor)
/// - `< 24 horas`   -> `hace Xh` (floor)
/// - resto          -> `hace Xd` (floor)
/// - `now < from`   -> `ahora` (fechas futuras no tienen sentido aquí)
String relativeTime(DateTime from, DateTime now) {
  final diff = now.difference(from);
  if (diff.isNegative) return 'ahora';

  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
  if (diff.inHours < 24) return 'hace ${diff.inHours}h';
  return 'hace ${diff.inDays}d';
}

/// Devuelve la distancia entre [from] y [now] en formato detallado.
///
/// - `< 60 segundos` y no negativa -> `hace Xs`
/// - cualquier otro caso            -> lo que devolvería [relativeTime]
String relativeTimeDetailed(DateTime from, DateTime now) {
  final diff = now.difference(from);
  if (!diff.isNegative && diff.inSeconds < 60) return 'hace ${diff.inSeconds}s';
  return relativeTime(from, now);
}
