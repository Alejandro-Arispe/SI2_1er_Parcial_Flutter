import 'package:flutter/material.dart';
import 'package:fashion_store/core/theme/app_colors.dart';

/// Define la escala tipográfica de la app: títulos grandes y texto de
/// cuerpo limpio, siguiendo la jerarquía visual pedida en la sección 29.
///
/// Se usa la tipografía por defecto del sistema (Roboto en Android) para
/// no incorporar una dependencia de fuente sin confirmarlo antes con el
/// equipo (ver sección 41.9 del documento del proyecto).
class AppTypography {
  const AppTypography._();

  static const TextTheme textTheme = TextTheme(
    // Títulos grandes: portada de colección, nombre de producto en detalle.
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.2,
    ),
    displayMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.2,
    ),
    // Encabezados de sección (títulos de pantalla, nombres de categoría).
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      height: 1.25,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      height: 1.3,
    ),
    // Texto de cuerpo.
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
      height: 1.4,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
      height: 1.4,
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.35,
    ),
    // Etiquetas: precios, tallas, botones.
    labelLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      letterSpacing: 0.2,
    ),
  );
}
