import 'package:fashion_store/features/catalog/domain/entities/product_variant.dart';

/// Un producto concreto (variante talla+color) dentro del carrito, con
/// la cantidad elegida. Guarda su propio nombre/imagen/precio en lugar
/// de referenciar solo el id del producto: así el carrito sigue
/// mostrando datos correctos aunque el precio del catálogo cambie
/// después de agregarlo (el precio ya pactado no debe moverse solo).
class CartItem {
  final String id;
  final String productId;
  final String productName;
  final String imageUrl;
  final ProductVariant variant;
  final double unitPrice;
  final int quantity;

  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.variant,
    required this.unitPrice,
    required this.quantity,
  });

  double get subtotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      productId: productId,
      productName: productName,
      imageUrl: imageUrl,
      variant: variant,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }
}
