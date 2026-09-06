import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:fashion_store/features/cart/domain/repositories/cart_repository.dart';

class ClearCartUseCase {
  final CartRepository _repository;

  const ClearCartUseCase(this._repository);

  Future<Result<void>> call() => _repository.clearCart();
}

final clearCartUseCaseProvider = Provider<ClearCartUseCase>((ref) {
  return ClearCartUseCase(ref.watch(cartRepositoryProvider));
});
