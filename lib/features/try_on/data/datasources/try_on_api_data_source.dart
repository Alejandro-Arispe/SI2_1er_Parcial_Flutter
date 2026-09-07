import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fashion_store/core/network/api_endpoints.dart';
import 'package:fashion_store/features/try_on/data/datasources/try_on_data_source.dart';
import 'package:fashion_store/features/try_on/data/models/try_on_result_model.dart';

/// Implementación real: envía la foto y los datos de la prenda a FastAPI,
/// que es quien genera/edita la imagen con Gemini (sección 17 del
/// documento). Flutter nunca llama a Gemini directamente ni maneja su
/// clave (sección 32).
class TryOnApiDataSource implements TryOnDataSource {
  final Dio _dio;

  const TryOnApiDataSource(this._dio);

  @override
  Future<TryOnResultModel> generate({
    required Uint8List photoBytes,
    required String productId,
    required String productName,
    String? colorHex,
  }) async {
    final formData = FormData.fromMap({
      'product_id': productId,
      'product_name': productName,
      'color_hex': ?colorHex,
      'photo': MultipartFile.fromBytes(photoBytes, filename: 'try_on_photo.jpg'),
    });

    final response = await _dio.post<Map<String, dynamic>>(ApiEndpoints.tryOnPhoto, data: formData);
    return TryOnResultModel.fromJson(response.data!, productId: productId);
  }
}
