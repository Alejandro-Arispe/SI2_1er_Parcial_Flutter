import 'package:fashion_store/core/error/exceptions.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/cart/domain/entities/cart_item.dart';
import 'package:fashion_store/features/orders/data/datasources/order_data_source.dart';
import 'package:fashion_store/features/orders/data/models/order_model.dart';
import 'package:fashion_store/features/orders/domain/entities/order.dart';

/// Datasource temporal de desarrollo: guarda los pedidos en memoria
/// (ver sección 42 del documento del proyecto), igual que los demás
/// mocks del proyecto.
class OrderMockDataSource implements OrderDataSource {
  static final List<OrderModel> _orders = [];
  static int _nextId = 1;

  @override
  Future<List<OrderModel>> getOrders() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Las más recientes primero, igual que ReservationMockDataSource.
    return _orders.reversed.toList();
  }

  @override
  Future<OrderModel> createOrder({
    required List<CartItem> items,
    required DeliveryMethod deliveryMethod,
    String? deliveryAddress,
    Branch? pickupBranch,
    required double total,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final order = OrderModel(
      id: 'order-${_nextId++}',
      items: items,
      deliveryMethod: deliveryMethod,
      deliveryAddress: deliveryAddress,
      pickupBranch: pickupBranch,
      total: total,
      status: OrderStatus.pendingPayment,
      createdAt: DateTime.now(),
    );
    _orders.add(order);
    return order;
  }

  @override
  Future<OrderModel> payOrder({required String orderId, String? paymentMethodId}) async {
    // Simula el tiempo de procesamiento de un cobro real; no se llama a
    // Stripe en modo mock (no hay tarjeta real que cobrar, ver sección
    // 13 del documento: nada de esto debe simular datos que no existen).
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1) {
      throw const ServerException('Pedido no encontrado.', statusCode: 404);
    }

    final paid = OrderModel(
      id: _orders[index].id,
      items: _orders[index].items,
      deliveryMethod: _orders[index].deliveryMethod,
      deliveryAddress: _orders[index].deliveryAddress,
      pickupBranch: _orders[index].pickupBranch,
      total: _orders[index].total,
      status: OrderStatus.paid,
      createdAt: _orders[index].createdAt,
    );
    _orders[index] = paid;
    return paid;
  }
}
