import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/favorites/data/repositories/favorite_repository_impl.dart';
import 'package:fashion_store/features/favorites/domain/repositories/favorite_repository.dart';

class RemoveFavoriteUseCase {
  final FavoriteRepository _repository;

  const RemoveFavoriteUseCase(this._repository);

  Future<Result<void>> call(String productId) => _repository.removeFavorite(productId);
}

final removeFavoriteUseCaseProvider = Provider<RemoveFavoriteUseCase>((ref) {
  return RemoveFavoriteUseCase(ref.watch(favoriteRepositoryProvider));
});
