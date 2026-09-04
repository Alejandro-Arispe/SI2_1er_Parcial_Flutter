import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:fashion_store/features/catalog/domain/entities/category.dart';
import 'package:fashion_store/features/catalog/domain/repositories/catalog_repository.dart';

class GetCategoriesUseCase {
  final CatalogRepository _repository;

  const GetCategoriesUseCase(this._repository);

  Future<Result<List<Category>>> call() => _repository.getCategories();
}

final getCategoriesUseCaseProvider = Provider<GetCategoriesUseCase>((ref) {
  return GetCategoriesUseCase(ref.watch(catalogRepositoryProvider));
});
