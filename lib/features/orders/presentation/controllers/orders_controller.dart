import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/error/failures.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/orders/domain/entities/order.dart';
import 'package:fashion_store/features/orders/domain/usecases/get_orders_usecase.dart';

class OrdersState {
  final List<Order> orders;
  final bool isLoading;
  final Failure? error;

  const OrdersState({required this.orders, required this.isLoading, required this.error});

  factory OrdersState.initial() => const OrdersState(orders: [], isLoading: true, error: null);
}

/// Controller del historial de compras (Fase 17). Solo lectura: los
/// pedidos se crean y se pagan en checkout (Fases 15/16), no aquí.
class OrdersController extends Notifier<OrdersState> {
  @override
  OrdersState build() {
    _load(); // no debe tocar state antes del primer await (ver FavoritesController)
    return OrdersState.initial();
  }

  Future<void> _load() async {
    final result = await ref.read(getOrdersUseCaseProvider).call();
    state = switch (result) {
      Success(:final data) => OrdersState(orders: data, isLoading: false, error: null),
      ResultError(:final failure) => OrdersState(orders: state.orders, isLoading: false, error: failure),
    };
  }

  Future<void> refresh() => _load();
}

final ordersControllerProvider = NotifierProvider<OrdersController, OrdersState>(OrdersController.new);
