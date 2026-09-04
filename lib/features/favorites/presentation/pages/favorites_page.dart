import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fashion_store/app/router/route_paths.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';
import 'package:fashion_store/core/widgets/empty_state.dart';
import 'package:fashion_store/core/widgets/error_state.dart';
import 'package:fashion_store/core/widgets/loading_indicator.dart';
import 'package:fashion_store/features/catalog/presentation/widgets/product_card.dart';
import 'package:fashion_store/features/favorites/presentation/controllers/favorites_controller.dart';

/// Favoritos del cliente (ver sección 9 del documento del proyecto).
/// Requiere sesión iniciada (protegido por el router).
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoritesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: state.isLoading
          ? const LoadingIndicator()
          : state.error != null && state.products.isEmpty
              ? ErrorStateView(
                  message: state.error!.message,
                  onRetry: () => ref.read(favoritesControllerProvider.notifier).refresh(),
                )
              : state.products.isEmpty
                  ? const EmptyState(
                      icon: Icons.favorite_border,
                      title: 'Sin favoritos todavía',
                      message: 'Toca el corazón en un producto para guardarlo aquí.',
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(favoritesControllerProvider.notifier).refresh(),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.lg,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.62,
                        ),
                        itemCount: state.products.length,
                        itemBuilder: (context, index) {
                          final product = state.products[index];
                          return ProductCard(
                            product: product,
                            width: null,
                            onTap: () => context.push(RoutePaths.productDetail(product.id)),
                          );
                        },
                      ),
                    ),
    );
  }
}
