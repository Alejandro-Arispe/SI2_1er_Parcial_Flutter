/// Excepciones de la capa de datos (data sources / red / almacenamiento
/// local). Se lanzan desde los data sources y son capturadas por los
/// repositorios, que las traducen a un Failure de dominio mediante
/// ErrorMapper antes de que lleguen a la capa de presentación.
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);
}

/// Sin conexión a internet en el momento de la solicitud.
final class NetworkException extends AppException {
  const NetworkException([super.message = 'Sin conexión a internet.']);
}

/// La solicitud excedió el tiempo de espera configurado en Dio.
final class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Tiempo de espera agotado.']);
}

/// El backend respondió con un error (4xx/5xx) distinto de autenticación.
final class ServerException extends AppException {
  final int? statusCode;
  const ServerException(super.message, {this.statusCode});
}

/// El backend respondió 401/403: token inválido, ausente o expirado.
final class AuthException extends AppException {
  const AuthException([super.message = 'No autorizado.']);
}

/// Error al leer o escribir en almacenamiento local (secure storage, caché).
final class CacheException extends AppException {
  const CacheException([super.message = 'Error de almacenamiento local.']);
}
