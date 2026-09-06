import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:fashion_store/features/cart/domain/entities/cart_item.dart';
import 'package:fashion_store/features/cart/domain/repositories/cart_repository.dart';

class GetCartUseCase {
  final CartRepository _repository;

  const GetCartUseCase(this._repository);

  Future<Result<List<CartItem>>> call() => _repository.getCart();
}

final getCartUseCaseProvider = Provider<GetCartUseCase>((ref) {
  return GetCartUseCase(ref.watch(cartRepositoryProvider));
});
