import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:fashion_store/features/cart/domain/repositories/cart_repository.dart';

class UpdateCartItemQuantityUseCase {
  final CartRepository _repository;

  const UpdateCartItemQuantityUseCase(this._repository);

  Future<Result<void>> call(String cartItemId, int quantity) {
    return _repository.updateQuantity(cartItemId, quantity);
  }
}

final updateCartItemQuantityUseCaseProvider = Provider<UpdateCartItemQuantityUseCase>((ref) {
  return UpdateCartItemQuantityUseCase(ref.watch(cartRepositoryProvider));
});
