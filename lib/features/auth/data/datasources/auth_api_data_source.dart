import 'package:dio/dio.dart';
import 'package:fashion_store/core/network/api_endpoints.dart';
import 'package:fashion_store/features/auth/data/datasources/auth_data_source.dart';
import 'package:fashion_store/features/auth/data/models/auth_session_model.dart';

/// Implementación real: llama a los endpoints de autenticación de
/// FastAPI. Los errores de red/servidor ya llegan traducidos a
/// AppException gracias a ErrorInterceptor (ver core/network/dio_client.dart).
class AuthApiDataSource implements AuthDataSource {
  final Dio _dio;

  const AuthApiDataSource(this._dio);

  @override
  Future<AuthSessionModel> login({required String email, required String password}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return AuthSessionModel.fromJson(response.data!);
  }

  @override
  Future<AuthSessionModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: {'name': name, 'email': email, 'password': password},
    );
    return AuthSessionModel.fromJson(response.data!);
  }
}
