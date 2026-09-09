import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fashion_store/core/network/connectivity_service.dart';
import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';

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
class MainScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Aviso persistente de conectividad (Fase 23, sección 19 del
    // documento): se muestra en las cuatro pestañas principales, no solo
    // cuando una operación puntual falla, para que la clienta sepa desde
    // el principio que está viendo datos guardados.
    final isOffline = ref.watch(connectivityStreamProvider).value == false;

    return Scaffold(
      body: Column(
        children: [
          if (isOffline) const _OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
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

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.warning,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Text(
            'Sin conexión a internet. Mostrando información guardada.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textOnPrimary),
          ),
        ),
      ),
    );
  }
}
