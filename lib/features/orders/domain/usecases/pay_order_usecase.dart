import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/orders/data/repositories/order_repository_impl.dart';
import 'package:fashion_store/features/orders/domain/entities/order.dart';
import 'package:fashion_store/features/orders/domain/repositories/order_repository.dart';

class PayOrderUseCase {
  final OrderRepository _repository;

  const PayOrderUseCase(this._repository);

  Future<Result<Order>> call({required String orderId, String? paymentMethodId}) {
    return _repository.payOrder(orderId: orderId, paymentMethodId: paymentMethodId);
  }
}

final payOrderUseCaseProvider = Provider<PayOrderUseCase>((ref) {
  return PayOrderUseCase(ref.watch(orderRepositoryProvider));
});
