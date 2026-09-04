import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/catalog/domain/repositories/catalog_repository.dart';

/// Caso de uso: listado paginado del catálogo, opcionalmente filtrado
/// por categoría. La búsqueda por texto y los filtros avanzados llegan
/// en la Fase 8.
class GetProductsUseCase {
  final CatalogRepository _repository;

  const GetProductsUseCase(this._repository);

  Future<Result<List<Product>>> call({
    required int page,
    required int pageSize,
    String? categoryId,
  }) {
    return _repository.getProducts(page: page, pageSize: pageSize, categoryId: categoryId);
  }
}

final getProductsUseCaseProvider = Provider<GetProductsUseCase>((ref) {
  return GetProductsUseCase(ref.watch(catalogRepositoryProvider));
});
