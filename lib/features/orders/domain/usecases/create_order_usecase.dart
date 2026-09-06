import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/cart/domain/entities/cart_item.dart';
import 'package:fashion_store/features/orders/data/repositories/order_repository_impl.dart';
import 'package:fashion_store/features/orders/domain/entities/order.dart';
import 'package:fashion_store/features/orders/domain/repositories/order_repository.dart';

class CreateOrderUseCase {
  final OrderRepository _repository;

  const CreateOrderUseCase(this._repository);

  Future<Result<Order>> call({
    required List<CartItem> items,
    required DeliveryMethod deliveryMethod,
    String? deliveryAddress,
    Branch? pickupBranch,
    required double total,
  }) {
    return _repository.createOrder(
      items: items,
      deliveryMethod: deliveryMethod,
      deliveryAddress: deliveryAddress,
      pickupBranch: pickupBranch,
      total: total,
    );
  }
}

final createOrderUseCaseProvider = Provider<CreateOrderUseCase>((ref) {
  return CreateOrderUseCase(ref.watch(orderRepositoryProvider));
});
