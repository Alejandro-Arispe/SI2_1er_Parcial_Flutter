import 'dart:convert';

import 'package:fashion_store/features/try_on/domain/entities/try_on_result.dart';

class TryOnResultModel extends TryOnResult {
  const TryOnResultModel({
    required super.imageBytes,
    required super.productId,
    required super.generatedAt,
  });

  /// [productId] se pasa aparte porque es un dato que ya tiene el
  /// cliente (no algo que el backend deba confirmar en la respuesta).
  factory TryOnResultModel.fromJson(Map<String, dynamic> json, {required String productId}) {
    return TryOnResultModel(
      imageBytes: base64Decode(json['image_base64'] as String),
      productId: productId,
      generatedAt: DateTime.now(),
    );
  }
}
