/// Centraliza todas las rutas de la API de FastAPI.
///
/// Ninguna URL debe escribirse directamente dentro de un datasource o
/// repositorio: siempre se referencia una constante de esta clase. Esto
/// evita rutas dispersas por el proyecto (ver sección 26 del documento).
///
/// Las rutas se agregan a medida que cada feature define su contrato con
/// el backend. No se anticipan endpoints que el backend todavía no ha
/// confirmado (ver sección 27: "no asumir que los endpoints existen").
class ApiEndpoints {
  const ApiEndpoints._();

  // Autenticación. Rutas propuestas siguiendo convención REST estándar;
  // deben confirmarse con el contrato real que exponga FastAPI.
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Catálogo. "products" admite parámetros de consulta (por ejemplo,
  // featured=true) en lugar de rutas separadas por caso de uso.
  static const String products = '/products';
  static const String categories = '/categories';

  static String productDetail(String productId) => '$products/$productId';

  static String variantAvailability(String variantId) => '/variants/$variantId/availability';

  // Favoritos. GET lista los del cliente autenticado; POST/DELETE
  // marcan y quitan un producto puntual.
  static const String favorites = '/favorites';

  static String favorite(String productId) => '$favorites/$productId';
}
