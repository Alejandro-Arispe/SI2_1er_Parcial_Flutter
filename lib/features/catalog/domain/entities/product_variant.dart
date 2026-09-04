import 'package:fashion_store/features/catalog/domain/entities/product_color.dart';
import 'package:fashion_store/features/catalog/domain/entities/product_size.dart';

/// Combinación concreta de producto + talla + color (ver sección 7 del
/// documento). La aplicación debe trabajar siempre con la variante
/// concreta, nunca con el producto genérico, a la hora de mostrar
/// disponibilidad o permitir una compra/reserva.
///
/// `isAvailable` es la disponibilidad global de la variante. La
/// disponibilidad por sucursal se agrega en la Fase 11.
class ProductVariant {
  final String id;
  final String productId;
  final ProductSize size;
  final ProductColor color;
  final bool isAvailable;

  const ProductVariant({
    required this.id,
    required this.productId,
    required this.size,
    required this.color,
    required this.isAvailable,
  });
}
