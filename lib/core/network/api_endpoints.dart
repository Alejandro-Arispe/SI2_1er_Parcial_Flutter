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

  // Carrito. GET lista los ítems del cliente autenticado; POST agrega
  // una variante (el servidor resuelve nombre/imagen/precio); PATCH/DELETE
  // actúan sobre un ítem puntual por su id.
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';

  static String cartItem(String cartItemId) => '$cartItems/$cartItemId';

  // Reservas. GET lista las del cliente autenticado; POST crea una
  // reserva (variante + sucursal); PATCH actualiza su estado (por
  // ejemplo, cancelarla).
  static const String reservations = '/reservations';

  static String reservation(String reservationId) => '$reservations/$reservationId';

  // Sucursales físicas de la empresa (ver sección 8 del documento).
  static const String branches = '/branches';

  // Pedidos. POST crea un pedido a partir del carrito (Fase 15); GET
  // lista el historial del cliente autenticado (Fase 17). El pago
  // (Fase 16) confirma un pedido puntual con el payment_method_id que
  // entrega Stripe al tokenizar la tarjeta en el cliente; el servidor es
  // quien crea y confirma el PaymentIntent con la clave secreta (ver
  // sección 13: la clave secreta nunca vive en Flutter).
  static const String orders = '/orders';

  static String orderPayment(String orderId) => '$orders/$orderId/pay';

  // Asistente inteligente (Fase 18, ver sección 14 del documento): el
  // backend reenvía el mensaje a Gemini con el contexto real del
  // catálogo. Flutter nunca llama a Gemini directamente ni maneja su
  // clave (sección 32).
  static const String assistantMessages = '/assistant/messages';
}
