import 'package:flutter/material.dart';
import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';

/// Pantalla temporal usada por las features que todavía no tienen su
/// implementación real (se construyen en fases posteriores del plan).
/// Permite verificar la navegación de la Fase 4 sin adelantar contenido
/// de negocio de otras fases.
class PlaceholderPage extends StatelessWidget {
  final String title;
  final String message;

  const PlaceholderPage({
    super.key,
    required this.title,
    this.message = 'Esta pantalla se implementará en una fase posterior del plan.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction_outlined, size: 48, color: AppColors.disabled),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
