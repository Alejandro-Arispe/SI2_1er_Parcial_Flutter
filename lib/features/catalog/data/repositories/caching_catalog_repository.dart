import 'dart:async';
import 'dart:convert';

import 'package:fashion_store/core/error/failures.dart';
import 'package:fashion_store/core/storage/local_storage_service.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/data/models/category_model.dart';
import 'package:fashion_store/features/catalog/data/models/product_model.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch_stock.dart';
import 'package:fashion_store/features/catalog/domain/entities/category.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/catalog/domain/entities/product_detail.dart';
import 'package:fashion_store/features/catalog/domain/repositories/catalog_repository.dart';

/// Decorador de caché sobre CatalogRepository (Fase 23, sección 19 del
/// documento: "caché de productos" y "categorías" como candidatos a
/// almacenamiento local no crítico).
///
/// Solo cubre getCategories() y getFeaturedProducts(), que es lo que
/// Home necesita para mostrar algo útil sin conexión: no tiene sentido
/// cachear cada combinación de filtros del catálogo paginado, ni datos
/// que deben ser siempre frescos (disponibilidad, detalle de producto).
///
/// Guarda la última respuesta exitosa y, si una consulta posterior falla
/// específicamente por conectividad (NetworkFailure/TimeoutFailure),
/// devuelve esa copia local en lugar de propagar el error. Cualquier
/// otro tipo de falla (autenticación, servidor) se propaga tal cual: no
/// tendría sentido taparla con datos viejos.
class CachingCatalogRepository implements CatalogRepository {
  final CatalogRepository _inner;
  final LocalStorageService _storage;

  const CachingCatalogRepository(this._inner, this._storage);

  static const _categoriesCacheKey = 'cache_catalog_categories';
  static const _featuredProductsCacheKey = 'cache_catalog_featured_products';

  @override
  Future<Result<List<Category>>> getCategories() async {
    final result = await _inner.getCategories();
    switch (result) {
      case Success(:final data):
        unawaited(_writeCache(_categoriesCacheKey, data.map(_categoryToJson).toList()));
        return result;
      case ResultError(:final failure):
        if (!_isOfflineFailure(failure)) return result;
        final cached = await _readCache(_categoriesCacheKey, CategoryModel.fromJson);
        return cached == null ? result : Success(cached);
    }
  }

  @override
  Future<Result<List<Product>>> getFeaturedProducts() async {
    final result = await _inner.getFeaturedProducts();
    switch (result) {
      case Success(:final data):
        unawaited(_writeCache(_featuredProductsCacheKey, data.map(_productToJson).toList()));
        return result;
      case ResultError(:final failure):
        if (!_isOfflineFailure(failure)) return result;
        final cached = await _readCache(_featuredProductsCacheKey, ProductModel.fromJson);
        return cached == null ? result : Success(cached);
    }
  }

  // El resto de las operaciones no se cachean: el catálogo paginado con
  // filtros tiene demasiadas combinaciones posibles para guardarlas
  // todas, y el detalle de producto, la disponibilidad y las sucursales
  // deben reflejar siempre el estado real del backend.
  @override
  Future<Result<List<Product>>> getProducts({
    required int page,
    required int pageSize,
    String? categoryId,
    String query = '',
    bool onlyAvailable = false,
    double? minPrice,
    double? maxPrice,
  }) {
    return _inner.getProducts(
      page: page,
      pageSize: pageSize,
      categoryId: categoryId,
      query: query,
      onlyAvailable: onlyAvailable,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  @override
  Future<Result<ProductDetail>> getProductDetail(String productId) {
    return _inner.getProductDetail(productId);
  }

  @override
  Future<Result<List<BranchStock>>> getVariantAvailability(String variantId) {
    return _inner.getVariantAvailability(variantId);
  }

  @override
  Future<Result<List<Branch>>> getBranches() => _inner.getBranches();

  bool _isOfflineFailure(Failure failure) => failure is NetworkFailure || failure is TimeoutFailure;

  Future<void> _writeCache(String key, List<Map<String, dynamic>> items) async {
    try {
      await _storage.writeString(key, jsonEncode(items));
    } catch (_) {
      // Guardar la caché es un extra, no la operación principal: si
      // falla no debe interrumpir la respuesta que ya se obtuvo.
    }
  }

  Future<List<T>?> _readCache<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final raw = await _storage.readString(key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as List;
      return decoded.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _categoryToJson(Category category) => {
    'id': category.id,
    'name': category.name,
    'image_url': category.imageUrl,
  };

  Map<String, dynamic> _productToJson(Product product) => {
    'id': product.id,
    'name': product.name,
    'category_id': product.categoryId,
    'base_price': product.basePrice,
    'image_url': product.imageUrl,
    'is_available': product.isAvailable,
  };
}
