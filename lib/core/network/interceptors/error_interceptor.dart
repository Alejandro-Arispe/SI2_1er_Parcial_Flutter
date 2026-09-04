import 'package:dio/dio.dart';
import 'package:fashion_store/core/error/exceptions.dart';
import 'package:fashion_store/core/security/secure_storage_service.dart';

/// Traduce cualquier DioException a una AppException de dominio propia,
/// para que los data sources y repositorios nunca tengan que conocer los
/// detalles de Dio (tipos de error, códigos HTTP crudos, etc.).
///
/// Cuando el backend responde 401 (sesión expirada o token inválido),
/// además se limpia la sesión guardada localmente para que el resto de
/// la app quede en estado "sin autenticar" de forma consistente.
class ErrorInterceptor extends Interceptor {
  final SecureStorageService _secureStorageService;

  ErrorInterceptor(this._secureStorageService);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final mapped = await _mapDioException(err);
    handler.reject(
      DioException(requestOptions: err.requestOptions, error: mapped, type: err.type),
    );
  }

  Future<AppException> _mapDioException(DioException err) async {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          await _secureStorageService.clearSession();
          return const AuthException();
        }
        final serverMessage = _extractServerMessage(err.response?.data);
        return ServerException(serverMessage, statusCode: statusCode);
      default:
        return const NetworkException();
    }
  }

  /// FastAPI suele devolver errores como {"detail": "mensaje"}. Se intenta
  /// extraer ese mensaje; si no es posible, se usa un mensaje genérico.
  String _extractServerMessage(dynamic responseData) {
    if (responseData is Map && responseData['detail'] is String) {
      return responseData['detail'] as String;
    }
    return 'Ocurrió un error en el servidor.';
  }
}
