import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/orders/data/repositories/order_repository_impl.dart';
import 'package:fashion_store/features/orders/domain/entities/order.dart';
import 'package:fashion_store/features/orders/domain/repositories/order_repository.dart';

class GetOrdersUseCase {
  final OrderRepository _repository;

  const GetOrdersUseCase(this._repository);

  Future<Result<List<Order>>> call() => _repository.getOrders();
}

final getOrdersUseCaseProvider = Provider<GetOrdersUseCase>((ref) {
  return GetOrdersUseCase(ref.watch(orderRepositoryProvider));
});
