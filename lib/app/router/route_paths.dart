/// Centraliza todas las rutas de navegación de la app. Ningún widget debe
/// escribir un path literal: siempre se referencia una constante de aquí
/// (mismo criterio que ApiEndpoints para las rutas de red).
class RoutePaths {
  const RoutePaths._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';

  // Ramas del shell con navegación inferior (ver MainScaffold).
  static const String home = '/home';
  static const String catalog = '/catalog';
  static const String favorites = '/favorites';
  static const String profile = '/profile';

  // Rutas de nivel superior, fuera del shell.
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String reservations = '/reservations';
  static const String tryOn = '/try-on';
  static const String aiAssistant = '/ai-assistant';

  static String productDetail(String productId) => '$catalog/product/$productId';
  static const String productDetailPattern = 'product/:productId';

  /// Rutas que exigen sesión iniciada (ver sección 21 del documento:
  /// favoritos, reservas, compra, historial, perfil e IA personalizada
  /// requieren cuenta; el catálogo y el detalle de producto son públicos).
  static const List<String> protectedPaths = [
    favorites,
    checkout,
    orders,
    reservations,
    profile,
    aiAssistant,
  ];

  static const List<String> authPaths = [login, register];
}
