import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/cart/domain/entities/cart_item.dart';
import 'package:fashion_store/features/orders/data/models/order_model.dart';
import 'package:fashion_store/features/orders/domain/entities/order.dart';

/// Contrato común para las fuentes de datos de pedidos. Dos
/// implementaciones intercambiables: OrderApiDataSource (real, contra
/// FastAPI) y OrderMockDataSource (temporal, datos de desarrollo).
abstract class OrderDataSource {
  Future<List<OrderModel>> getOrders();

  Future<OrderModel> createOrder({
    required List<CartItem> items,
    required DeliveryMethod deliveryMethod,
    String? deliveryAddress,
    Branch? pickupBranch,
    required double total,
  });

  Future<OrderModel> payOrder({required String orderId, String? paymentMethodId});
}
