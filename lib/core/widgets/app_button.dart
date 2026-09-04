import 'package:flutter/material.dart';
import 'package:fashion_store/core/theme/app_colors.dart';

/// Variante visual del botón: primaria (acción principal, fondo carmesí)
/// o secundaria (acción alternativa, contorno).
enum AppButtonVariant { primary, secondary }

/// Botón reutilizable de la app.
///
/// Centraliza el comportamiento de carga: cuando [isLoading] es true, el
/// botón se deshabilita y muestra un spinner en lugar del texto. Esto
/// evita reimplementar ese patrón en cada pantalla (login, checkout,
/// confirmar reserva, etc.).
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = isLoading || onPressed == null;

    final Color spinnerColor =
        variant == AppButtonVariant.primary ? AppColors.textOnPrimary : AppColors.textPrimary;

    final Widget child = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: spinnerColor),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    if (variant == AppButtonVariant.secondary) {
      return OutlinedButton(
        onPressed: disabled ? null : onPressed,
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: disabled ? null : onPressed,
      child: child,
    );
  }
}
