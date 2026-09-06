import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/product_variant.dart';
import 'package:fashion_store/features/cart/domain/entities/cart_item.dart';

/// Contrato del carrito de compras (ver sección 10 del documento del
/// proyecto). El carrito trabaja con la variante concreta del producto,
/// nunca con el producto genérico, siguiendo el mismo criterio que el
/// detalle de producto (sección 7).
abstract class CartRepository {
  Future<Result<List<CartItem>>> getCart();

  /// Agrega [quantity] unidades de [variant] al carrito. Si la variante
  /// ya está en el carrito, el backend/mock debe sumar la cantidad al
  /// ítem existente en lugar de crear una línea duplicada.
  Future<Result<CartItem>> addItem({
    required ProductVariant variant,
    required String productId,
    required String productName,
    required String imageUrl,
    required double unitPrice,
    required int quantity,
  });

  Future<Result<void>> updateQuantity(String cartItemId, int quantity);

  Future<Result<void>> removeItem(String cartItemId);

  /// Vacía el carrito por completo. Se usa al confirmar un pedido en
  /// checkout (Fase 15): una vez creado el pedido, los ítems ya no
  /// pertenecen al carrito.
  Future<Result<void>> clearCart();
}
