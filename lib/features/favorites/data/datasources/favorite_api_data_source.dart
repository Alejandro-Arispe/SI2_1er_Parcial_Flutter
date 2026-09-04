import 'package:dio/dio.dart';
import 'package:fashion_store/core/network/api_endpoints.dart';
import 'package:fashion_store/features/catalog/data/models/product_model.dart';
import 'package:fashion_store/features/favorites/data/datasources/favorite_data_source.dart';

/// Implementación real: consulta los endpoints de favoritos de FastAPI.
class FavoriteApiDataSource implements FavoriteDataSource {
  final Dio _dio;

  const FavoriteApiDataSource(this._dio);

  @override
  Future<List<ProductModel>> getFavorites() async {
    final response = await _dio.get<List<dynamic>>(ApiEndpoints.favorites);
    return response.data!
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addFavorite(String productId) async {
    await _dio.post<void>(ApiEndpoints.favorite(productId));
  }

  @override
  Future<void> removeFavorite(String productId) async {
    await _dio.delete<void>(ApiEndpoints.favorite(productId));
  }
}
