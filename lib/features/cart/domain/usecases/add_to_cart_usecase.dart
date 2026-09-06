import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/product_variant.dart';
import 'package:fashion_store/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:fashion_store/features/cart/domain/entities/cart_item.dart';
import 'package:fashion_store/features/cart/domain/repositories/cart_repository.dart';

class AddToCartUseCase {
  final CartRepository _repository;

  const AddToCartUseCase(this._repository);

  Future<Result<CartItem>> call({
    required ProductVariant variant,
    required String productId,
    required String productName,
    required String imageUrl,
    required double unitPrice,
    required int quantity,
  }) {
    return _repository.addItem(
      variant: variant,
      productId: productId,
      productName: productName,
      imageUrl: imageUrl,
      unitPrice: unitPrice,
      quantity: quantity,
    );
  }
}

final addToCartUseCaseProvider = Provider<AddToCartUseCase>((ref) {
  return AddToCartUseCase(ref.watch(cartRepositoryProvider));
});
