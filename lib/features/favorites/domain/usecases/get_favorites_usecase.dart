import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/favorites/data/repositories/favorite_repository_impl.dart';
import 'package:fashion_store/features/favorites/domain/repositories/favorite_repository.dart';

class GetFavoritesUseCase {
  final FavoriteRepository _repository;

  const GetFavoritesUseCase(this._repository);

  Future<Result<List<Product>>> call() => _repository.getFavorites();
}

final getFavoritesUseCaseProvider = Provider<GetFavoritesUseCase>((ref) {
  return GetFavoritesUseCase(ref.watch(favoriteRepositoryProvider));
});
