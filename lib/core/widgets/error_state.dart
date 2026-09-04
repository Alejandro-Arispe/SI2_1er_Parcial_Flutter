import 'package:flutter/material.dart';
import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';
import 'package:fashion_store/core/widgets/app_button.dart';

/// Estado de error reutilizable: se muestra cuando un caso de uso falla
/// (sin conexión, error de servidor, error de autenticación, etc.).
///
/// Recibe el mensaje ya traducido por ErrorMapper (nunca un stack trace
/// ni un detalle técnico, ver sección 33 del documento del proyecto) y
/// expone un botón de reintentar.
class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateView({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: 'Reintentar', onPressed: onRetry, variant: AppButtonVariant.secondary),
            ],
          ],
        ),
      ),
    );
  }
}
