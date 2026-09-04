import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/catalog/domain/repositories/catalog_repository.dart';

class GetFeaturedProductsUseCase {
  final CatalogRepository _repository;

  const GetFeaturedProductsUseCase(this._repository);

  Future<Result<List<Product>>> call() => _repository.getFeaturedProducts();
}

final getFeaturedProductsUseCaseProvider = Provider<GetFeaturedProductsUseCase>((ref) {
  return GetFeaturedProductsUseCase(ref.watch(catalogRepositoryProvider));
});
