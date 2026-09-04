import 'package:flutter/material.dart';

/// Indicador de carga centrado, usado mientras una pantalla espera la
/// respuesta de un caso de uso (catálogo, favoritos, reservas, etc.).
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
