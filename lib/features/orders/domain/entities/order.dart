import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/cart/domain/entities/cart_item.dart';

/// Forma en que el cliente recibe el pedido (ver sección 10 del
/// documento del proyecto): envío a un domicilio, o recojo en una
/// sucursal física (reutilizando el mismo concepto de sucursal que
/// disponibilidad y reservas, Fases 11 y 14).
enum DeliveryMethod { delivery, pickup }

/// Estado del pedido. Solo `pendingPayment` se crea en esta fase
/// (Fase 15: checkout sin pago); la Fase 16 agrega el pago con Stripe
/// que transiciona a `paid`, y `cancelled` queda modelado para cuando
/// exista esa acción (no se usa todavía).
enum OrderStatus { pendingPayment, paid, cancelled }

/// Pedido creado a partir del carrito al confirmar checkout. Reutiliza
/// CartItem como línea de pedido en lugar de duplicar sus campos: un
/// ítem de pedido es exactamente "qué se pidió, a qué precio y en qué
/// cantidad", igual que un ítem de carrito.
class Order {
  final String id;
  final List<CartItem> items;
  final DeliveryMethod deliveryMethod;
  final String? deliveryAddress;
  final Branch? pickupBranch;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.items,
    required this.deliveryMethod,
    required this.deliveryAddress,
    required this.pickupBranch,
    required this.total,
    required this.status,
    required this.createdAt,
  });
}
