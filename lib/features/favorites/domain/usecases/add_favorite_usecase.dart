import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/favorites/data/repositories/favorite_repository_impl.dart';
import 'package:fashion_store/features/favorites/domain/repositories/favorite_repository.dart';

class AddFavoriteUseCase {
  final FavoriteRepository _repository;

  const AddFavoriteUseCase(this._repository);

  Future<Result<void>> call(String productId) => _repository.addFavorite(productId);
}

final addFavoriteUseCaseProvider = Provider<AddFavoriteUseCase>((ref) {
  return AddFavoriteUseCase(ref.watch(favoriteRepositoryProvider));
});
