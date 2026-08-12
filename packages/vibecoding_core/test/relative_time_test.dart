import 'package:test/test.dart';
import 'package:vibecoding_core/vibecoding_core.dart';

void main() {
  final now = DateTime(2026, 8, 11, 12, 0, 0);

  group('relativeTime', () {
    test('5 minutos -> hace 5m', () {
      final from = now.subtract(const Duration(minutes: 5));
      expect(relativeTime(from, now), 'hace 5m');
    });

    test('90 minutos -> hace 1h', () {
      final from = now.subtract(const Duration(minutes: 90));
      expect(relativeTime(from, now), 'hace 1h');
    });

    test('3 dias -> hace 3d', () {
      final from = now.subtract(const Duration(days: 3));
      expect(relativeTime(from, now), 'hace 3d');
    });

    test('diff negativa -> ahora', () {
      final from = now.add(const Duration(minutes: 10));
      expect(relativeTime(from, now), 'ahora');
    });

    test('limite exacto 60 minutos -> hace 1h', () {
      final from = now.subtract(const Duration(minutes: 60));
      expect(relativeTime(from, now), 'hace 1h');
    });

    test('59 minutos con 40 segundos -> hace 59m (floor)', () {
      final from = now.subtract(const Duration(minutes: 59, seconds: 40));
      expect(relativeTime(from, now), 'hace 59m');
    });

    test('23:59:59 horas -> hace 23h (floor)', () {
      final from = now.subtract(const Duration(hours: 23, minutes: 59));
      expect(relativeTime(from, now), 'hace 23h');
    });

    test('24 horas -> hace 1d', () {
      final from = now.subtract(const Duration(hours: 24));
      expect(relativeTime(from, now), 'hace 1d');
    });
  });

  group('relativeTimeDetailed', () {
    test('30 segundos -> hace 30s', () {
      final from = now.subtract(const Duration(seconds: 30));
      expect(relativeTimeDetailed(from, now), 'hace 30s');
    });

    test('59 segundos -> hace 59s', () {
      final from = now.subtract(const Duration(seconds: 59));
      expect(relativeTimeDetailed(from, now), 'hace 59s');
    });

    test('60 segundos -> hace 1m', () {
      final from = now.subtract(const Duration(seconds: 60));
      expect(relativeTimeDetailed(from, now), 'hace 1m');
    });

    test('5 minutos -> hace 5m', () {
      final from = now.subtract(const Duration(minutes: 5));
      expect(relativeTimeDetailed(from, now), 'hace 5m');
    });
  });
}