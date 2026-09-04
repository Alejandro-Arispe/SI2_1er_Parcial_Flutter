import 'package:dio/dio.dart';
import 'package:fashion_store/core/network/api_endpoints.dart';
import 'package:fashion_store/features/catalog/data/datasources/catalog_data_source.dart';
import 'package:fashion_store/features/catalog/data/models/category_model.dart';
import 'package:fashion_store/features/catalog/data/models/product_model.dart';

/// Implementación real: consulta los endpoints de catálogo de FastAPI.
class CatalogApiDataSource implements CatalogDataSource {
  final Dio _dio;

  const CatalogApiDataSource(this._dio);

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await _dio.get<List<dynamic>>(ApiEndpoints.categories);
    return response.data!
        .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ProductModel>> getFeaturedProducts() async {
    final response = await _dio.get<List<dynamic>>(
      ApiEndpoints.products,
      queryParameters: {'featured': true},
    );
    return response.data!
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ProductModel>> getProducts({
    required int page,
    required int pageSize,
    String? categoryId,
    String query = '',
    bool onlyAvailable = false,
    double? minPrice,
    double? maxPrice,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      ApiEndpoints.products,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        'category_id': ?categoryId,
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (onlyAvailable) 'only_available': true,
        'min_price': ?minPrice,
        'max_price': ?maxPrice,
      },
    );
    return response.data!
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
