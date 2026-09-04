import 'package:flutter/material.dart';
import 'package:fashion_store/core/widgets/placeholder_page.dart';

/// Detalle de producto y sus variantes (talla/color). Contenido real en
/// las Fases 9 y 10. Recibe el id de producto desde la ruta del catálogo.
class ProductDetailPage extends StatelessWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return PlaceholderPage(
      title: 'Producto $productId',
      message: 'El detalle de este producto se implementará en la Fase 9.',
    );
  }
}
