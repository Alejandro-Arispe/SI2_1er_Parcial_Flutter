import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/cart/domain/entities/cart_item.dart';
import 'package:fashion_store/features/orders/domain/entities/order.dart';

/// Contrato de pedidos: crearlos a partir del carrito (Fase 15),
/// pagarlos (Fase 16) y consultar el historial del cliente (Fase 17).
abstract class OrderRepository {
  Future<Result<List<Order>>> getOrders();

  Future<Result<Order>> createOrder({
    required List<CartItem> items,
    required DeliveryMethod deliveryMethod,
    String? deliveryAddress,
    Branch? pickupBranch,
    required double total,
  });

  /// Confirma el pago de un pedido pendiente (Fase 16). [paymentMethodId]
  /// es el id que devuelve Stripe al tokenizar la tarjeta en el cliente
  /// (ver PaymentMethodParams.card); es null en modo mock, donde no hay
  /// una tarjeta real que tokenizar.
  Future<Result<Order>> payOrder({
    required String orderId,
    String? paymentMethodId,
  });
}
