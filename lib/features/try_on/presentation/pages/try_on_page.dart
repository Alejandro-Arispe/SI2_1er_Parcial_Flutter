import 'package:flutter/material.dart';
import 'package:fashion_store/core/widgets/placeholder_page.dart';

/// Probador virtual (modo fotografía y modo cámara/AR). Accesible sin
/// sesión iniciada para las funciones que no requieran guardar
/// información (ver sección 21). Contenido real en las Fases 20 y 21.
class TryOnPage extends StatelessWidget {
  const TryOnPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(title: 'Probador virtual');
  }
}
