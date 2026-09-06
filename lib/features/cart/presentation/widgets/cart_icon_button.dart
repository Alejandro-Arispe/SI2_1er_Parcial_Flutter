import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fashion_store/app/router/route_paths.dart';
import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/features/cart/presentation/controllers/cart_controller.dart';

/// Ícono de carrito con contador de unidades, reutilizable en las
/// pantallas donde se puede agregar productos (Home, Catálogo, detalle
/// de producto). El carrito no es una pestaña del bottom nav (ver
/// MainScaffold), así que este ícono es el punto de entrada.
class CartIconButton extends ConsumerWidget {
  const CartIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalItems = ref.watch(cartControllerProvider.select((state) => state.totalItems));

    return IconButton(
      tooltip: 'Carrito',
      onPressed: () => context.push(RoutePaths.cart),
      icon: Badge(
        label: Text('$totalItems'),
        isLabelVisible: totalItems > 0,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.shopping_bag_outlined),
      ),
    );
  }
}
