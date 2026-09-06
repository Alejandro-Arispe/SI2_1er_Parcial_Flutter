import 'dart:async';

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
import 'package:fashion_store/features/cart/presentation/widgets/cart_icon_button.dart';
import 'package:fashion_store/features/catalog/domain/entities/category.dart';
import 'package:fashion_store/features/catalog/presentation/controllers/catalog_controller.dart';
import 'package:fashion_store/features/catalog/presentation/widgets/product_card.dart';
import 'package:fashion_store/features/reservations/presentation/widgets/reservation_icon_button.dart';

/// Precio máximo considerado por el filtro de rango. Es un límite
/// razonable para los datos de desarrollo actuales; cuando el backend
/// defina el rango real de precios del catálogo, este valor debe
/// ajustarse (o consultarse dinámicamente) en lugar de quedar fijo.
const double _maxFilterablePrice = 500;

/// Catálogo completo: búsqueda por texto, filtro por categoría, filtros
/// de disponibilidad y rango de precio, y listado paginado con scroll
/// infinito. No incluye talla/color/temporada: esos filtros llegan
/// cuando exista el modelo de variantes (Fase 10).
class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
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

  /// Espera una pausa breve en la escritura antes de buscar, para no
  /// disparar una consulta por cada letra tecleada.
  void _onSearchChanged(String value) {
    // Redibuja de inmediato solo para mostrar/ocultar el botón de
    // limpiar; la búsqueda real se dispara con debounce más abajo.
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(catalogControllerProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catalogControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          const CartIconButton(),
          const ReservationIconButton(),
          IconButton(
            tooltip: 'Filtros',
            onPressed: state.isInitialLoading
                ? null
                : () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _FilterSheet(state: state),
                    ),
            icon: Icon(
              state.hasActiveFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: state.hasActiveFilters ? AppColors.primary : null,
            ),
          ),
        ],
      ),
      body: state.isInitialLoading
          ? const LoadingIndicator()
          : state.error != null && state.products.isEmpty
              ? ErrorStateView(
                  message: state.error!.message,
                  onRetry: () => ref.read(catalogControllerProvider.notifier).refresh(),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Buscar prendas...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _searchController.clear();
                                    _debounce?.cancel();
                                    ref.read(catalogControllerProvider.notifier).search('');
                                  },
                                ),
                        ),
                      ),
                    ),
                    if (state.categories.isNotEmpty)
                      _CategoryFilterBar(
                        categories: state.categories,
                        selectedCategoryId: state.selectedCategoryId,
                        onSelected: (categoryId) =>
                            ref.read(catalogControllerProvider.notifier).selectCategory(categoryId),
                      ),
                    Expanded(
                      child: state.products.isEmpty
                          ? EmptyState(
                              icon: Icons.search_off,
                              title: 'Sin resultados',
                              message: state.searchQuery.isNotEmpty || state.hasActiveFilters
                                  ? 'No encontramos prendas con estos filtros. Intenta ajustarlos.'
                                  : 'No encontramos prendas en esta categoría por ahora.',
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

/// Hoja inferior con los filtros de disponibilidad y rango de precio.
/// Aplica los cambios recién al tocar "Aplicar filtros", para no
/// disparar una consulta por cada movimiento del slider.
class _FilterSheet extends ConsumerStatefulWidget {
  final CatalogState state;

  const _FilterSheet({required this.state});

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late bool _onlyAvailable = widget.state.onlyAvailable;
  late RangeValues _priceRange = RangeValues(
    widget.state.minPrice ?? 0,
    widget.state.maxPrice ?? _maxFilterablePrice,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtros', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Solo disponibles'),
            value: _onlyAvailable,
            onChanged: (value) => setState(() => _onlyAvailable = value),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Precio', style: Theme.of(context).textTheme.titleMedium),
          Text(
            'Bs ${_priceRange.start.round()} - Bs ${_priceRange.end.round()}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: _maxFilterablePrice,
            divisions: 20,
            labels: RangeLabels(
              'Bs ${_priceRange.start.round()}',
              'Bs ${_priceRange.end.round()}',
            ),
            onChanged: (values) => setState(() => _priceRange = values),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Aplicar filtros',
            onPressed: () {
              ref.read(catalogControllerProvider.notifier).applyFilters(
                    onlyAvailable: _onlyAvailable,
                    minPrice: _priceRange.start > 0 ? _priceRange.start : null,
                    maxPrice: _priceRange.end < _maxFilterablePrice ? _priceRange.end : null,
                  );
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Limpiar filtros',
            variant: AppButtonVariant.secondary,
            onPressed: () {
              ref.read(catalogControllerProvider.notifier).applyFilters(
                    onlyAvailable: false,
                    minPrice: null,
                    maxPrice: null,
                  );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
