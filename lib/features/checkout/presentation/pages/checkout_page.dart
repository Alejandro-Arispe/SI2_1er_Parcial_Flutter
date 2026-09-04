import 'package:flutter/material.dart';
import 'package:fashion_store/core/widgets/placeholder_page.dart';

/// Flujo de compra y pago con Stripe. Requiere sesión iniciada. Contenido
/// real en las Fases 15 y 16.
class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(title: 'Checkout');
  }
}
