import 'package:flutter/material.dart';

/// Paleta de colores de FashionStore.
///
/// Basada en la descripción textual de identidad visual del documento del
/// proyecto (sección 29): fondo claro, mucho blanco, negro para textos
/// principales y rojo/carmesí como color de acción. Se ajustará más
/// adelante si se proporcionan capturas de referencia oficiales.
class AppColors {
  const AppColors._();

  // Color principal de marca: usado en botones de acción, enlaces activos,
  // selección de talla/color, badges de estado destacado.
  static const Color primary = Color(0xFFC41E3A);
  static const Color primaryDark = Color(0xFF9E1730);

  // Fondo general de la app y superficies (cards, sheets).
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  // Texto.
  static const Color textPrimary = Color(0xFF141414);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Bordes suaves para cards e inputs, siguiendo el estilo minimalista.
  static const Color border = Color(0xFFE6E6E6);
  static const Color divider = Color(0xFFF0F0F0);

  // Estados semánticos. Se usa un rojo distinto al de marca para que un
  // mensaje de error no se confunda visualmente con un botón de acción.
  static const Color error = Color(0xFFB3261E);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFB8860B);

  // Superficie deshabilitada / placeholders de carga.
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color skeleton = Color(0xFFF2F2F2);
}
