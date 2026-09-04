/// Failures de dominio: representan errores ya traducidos a un lenguaje que
/// la capa de presentación puede mostrar al usuario, sin detalles técnicos
/// (sin stack traces, sin mensajes crudos del servidor).
///
/// Los repositorios son responsables de capturar las excepciones de la capa
/// de datos (ver core/error/exceptions.dart) y convertirlas en un Failure
/// mediante ErrorMapper.
sealed class Failure {
  final String message;
  const Failure(this.message);
}

/// Error de conectividad: el dispositivo no tiene conexión a internet.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexión a internet.']);
}

/// El servidor tardó demasiado en responder.
final class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'La solicitud tardó demasiado. Intenta nuevamente.']);
}

/// Error devuelto por el backend (FastAPI) con un mensaje específico.
final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Ocurrió un error en el servidor.']);
}

/// Error de autenticación: credenciales inválidas o sesión expirada.
final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Sesión inválida o expirada.']);
}

/// Error de validación de datos enviados por el usuario.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Error al leer o escribir datos locales (caché, almacenamiento seguro).
final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'No se pudo acceder a los datos locales.']);
}

/// Cualquier error no clasificado explícitamente.
final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Ocurrió un error inesperado.']);
}
