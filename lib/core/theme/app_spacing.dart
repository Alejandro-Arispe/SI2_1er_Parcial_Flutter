/// Escala de espaciado única para toda la app.
///
/// Usar siempre estas constantes en lugar de números sueltos permite
/// mantener el "mucho espacio en blanco" y la jerarquía visual consistente
/// que pide la sección 29 del documento del proyecto.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Radio de borde estándar para botones, cards e inputs redondeados.
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 20;
}
