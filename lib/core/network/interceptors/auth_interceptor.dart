import 'package:dio/dio.dart';
import 'package:fashion_store/core/security/secure_storage_service.dart';

/// Adjunta el token de acceso guardado (si existe) a cada solicitud saliente.
///
/// No falla si no hay token: muchos endpoints del catálogo son públicos
/// (ver sección 21, "acceso sin cuenta"). Los endpoints que requieren
/// sesión devolverán 401 si el token falta o expiró, y ese caso lo
/// resuelve ErrorInterceptor.
class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorageService;

  AuthInterceptor(this._secureStorageService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _secureStorageService.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
