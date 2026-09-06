import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:fashion_store/features/cart/domain/repositories/cart_repository.dart';

class RemoveFromCartUseCase {
  final CartRepository _repository;

  const RemoveFromCartUseCase(this._repository);

  Future<Result<void>> call(String cartItemId) => _repository.removeItem(cartItemId);
}

final removeFromCartUseCaseProvider = Provider<RemoveFromCartUseCase>((ref) {
  return RemoveFromCartUseCase(ref.watch(cartRepositoryProvider));
});
