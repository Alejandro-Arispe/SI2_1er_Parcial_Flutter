import 'package:fashion_store/features/catalog/domain/entities/product_variant.dart';

/// Una prenda concreta (variante talla+color) dentro de una reserva, con
/// la cantidad elegida. No incluye precio: la reserva no es una venta
/// (ver sección 10 del documento), así que no tiene sentido fijar un
/// precio como sí ocurre con CartItem.
class ReservationItem {
  final String productId;
  final String productName;
  final String imageUrl;
  final ProductVariant variant;
  final int quantity;

  const ReservationItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.variant,
    required this.quantity,
  });

  ReservationItem copyWith({int? quantity}) {
    return ReservationItem(
      productId: productId,
      productName: productName,
      imageUrl: imageUrl,
      variant: variant,
      quantity: quantity ?? this.quantity,
    );
  }
}
