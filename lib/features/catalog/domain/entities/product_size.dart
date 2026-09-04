/// Talla de una variante de producto (ver sección 7 del documento: una
/// variante está determinada, como mínimo, por producto, talla y color).
class ProductSize {
  final String id;
  final String label;

  const ProductSize({required this.id, required this.label});
}
