import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/catalog/domain/repositories/catalog_repository.dart';

/// Caso de uso: listado paginado del catálogo con búsqueda por texto y
/// filtros (categoría, disponibilidad, rango de precio).
class GetProductsUseCase {
  final CatalogRepository _repository;

  const GetProductsUseCase(this._repository);

  Future<Result<List<Product>>> call({
    required int page,
    required int pageSize,
    String? categoryId,
    String query = '',
    bool onlyAvailable = false,
    double? minPrice,
    double? maxPrice,
  }) {
    return _repository.getProducts(
      page: page,
      pageSize: pageSize,
      categoryId: categoryId,
      query: query,
      onlyAvailable: onlyAvailable,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }
}

final getProductsUseCaseProvider = Provider<GetProductsUseCase>((ref) {
  return GetProductsUseCase(ref.watch(catalogRepositoryProvider));
});
