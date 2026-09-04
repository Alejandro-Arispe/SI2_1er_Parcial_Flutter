import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:fashion_store/features/catalog/domain/entities/product_detail.dart';
import 'package:fashion_store/features/catalog/domain/repositories/catalog_repository.dart';

/// Caso de uso: obtener el detalle completo de un producto (Fase 9).
class GetProductDetailUseCase {
  final CatalogRepository _repository;

  const GetProductDetailUseCase(this._repository);

  Future<Result<ProductDetail>> call(String productId) {
    return _repository.getProductDetail(productId);
  }
}

final getProductDetailUseCaseProvider = Provider<GetProductDetailUseCase>((ref) {
  return GetProductDetailUseCase(ref.watch(catalogRepositoryProvider));
});
