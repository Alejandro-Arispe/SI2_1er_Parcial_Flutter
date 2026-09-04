/// Producto del catálogo, en su forma resumida para listados (Home,
/// catálogo, favoritos). El detalle completo (descripción, galería de
/// imágenes) se modela por separado en ProductDetail (Fase 9). No
/// incluye variantes de talla/color: eso se agrega en la Fase 10
/// (ProductVariant).
class Product {
  final String id;
  final String name;
  final String categoryId;
  final double basePrice;
  final String imageUrl;
  final bool isAvailable;

  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.basePrice,
    required this.imageUrl,
    required this.isAvailable,
  });
}
