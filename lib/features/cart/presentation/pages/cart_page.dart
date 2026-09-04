import 'package:flutter/material.dart';
import 'package:fashion_store/core/widgets/placeholder_page.dart';

/// Carrito de compras. Accesible sin sesión iniciada (el login se exige
/// recién al pasar a checkout, ver sección 21). Contenido real en la
/// Fase 13.
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(title: 'Carrito');
  }
}
