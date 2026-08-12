import 'canva_storage.dart';

/// Stub para plataformas sin archivo ni localStorage (solo resolución de
/// conditional import en VM/tests — no se usa en runtime real).
class StubCanvaStorage implements CanvaStorage {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String data) async {}
}

CanvaStorage defaultCanvaStorage() => StubCanvaStorage();
