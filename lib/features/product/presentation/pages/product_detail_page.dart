import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashion_store/core/error/failures.dart';
import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';
import 'package:fashion_store/core/widgets/error_state.dart';
import 'package:fashion_store/core/widgets/loading_indicator.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch_stock.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/catalog/domain/entities/product_color.dart';
import 'package:fashion_store/features/catalog/domain/entities/product_detail.dart';
import 'package:fashion_store/features/catalog/domain/entities/product_size.dart';
import 'package:fashion_store/features/catalog/domain/entities/product_variant.dart';
import 'package:fashion_store/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:fashion_store/features/product/presentation/controllers/product_detail_provider.dart';
import 'package:fashion_store/features/product/presentation/controllers/variant_availability_provider.dart';

/// Detalle de producto: galería de imágenes, precio, descripción y
/// selector de variante (talla + color, ver sección 7 del documento).
/// Recibe el id de producto desde la ruta del catálogo.
///
/// Todavía no incluye acciones de compra (agregar al carrito, reservar):
/// esas se habilitan en las Fases 13/14, una vez elegida una variante
/// concreta y disponible.
class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  String? _selectedSizeId;
  String? _selectedColorId;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del producto'),
        actions: [
          if (detailAsync.value case final detail?)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: FavoriteButton(product: _productFromDetail(detail)),
            ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, stackTrace) => ErrorStateView(
          message: error is Failure ? error.message : 'No se pudo cargar el producto.',
          onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
        ),
        data: (detail) => _ProductDetailContent(
          detail: detail,
          selectedSizeId: _selectedSizeId,
          selectedColorId: _selectedColorId,
          onSizeSelected: (sizeId) => setState(() => _selectedSizeId = sizeId),
          onColorSelected: (colorId) => setState(() => _selectedColorId = colorId),
        ),
      ),
    );
  }
}

class _ProductDetailContent extends StatelessWidget {
  final ProductDetail detail;
  final String? selectedSizeId;
  final String? selectedColorId;
  final ValueChanged<String> onSizeSelected;
  final ValueChanged<String> onColorSelected;

  const _ProductDetailContent({
    required this.detail,
    required this.selectedSizeId,
    required this.selectedColorId,
    required this.onSizeSelected,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final sizes = _distinctSizes(detail.variants);
    final colors = _distinctColors(detail.variants);
    final selectedVariant = _findVariant(detail.variants, selectedSizeId, selectedColorId);

    return ListView(
      children: [
        _ImageGallery(imageUrls: detail.imageUrls),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.categoryName,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(detail.name, style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Bs ${detail.basePrice.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.lg),
              if (sizes.isNotEmpty) ...[
                Text('Talla', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: sizes.map((size) {
                    return ChoiceChip(
                      label: Text(size.label),
                      selected: selectedSizeId == size.id,
                      onSelected: (_) => onSizeSelected(size.id),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (colors.isNotEmpty) ...[
                Text('Color', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  children: colors.map((color) {
                    return _ColorSwatch(
                      color: color,
                      selected: selectedColorId == color.id,
                      onTap: () => onColorSelected(color.id),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _VariantAvailability(
                hasSelection: selectedSizeId != null && selectedColorId != null,
                variant: selectedVariant,
              ),
              if (selectedVariant != null) ...[
                const SizedBox(height: AppSpacing.md),
                _BranchAvailabilitySection(variantId: selectedVariant.id),
              ],
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.lg),
              Text('Descripción', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(detail.description, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mensaje de disponibilidad de la variante elegida. No hay variante
/// concreta hasta que se elige talla y color a la vez (ver sección 7:
/// la app debe trabajar con la variante, no con el producto genérico).
class _VariantAvailability extends StatelessWidget {
  final bool hasSelection;
  final ProductVariant? variant;

  const _VariantAvailability({required this.hasSelection, required this.variant});

  @override
  Widget build(BuildContext context) {
    if (!hasSelection) {
      return Text(
        'Selecciona talla y color para ver disponibilidad.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      );
    }

    final isAvailable = variant?.isAvailable ?? false;
    return Row(
      children: [
        Icon(
          isAvailable ? Icons.check_circle_outline : Icons.cancel_outlined,
          size: 18,
          color: isAvailable ? AppColors.success : AppColors.error,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          isAvailable ? 'Disponible en esta talla y color.' : 'Agotado en esta combinación.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isAvailable ? AppColors.success : AppColors.error,
              ),
        ),
      ],
    );
  }
}

/// Lista de sucursales con la disponibilidad de la variante elegida
/// (ver sección 8 del documento: el cliente debe poder saber dónde está
/// disponible una prenda). Se consulta recién cuando hay una variante
/// concreta seleccionada, no antes.
class _BranchAvailabilitySection extends ConsumerWidget {
  final String variantId;

  const _BranchAvailabilitySection({required this.variantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availabilityAsync = ref.watch(variantAvailabilityProvider(variantId));

    return availabilityAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          'No se pudo consultar la disponibilidad por sucursal.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ),
      data: (branchStocks) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text('Disponibilidad por sucursal', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...branchStocks.map((branchStock) => _BranchStockTile(branchStock: branchStock)),
        ],
      ),
    );
  }
}

class _BranchStockTile extends StatelessWidget {
  final BranchStock branchStock;

  const _BranchStockTile({required this.branchStock});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            branchStock.isAvailable ? Icons.storefront : Icons.storefront_outlined,
            size: 18,
            color: branchStock.isAvailable ? AppColors.textPrimary : AppColors.disabled,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(branchStock.branch.name, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  branchStock.branch.city,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            branchStock.isAvailable ? '${branchStock.stock} disponibles' : 'Sin stock',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: branchStock.isAvailable ? AppColors.success : AppColors.error,
                ),
          ),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final ProductColor color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final swatchColor = _parseHexColor(color.hexValue);
    return Tooltip(
      message: color.name,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: swatchColor,
              border: Border.all(color: AppColors.border),
            ),
          ),
        ),
      ),
    );
  }
}

/// Convierte el detalle a la entidad Product resumida que usa el
/// feature de favoritos, para no duplicar el modelo de "producto
/// favorito" ni acoplar favoritos al detalle completo.
Product _productFromDetail(ProductDetail detail) {
  return Product(
    id: detail.id,
    name: detail.name,
    categoryId: detail.categoryId,
    basePrice: detail.basePrice,
    imageUrl: detail.imageUrls.first,
    isAvailable: detail.isAvailable,
  );
}

List<ProductSize> _distinctSizes(List<ProductVariant> variants) {
  final seenIds = <String>{};
  final result = <ProductSize>[];
  for (final variant in variants) {
    if (seenIds.add(variant.size.id)) result.add(variant.size);
  }
  return result;
}

List<ProductColor> _distinctColors(List<ProductVariant> variants) {
  final seenIds = <String>{};
  final result = <ProductColor>[];
  for (final variant in variants) {
    if (seenIds.add(variant.color.id)) result.add(variant.color);
  }
  return result;
}

ProductVariant? _findVariant(List<ProductVariant> variants, String? sizeId, String? colorId) {
  if (sizeId == null || colorId == null) return null;
  for (final variant in variants) {
    if (variant.size.id == sizeId && variant.color.id == colorId) return variant;
  }
  return null;
}

Color _parseHexColor(String hex) {
  final normalized = hex.replaceFirst('#', '');
  final withAlpha = normalized.length == 6 ? 'ff$normalized' : normalized;
  return Color(int.parse(withAlpha, radix: 16));
}

/// Carrusel de imágenes del producto con indicadores de página. Se
/// mantiene como StatefulWidget local porque el índice actual es un
/// detalle puramente visual, sin relevancia para el resto de la app.
class _ImageGallery extends StatefulWidget {
  final List<String> imageUrls;

  const _ImageGallery({required this.imageUrls});

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  final _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) => CachedNetworkImage(
              imageUrl: widget.imageUrls[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => const ColoredBox(color: AppColors.skeleton),
              errorWidget: (context, url, error) => const ColoredBox(
                color: AppColors.skeleton,
                child: Icon(Icons.image_not_supported_outlined, color: AppColors.disabled),
              ),
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: AppSpacing.md,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.imageUrls.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex ? AppColors.primary : AppColors.background,
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
