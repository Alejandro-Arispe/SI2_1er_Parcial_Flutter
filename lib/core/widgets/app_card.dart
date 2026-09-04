import 'package:flutter/material.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';

/// Contenedor tipo tarjeta reutilizable: bordes suaves, esquinas
/// redondeadas y sin sombra pronunciada, siguiendo el estilo minimalista
/// pedido en la sección 29. Se usará como base para las tarjetas de
/// producto del catálogo, resumen de reserva, resumen de pedido, etc.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: card,
    );
  }
}
