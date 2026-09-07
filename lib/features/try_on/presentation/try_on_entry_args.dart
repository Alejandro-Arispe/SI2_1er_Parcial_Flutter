import 'package:fashion_store/features/catalog/domain/entities/product.dart';

/// Datos que llegan por GoRouter `extra` al abrir el probador virtual
/// desde el detalle de un producto (ver ProductDetailPage). [colorHex]
/// es opcional: solo existe si la clienta ya había elegido una variante
/// concreta antes de tocar "Probar con tu foto".
class TryOnEntryArgs {
  final Product product;
  final String? colorHex;

  const TryOnEntryArgs({required this.product, this.colorHex});
}
