/// Lectura en voz alta (Fase 22, sección 18 del documento: interacción
/// mediante voz). Interfaz separada de su implementación real por el
/// mismo motivo que VoiceInputSource: reemplazable y testeable sin
/// depender del plugin de plataforma.
abstract class VoiceOutputSource {
  /// Lee [text] en voz alta. Corta cualquier lectura anterior en curso
  /// antes de empezar la nueva, para no superponer dos lecturas.
  Future<void> speak(String text);

  Future<void> stop();
}
