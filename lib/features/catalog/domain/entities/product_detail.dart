import 'package:fashion_store/features/catalog/domain/entities/product_variant.dart';

/// Detalle completo de un producto: lo que necesita la pantalla de
/// detalle (descripción larga, galería de imágenes, variantes
/// disponibles) y que no tiene sentido cargar en un listado. Se obtiene
/// con una consulta separada de la del catálogo (ver
/// GetProductDetailUseCase).
class ProductDetail {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String categoryName;
  final double basePrice;
  final List<String> imageUrls;
  final bool isAvailable;
  final List<ProductVariant> variants;

  const ProductDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.basePrice,
    required this.imageUrls,
    required this.isAvailable,
    required this.variants,
  });
}
