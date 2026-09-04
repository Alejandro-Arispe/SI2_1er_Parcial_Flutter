import 'package:flutter/material.dart';
import 'package:fashion_store/core/widgets/placeholder_page.dart';

/// Historial de compras del cliente. Requiere sesión iniciada. Contenido
/// real en la Fase 17.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(title: 'Mis compras');
  }
}
