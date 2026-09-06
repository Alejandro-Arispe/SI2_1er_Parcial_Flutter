import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/config/app_config.dart';
import 'package:fashion_store/core/error/error_mapper.dart';
import 'package:fashion_store/core/error/exceptions.dart';
import 'package:fashion_store/core/network/dio_client.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/cart/domain/entities/cart_item.dart';
import 'package:fashion_store/features/orders/data/datasources/order_api_data_source.dart';
import 'package:fashion_store/features/orders/data/datasources/order_data_source.dart';
import 'package:fashion_store/features/orders/data/datasources/order_mock_data_source.dart';
import 'package:fashion_store/features/orders/domain/entities/order.dart';
import 'package:fashion_store/features/orders/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderDataSource _dataSource;

  const OrderRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Order>>> getOrders() async {
    try {
      return Success(await _dataSource.getOrders());
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }

  @override
  Future<Result<Order>> createOrder({
    required List<CartItem> items,
    required DeliveryMethod deliveryMethod,
    String? deliveryAddress,
    Branch? pickupBranch,
    required double total,
  }) async {
    try {
      final order = await _dataSource.createOrder(
        items: items,
        deliveryMethod: deliveryMethod,
        deliveryAddress: deliveryAddress,
        pickupBranch: pickupBranch,
        total: total,
      );
      return Success(order);
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }

  @override
  Future<Result<Order>> payOrder({required String orderId, String? paymentMethodId}) async {
    try {
      return Success(await _dataSource.payOrder(orderId: orderId, paymentMethodId: paymentMethodId));
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }
}

final orderDataSourceProvider = Provider<OrderDataSource>((ref) {
  return AppConfig.useMockData ? OrderMockDataSource() : OrderApiDataSource(ref.watch(dioClientProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(ref.watch(orderDataSourceProvider));
});
