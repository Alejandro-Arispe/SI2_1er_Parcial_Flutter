import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';
import 'package:fashion_store/core/widgets/app_button.dart';
import 'package:fashion_store/core/widgets/loading_indicator.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/try_on/presentation/controllers/ar_garment_options_provider.dart';
import 'package:fashion_store/features/try_on/presentation/controllers/ar_try_on_controller.dart';
import 'package:fashion_store/features/try_on/presentation/try_on_entry_args.dart';
import 'package:fashion_store/features/try_on/presentation/widgets/garment_overlay_painter.dart';

/// Probador virtual por cámara/AR (Fase 21, sección 17.2 del documento).
/// A diferencia del modo fotografía (Fase 20), este flujo es en vivo:
/// pide cámara, hace seguimiento corporal en tiempo real y superpone la
/// prenda mientras la clienta se mueve, sin enviar ningún frame a Gemini
/// (sección 37: "no tratar Gemini como motor de AR en tiempo real").
class ArTryOnPage extends ConsumerStatefulWidget {
  final TryOnEntryArgs? entryArgs;

  const ArTryOnPage({super.key, this.entryArgs});

  @override
  ConsumerState<ArTryOnPage> createState() => _ArTryOnPageState();
}

class _ArTryOnPageState extends ConsumerState<ArTryOnPage> {
  @override
  void initState() {
    super.initState();
    // No se puede escribir el estado del provider durante build/initState
    // (mismo motivo que en TryOnPage): se agenda para el primer frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(arTryOnControllerProvider.notifier);
      final product = widget.entryArgs?.product;
      if (product != null) notifier.selectProduct(product);
      notifier.start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(arTryOnControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Probador con cámara')),
      body: SafeArea(child: _buildBody(state)),
    );
  }

  Widget _buildBody(ArTryOnState state) {
    switch (state.status) {
      case ArTryOnStatus.idle:
      case ArTryOnStatus.checkingAvailability:
      case ArTryOnStatus.requestingPermission:
      case ArTryOnStatus.starting:
        return const Center(child: LoadingIndicator());

      case ArTryOnStatus.unavailable:
        return const _ArStatusMessage(
          icon: Icons.videocam_off_outlined,
          message:
              'Este dispositivo no tiene una cámara disponible para el probador con AR. '
              'Puedes usar el probador con fotografía en su lugar.',
        );

      case ArTryOnStatus.permissionDenied:
        return _ArStatusMessage(
          icon: Icons.no_photography_outlined,
          message:
              'FashionStore necesita permiso de cámara para mostrarte la prenda en vivo '
              'sobre ti. Sin ese permiso este modo no puede funcionar.',
          actionLabel: 'Abrir configuración',
          onAction: () => ref.read(arTryOnControllerProvider.notifier).openSettings(),
        );

      case ArTryOnStatus.cameraError:
        return _ArStatusMessage(
          icon: Icons.error_outline,
          message: 'No se pudo iniciar la cámara. Intenta de nuevo.',
          actionLabel: 'Reintentar',
          onAction: () => ref.read(arTryOnControllerProvider.notifier).start(),
        );

      case ArTryOnStatus.tracking:
        return _ArTrackingView(state: state);
    }
  }
}

class _ArStatusMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ArStatusMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.disabled),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

class _ArTrackingView extends ConsumerWidget {
  final ArTryOnState state;

  const _ArTrackingView({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(arTryOnControllerProvider.notifier).previewController;
    final product = state.product;

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (controller != null && controller.value.isInitialized)
                CameraPreview(controller)
              else
                const ColoredBox(
                  color: AppColors.skeleton,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'Vista previa de cámara no disponible en este entorno.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              if (state.pose != null && state.garmentImage != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: GarmentOverlayPainter(pose: state.pose!, garmentImage: state.garmentImage!),
                  ),
                ),
              if (state.pose == null)
                Positioned(
                  bottom: AppSpacing.lg,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  child: _HintBanner(text: 'Ubícate frente a la cámara, de cuerpo entero.'),
                ),
            ],
          ),
        ),
        if (product != null) _GarmentSwitcher(currentProduct: product),
      ],
    );
  }
}

class _HintBanner extends StatelessWidget {
  final String text;

  const _HintBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xB3000000),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Text(text, style: const TextStyle(color: AppColors.textOnPrimary)),
        ),
      ),
    );
  }
}

/// Tira horizontal para cambiar de prenda sin salir de la cámara en
/// vivo (sección 17.2: "selección/cambio de prendas"). Se limita a
/// prendas de la misma categoría que la elegida al entrar, para que las
/// opciones sean relevantes en lugar de mostrar todo el catálogo.
class _GarmentSwitcher extends ConsumerWidget {
  final Product currentProduct;

  const _GarmentSwitcher({required this.currentProduct});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final optionsAsync = ref.watch(arGarmentOptionsProvider(currentProduct.categoryId));

    return SizedBox(
      height: 96,
      child: optionsAsync.when(
        loading: () => const Center(
          child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (error, stackTrace) => const SizedBox.shrink(),
        data: (options) {
          if (options.isEmpty) return const SizedBox.shrink();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            itemCount: options.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final option = options[index];
              final selected = option.id == currentProduct.id;
              return GestureDetector(
                onTap: () => ref.read(arTryOnControllerProvider.notifier).selectProduct(option),
                child: Container(
                  width: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Image.network(option.imageUrl, fit: BoxFit.cover),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
