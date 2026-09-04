import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fashion_store/app/router/route_paths.dart';
import 'package:fashion_store/core/error/failures.dart';
import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';
import 'package:fashion_store/core/widgets/error_state.dart';
import 'package:fashion_store/core/widgets/loading_indicator.dart';
import 'package:fashion_store/features/catalog/domain/entities/category.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/catalog/presentation/controllers/catalog_controller.dart';
import 'package:fashion_store/features/catalog/presentation/widgets/product_card.dart';
import 'package:fashion_store/features/home/presentation/controllers/home_controller.dart';
import 'package:fashion_store/shared/session/session_controller.dart';
import 'package:fashion_store/shared/session/session_state.dart';

/// Pantalla principal del cliente: saludo, categorías destacadas y
/// productos destacados. Consume el catálogo a través de
/// homeControllerProvider (mock por ahora, reemplazable por la API real
/// cambiando AppConfig.useMockData).
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);
    final session = ref.watch(sessionControllerProvider);
    final userName = session is SessionAuthenticated ? session.user.name : null;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(homeControllerProvider.notifier).refresh(),
          child: homeState.when(
            loading: () => const LoadingIndicator(),
            error: (error, stackTrace) => ErrorStateView(
              message: error is Failure ? error.message : 'No se pudo cargar el catálogo.',
              onRetry: () => ref.read(homeControllerProvider.notifier).refresh(),
            ),
            data: (data) => _HomeContent(userName: userName, data: data),
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final String? userName;
  final HomeData data;

  const _HomeContent({required this.userName, required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName != null && userName!.isNotEmpty ? 'Hola, $userName' : 'FashionStore',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Comercio inteligente. Descubre la nueva colección.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (data.categories.isNotEmpty) ...[
          _SectionTitle('Categorías'),
          const SizedBox(height: AppSpacing.sm),
          _CategoryList(categories: data.categories),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (data.featuredProducts.isNotEmpty) ...[
          _SectionTitle('Destacados'),
          const SizedBox(height: AppSpacing.sm),
          _FeaturedProductList(products: data.featuredProducts),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<Category> categories;

  const _CategoryList({required this.categories});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final category = categories[index];
          return _CategoryChip(category: category);
        },
      ),
    );
  }
}

class _CategoryChip extends ConsumerWidget {
  final Category category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        // catalogControllerProvider es global: preseleccionar la
        // categoría aquí hace que el catálogo abra ya filtrado.
        ref.read(catalogControllerProvider.notifier).selectCategory(category.id);
        context.go(RoutePaths.catalog);
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Column(
        children: [
          CircleAvatar(radius: 30, backgroundColor: AppColors.skeleton, backgroundImage: NetworkImage(category.imageUrl)),
          const SizedBox(height: AppSpacing.xs),
          Text(category.name, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _FeaturedProductList extends StatelessWidget {
  final List<Product> products;

  const _FeaturedProductList({required this.products});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            onTap: () => context.push(RoutePaths.productDetail(product.id)),
          );
        },
      ),
    );
  }
}
