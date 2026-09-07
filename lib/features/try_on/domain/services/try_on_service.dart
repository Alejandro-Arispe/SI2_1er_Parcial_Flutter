/// Modo del probador virtual (sección 17 del documento: dos modos,
/// fotografía y cámara/AR).
enum TryOnMode { photo, ar }

/// Abstracción común de los dos modos del probador virtual (sección
/// 17.3 del documento):
///
/// TryOnService
///   +-- PhotoTryOnService
///   +-- ARTryOnService
///
/// El resto de la aplicación (por ejemplo, la pantalla de detalle de
/// producto o una futura pantalla que liste los modos disponibles)
/// depende de TryOnService, nunca de una implementación concreta. Esto
/// es lo que permite cambiar el motor de AR más adelante (por ejemplo,
/// de ML Kit a otra librería) sin modificar el resto de la app.
abstract class TryOnService {
  TryOnMode get mode;

  /// Indica si este modo puede usarse ahora mismo en este dispositivo.
  /// El modo foto siempre está disponible (solo necesita la galería o
  /// la cámara vía image_picker); el modo AR depende de que el
  /// dispositivo tenga una cámara física real (ver ARTryOnService).
  Future<bool> isAvailable();
}
