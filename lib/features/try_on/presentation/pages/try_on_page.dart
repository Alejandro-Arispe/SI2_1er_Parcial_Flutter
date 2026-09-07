import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fashion_store/app/router/route_paths.dart';
import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';
import 'package:fashion_store/core/widgets/app_button.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/try_on/presentation/controllers/try_on_controller.dart';
import 'package:fashion_store/features/try_on/presentation/try_on_entry_args.dart';

/// Probador virtual por fotografía (Fase 20, ver sección 17 del
/// documento). Accesible sin sesión iniciada (sección 21: solo las
/// funciones que guardan información personalizada exigen cuenta) y
/// pensada para una prenda concreta, elegida desde el detalle de
/// producto. Contenido de cámara/AR en tiempo real: Fase 21.
class TryOnPage extends ConsumerStatefulWidget {
  final TryOnEntryArgs? entryArgs;

  const TryOnPage({super.key, this.entryArgs});

  @override
  ConsumerState<TryOnPage> createState() => _TryOnPageState();
}

class _TryOnPageState extends ConsumerState<TryOnPage> {
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final entryArgs = widget.entryArgs;
    if (entryArgs != null) {
      // No se puede escribir el estado del provider durante build/initState;
      // se agenda para el primer frame (mismo motivo que ref.listen en
      // ProductDetailPage para recentlyViewedController).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(tryOnControllerProvider.notifier).selectProduct(
          entryArgs.product,
          colorHex: entryArgs.colorHex,
        );
      });
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(source: source, maxWidth: 1280, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      ref.read(tryOnControllerProvider.notifier).setPhoto(bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('No se pudo acceder a la cámara o galería.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tryOnControllerProvider);
    final product = state.product;

    return Scaffold(
      appBar: AppBar(title: const Text('Probador virtual')),
      body: SafeArea(
        child: product == null ? const _NoProductSelected() : _TryOnContent(onPickPhoto: _pickPhoto),
      ),
    );
  }
}

class _NoProductSelected extends StatelessWidget {
  const _NoProductSelected();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.checkroom_outlined, size: 48, color: AppColors.disabled),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Elige una prenda desde el catálogo y toca "Probar con tu foto" para verla aquí.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Ver catálogo',
              icon: Icons.storefront_outlined,
              onPressed: () => context.go(RoutePaths.catalog),
            ),
          ],
        ),
      ),
    );
  }
}

class _TryOnContent extends ConsumerWidget {
  final Future<void> Function(ImageSource source) onPickPhoto;

  const _TryOnContent({required this.onPickPhoto});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tryOnControllerProvider);
    final product = state.product!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductSummary(product: product),
          const SizedBox(height: AppSpacing.lg),
          Text('Tu foto', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _PhotoPreview(photoBytes: state.photoBytes, resultBytes: state.result?.imageBytes),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Tomar foto',
                  icon: Icons.camera_alt_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => onPickPhoto(ImageSource.camera),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Galería',
                  icon: Icons.photo_library_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => onPickPhoto(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Generar vista previa',
            icon: Icons.auto_awesome_outlined,
            isLoading: state.isGenerating,
            onPressed: state.photoBytes == null
                ? null
                : () => ref.read(tryOnControllerProvider.notifier).generate(),
          ),
          if (state.error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.error!.message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            'Esta vista previa se genera en tu dispositivo mientras no hay una conexión al '
            'backend con Gemini. Tu foto no se guarda ni se comparte: solo se usa para armar '
            'esta vista previa.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ProductSummary extends StatelessWidget {
  final Product product;

  const _ProductSummary({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Image.network(
            product.imageUrl,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const ColoredBox(
              color: AppColors.skeleton,
              child: SizedBox(width: 56, height: 56),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(product.name, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final Uint8List? photoBytes;
  final Uint8List? resultBytes;

  const _PhotoPreview({required this.photoBytes, required this.resultBytes});

  @override
  Widget build(BuildContext context) {
    final bytesToShow = resultBytes ?? photoBytes;

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.skeleton,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: bytesToShow == null
            ? const Center(
                child: Icon(Icons.image_outlined, size: 40, color: AppColors.disabled),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: Image.memory(bytesToShow, fit: BoxFit.cover),
              ),
      ),
    );
  }
}
