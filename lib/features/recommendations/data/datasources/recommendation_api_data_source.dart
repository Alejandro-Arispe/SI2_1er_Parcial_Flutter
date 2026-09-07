import 'package:dio/dio.dart';
import 'package:fashion_store/core/network/api_endpoints.dart';
import 'package:fashion_store/features/catalog/data/models/product_model.dart';
import 'package:fashion_store/features/recommendations/data/datasources/recommendation_data_source.dart';

/// Implementación real: el backend combina favoritos e historial de
/// compras del cliente autenticado (ya los conoce) con los últimos
/// productos consultados en este dispositivo, que se envían como
/// parámetro porque solo Flutter los tiene (ver sección 16).
class RecommendationApiDataSource implements RecommendationDataSource {
  final Dio _dio;

  const RecommendationApiDataSource(this._dio);

  @override
  Future<List<ProductModel>> getRecommendations({required List<String> recentlyViewedProductIds}) async {
    final response = await _dio.get<List<dynamic>>(
      ApiEndpoints.recommendations,
      queryParameters: {
        if (recentlyViewedProductIds.isNotEmpty) 'recently_viewed': recentlyViewedProductIds.join(','),
      },
    );
    return response.data!
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
