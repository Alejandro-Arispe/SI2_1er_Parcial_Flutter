import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Estructura visual compartida por las cuatro ramas principales del
/// cliente: Home, Catálogo, Favoritos y Perfil.
///
/// Se usa StatefulShellRoute para que cada pestaña mantenga su propia
/// pila de navegación independiente (por ejemplo, entrar a un producto
/// desde Catálogo y volver a Home no pierde el detalle abierto).
///
/// Decisión de diseño: el carrito no es una pestaña del bottom nav, se
/// alcanza como una ruta independiente (RoutePaths.cart) desde un ícono
/// en las pantallas de catálogo/producto, siguiendo el patrón común de
/// apps de moda donde el carrito es una acción, no una sección permanente.
class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Si se vuelve a tocar la pestaña activa, regresa a su raíz
          // en lugar de apilar otra vez la misma pantalla.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checkroom_outlined),
            selectedIcon: Icon(Icons.checkroom),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
