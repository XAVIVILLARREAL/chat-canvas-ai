/// Abstracción de persistencia del canva. `CanvaStore` inyecta una impl
/// según plataforma: archivo (io) o localStorage (web).
abstract interface class CanvaStorage {
  /// Devuelve el JSON crudo guardado, o null si no existe nada.
  Future<String?> read();

  /// Escribe el JSON crudo (sobrescribe).
  Future<void> write(String data);
}
