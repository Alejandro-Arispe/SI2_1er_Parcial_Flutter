import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fashion_store/app/router/route_paths.dart';
import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';
import 'package:fashion_store/core/widgets/empty_state.dart';
import 'package:fashion_store/core/widgets/error_state.dart';
import 'package:fashion_store/core/widgets/loading_indicator.dart';
import 'package:fashion_store/features/catalog/domain/entities/category.dart';
import 'package:fashion_store/features/catalog/presentation/controllers/catalog_controller.dart';
import 'package:fashion_store/features/catalog/presentation/widgets/product_card.dart';

/// Catálogo completo: filtro por categoría y listado paginado con
/// scroll infinito. La búsqueda por texto y los filtros avanzados
/// (talla, color, precio, temporada) se agregan en la Fase 8.
class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Dispara la siguiente página un poco antes de llegar al final, para
    // que el contenido nuevo esté listo cuando la usuaria llega abajo.
    final threshold = _scrollController.position.maxScrollExtent - 300;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(catalogControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catalogControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      body: state.isInitialLoading
          ? const LoadingIndicator()
          : state.error != null && state.products.isEmpty
              ? ErrorStateView(
                  message: state.error!.message,
                  onRetry: () => ref.read(catalogControllerProvider.notifier).refresh(),
                )
              : Column(
                  children: [
                    if (state.categories.isNotEmpty)
                      _CategoryFilterBar(
                        categories: state.categories,
                        selectedCategoryId: state.selectedCategoryId,
                        onSelected: (categoryId) =>
                            ref.read(catalogControllerProvider.notifier).selectCategory(categoryId),
                      ),
                    Expanded(
                      child: state.products.isEmpty
                          ? const EmptyState(
                              icon: Icons.checkroom_outlined,
                              title: 'Sin resultados',
                              message: 'No encontramos prendas en esta categoría por ahora.',
                            )
                          : RefreshIndicator(
                              onRefresh: () => ref.read(catalogControllerProvider.notifier).refresh(),
                              child: GridView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                physics: const AlwaysScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: AppSpacing.lg,
                                  crossAxisSpacing: AppSpacing.md,
                                  childAspectRatio: 0.62,
                                ),
                                itemCount: state.products.length + (state.isLoadingMore ? 2 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= state.products.length) {
                                    return const _LoadingMoreTile();
                                  }
                                  final product = state.products[index];
                                  return ProductCard(
                                    product: product,
                                    width: null,
                                    onTap: () => context.push(RoutePaths.productDetail(product.id)),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;

  const _CategoryFilterBar({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        itemCount: categories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return ChoiceChip(
              label: const Text('Todas'),
              selected: selectedCategoryId == null,
              onSelected: (_) => onSelected(null),
            );
          }
          final category = categories[index - 1];
          return ChoiceChip(
            label: Text(category.name),
            selected: selectedCategoryId == category.id,
            onSelected: (_) => onSelected(category.id),
          );
        },
      ),
    );
  }
}

class _LoadingMoreTile extends StatelessWidget {
  const _LoadingMoreTile();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary),
      ),
    );
  }
}
