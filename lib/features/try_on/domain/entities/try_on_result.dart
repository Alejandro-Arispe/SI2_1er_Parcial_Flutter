import 'dart:typed_data';

/// Resultado del probador virtual por fotografía (Fase 20, ver sección 17
/// del documento). La imagen generada vive solo en memoria: por las
/// reglas de privacidad de fotos (sección 17.4) no se guarda en disco de
/// forma permanente ni se conserva más allá de la sesión de prueba
/// actual (ver TryOnController, que usa un provider autoDispose).
class TryOnResult {
  final Uint8List imageBytes;
  final String productId;
  final DateTime generatedAt;

  const TryOnResult({
    required this.imageBytes,
    required this.productId,
    required this.generatedAt,
  });
}
