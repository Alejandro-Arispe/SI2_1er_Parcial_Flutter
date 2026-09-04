import 'package:fashion_store/core/error/exceptions.dart';
import 'package:fashion_store/core/error/failures.dart';

/// Traduce las excepciones de la capa de datos (AppException) a Failures de
/// dominio. Los repositorios llaman a este mapper dentro de su bloque
/// catch para no filtrar detalles técnicos hacia la presentación.
class ErrorMapper {
  const ErrorMapper._();

  static Failure map(Object error) {
    if (error is NetworkException) return NetworkFailure(error.message);
    if (error is TimeoutException) return TimeoutFailure(error.message);
    if (error is AuthException) return AuthFailure(error.message);
    if (error is ServerException) return ServerFailure(error.message);
    if (error is CacheException) return CacheFailure(error.message);
    return const UnknownFailure();
  }
}
