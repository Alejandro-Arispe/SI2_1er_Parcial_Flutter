import 'dart:typed_data';

import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/try_on/domain/entities/try_on_result.dart';

abstract class TryOnRepository {
  /// Genera la vista previa de [productName] (color [colorHex] si hay una
  /// variante elegida) sobre la foto [photoBytes]. En el backend real esto
  /// se resuelve con Gemini (sección 17); Flutter nunca llama a Gemini
  /// directamente (sección 32), solo envía la foto y los datos de la
  /// prenda.
  Future<Result<TryOnResult>> generate({
    required Uint8List photoBytes,
    required String productId,
    required String productName,
    String? colorHex,
  });
}
