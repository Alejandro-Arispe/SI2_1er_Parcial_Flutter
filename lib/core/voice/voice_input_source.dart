/// Reconocimiento de voz (Fase 22, sección 18 del documento: "consultar
/// al asistente" por voz). Es una interfaz separada de su implementación
/// real a propósito, siguiendo el mismo criterio que ArCameraSource en
/// el probador AR: permite reemplazar el motor de reconocimiento más
/// adelante y, sobre todo, reemplazarlo por un fake en los tests sin
/// depender del plugin de plataforma (que no funciona en el entorno de
/// pruebas).
abstract class VoiceInputSource {
  /// Inicializa el motor de reconocimiento de voz. En dispositivos
  /// reales, esta llamada es la que dispara el pedido de permiso de
  /// micrófono al sistema operativo (sección 34: el permiso se pide
  /// justo antes de usarse, no al abrir la app). Devuelve false si no
  /// hay reconocimiento de voz disponible en el dispositivo o si la
  /// clienta rechazó el permiso.
  Future<bool> initialize();

  bool get isListening;

  /// Emite el texto reconocido a medida que se habla (resultados
  /// parciales primero, el resultado final al terminar).
  Stream<String> get transcriptStream;

  Future<void> startListening();
  Future<void> stopListening();
  Future<void> dispose();
}
