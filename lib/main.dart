import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/app/app.dart';

/// Punto de entrada de la aplicación.
///
/// ProviderScope habilita Riverpod para todo el árbol de widgets: es el
/// contenedor que guarda el estado de todos los providers de la app.
void main() {
  runApp(const ProviderScope(child: FashionStoreApp()));
}
