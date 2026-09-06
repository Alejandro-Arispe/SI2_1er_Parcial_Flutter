import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fashion_store/app/router/route_paths.dart';
import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';
import 'package:fashion_store/core/widgets/app_button.dart';
import 'package:fashion_store/core/widgets/empty_state.dart';
import 'package:fashion_store/core/widgets/error_state.dart';
import 'package:fashion_store/core/widgets/loading_indicator.dart';
import 'package:fashion_store/features/cart/domain/entities/cart_item.dart';
import 'package:fashion_store/features/cart/presentation/controllers/cart_controller.dart';

/// Carrito de compras. Accesible sin sesión iniciada (el login se exige
/// recién al pasar a checkout, ver sección 21).
class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cartControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Carrito')),
      body: state.isLoading
          ? const LoadingIndicator()
          : state.error != null && state.items.isEmpty
              ? ErrorStateView(
                  message: state.error!.message,
                  onRetry: () => ref.read(cartControllerProvider.notifier).refresh(),
                )
              : state.items.isEmpty
                  ? const EmptyState(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Tu carrito está vacío',
                      message: 'Agrega prendas desde el catálogo para verlas aquí.',
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: state.items.length,
                            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) => _CartItemTile(item: state.items[index]),
                          ),
                        ),
                        _CartSummary(state: state),
                      ],
                    ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: CachedNetworkImage(
            imageUrl: item.imageUrl,
            width: 80,
            height: 96,
            fit: BoxFit.cover,
            placeholder: (context, url) => const ColoredBox(
              color: AppColors.skeleton,
              child: SizedBox(width: 80, height: 96),
            ),
            errorWidget: (context, url, error) => const ColoredBox(
              color: AppColors.skeleton,
              child: Icon(Icons.image_not_supported_outlined, color: AppColors.disabled),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.productName, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Talla ${item.variant.size.label} · ${item.variant.color.name}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Bs ${item.unitPrice.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _QuantityButton(
                    icon: Icons.remove,
                    onPressed: () =>
                        ref.read(cartControllerProvider.notifier).updateQuantity(item.id, item.quantity - 1),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  _QuantityButton(
                    icon: Icons.add,
                    onPressed: () =>
                        ref.read(cartControllerProvider.notifier).updateQuantity(item.id, item.quantity + 1),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Quitar',
                    icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
                    onPressed: () => ref.read(cartControllerProvider.notifier).removeItem(item.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final CartState state;

  const _CartSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  'Bs ${state.subtotal.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Continuar a checkout',
              // Se usa go() y no push(): checkout es una ruta protegida
              // (ver app_router.dart) y, si el cliente no tiene sesión,
              // el router lo redirige a login. Con go(), iniciar sesión
              // desde ahí vuelve a la app con normalidad (a Home, mismo
              // comportamiento que el resto de accesos protegidos) en
              // lugar de dejarlo atascado en login (mismo caso que
              // FavoriteButton). El cliente vuelve a tocar "Continuar a
              // checkout" ya autenticado para completar la compra.
              onPressed: () => context.go(RoutePaths.checkout),
            ),
          ],
        ),
      ),
    );
  }
}
