import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fashion_store/app/app.dart';
import 'package:fashion_store/core/config/app_config.dart';

/// Punto de entrada de la aplicación.
///
/// ProviderScope habilita Riverpod para todo el árbol de widgets: es el
/// contenedor que guarda el estado de todos los providers de la app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // El SDK de Stripe solo se inicializa con datos reales y una clave
  // publicable configurada (ver sección 13: sin clave no hay nada que
  // inicializar, y en modo mock no se toca Stripe en absoluto).
  if (!AppConfig.useMockData && AppConfig.stripePublishableKey.isNotEmpty) {
    Stripe.publishableKey = AppConfig.stripePublishableKey;
    await Stripe.instance.applySettings();
  }

  runApp(const ProviderScope(child: FashionStoreApp()));
}
