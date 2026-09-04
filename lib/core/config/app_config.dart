/// Configuración centralizada de la aplicación.
///
/// Todos los valores se leen en tiempo de compilación mediante
/// --dart-define, nunca hardcodeados. Esto permite cambiar de entorno
/// (desarrollo, pruebas, producción) sin modificar código, y evita que
/// claves o URLs queden dispersas por el proyecto (ver sección 26 y 32
/// del documento del proyecto: ninguna clave secreta va dentro de Flutter).
///
/// Ejemplo de ejecución apuntando a un backend local durante desarrollo:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
class AppConfig {
  const AppConfig._();

  /// URL base del backend FastAPI. El valor por defecto (10.0.2.2) es la
  /// dirección que usa el emulador de Android para llegar al localhost
  /// de la máquina anfitriona durante el desarrollo.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  /// Cuando es true, los repositorios usan datasources de desarrollo
  /// (mock) en lugar de llamar al backend real. Debe pasar a false a
  /// medida que cada endpoint de FastAPI quede disponible.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );

  /// Clave publicable de Stripe (segura para incluir en el cliente).
  /// La clave secreta de Stripe NUNCA debe estar aquí: vive únicamente
  /// en el backend (ver sección 13 del documento del proyecto).
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  /// Tiempo máximo de espera para conexión y respuesta HTTP.
  static const Duration networkTimeout = Duration(seconds: 20);
}
