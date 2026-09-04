import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/favorites/presentation/widgets/favorite_button.dart';

/// Tarjeta de producto reutilizable: imagen grande, nombre y precio,
/// siguiendo la prioridad de "imágenes grandes de producto" de la
/// sección 29. La usan Home, Catálogo y (más adelante) Favoritos.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  /// Ancho fijo para listas horizontales (Home). Si es null, la tarjeta
  /// ocupa el ancho que le dé su padre (uso en GridView, ver Catálogo).
  final double? width;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    final card = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            AspectRatio(
              aspectRatio: 4 / 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ColoredBox(color: AppColors.skeleton),
                      errorWidget: (context, url, error) => const ColoredBox(
                        color: AppColors.skeleton,
                        child: Icon(Icons.image_not_supported_outlined, color: AppColors.disabled),
                      ),
                    ),
                    if (!product.isAvailable)
                      Positioned(
                        left: AppSpacing.sm,
                        top: AppSpacing.sm,
                        child: _AvailabilityBadge(),
                      ),
                    Positioned(
                      right: AppSpacing.sm,
                      top: AppSpacing.sm,
                      child: FavoriteButton(product: product),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Bs ${product.basePrice.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );

    return width == null ? card : SizedBox(width: width, child: card);
  }
}

/// Distintivo que indica que un producto no está disponible por el
/// momento, sin ocultarlo del catálogo (el cliente igual puede consultar
/// su información aunque no pueda comprarlo).
class _AvailabilityBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        'Agotado',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textOnPrimary),
      ),
    );
  }
}
